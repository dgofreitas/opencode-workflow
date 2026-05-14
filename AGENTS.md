# AGENTS.md — New OpenCode Workflow

> Compact guidance for agents editing this repo. When in doubt, trust executable sources (install scripts, `opencode.json`, `tsconfig.json`) over prose docs.

## What this repo is

This repo **is not a runnable app**. It is the *source of truth* for a multi-agent SDLC workflow that installs into `<project>/.opencode/` via a self-contained shell installer. The deliverable is `opencode-workflow-installer.sh`.

## Build / deliverable

- **Generate installer:** `bash build-installer.sh`
- **Install locally (for dev testing):** `bash install.sh --dest <target-project>`
- **What the installer copies:** `agent/`, `command/`, `config/`, `context/`, `plugins/`, `skills/`, `tool/`, `bin/`, `package.json`, `opencode.json`, `instructions.md`
- Verify the installer after any structural change.

## TypeScript compilation

- `tsconfig.json` only compiles `plugins/**/*.ts` and `agent-fallback.ts`. Do not assume other `.ts` files are part of the build.
- Strict mode is **off** (`"strict": false`, `"noImplicitAny": false`).

## Models & config

- `opencode.json` assigns exact models per agent. Do **not** swap models without a strong reason; the mapping is tuned for cost/quality per role.
- `opencode.json` references `./instructions.md`. Keep it accurate — it is injected into every OpenCode session that uses this workflow.
- `config/agent-fallback.json` and `config/agent-metadata.json` define fallback behavior and agent taxonomy. Keep them in sync when adding/removing agents.
- Legacy files `opencode_old.json` and `opencode-v1.json` exist for reference; do not edit them unless explicitly asked.

## RTK plugin (token-saving bash proxy)

- `plugins/rtk.ts` intercepts `bash` tool calls and rewrites them via `rtk rewrite`. The binary is at `bin/rtk` and must be in `PATH`.
- **Critical rule from `instructions.md`:** Always use `npm run <script>`. Short forms (`npm test`, `npm start`, `npm build`) break the rewrite.
- Do **not** add pipes like `| tail` or `| head` to RTK-supported commands; RTK already filters output.

## Agent & skill files

- Agents are **Markdown files** under `agent/` (not code). Subagents live under `agent/subagents/`, core agent at `agent/core/master.md`.
- Skills are under `skills/` with `SKILL.md` entrypoints.
- Commands are under `command/` as Markdown files.
- Context system lives under `context/` — `INDEX.md` is the flat semantic index consumed by ContextScout.

## Testing

- There is **no executable test suite** in this repo. "Testing" means installing into a real project and exercising the OpenCode pipeline (`opencode --agent Master`).
- `context/standards/test-coverage.md` and `.github/agents/test-engineer.agent.md` are **specifications**, not runnable tests.

## Timeout & fallback

- **Provider timeout** in `opencode.json` was changed from `36000000`ms (10h) → `600000`ms (10 min) on all providers. A 10h timeout silently stalls the entire pipeline when a model stops responding; the fallback plugin never triggers because OpenCode waits indefinitely. With 10 min, stalled sessions abort but still give enough time for agents to generate complete outputs like technical analysis docs or full test suites.
- **Every agent MUST have fallbackModels** in `config/agent-fallback.json`. Empty `fallbackModels: []` means that agent has no recovery path when its primary model hangs. The fallback plugin (`plugins/opencode-agent-fallback.ts`) only works when fallbacks are configured per-agent.

## max_tokens warning

- `max_tokens` limits **output** (response), not input/context. Agents that generate source code (BackendDeveloper, FrontendDeveloper*, TestEngineer, ShellDeveloper) must **never** have `max_tokens` capped — a mid-file truncation produces broken, uncompilable code.
- Safe to cap only on **orchestrator/reporting agents** (Master, QAAnalyst, CodeReviewer) that emit short routing decisions or markdown reports.

## Plugin reference

- The token-logger plugin is named `opencode-token-logger` in `plugins/`. Any `opencode.json` referencing `opencode-token-monitor@latest` is stale and should be fixed to `opencode-token-logger` before running `build-installer.sh`.
