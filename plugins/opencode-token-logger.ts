// @ts-ignore
import type { Plugin } from "@opencode-ai/plugin";
// @ts-ignore
import { appendFileSync, readFileSync, existsSync } from "fs";
// @ts-ignore
import { join } from "path";
// @ts-ignore
import { homedir } from "os";

interface TokenLoggerConfig {
  enabled?: boolean;
  fetchTimeoutMs?: number;
  fetchTimeoutEnabled?: boolean;
  logLevel?: "debug" | "info" | "warn" | "error";
}

const LEVELS = { debug: 0, info: 1, warn: 2, error: 3 };

function loadConfig(directory: string, worktree: string): TokenLoggerConfig {
  const candidates = [
    join(worktree, ".opencode", "config", "token-logger.json"),
    join(directory, ".opencode", "config", "token-logger.json"),
    join(homedir(), ".opencode", "config", "token-logger.json"),
    join(homedir(), ".config", "opencode", "config", "token-logger.json"),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      try {
        const raw = readFileSync(candidate, "utf-8");
        return JSON.parse(raw) as TokenLoggerConfig;
      } catch { }
    }
  }
  return {};
}

/**
 * opencode-token-logger
 *
 * Plugin para interceptar, registrar e aplicar timeout em chamadas de IA.
 * Log levels: debug > info > warn > error
 */
export const TokenLoggerPlugin: Plugin = async ({ client, directory, worktree }: any) => {

  const config = loadConfig(directory, worktree);

  if (config.enabled === false) {
    return {};
  }

  const LOG_LEVEL = LEVELS[config.logLevel ?? "info"];

  let activeSessionID = "global";
  let activeAgent = "unknown";

  function log(level: "debug" | "info" | "warn" | "error", tag: string, data: any) {
    if (LEVELS[level] < LOG_LEVEL) return;
    try {
      const ts = new Date().toISOString();
      const payload = typeof data === "string" ? data : JSON.stringify(data, null, 2);
      const line = `[${ts}] [${level.toUpperCase()}] [AGENT: ${activeAgent}] [${tag}] ${payload}\n\n`;
      const fileName = `/tmp/opencode-token-logger-${activeSessionID.replace(/[^a-zA-Z0-9_-]/g, "")}.log`;
      appendFileSync(fileName, line);
    } catch { }
  }

  log("info", "PLUGIN_INIT", "Token Logger + Fetch Timeout Plugin inicializado");
  log("info", "PLUGIN_CONFIG", config);

  const FETCH_TIMEOUT_MS = config.fetchTimeoutMs ?? 600000;
  const TIMEOUT_ENABLED = config.fetchTimeoutEnabled !== false;
  log("info", "TIMEOUT_CONFIG", { fetchTimeoutMs: FETCH_TIMEOUT_MS, enabled: TIMEOUT_ENABLED });

  // --- Interceptação de globalThis.fetch ---
  // @ts-ignore
  const originalFetch = globalThis.fetch;
  if (originalFetch) {
    // @ts-ignore
    globalThis.fetch = async function (...args) {
      const requestInput = args[0];
      const requestInit = args[1];

      let url = "";
      if (typeof requestInput === "string") {
        url = requestInput;
      } else if (requestInput instanceof URL) {
        url = requestInput.toString();
      } else if (requestInput && typeof requestInput === "object" && "url" in requestInput) {
        url = (requestInput as any).url;
      }

      const isProvider = url && (url.includes("api") || url.includes("openai") || url.includes("openrouter") || url.includes("anthropic") || url.includes("ollama"));

      if (isProvider) {
        // Log em debug: body completo. Info: apenas url + method.
        let bodyToLog = requestInit?.body;
        if (typeof bodyToLog === "string") {
          try { bodyToLog = JSON.parse(bodyToLog); } catch { }
        }
        log("info", "HTTP_FETCH_REQUEST", { url, method: requestInit?.method || "GET" });
        log("debug", "HTTP_FETCH_REQUEST_BODY", bodyToLog);
      }

      if (isProvider && TIMEOUT_ENABLED) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => {
          controller.abort();
          log("warn", "HTTP_FETCH_TIMEOUT", { url, timeoutMs: FETCH_TIMEOUT_MS, message: `Abortado após ${FETCH_TIMEOUT_MS}ms` });
        }, FETCH_TIMEOUT_MS);

        try {
          const response = await originalFetch.call(this, requestInput, {
            ...(requestInit || {}),
            signal: controller.signal,
          });
          clearTimeout(timeoutId);
          log("info", "HTTP_FETCH_RESPONSE", { url, status: response.status, ok: response.ok });
          log("debug", "HTTP_FETCH_RESPONSE_HEADERS", Object.fromEntries(response.headers.entries()));
          return response;
        } catch (err: any) {
          clearTimeout(timeoutId);
          if (err.name === "AbortError" || err.code === "ABORT_ERR") {
            log("error", "HTTP_FETCH_ABORTED", { url, timeoutMs: FETCH_TIMEOUT_MS });
            const error = new Error(`[FetchTimeout] Provedor não respondeu em ${FETCH_TIMEOUT_MS}ms. URL: ${url}`);
            // @ts-ignore
            error.code = "ETIMEDOUT";
            throw error;
          }
          log("error", "HTTP_FETCH_ERROR", { url, error: err.message, stack: err.stack });
          throw err;
        }
      }

      return originalFetch.apply(this, args);
    };
  }

  return {
    "chat.message": async (ctx: any, message: any) => {
      if (ctx?.sessionID) activeSessionID = ctx.sessionID;
      log("info", "CHAT_MESSAGE", { sessionID: activeSessionID, role: message?.role });
      log("debug", "CHAT_MESSAGE_BODY", message);
      return message;
    },

    event: async ({ event }: any) => {
      const e = event as { type: string; properties: Record<string, any> };
      const info = e.properties?.info;
      if (info?.sessionID) activeSessionID = info.sessionID;
      else if (e.properties?.sessionID) activeSessionID = e.properties.sessionID;
      if (info?.agent) activeAgent = info.agent;
      else if (info?.mode) activeAgent = info.mode;

      if (
        e.type.startsWith("message") ||
        e.type.startsWith("session") ||
        e.type.includes("provider") ||
        e.type.includes("model")
      ) {
        log("info", `EVENT:${e.type}`, { sessionID: activeSessionID, agent: activeAgent });
        log("debug", `EVENT:${e.type}:DETAIL`, e.properties);
      }
    },

    "tool.execute.before": async (ctx: any, toolName: string, params: any) => {
      log("info", `TOOL_BEFORE:${toolName}`, { agent: activeAgent });
      log("debug", `TOOL_BEFORE:${toolName}:PARAMS`, params);
      return params;
    },

    "tool.execute.after": async (ctx: any, toolName: string, result: any) => {
      log("info", `TOOL_AFTER:${toolName}`, { agent: activeAgent });
      log("debug", `TOOL_AFTER:${toolName}:RESULT`, result);
    },
  };
};

export default TokenLoggerPlugin;
