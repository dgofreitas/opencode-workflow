/**
 * opencode-background
 *
 * Plugin unificado que substitui rtk.ts + opencode-background.ts.
 *
 * Arquitetura before/after:
 *   tool.execute.before → reescrita rtk + dispara processo em background
 *   tool.execute.after  → aguarda até 100s, substitui output sem duplicata
 *
 * Fluxo completo:
 *   1. before: rtk rewrite (se disponível)
 *   2. before: dispara processo em background, registra taskId
 *   3. opencode executa o comando original (output em tempo real para o usuário)
 *   4. after:  aguarda até 100s pelo background task
 *      - < 100s → substitui output pelo do background (sem duplicata)
 *      - > 100s → substitui output por JSON com taskId para polling
 *   5. Paracaídas de 20min → mata processo + JSON com output parcial
 *
 * Tools expostas:
 *   - getBackgroundProcess    → status + últimas 20 linhas (polling a cada 30s)
 *   - killBackgroundProcess   → mata processo por taskId
 *   - listBackgroundProcesses → lista todos os processos
 *
 * Baseado em: https://github.com/zenobi-us/opencode-background (MIT License)
 *
 * Instalação:
 *   1. Copie para .opencode/plugins/opencode-background.ts
 *   2. Remova rtk.ts e o opencode-background.ts anterior
 *   3. Opcional: coloque o binário rtk em .opencode/bin/rtk
 */

// @ts-ignore
import { type Plugin, tool } from "@opencode-ai/plugin";
// @ts-ignore
import { spawn, execSync } from "node:child_process";
// @ts-ignore
import {
  existsSync,
  appendFileSync,
  statSync,
  renameSync,
  readdirSync,
  unlinkSync,
} from "node:fs";
// @ts-ignore
import { join } from "node:path";

declare const process: any;

// ─── Constants ────────────────────────────────────────────────────────────────

const SYNC_TIMEOUT_MS = 10000;     // 100s — se ultrapassar, vira background
const KILL_TIMEOUT_MS = 1 * 60000; // 20min — paracaídas, mata o processo
const RTK_TIMEOUT_MS = 5000;       // 5s — timeout para rtk rewrite e detecção

// ─── Types ────────────────────────────────────────────────────────────────────

type TaskStatus = "running" | "completed" | "failed" | "cancelled" | "killed";

interface BackgroundTask {
  id: string;
  originalCommand: string;
  command: string;      // após reescrita rtk (pode ser igual ao original)
  status: TaskStatus;
  pid?: number;
  startedAt: string;
  completedAt?: string;
  error?: string;
  outputStream: string; // raw output buffer, max 1MB
  killTimer?: any;
  // Promise que resolve quando o processo termina (ou timeout de 100s)
  donePromise: Promise<{ timedOut: boolean }>;
}

// ─── Logger ───────────────────────────────────────────────────────────────────

function getLocalTimestamp(): string {
  const now = new Date();
  const tzOffset = now.getTimezoneOffset() * 60000;
  return new Date(now.getTime() - tzOffset).toISOString().slice(0, -1);
}

const LOG_FILE = "/tmp/opencode-background.log";
const MAX_LOG_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_LOG_FILES = 20;
let logWriteCounter = 0;

function rotateLogIfNeeded() {
  logWriteCounter++;
  if (logWriteCounter % 20 !== 0) return;
  try {
    if (!existsSync(LOG_FILE)) return;
    const stats = statSync(LOG_FILE);
    if (stats.size >= MAX_LOG_SIZE) {
      const timestamp = getLocalTimestamp().replace(/[:.]/g, "-");
      renameSync(LOG_FILE, `${LOG_FILE}.${timestamp}`);
      const files = readdirSync("/tmp");
      const logFiles = files
        .filter((f: string) => f.startsWith("opencode-background.log."))
        .map((f: string) => join("/tmp", f))
        .sort();
      while (logFiles.length > MAX_LOG_FILES) {
        const oldest = logFiles.shift();
        if (oldest) unlinkSync(oldest);
      }
    }
  } catch { }
}

function fileLog(msg: string, extra?: any) {
  try {
    rotateLogIfNeeded();
    const line = `[${getLocalTimestamp()}] ${msg} ${extra ? JSON.stringify(extra) : ""}\n`;
    appendFileSync(LOG_FILE, line);
  } catch { }
}

// ─── RTK Rewriter ─────────────────────────────────────────────────────────────

let rtkPath: string | null | undefined = undefined; // undefined = não testado ainda

/**
 * Ordem de busca:
 *   1. .opencode/bin/rtk  (projeto — preferencial, portável, versão fixada)
 *   2. which rtk          (PATH global — fallback)
 */
function getRtkPath(): string | null {
  if (rtkPath !== undefined) return rtkPath;

  // 1. Busca local no projeto
  try {
    const repoRoot = execSync("git rev-parse --show-toplevel", { timeout: RTK_TIMEOUT_MS })
      .toString()
      .trim();
    const localRtk = join(repoRoot, ".opencode", "bin", "rtk");
    if (existsSync(localRtk)) {
      rtkPath = localRtk;
      fileLog(`rtk found locally: ${rtkPath}`);
      return rtkPath;
    }
  } catch { }

  // 2. Fallback para PATH global
  try {
    const found = execSync("which rtk", { timeout: RTK_TIMEOUT_MS }).toString().trim();
    rtkPath = found || null;
    if (rtkPath) fileLog(`rtk found in PATH: ${rtkPath}`);
  } catch {
    rtkPath = null;
    fileLog("rtk not found — rewrite disabled");
  }

  return rtkPath;
}

function rewriteWithRtk(command: string): string {
  const rtk = getRtkPath();
  if (!rtk) return command;
  try {
    const rewritten = execSync(`"${rtk}" rewrite ${command}`, {
      timeout: RTK_TIMEOUT_MS,
    })
      .toString()
      .trim();
    if (rewritten && rewritten !== command) {
      fileLog("rtk rewrite", { original: command, rewritten });
      return rewritten;
    }
  } catch {
    fileLog("rtk rewrite failed — using original command", { command });
  }
  return command;
}

// ─── Background Process Manager ──────────────────────────────────────────────

const tasks = new Map<string, BackgroundTask>();

// Correlação entre chamadas before/after: command → taskId
// Usamos o comando original como chave pois é o que o opencode passa em ambos os hooks
const pendingByCommand = new Map<string, string>();

function generateId(): string {
  return "bg-" + Math.random().toString(36).substring(2, 9);
}

function killProcess(task: BackgroundTask, originalCommand: string, reason: string) {
  try {
    if (task.pid) (process as any).kill(task.pid);
    fileLog(`[${task.id}] Killed`, { pid: task.pid, reason });
  } catch (err: any) {
    fileLog(`[${task.id}] Kill failed`, { error: err.message });
  }
  if (task.killTimer) clearTimeout(task.killTimer);
  task.status = "killed";
  task.completedAt = getLocalTimestamp();
  task.error = reason;
  pendingByCommand.delete(originalCommand);
}

/**
 * Dispara o comando em background imediatamente.
 * Retorna o task com uma donePromise que resolve quando:
 *   - O processo termina (timedOut: false)
 *   - 100s passam sem terminar (timedOut: true)
 */
function spawnBackground(command: string, originalCommand: string, output: any): BackgroundTask {
  const id = generateId();

  let resolveDone!: (result: { timedOut: boolean }) => void;
  const donePromise = new Promise<{ timedOut: boolean }>((resolve) => {
    resolveDone = resolve;
  });

  const task: BackgroundTask = {
    id,
    originalCommand,
    command,
    status: "running",
    startedAt: getLocalTimestamp(),
    outputStream: "",
    donePromise,
  };

  const child = spawn(command, {
    shell: true,
    detached: true,
    stdio: ["ignore", "pipe", "pipe"],
  });

  task.pid = child.pid;
  tasks.set(id, task);

  fileLog(`[${id}] Started`, { command, pid: task.pid });

  let syncTimer: any = null;
  let resolved = false;

  const startSyncTimer = () => {
    if (resolved) return;
    if (syncTimer) clearTimeout(syncTimer);
    syncTimer = setTimeout(() => {
      if (resolved) return;
      resolved = true;
      fileLog(
        `[${id}] Sync timeout reached (${SYNC_TIMEOUT_MS}ms of silence) — continuing in background`
      );

      // > 100s — substitui output por JSON com taskId para polling
      output.output = buildTimeoutPayload(task);

      // ── Timer 2: KILL_TIMEOUT (20min) — paracaídas ─────────────────────────
      task.killTimer = setTimeout(() => {
        if (task.status !== "running") return;
        fileLog(`[${id}] Kill timeout (20min) — terminating`);
        killProcess(
          task,
          originalCommand,
          "Process exceeded maximum allowed runtime of 20 minutes and was forcefully terminated."
        );

        // Paracaídas ativado (edge case: processo morto durante janela síncrona)
        output.output = buildKilledPayload(task);
        fileLog(`[after] Killed — partial output sent to agent`, { taskId, response: output.output });
      }, KILL_TIMEOUT_MS);

      resolveDone({ timedOut: true });
    }, SYNC_TIMEOUT_MS);
  };

  let lastResetAt = 0;
  const appendOutput = (data: any) => {
    task.outputStream += data.toString();
    // Mantém último 1MB para evitar OOM
    if (task.outputStream.length > 1024 * 1024) {
      task.outputStream = task.outputStream.slice(-1024 * 1024);
    }

    // Throttling: evita sobrecarga de CPU se o output for muito constante.
    // Só reseta o timer de timeout se houver um intervalo de pelo menos 2s.
    const now = Date.now();
    if (now - lastResetAt > 10000) {
      startSyncTimer();
      lastResetAt = now;
    }
  };

  child.stdout?.on("data", appendOutput);
  child.stderr?.on("data", appendOutput);

  // Inicia o timer inicial
  startSyncTimer();

  // ── Processo terminou antes do sync timeout ─────────────────────────────────
  child.on("close", (code: number | null) => {
    if (task.status === "killed") return;
    clearTimeout(syncTimer);
    if (task.killTimer) clearTimeout(task.killTimer);
    task.completedAt = getLocalTimestamp();
    task.status = code === 0 ? "completed" : "failed";
    if (code !== 0) task.error = `Process exited with code ${code}`;
    fileLog(`[${id}] Finished`, { code, status: task.status });
    if (!resolved) {
      resolved = true;
      resolveDone({ timedOut: false });
    }
  });

  child.on("error", (err: Error) => {
    clearTimeout(syncTimer);
    if (task.killTimer) clearTimeout(task.killTimer);
    task.status = "failed";
    task.error = err.message;
    task.completedAt = getLocalTimestamp();
    appendOutput(`\nError: ${err.message}\n`);
    fileLog(`[${id}] Error`, { error: err.message });
    if (!resolved) {
      resolved = true;
      resolveDone({ timedOut: false });
    }
  });

  child.unref();

  return task;
}

// ─── Payload Builders ─────────────────────────────────────────────────────────

function buildTimeoutPayload(task: BackgroundTask): string {
  console.log("DGO ==========>")
  return JSON.stringify({
    intercepted: true,
    taskId: task.id,
    pid: task.pid,
    command: task.command,
    status: "running",
    startedAt: task.startedAt,
    instructions: [
      "Command is still running after 100s — now tracked as a background process.",
      "Use getBackgroundProcess tool with this taskId to check progress.",
      "Poll every 30 seconds until status is 'completed', 'failed', or 'killed'.",
      "Do NOT use bash tool to wait — use getBackgroundProcess only.",
    ],
  });
}

function buildKilledPayload(task: BackgroundTask): string {
  return JSON.stringify({
    intercepted: true,
    taskId: task.id,
    pid: task.pid,
    command: task.command,
    status: "killed",
    startedAt: task.startedAt,
    completedAt: task.completedAt,
    error: task.error,
    partialOutput: task.outputStream.split("\n").slice(-20),
    instructions: [
      "Process was forcefully terminated after 20 minutes without completing.",
      "Review partialOutput above to understand what happened.",
      "Consider breaking the command into smaller parts.",
      "Or investigate why the process is taking too long.",
    ],
  });
}

// ─── Plugin ───────────────────────────────────────────────────────────────────

export const BackgroundPlugin: Plugin = async (_ctx) => {
  fileLog("Plugin initialized");

  // Detecta rtk na inicialização sem bloquear
  setTimeout(() => getRtkPath(), 0);

  // ── Tool: getBackgroundProcess ─────────────────────────────────────────────
  const getBackgroundProcess = tool({
    description:
      "Get the current status and last output lines of a background process. " +
      "ALWAYS use this after a command exceeds 100s and returns a taskId. " +
      "Poll every 30 seconds until status is 'completed', 'failed', or 'killed'. " +
      "Never use bash tool to wait — use this tool only.",
    args: {
      taskId: tool.schema
        .string()
        .describe("The taskId received when the command timed out after 100s"),
    },
    async execute(args) {
      const task = tasks.get(args.taskId);
      if (!task) {
        return JSON.stringify({ error: `Task ${args.taskId} not found` });
      }
      return JSON.stringify({
        taskId: task.id,
        command: task.command,
        status: task.status,
        pid: task.pid,
        startedAt: task.startedAt,
        completedAt: task.completedAt ?? null,
        error: task.error ?? null,
        lastOutput: task.outputStream.split("\n").slice(-20),
        ...(task.status === "running" && {
          reminder: "Still running. Poll again in 30 seconds with getBackgroundProcess.",
        }),
        ...(task.status === "killed" && {
          instructions: [
            "Process was forcefully terminated after 20 minutes.",
            "Review lastOutput and consider breaking the command into smaller parts.",
          ],
        }),
      });
    },
  });

  // ── Tool: killBackgroundProcess ────────────────────────────────────────────
  const killBackgroundProcess = tool({
    description:
      "Kill a background process by taskId. Use when a process is stuck or no longer needed.",
    args: {
      taskId: tool.schema.string().describe("The taskId of the process to kill"),
    },
    async execute(args) {
      const task = tasks.get(args.taskId);
      if (!task) {
        return JSON.stringify({ error: `Task ${args.taskId} not found` });
      }
      killProcess(task, "Manually killed by agent");
      return JSON.stringify({ taskId: task.id, status: "cancelled" });
    },
  });

  // ── Tool: listBackgroundProcesses ──────────────────────────────────────────
  const listBackgroundProcesses = tool({
    description:
      "List all background processes. Useful to check if any process is still running.",
    args: {
      status: tool.schema
        .string()
        .optional()
        .describe(
          "Filter by status: running | completed | failed | cancelled | killed"
        ),
    },
    async execute(args) {
      const results = Array.from(tasks.values()).filter(
        (t) => !args.status || t.status === args.status
      );
      return JSON.stringify(
        results.map((t) => ({
          taskId: t.id,
          command: t.command,
          status: t.status,
          pid: t.pid,
          startedAt: t.startedAt,
          completedAt: t.completedAt ?? null,
          error: t.error ?? null,
          lastOutput: t.outputStream.split("\n").slice(-5),
        }))
      );
    },
  });

  return {
    tool: {
      getBackgroundProcess,
      killBackgroundProcess,
      listBackgroundProcesses,
    },

    /**
     * BEFORE: reescrita rtk + dispara processo em background.
     * NÃO substitui args.command — deixa o opencode executar normalmente.
     * O output em tempo real vai para o usuário como sempre.
     * Registra taskId em pendingByCommand para o hook after recuperar.
     */
    "tool.execute.before": async (input: any, output: any) => {
      const toolName = String(input?.tool ?? "").toLowerCase();
      if (toolName !== "bash" && toolName !== "shell") return;

      const args = output?.args as Record<string, unknown> | undefined;
      if (!args) return;

      const originalCommand = args.command;
      if (typeof originalCommand !== "string" || !originalCommand.trim()) return;

      // Reescrita rtk (fallback silencioso)
      const command = rewriteWithRtk(originalCommand);
      if (command !== originalCommand) {
        args.command = command; // aplica reescrita rtk
      }

      // Dispara em background imediatamente — NÃO aguarda aqui
      const task = spawnBackground(command, originalCommand, output);

      // Registra correlação para o hook after
      pendingByCommand.set(originalCommand, task.id);

      fileLog(`[before] Spawned background task`, {
        taskId: task.id,
        command,
      });
    },

    /**
     * AFTER: aguarda o background task terminar (até 100s).
     * Substitui o output do opencode pelo do background task — sem duplicata.
     *   - < 100s → output do background task (idêntico ao que apareceu em tempo real)
     *   - > 100s → JSON com taskId para polling
     *   - killed → JSON com output parcial + instruções
     *
     * O output substituído é o que o agente LLM vai ler para tomar decisões.
     * O que o usuário viu em tempo real não é afetado.
     */
    "tool.execute.after": async (input: any, output: any) => {
      const toolName = String(input?.tool ?? "").toLowerCase();
      if (toolName !== "bash" && toolName !== "shell") return;

      const originalCommand = input?.args?.command ?? input?.input?.command;
      if (!originalCommand) return;

      // Recupera o taskId registrado pelo before
      const taskId = pendingByCommand.get(originalCommand);
      if (!taskId) return;
      pendingByCommand.delete(originalCommand);

      const task = tasks.get(taskId);
      if (!task) return;

      fileLog(`[after] Waiting for task`, { taskId });

      // Aguarda o processo terminar ou o timeout de 100s
      const { timedOut } = await task.donePromise;




      // < 100s — processo terminou normalmente
      // O output já apareceu em tempo real para o usuário.
      // Passamos o output do background task para o agente LLM sem duplicar na UI.
      output.output = task.outputStream || `[bg:${taskId}] completed with no output`;
      fileLog(`[after] Done — output passed to agent`, {
        taskId,
        status: task.status,
        outputLength: task.outputStream.length,
        response: output.output,
      });
    },

    event: async ({ event }: any) => {
      if (event?.type === "session.deleted") {
        const sessionId =
          event?.properties?.info?.id || event?.properties?.sessionID;
        if (sessionId) {
          fileLog(`Session deleted: ${sessionId}`);
        }
      }
    },
  };
};

export default BackgroundPlugin;
