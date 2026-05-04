/**
 * opencode-background
 *
 * Plugin unificado que substitui rtk.ts + opencode-background.ts.
 *
 * Todo comando bash passa por aqui:
 *   1. Reescrita via rtk (se disponível no PATH, timeout 5s, fallback silencioso)
 *   2. Execução em background com timer de 100s
 *      - Terminou em < 100s → retorna output normal (agente não percebe nada)
 *      - Terminou em > 100s → retorna JSON com taskId para polling
 *   3. Paracaídas de 20min → mata o processo + JSON estruturado com output parcial
 *
 * Tools expostas para polling:
 *   - getBackgroundProcess   → status + últimas 20 linhas (polling a cada 30s)
 *   - killBackgroundProcess  → mata processo por taskId
 *   - listBackgroundProcesses → lista todos os processos
 *
 * Baseado em: https://github.com/zenobi-us/opencode-background (MIT License)
 *
 * Instalação:
 *   Copie para .opencode/plugins/opencode-background.ts
 *   Remova rtk.ts e o opencode-background.ts anterior
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

const SYNC_TIMEOUT_MS = 100_000; // 100s — se ultrapassar, vira background
const KILL_TIMEOUT_MS = 20 * 60 * 1000; // 20min — paracaídas, mata o processo
const RTK_TIMEOUT_MS = 5_000;  // 5s — timeout para rtk rewrite

// ─── Types ────────────────────────────────────────────────────────────────────

type TaskStatus = "running" | "completed" | "failed" | "cancelled" | "killed";

interface BackgroundTask {
  id: string;
  originalCommand: string;
  command: string; // comando após reescrita rtk (pode ser igual ao original)
  status: TaskStatus;
  pid?: number;
  startedAt: string;
  completedAt?: string;
  error?: string;
  outputStream: string[]; // rolling buffer, max 100 lines
  killTimer?: any;
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
    const logLine = `[${getLocalTimestamp()}] ${msg} ${extra ? JSON.stringify(extra) : ""}\n`;
    appendFileSync(LOG_FILE, logLine);
  } catch { }
}

// ─── RTK Rewriter ─────────────────────────────────────────────────────────────

let rtkPath: string | null | undefined = undefined; // undefined = não testado ainda

// Ordem de busca:
// 1. .opencode/bin/rtk  (projeto — preferencial)
// 2. which rtk          (PATH global — fallback)

function getRtkPath(): string | null {
  if (rtkPath !== undefined) return rtkPath;

  // 1. Tenta path local do projeto
  try {
    const localPath = execSync("git rev-parse --show-toplevel", { timeout: 3_000 })
      .toString().trim() + "/.opencode/bin/rtk";

    if (existsSync(localPath)) {
      rtkPath = localPath;
      fileLog(`rtk found locally: ${rtkPath}`);
      return rtkPath;
    }
  } catch { }

  // 2. Fallback para PATH global
  try {
    rtkPath = execSync("which rtk", { timeout: RTK_TIMEOUT_MS }).toString().trim() || null;
    fileLog(`rtk found in PATH: ${rtkPath}`);
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
    const rewritten = execSync(`rtk rewrite ${command}`, {
      timeout: RTK_TIMEOUT_MS,
    }).toString().trim();
    if (rewritten && rewritten !== command) {
      fileLog(`rtk rewrite`, { original: command, rewritten });
      return rewritten;
    }
  } catch {
    // rtk rewrite falhou — passa o comando original silenciosamente
  }
  return command;
}

// ─── Background Process Manager ──────────────────────────────────────────────

const tasks = new Map<string, BackgroundTask>();

function generateId(): string {
  return "bg-" + Math.random().toString(36).substring(2, 9);
}

function killProcess(task: BackgroundTask, reason: string) {
  try {
    if (task.pid) (process as any).kill(task.pid);
    fileLog(`[${task.id}] Process killed`, { pid: task.pid, reason });
  } catch (err: any) {
    fileLog(`[${task.id}] Kill failed`, { error: err.message });
  }
  if (task.killTimer) clearTimeout(task.killTimer);
  task.status = "killed";
  task.completedAt = getLocalTimestamp();
  task.error = reason;
}

interface RunResult {
  timedOut: boolean;
  task: BackgroundTask;
}

/**
 * Roda o comando em background e aguarda até SYNC_TIMEOUT_MS.
 * - Se terminar antes: resolve com timedOut=false e output completo
 * - Se não terminar:   resolve com timedOut=true e taskId para polling
 */
function runWithTimeout(command: string, originalCommand: string): Promise<RunResult> {
  return new Promise((resolve) => {
    const id = generateId();

    const task: BackgroundTask = {
      id,
      originalCommand,
      command,
      status: "running",
      startedAt: getLocalTimestamp(),
      outputStream: [],
    };

    const child = spawn(command, {
      shell: true,
      detached: true,
      stdio: ["ignore", "pipe", "pipe"],
    });

    task.pid = child.pid;
    tasks.set(id, task);

    fileLog(`[${id}] Started`, { command, pid: task.pid });

    const record = (line: string, isErr = false) => {
      const formatted = isErr ? `[stderr] ${line}` : line;
      task.outputStream.push(formatted);
      if (task.outputStream.length > 100) task.outputStream.shift();
    };

    child.stdout?.on("data", (chunk: any) =>
      chunk.toString().split("\n").filter(Boolean).forEach((l: string) => record(l))
    );
    child.stderr?.on("data", (chunk: any) =>
      chunk.toString().split("\n").filter(Boolean).forEach((l: string) => record(l, true))
    );

    let resolved = false;

    // ── Timer 1: SYNC_TIMEOUT (100s) ─────────────────────────────────────────
    // Se o processo ainda estiver rodando após 100s, resolve com timedOut=true
    // O processo continua em background — não é morto aqui.
    const syncTimer = setTimeout(() => {
      if (resolved) return;
      resolved = true;
      fileLog(`[${id}] Sync timeout reached (${SYNC_TIMEOUT_MS}ms) — continuing in background`);

      // ── Timer 2: KILL_TIMEOUT (20min) ──────────────────────────────────────
      // Paracaídas — mata o processo se ainda estiver rodando após 20min
      task.killTimer = setTimeout(() => {
        if (task.status !== "running") return;
        fileLog(`[${id}] Kill timeout reached (20min) — terminating`);
        killProcess(task, `Process exceeded maximum allowed runtime of 20 minutes and was forcefully terminated.`);
      }, KILL_TIMEOUT_MS);

      resolve({ timedOut: true, task });
    }, SYNC_TIMEOUT_MS);

    // ── Processo terminou antes do sync timeout ───────────────────────────────
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
        resolve({ timedOut: false, task });
      }
    });

    child.on("error", (err: Error) => {
      clearTimeout(syncTimer);
      if (task.killTimer) clearTimeout(task.killTimer);
      task.status = "failed";
      task.error = err.message;
      task.completedAt = getLocalTimestamp();
      record(err.message, true);
      fileLog(`[${id}] Error`, { error: err.message });

      if (!resolved) {
        resolved = true;
        resolve({ timedOut: false, task });
      }
    });

    child.unref();
  });
}

// ─── Payload Builders ─────────────────────────────────────────────────────────

function buildTimeoutPayload(task: BackgroundTask): string {
  const payload = {
    intercepted: true,
    taskId: task.id,
    pid: task.pid,
    command: task.command,
    status: "running",
    startedAt: task.startedAt,
    instructions: [
      "Command is still running after 100s — now tracked as a background process.",
      "Use getBackgroundProcess tool with this taskId to check progress.",
      "Poll every 30 seconds until status is 'completed' or 'failed'.",
      "Do NOT use bash tool to wait — use getBackgroundProcess only.",
    ],
  };
  const escaped = JSON.stringify(payload).replace(/'/g, "'\\''");
  return `echo '${escaped}'`;
}

function buildKilledPayload(task: BackgroundTask): string {
  const payload = {
    intercepted: true,
    taskId: task.id,
    pid: task.pid,
    command: task.command,
    status: "killed",
    startedAt: task.startedAt,
    completedAt: task.completedAt,
    error: task.error,
    partialOutput: task.outputStream.slice(-20),
    instructions: [
      "Process was forcefully terminated after 20 minutes without completing.",
      "Review the partial output above to understand what happened.",
      "Consider breaking the command into smaller parts.",
      "Or investigate why the process is taking too long.",
    ],
  };
  const escaped = JSON.stringify(payload).replace(/'/g, "'\\''");
  return `echo '${escaped}'`;
}

// ─── Plugin ───────────────────────────────────────────────────────────────────

export const BackgroundPlugin: Plugin = async (_ctx) => {
  fileLog("Plugin initialized");

  // Detecta rtk na inicialização (não bloqueia)
  setTimeout(() => getRtkPath(), 0);

  // ── Tool: getBackgroundProcess ─────────────────────────────────────────────
  const getBackgroundProcess = tool({
    description:
      "Get the current status and last output lines of a background process. " +
      "ALWAYS use this to poll progress after a long-running command exceeds 100s. " +
      "Poll every 30 seconds until status is 'completed', 'failed', or 'killed'. " +
      "Never use bash tool to wait — use this tool only.",
    args: {
      taskId: tool.schema
        .string()
        .describe("The taskId received when the command timed out"),
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
        lastOutput: task.outputStream.slice(-20),
        ...(task.status === "running" && {
          reminder: "Still running. Poll again in 30 seconds with getBackgroundProcess.",
        }),
        ...(task.status === "killed" && {
          instructions: [
            "Process was forcefully terminated after 20 minutes.",
            "Review partialOutput and consider breaking the command into smaller parts.",
          ],
        }),
      });
    },
  });

  // ── Tool: killBackgroundProcess ────────────────────────────────────────────
  const killBackgroundProcess = tool({
    description: "Kill a background process by taskId. Use when a process is stuck or no longer needed.",
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
    description: "List all background processes. Useful to check if any process is still running.",
    args: {
      status: tool.schema
        .string()
        .optional()
        .describe("Filter by status: running | completed | failed | cancelled | killed"),
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
          lastOutput: t.outputStream.slice(-5),
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
     * Intercepta todo bash/shell call.
     *
     * 1. Reescreve com rtk se disponível (timeout 5s, fallback silencioso)
     * 2. Roda em background com timer de 100s
     *    - < 100s: injeta output real de volta no args.command via echo
     *    - > 100s: injeta JSON com taskId para polling
     * 3. Paracaídas de 20min: mata o processo e sinaliza erro estruturado
     */
    "tool.execute.before": async (input: any, output: any) => {
      const toolName = String(input?.tool ?? "").toLowerCase();
      if (toolName !== "bash" && toolName !== "shell") return;

      const args = output?.args as Record<string, unknown> | undefined;
      if (!args) return;

      const originalCommand = args.command;
      if (typeof originalCommand !== "string" || !originalCommand.trim()) return;

      // Reescrita rtk (fallback silencioso se indisponível ou falhar)
      const command = rewriteWithRtk(originalCommand);

      // Roda em background e aguarda até 100s
      const { timedOut, task } = await runWithTimeout(command, originalCommand);

      if (!timedOut) {
        if (task.status === "killed") {
          // Paracaídas ativado durante janela síncrona (edge case improvável)
          args.command = buildKilledPayload(task);
          return;
        }

        // Terminou dentro de 100s — injeta output real via echo
        // O agente recebe exatamente o que receberia de um bash normal
        const output = task.outputStream.join("\n").replace(/'/g, "'\\''");
        args.command = output
          ? `echo '${output}'`
          : `echo '[bg:${task.id}] Command completed with no output. Exit status: ${task.status}'`;
        return;
      }

      // Ultrapassou 100s — retorna JSON com taskId para polling
      args.command = buildTimeoutPayload(task);

      // Registra listener para atualizar o payload se o processo for morto
      // pelo paracaídas de 20min enquanto o agente faz polling
      const interval = setInterval(() => {
        if (task.status !== "killed") return;
        clearInterval(interval);
        // O agente vai descobrir via getBackgroundProcess na próxima poll
        fileLog(`[${task.id}] Kill detected during polling window`);
      }, 5_000);
    },

    event: async ({ event }: any) => {
      if (event?.type === "session.deleted") {
        const sessionId =
          event?.properties?.info?.id ||
          event?.properties?.sessionID;
        if (sessionId) {
          fileLog(`Session deleted: ${sessionId}`);
        }
      }
    },
  };
};

export default BackgroundPlugin;
