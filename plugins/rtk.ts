import type { Plugin } from "@opencode-ai/plugin"

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// ── Anti-loop guard ───────────────────────────────────────────────────────
// If the SAME original command fails 3 times in a row in a session (same
// command string + same failing output signature), we stop rewriting that
// command for the rest of the session and let it run natively. This breaks
// deterministic RTK loops (e.g. `rtk lint` always failing with
// `Environment key "es2022" is unknown` because rtk resolves the system
// eslint instead of the project one) without needing any prompt-level rules.
//
// A "failing output signature" is any of:
//   - exit code != 0 AND output is empty/whitespace
//   - output contains "JSON parse failed"
//   - output contains "[RTK:PASSTHROUGH]"
//   - output contains "Output truncated"
//
// The blocklist is keyed by (sessionID, normalizedCommandHash) and lives for
// the lifetime of the plugin module (per OpenCode server process). It is
// intentionally in-memory and per-process: no cross-session persistence.

type AttemptRecord = {
  command: string
  result: "fail" | "ok"
  signature: string
  ts: number
}

const perSession = new Map<string, { recent: AttemptRecord[]; blocked: Set<string> }>()

const BLOCK_THRESHOLD = 3
const RECENT_WINDOW = 5
const TTL_MS = 30 * 60 * 1000

function signatureOf(output: string, exitLike: boolean): string {
  const o = (output ?? "").trim()
  if (!o && exitLike) return "empty-fail"
  if (o.includes("JSON parse failed")) return "json-parse-failed"
  if (o.includes("[RTK:PASSTHROUGH]")) return "passthrough"
  if (o.includes("Output truncated")) return "truncated"
  if (o.includes("Environment key") && o.includes("is unknown")) return "env-unknown"
  if (exitLike && o.length > 0) return "exit-nonzero"
  return "ok"
}

function normalizeCommand(cmd: string): string {
  return cmd
    .replace(/\s+/g, " ")
    .replace(/\/home\/[^/]+\//g, "/home/*/")
    .replace(/\/Users\/[^/]+\//g, "/Users/*/")
    .trim()
}

function hash(s: string): string {
  let h = 5381
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
  return (h >>> 0).toString(36)
}

function getSessionState(sessionID: string) {
  const now = Date.now()
  let st = perSession.get(sessionID)
  if (!st) {
    st = { recent: [], blocked: new Set() }
    perSession.set(sessionID, st)
  }
  st.recent = st.recent.filter((r) => now - r.ts < TTL_MS)
  return st
}

function looksFailing(sig: string): boolean {
  return sig !== "ok"
}

function shouldBlock(st: { recent: AttemptRecord[]; blocked: Set<string> }, key: string): boolean {
  if (st.blocked.has(key)) return true
  const last = st.recent.slice(-BLOCK_THRESHOLD)
  if (last.length < BLOCK_THRESHOLD) return false
  const cmd = last[0].command
  const sig = last[0].signature
  if (!looksFailing(sig)) return false
  for (const r of last) {
    if (r.command !== cmd) return false
    if (r.result !== "fail") return false
    if (r.signature !== sig) return false
  }
  st.blocked.add(key)
  st.recent = st.recent.slice(-RECENT_WINDOW)
  return true
}

export const RtkOpenCodePlugin: Plugin = async ({ $ }) => {
  try {
    await $`which rtk`.quiet()
  } catch {
    console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
    return {}
  }

  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return
      const args = output?.args
      if (!args || typeof args !== "object") return

      const command = (args as Record<string, unknown>).command
      if (typeof command !== "string" || !command) return

      const sessionID = String(input?.sessionID ?? "default")
      const key = hash(normalizeCommand(command))
      const st = getSessionState(sessionID)

      if (shouldBlock(st, key)) {
        return
      }

      try {
        const result = await $`rtk rewrite ${command}`.quiet().nothrow()
        const rewritten = String(result.stdout).trim()
        if (rewritten && rewritten !== command) {
          ;(args as Record<string, unknown>).command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    },

    "tool.execute.after": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const sessionID = String(input?.sessionID ?? "default")
      const st = getSessionState(sessionID)

      const args = (input?.args ?? {}) as Record<string, unknown>
      const command = typeof args.command === "string" ? args.command : ""
      if (!command) return

      const outStr = typeof output?.output === "string" ? output.output : String(output?.output ?? "")
      const meta = (output?.metadata ?? {}) as Record<string, unknown>
      const exitCode = typeof meta.exitCode === "number" ? meta.exitCode : Number(meta.exitCode ?? 0)
      const exitLike = !Number.isNaN(exitCode) && exitCode !== 0

      const sig = signatureOf(outStr, exitLike)
      const key = hash(normalizeCommand(command))
      st.recent.push({
        command: key,
        result: looksFailing(sig) ? "fail" : "ok",
        signature: sig,
        ts: Date.now(),
      })
      st.recent = st.recent.slice(-RECENT_WINDOW)

      if (shouldBlock(st, key)) {
        const note =
          "[rtk-anti-loop] " +
          "detected a repeated failing command (" + BLOCK_THRESHOLD + "x, " + sig + "). " +
          "RTK rewrite disabled for this command for the rest of the session; " +
          "the original command now runs natively (uses the project's local binary)."
        try {
          output.metadata = { ...(output.metadata ?? {}), "rtk-anti-loop": { blocked: true, signature: sig } }
        } catch {
          // metadata is optional/best-effort
        }
        void note
      }
    },
  }
}