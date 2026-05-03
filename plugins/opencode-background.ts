/**
 * opencode-background
 *
 * Plugin para OpenCode que intercepta automaticamente comandos bash de longa
 * duração e os executa como processos background detached.
 *
 * Evita o timeout do servidor LLM (120s) mantendo cada tool call curta.
 * O agente não precisa decidir nada — a interceptação é automática.
 *
 * Fluxo:
 *   1. agente chama bash "npm test"
 *   2. interceptor (tool.execute.before) substitui por echo + taskId  <- retorna em < 1s
 *   3. agente lê o echo e chama getBackgroundProcess(taskId)          <- retorna em < 1s
 *   4. agente faz polling a cada 30s até status=completed|failed
 *   5. agente lê output final e continua o workflow
 *
 * Baseado em: https://github.com/zenobi-us/opencode-background (MIT License)
 *
 * Instalação:
 *   Copie este arquivo para .opencode/plugins/opencode-background.ts
 */

// @ts-ignore
import { type Plugin, tool } from "@opencode-ai/plugin";
// @ts-ignore
import { spawn } from "node:child_process";
// @ts-ignore
import { existsSync, appendFileSync, statSync, renameSync, readdirSync, unlinkSync } from "node:fs";
// @ts-ignore
import { join } from "node:path";

declare const process: any;

// ─── Types ────────────────────────────────────────────────────────────────────

type TaskStatus = "running" | "completed" | "failed" | "cancelled";

interface BackgroundTask {
  id: string;
  command: string;
  status: TaskStatus;
  pid?: number;
  startedAt: string;
  completedAt?: string;
  error?: string;
  outputStream: string[]; // rolling buffer, max 100 lines
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

// ─── Long-Running Command Detector ───────────────────────────────────────────

/**
 * Padrões que identificam comandos que podem exceder o timeout do servidor LLM.
 * Adicione aqui qualquer comando que costume demorar mais de 30s no seu projeto.
 */
const LONG_RUNNING_PATTERNS: RegExp[] = [
  // Testes
  /\bnpm\s+(run\s+)?test\b/,
  /\bvitest\b/,
  /\bjest\b/,
  /\bplaywright\b/,
  /\bcypress\b/,
  /\bmocha\b/,
  /\bpytest\b/,
  /\bnpx\s+.*test\b/,

  // Builds
  /\bnpm\s+run\s+build\b/,
  /\bvite\s+build\b/,
  /\bnext\s+build\b/,
  /\btsc\b/,
  /\bwebpack\b/,
  /\besbuild\b/,
  /\brollup\b/,

  // Installs
  /\bnpm\s+install\b/,
  /\bnpm\s+ci\b/,
  /\bpnpm\s+install\b/,
  /\byarn\s+install\b/,
  /\bbun\s+install\b/,

  // Dev servers (nunca terminam — sempre precisam de background)
  /\bnpm\s+run\s+dev\b/,
  /\bnpm\s+run\s+start\b/,
  /\bnext\s+dev\b/,
  /\bvite\b(?!\s+build)/,
];

function isLongRunning(command: string): boolean {
  const lower = command.toLowerCase().trim();
  return LONG_RUNNING_PATTERNS.some((pattern) => pattern.test(lower));
}

// ─── Background Process Manager ──────────────────────────────────────────────

const tasks = new Map<string, BackgroundTask>();

function generateId(): string {
  return "bg-" + Math.random().toString(36).substring(2, 9);
}

function runInBackground(command: string): BackgroundTask {
  const id = generateId();

  const task: BackgroundTask = {
    id,
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

  child.on("close", (code: number | null) => {
    if (task.status === "cancelled") return;
    task.completedAt = getLocalTimestamp();
    task.status = code === 0 ? "completed" : "failed";
    if (code !== 0) task.error = `Process exited with code ${code}`;
    fileLog(`[${id}] Finished`, { code, status: task.status });
  });

  child.on("error", (err: Error) => {
    task.status = "failed";
    task.error = err.message;
    task.completedAt = getLocalTimestamp();
    record(err.message, true);
    fileLog(`[${id}] Error`, { error: err.message });
  });

  child.unref();

  return task;
}

// ─── Plugin ───────────────────────────────────────────────────────────────────

export const BackgroundPlugin: Plugin = async (_ctx) => {
  fileLog("Plugin initialized");

  // ── Tool: getBackgroundProcess ─────────────────────────────────────────────
  const getBackgroundProcess = tool({
    description:
      "Get the current status and last output lines of a background process. " +
      "ALWAYS use this to poll progress after a long-running bash command is intercepted. " +
      "Poll every 30 seconds until status is 'completed' or 'failed'. " +
      "Never use bash tool to wait — use this tool only.",
    args: {
      taskId: tool.schema
        .string()
        .describe("The taskId received when the bash command was intercepted"),
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
        // Lembrete explícito enquanto ainda está rodando
        ...(task.status === "running" && {
          reminder: "Still running. Poll again in 30 seconds with getBackgroundProcess.",
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

      try {
        if (task.pid) (process as any).kill(task.pid);
        fileLog(`[${task.id}] Killed`, { pid: task.pid });
      } catch (err: any) {
        fileLog(`[${task.id}] Kill failed`, { error: err.message });
      }

      task.status = "cancelled";
      task.completedAt = getLocalTimestamp();

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
        .describe("Filter by status: running | completed | failed | cancelled"),
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
     * Intercepta todo bash/shell call ANTES da execução.
     * Se o comando for de longa duração, substitui por um echo com taskId
     * e instrução de polling — o servidor LLM nunca fica esperando.
     */
    "tool.execute.before": async (input: any, output: any) => {
      const toolName = String(input?.tool ?? "").toLowerCase();
      if (toolName !== "bash" && toolName !== "shell") return;

      const args = output?.args as Record<string, unknown> | undefined;
      if (!args) return;

      const command = args.command;
      if (typeof command !== "string" || !command.trim()) return;
      if (!isLongRunning(command)) return;

      // Interceptado — inicia em background, retorna taskId em < 1s
      const task = runInBackground(command);

      fileLog(`[intercepted] bash → background`, { command, taskId: task.id });

      // Substitui o bash por um echo com JSON estruturado.
      // O agente lê isso como output do bash e sabe exatamente o que fazer.
      const payload = JSON.stringify({
        intercepted: true,
        taskId: task.id,
        pid: task.pid,
        command: task.command,
        status: "running",
        startedAt: task.startedAt,
        instructions: [
          "Command intercepted — running as background process to avoid LLM timeout.",
          "Use getBackgroundProcess tool with this taskId to check progress.",
          "Poll every 30 seconds until status is 'completed' or 'failed'.",
          "Do NOT use bash tool to wait — use getBackgroundProcess only.",
        ],
      });

      // Escapamos as aspas simples para o shell não quebrar o echo
      const escaped = payload.replace(/'/g, "'\\''");
      args.command = `echo '${escaped}'`;
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
