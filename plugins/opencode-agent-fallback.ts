/**
 * opencode-agent-fallback
 *
 * Plugin para OpenCode que detecta rate limits e faz fallback de modelo
 * por agente, com lista de fallback configurável individualmente.
 *
 * Instalação:
 *   Copie este arquivo para ~/.config/opencode/plugins/opencode-agent-fallback.ts
 *
 * Configuração:
 *   Crie ~/.opencode/config/agent-fallback.json (veja exemplo abaixo)
 *
 * Exemplo de config:
 * {
 *   "enabled": true,
 *   "cooldownMs": 60000,
 *   "agents": {
 *     "test-engineer": {
 *       "fallbackModels": [
 *         { "providerID": "openrouter", "modelID": "z-ai/glm-4.5-air:free" },
 *         { "providerID": "openrouter", "modelID": "minimax-m2.5-free" },
 *         { "providerID": "zai-coding-plan", "modelID": "glm-4.5-air" }
 *       ]
 *     },
 *     "backend-developer": {
 *       "fallbackModels": [
 *         { "providerID": "zai-coding-plan", "modelID": "glm-5-turbo" },
 *         { "providerID": "zai-coding-plan", "modelID": "glm-4.7" }
 *       ]
 *     }
 *   },
 *   "fallbackModels": [
 *     { "providerID": "zai-coding-plan", "modelID": "glm-4.7" }
 *   ]
 * }
 */

// @ts-ignore
import type { Plugin } from "@opencode-ai/plugin";
// @ts-ignore
import { readFileSync, existsSync } from "fs";
// @ts-ignore
import { join } from "path";
// @ts-ignore
import { homedir } from "os"; // FIX #1: homedir vem de "os", não de "path"

// ─── Types ────────────────────────────────────────────────────────────────────

interface FallbackModel {
  providerID: string;
  modelID: string;
}

interface AgentFallbackConfig {
  fallbackModels: FallbackModel[];
  cooldownMs?: number;
}

interface PluginConfig {
  enabled?: boolean;
  cooldownMs?: number;
  agents?: Record<string, AgentFallbackConfig>;
  fallbackModels?: FallbackModel[];
  patterns?: string[];
  logging?: boolean;
}

interface SessionState {
  agentID: string | null;
  providerID: string;
  modelID: string;
  fallbackIndex: number;
  rateLimitedUntil: number;
  lastUserMessage: string;
  lastUserMessageID: string | null;
  parentSessionID: string | null;
}

// ─── Config Loader ────────────────────────────────────────────────────────────

function loadConfig(directory: string, worktree: string): PluginConfig {
  const candidates = [
    join(worktree, ".opencode", "config", "agent-fallback.json"),
    join(directory, ".opencode", "config", "agent-fallback.json"),
    join(homedir(), ".opencode", "config", "agent-fallback.json"),
    join(homedir(), ".config", "opencode", "config", "agent-fallback.json"),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      try {
        const raw = readFileSync(candidate, "utf-8");
        return JSON.parse(raw) as PluginConfig;
      } catch {
        // arquivo inválido, tenta o próximo
      }
    }
  }

  return {};
}

// ─── Rate Limit Detector ──────────────────────────────────────────────────────

const DEFAULT_PATTERNS = [
  "rate limit",
  "usage limit",
  "usage exceeded",
  "too many requests",
  "quota exceeded",
  "high concurrency",
  "reduce concurrency",
  "overloaded",
  "capacity exceeded",
  "free usage exceeded",
  // NOTA: "credits" foi removido — muito genérico, causa falsos positivos
];

// FIX #2: error nos eventos é um objeto tipado (ApiError | ProviderAuthError | etc),
// não uma string. Extraímos a mensagem corretamente antes de comparar.
function getRateLimitError(value: unknown, patterns: string[]): string | null {
  let message: string;

  if (typeof value === "string") {
    message = value;
  } else if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    // ApiError / UnknownError / ProviderAuthError: { name, data: { message } }
    const data = obj["data"] as Record<string, unknown> | undefined;
    message = String(data?.["message"] ?? obj["message"] ?? JSON.stringify(obj));
  } else {
    return null;
  }

  const lower = message.toLowerCase();
  const matched = patterns.find((p) => lower.includes(p.toLowerCase()));

  return matched ? message : null;
}

// ─── Logger ───────────────────────────────────────────────────────────────────

function makeLog(enabled: boolean, client: any) {
  return (level: "info" | "warn" | "error", msg: string, extra?: Record<string, unknown>) => {
    if (!enabled) return;
    // Não usamos await aqui para não bloquear o fluxo principal
    client.app
      .log({ body: { service: "agent-fallback", level, message: msg, extra } })
      .catch(() => { });
  };
}

// ─── Toast Helper ─────────────────────────────────────────────────────────────

// FIX #3: API correta confirmada em types.gen.ts — EventTuiToastShow:
// { type: "tui.toast.show", properties: { title?, message, variant, duration? } }
// O SDK expõe isso via client.tui.showToast({ body: { message, variant, title?, duration? } })
// variant: "info" | "success" | "warning" | "error"
async function showToast(
  client: any,
  message: string,
  variant: "info" | "success" | "warning" | "error",
  title?: string,
): Promise<void> {
  try {
    await client.tui.showToast({
      body: { message, variant, ...(title ? { title } : {}), duration: 5000 },
    });
  } catch {
    // modo headless — sem TUI, ignora silenciosamente
  }
}

// ─── Plugin ───────────────────────────────────────────────────────────────────

export const AgentFallbackPlugin: Plugin = async ({ client, directory, worktree }: any) => {
  const config = loadConfig(directory, worktree);

  if (config.enabled === false) return {};

  const log = makeLog(config.logging ?? true, client);
  const patterns = [...DEFAULT_PATTERNS, ...(config.patterns ?? [])];
  const globalCooldown = config.cooldownMs ?? 60_000;

  const sessions = new Map<string, SessionState>();

  // Guard para evitar double-trigger na mesma sessão
  const handling = new Set<string>();

  // ── Helpers ────────────────────────────────────────────────────────────────

  function getOrCreateSession(sessionID: string): SessionState {
    if (!sessions.has(sessionID)) {
      sessions.set(sessionID, {
        agentID: null,
        providerID: "",
        modelID: "",
        fallbackIndex: 0,
        rateLimitedUntil: 0,
        lastUserMessage: "",
        lastUserMessageID: null,
        parentSessionID: null,
      });
    }
    return sessions.get(sessionID)!;
  }

  function getFallbackList(state: SessionState): FallbackModel[] {
    if (state.agentID && config.agents?.[state.agentID]?.fallbackModels !== undefined) {
      return config.agents[state.agentID].fallbackModels;
    }
    return config.fallbackModels ?? [];
  }

  function getCooldown(state: SessionState): number {
    if (state.agentID && config.agents?.[state.agentID]?.cooldownMs !== undefined) {
      return config.agents[state.agentID].cooldownMs!;
    }
    return globalCooldown;
  }

  // ── Fallback Handler ───────────────────────────────────────────────────────

  async function handleRateLimit(sessionID: string, errorMessage: string): Promise<void> {
    if (handling.has(sessionID)) return;
    handling.add(sessionID);

    try {
      const state = getOrCreateSession(sessionID);
      const now = Date.now();

      if (state.rateLimitedUntil > now) {
        log("info", `[${sessionID}] Em cooldown, ignorando`, {
          agentID: state.agentID,
          until: new Date(state.rateLimitedUntil).toISOString(),
        });
        return;
      }

      const fallbackList = getFallbackList(state);

      if (!fallbackList.length) {
        log("warn", `[${sessionID}] Sem modelos de fallback configurados`, { agentID: state.agentID });
        await showToast(client, `⚠️ Sem fallback para [${state.agentID ?? "agente"}]`, "warning");
        return;
      }

      if (state.fallbackIndex >= fallbackList.length) {
        state.fallbackIndex = 0;
        log("warn", `[${sessionID}] Lista esgotada, reiniciando`, { agentID: state.agentID });
      }

      const nextModel = fallbackList[state.fallbackIndex];
      state.fallbackIndex++;
      state.rateLimitedUntil = now + getCooldown(state);

      const fromModel =
        state.providerID && state.modelID ? `${state.providerID}/${state.modelID}` : "modelo atual";
      const toModel = `${nextModel.providerID}/${nextModel.modelID}`;
      const agentLabel = state.agentID ? ` [${state.agentID}]` : "";

      log("info", `[${sessionID}] Rate limit — iniciando fallback`, {
        agentID: state.agentID,
        from: fromModel,
        to: toModel,
        index: state.fallbackIndex,
      });

      // Aborta e Reverte para limpar o estado antes do retry
      try {
        await client.session.abort({ path: { id: sessionID } });
        await client.session.revert({ path: { id: sessionID } });
      } catch {
        // Pode falhar se já estiver idle — continua
      }

      // Toast consolidado conforme pedido do usuário: Erro + Transição
      // Limitamos o tamanho da mensagem de erro para o toast ficar legível
      const shortError = errorMessage.length > 60 ? errorMessage.substring(0, 57) + "..." : errorMessage;
      await showToast(
        client,
        `🚨 ${shortError}\n🔄 Fallback${agentLabel}: ${fromModel} ➜ ${toModel}`,
        "warning",
        "Rate Limit Detectado",
      );

      await new Promise<void>((r) => setTimeout(r, 600));

      if (!state.lastUserMessage) {
        log("warn", `[${sessionID}] Sem mensagem para resubmeter`);
        return;
      }

      try {
        await client.session.prompt({
          path: { id: sessionID },
          body: {
            model: {
              providerID: nextModel.providerID,
              modelID: nextModel.modelID,
            },
            parts: [{ type: "text", text: state.lastUserMessage }],
          },
        });

        log("info", `[${sessionID}] Fallback bem-sucedido`, { from: fromModel, to: toModel });

        // Toast de confirmação final
        await showToast(
          client,
          `✅ Atividade retomada com ${toModel}`,
          "success",
          "Fallback Realizado",
        );
      } catch (err) {
        log("error", `[${sessionID}] Falha no fallback`, { error: String(err), to: toModel });

        await showToast(
          client,
          `❌ Erro ao tentar ${toModel}: ${String(err)}`,
          "error",
          "Falha no Fallback",
        );
      }
    } finally {
      handling.delete(sessionID);
    }
  }

  // ── Event Handler ──────────────────────────────────────────────────────────

  return {
    event: async ({ event }: any) => {
      const e = event as { type: string; properties: Record<string, any> };

      switch (e.type) {

        // ── message.updated ─────────────────────────────────────────────────
        // Tipo: EventMessageUpdated → { info: Message }
        // Message = UserMessage | AssistantMessage
        //
        // UserMessage campos relevantes:
        //   info.agent   → nome do agente (ex: "test-engineer")
        //   info.model   → { providerID, modelID }
        //   info.id      → messageID
        //
        // AssistantMessage campos relevantes:
        //   info.mode      → nome do agente (ex: "test-engineer")
        //   info.providerID / info.modelID → modelo usado
        //   info.error     → ProviderAuthError | ApiError | UnknownError | ...
        case "message.updated": {
          const info = e.properties?.info;
          if (!info?.sessionID) break;

          const sessionID: string = info.sessionID;
          const state = getOrCreateSession(sessionID);

          if (info.role === "user") {
            // FIX #6: campo correto é info.agent, não info.agentID
            if (info.agent) state.agentID = info.agent;
            if (info.model?.providerID) state.providerID = info.model.providerID;
            if (info.model?.modelID) state.modelID = info.model.modelID;
            if (info.id) state.lastUserMessageID = info.id;

            // Parts podem não estar presentes aqui — chegam via message.part.updated
            if (Array.isArray(info.parts)) {
              const text = info.parts
                .filter((p: any) => p.type === "text" && !p.synthetic)
                .map((p: any) => String(p.text ?? ""))
                .join("\n")
                .trim();
              if (text) state.lastUserMessage = text;
            }

          } else if (info.role === "assistant") {
            // FIX #7: campo correto é info.mode para AssistantMessage
            if (info.mode) state.agentID = info.mode;
            if (info.providerID) state.providerID = info.providerID;
            if (info.modelID) state.modelID = info.modelID;

            // Detecta rate limit no error da AssistantMessage
            if (info.error) {
              const err = getRateLimitError(info.error, patterns);
              if (err) await handleRateLimit(sessionID, err);
            }
          }
          break;
        }

        // ── message.part.updated ────────────────────────────────────────────
        // Tipo: EventMessagePartUpdated → { part: Part, delta?: string }
        // Captura texto de user messages e detecta RetryPart de rate limit
        case "message.part.updated": {
          const part = e.properties?.part;
          if (!part?.sessionID) break;

          // TextPart: acumula o texto mais recente da user message
          if (part.type === "text" && part.text && !part.synthetic) {
            const state = getOrCreateSession(part.sessionID);
            state.lastUserMessageID = part.messageID ?? state.lastUserMessageID;
            state.lastUserMessage = part.text;
          }

          // RetryPart: { type: "retry", attempt, error: ApiError }
          // FIX #8: RetryPart tem campo error: ApiError — passamos direto para getRateLimitError
          if (part.type === "retry" && part.error) {
            const err = getRateLimitError(part.error, patterns);
            if (err) await handleRateLimit(part.sessionID, err);
          }
          break;
        }

        // ── session.status ──────────────────────────────────────────────────
        // Tipo: EventSessionStatus → { sessionID, status: SessionStatus }
        // SessionStatus retry: { type: "retry", attempt: number, message: string, next: number }
        case "session.status": {
          const { sessionID, status } = e.properties ?? {};
          if (!sessionID || status?.type !== "retry" || !status?.message) break;

          const err = getRateLimitError(status.message, patterns);
          if (err) await handleRateLimit(sessionID, err);
          break;
        }

        // ── session.error ───────────────────────────────────────────────────
        // Tipo: EventSessionError → { sessionID?: string, error?: Error }
        // error é opcional nos tipos oficiais — verificamos antes de usar
        case "session.error": {
          const { sessionID, error } = e.properties ?? {};
          if (!sessionID || !error) break;

          const err = getRateLimitError(error, patterns);
          if (err) await handleRateLimit(sessionID, err);
          break;
        }

        // ── session.created ─────────────────────────────────────────────────
        // Tipo: EventSessionCreated → { info: Session }
        // Session: { id, parentID?, projectID, title, ... }
        // FIX #9: Session NÃO tem agentID nem mode — não tentar ler esses campos aqui.
        // O agentID só aparece nas mensagens (UserMessage.agent, AssistantMessage.mode).
        case "session.created": {
          const info = e.properties?.info;
          if (!info?.id) break;

          const state = getOrCreateSession(info.id);
          if (info.parentID) {
            state.parentSessionID = info.parentID;
          }
          break;
        }

        // ── session.deleted ─────────────────────────────────────────────────
        // Tipo: EventSessionDeleted → { info: Session }
        case "session.deleted": {
          const info = e.properties?.info;
          if (info?.id) {
            sessions.delete(info.id);
            handling.delete(info.id);
          }
          break;
        }

        // ── session.idle ────────────────────────────────────────────────────
        // Tipo: EventSessionIdle → { sessionID }
        // Reseta o fallbackIndex ao completar com sucesso,
        // para que o próximo rate limit tente da frente da lista.
        case "session.idle": {
          const { sessionID } = e.properties ?? {};
          if (sessionID) {
            const state = sessions.get(sessionID);
            if (state) state.fallbackIndex = 0;
          }
          break;
        }
      }
    },

    cleanup: () => {
      sessions.clear();
      handling.clear();
    },
  };
};

export default AgentFallbackPlugin;
