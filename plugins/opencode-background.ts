/**
 * opencode-background
 *
 * Self-contained OpenCode plugin for managing long-running background processes.
 * Prevents agent freeze caused by the 120s bash tool timeout.
 *
 * Based on: https://github.com/zenobi-us/opencode-background (MIT License)
 * Adapted to be dependency-free (no execa), using Node.js native child_process.
 *
 * Tools exposed to the agent:
 *   - createBackgroundProcess  → Start a command in the background
 *   - getBackgroundProcess     → Get status + last output lines of a task
 *   - listBackgroundProcesses  → List/filter all tasks
 *   - killBackgroundProcesses  → Kill tasks by id, session, status or tags
 *
 * Installation:
 *   Copy this file to ~/.config/opencode/plugins/opencode-background.ts
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
  name: string;
  command: string;
  status: TaskStatus;
  tags: string[];
  global: boolean;
  sessionId: string;
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
      const archiveName = `${LOG_FILE}.${timestamp}`;
      renameSync(LOG_FILE, archiveName);

      const dir = "/tmp";
      const files = readdirSync(dir);
      const logFiles = files
        .filter((f: string) => f.startsWith("opencode-background.log."))
        .map((f: string) => join(dir, f))
        .sort();
      
      while (logFiles.length > MAX_LOG_FILES) {
        const oldest = logFiles.shift();
        if (oldest) unlinkSync(oldest);
      }
    }
  } catch (err) {
  }
}

function fileLog(msg: string, extra?: any) {
  try {
    rotateLogIfNeeded();
    const logLine = `[${getLocalTimestamp()}] ${msg} ${extra ? JSON.stringify(extra) : ""}\n`;
    appendFileSync(LOG_FILE, logLine);
  } catch (err) { }
}

// ─── BackgroundProcessManager ─────────────────────────────────────────────────

class BackgroundProcessManager {
  private tasks = new Map<string, BackgroundTask>();

  private generateId(): string {
    return "task-" + Math.random().toString(36).substring(2, 9);
  }

  createTask(input: {
    command: string;
    name?: string;
    tags?: string[];
    global?: boolean;
    sessionId?: string;
  }): string {
    const id = this.generateId();

    const task: BackgroundTask = {
      id,
      name: input.name || input.command,
      command: input.command,
      status: "running",
      tags: input.tags || [],
      global: input.global ?? false,
      sessionId: input.sessionId || "unknown",
      startedAt: getLocalTimestamp(),
      outputStream: [],
    };

    // Spawn via shell so pipes, redirects, etc. work as expected
    const child = spawn(input.command, {
      shell: true,
      detached: true, // Detach from parent so OpenCode's bash tool doesn't block
      stdio: ["ignore", "pipe", "pipe"],
    });

    task.pid = child.pid;
    this.tasks.set(id, task);

    fileLog(`[${id}] Task created`, { command: task.command, pid: task.pid, sessionId: task.sessionId });

    const recordOutput = (line: string, isError = false) => {
      const formatted = isError ? `[ERROR] ${line}` : line;
      task.outputStream.push(formatted);
      // Rolling buffer: keep only the last 100 lines
      if (task.outputStream.length > 100) {
        task.outputStream.shift();
      }
    };

    child.stdout?.on("data", (chunk: any) => {
      chunk.toString().split("\n").filter(Boolean).forEach((l) => recordOutput(l));
    });

    child.stderr?.on("data", (chunk: any) => {
      chunk.toString().split("\n").filter(Boolean).forEach((l) => recordOutput(l, true));
    });

    child.on("close", (code: number | null) => {
      if (task.status === "cancelled") {
        fileLog(`[${id}] Process closed after cancellation`, { code });
        return; // Already marked cancelled
      }
      task.completedAt = getLocalTimestamp();
      if (code === 0) {
        task.status = "completed";
        fileLog(`[${id}] Task completed successfully`);
      } else {
        task.status = "failed";
        task.error = `Process exited with code ${code}`;
        fileLog(`[${id}] Task failed`, { code });
      }
    });

    child.on("error", (err: Error) => {
      task.status = "failed";
      task.error = err.message;
      task.completedAt = getLocalTimestamp();
      recordOutput(err.message, true);
      fileLog(`[${id}] Task error`, { error: err.message });
    });

    // Unref so the OpenCode process itself can exit without waiting for the child
    child.unref();

    return JSON.stringify({ taskId: id, pid: task.pid, name: task.name });
  }

  getTask(taskId: string): string {
    const task = this.tasks.get(taskId);
    if (!task) {
      return JSON.stringify({ error: `Task ${taskId} not found` });
    }
    return JSON.stringify({ ...task, outputStream: task.outputStream.slice(-20) });
  }

  listTasks(filters: { sessionId?: string; status?: string; tags?: string[] }): string {
    const results = Array.from(this.tasks.values()).filter((task) => {
      const sessionMatch = !filters.sessionId || task.sessionId === filters.sessionId;
      const statusMatch = !filters.status || task.status === filters.status;
      const tagMatch =
        !filters.tags ||
        filters.tags.length === 0 ||
        filters.tags.some((t) => task.tags.includes(t));
      return sessionMatch && statusMatch && tagMatch;
    });

    return JSON.stringify(
      results.map((t) => ({
        id: t.id,
        name: t.name,
        command: t.command,
        status: t.status,
        tags: t.tags,
        global: t.global,
        sessionId: t.sessionId,
        pid: t.pid,
        startedAt: t.startedAt,
        completedAt: t.completedAt,
        error: t.error,
        lastOutput: t.outputStream.slice(-5), // summary: last 5 lines only
      }))
    );
  }

  killTasks(input: {
    taskId?: string;
    sessionId?: string;
    status?: string;
    tags?: string[];
  }): string {
    const killed: string[] = [];

    const kill = (task: BackgroundTask) => {
      try {
        if (task.pid) (process as any).kill(task.pid);
        fileLog(`[${task.id}] Killed process`, { pid: task.pid });
      } catch (err: any) {
        fileLog(`[${task.id}] Failed to kill process`, { pid: task.pid, error: err.message });
      }
      task.status = "cancelled";
      task.completedAt = getLocalTimestamp();
      killed.push(task.id);
    };

    if (input.taskId) {
      const t = this.tasks.get(input.taskId);
      if (t) kill(t);
      return JSON.stringify({ killed });
    }

    Array.from(this.tasks.values())
      .filter((task) => {
        const sessionMatch = !input.sessionId || task.sessionId === input.sessionId;
        const statusMatch = !input.status || task.status === input.status;
        const tagMatch =
          !input.tags ||
          input.tags.length === 0 ||
          input.tags.some((t) => task.tags.includes(t));
        return sessionMatch && statusMatch && tagMatch;
      })
      .forEach(kill);

    return JSON.stringify({ killed });
  }

  cleanupSession(sessionId: string): void {
    Array.from(this.tasks.values())
      .filter((t) => t.sessionId === sessionId && !t.global)
      .forEach((task) => {
        try {
          if (task.pid) (process as any).kill(task.pid);
          fileLog(`[${task.id}] Cleaned up process`, { pid: task.pid });
        } catch (err: any) {
          fileLog(`[${task.id}] Cleanup failed to kill process`, { pid: task.pid, error: err.message });
        }
        this.tasks.delete(task.id);
      });
  }
}

// ─── Plugin ───────────────────────────────────────────────────────────────────

const manager = new BackgroundProcessManager();

export const BackgroundPlugin: Plugin = async (ctx) => {
  fileLog(`Plugin initialized`);

  const createBackgroundProcess = tool({
    description:
      "Run a shell command as a detached background process. Use this for any command that may take longer than 60 seconds (installs, builds, test suites, etc.) to avoid the 120s bash timeout. Returns a taskId to monitor progress.",
    args: {
      command: tool.schema.string().describe("The shell command to execute"),
      name: tool.schema.string().optional().describe("Human-readable name for this task"),
      tags: tool.schema.array(tool.schema.string()).optional().describe("Tags for filtering (e.g. ['test', 'build'])"),
      global: tool.schema.boolean().optional().describe("If true, task persists across sessions (default: false)"),
    },
    async execute(args, toolCtx) {
      return manager.createTask({
        command: args.command,
        name: args.name,
        tags: args.tags,
        global: args.global,
        sessionId: (toolCtx as any)?.sessionID || (toolCtx as any)?.session_id,
      });
    }
  });

  const getBackgroundProcess = tool({
    description:
      "Get the current status, PID, and last 20 output lines of a specific background task by its taskId.",
    args: {
      taskId: tool.schema.string().describe("The task ID returned by createBackgroundProcess"),
    },
    async execute(args) {
      return manager.getTask(args.taskId);
    }
  });

  const listBackgroundProcesses = tool({
    description:
      "List all background tasks with optional filtering by sessionId, status, or tags. Returns id, name, status, and last 5 output lines per task.",
    args: {
      sessionId: tool.schema.string().optional().describe("Filter by session ID"),
      status: tool.schema.string().optional().describe("Filter by status: running | completed | failed | cancelled"),
      tags: tool.schema.array(tool.schema.string()).optional().describe("Filter by tags"),
    },
    async execute(args) {
      return manager.listTasks({
        sessionId: args.sessionId,
        status: args.status,
        tags: args.tags
      });
    }
  });

  const killBackgroundProcesses = tool({
    description:
      "Kill one or more background tasks. Specify taskId to kill a specific task, or use sessionId/status/tags to kill matching tasks in bulk.",
    args: {
      taskId: tool.schema.string().optional().describe("Kill a specific task by ID"),
      sessionId: tool.schema.string().optional().describe("Kill all tasks in a session"),
      status: tool.schema.string().optional().describe("Kill all tasks with this status"),
      tags: tool.schema.array(tool.schema.string()).optional().describe("Kill all tasks with these tags"),
    },
    async execute(args) {
      return manager.killTasks({
        taskId: args.taskId,
        sessionId: args.sessionId,
        status: args.status,
        tags: args.tags || []
      });
    }
  });

  return {
    tool: {
      createBackgroundProcess,
      getBackgroundProcess,
      listBackgroundProcesses,
      killBackgroundProcesses,
    },

    event: async ({ event }: any) => {
      // Cleanup session-specific tasks when a session is deleted
      const sessionId = (event as any).session_id || (event as any).sessionID || event?.properties?.info?.id || event?.properties?.info?.parentID;
      
      fileLog(`Received event: ${event?.type}`, { sessionId });

      if (event?.type === "session.deleted" && sessionId) {
        fileLog(`Session deleted, cleaning up tasks for ${sessionId}`);
        manager.cleanupSession(sessionId);
      }
    }
  };
};

export default BackgroundPlugin;
