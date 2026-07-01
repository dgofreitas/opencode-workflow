# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is the source of truth for a multi-agent SDLC workflow built for **OpenCode**. It installs into a target project via `opencode-workflow-installer.sh`.

> The **Claude Code** port of this same workflow has moved to a dedicated repo: [`dgofreitas/claude_code-workflow`](https://github.com/dgofreitas/claude_code-workflow). This repo no longer contains a `claude/` directory — do not recreate one here. If you're asked to work on the Claude Code deliverable, point to that repo instead.

There is **no automated test suite**. Testing means installing into a real project and exercising the workflow via the `opencode` CLI.

## Build & install commands

```bash
# Build the self-contained installer (outputs opencode-workflow-installer.sh)
bash build-installer.sh

# Install into a target project
bash install.sh --dest <target-project>
```

## Architecture

```
agent/        # OpenCode agents (core/master.md + subagents/)
skills/       # OpenCode skills
context/      # 5-bucket context system (INDEX.md + files)
command/      # OpenCode slash commands
config/       # agent-fallback.json, agent-metadata.json
opencode.json # OpenCode agent models & timeouts
```

### SDLC pipeline (the happy path)

```
Master (router)
  → ProductManager → [GATE-PM] → stories
  → SystemArchitect → [GATE-SA] → stack (greenfield only)
  → Architect → [GATE-AR] → technical plan
  → TechLead (per-story orchestration)
      → Backend/Frontend devs (parallel)
      → TestEngineer → [GATE: coverage ≥90%]
      → QAAnalyst → [GATE: QA PASSED]
      → CodeReviewer → [GATE: REVIEW APPROVED]
      → MergeRequestCreator → [GATE-MR: PR created]
  → [GATE-NEXT] → next story or summary
```

Five named human approval gates: `GATE-PM`, `GATE-SA`, `GATE-AR`, `GATE-MR`, `GATE-NEXT`.

### Context system (`context/`)

Five buckets: `standards/`, `workflows/`, `stacks/`, `meta/`, `project/`. The only navigation point is `context/INDEX.md` — a flat semantic index with tags. ContextScout reads INDEX.md, filters by tags, and returns ≤5 files. Each file targets ≤200 lines (MVI — Minimal Viable Information principle).

## Critical rules

### Agent permission blocks (OpenCode)
`"*": "deny"` **must be the FIRST entry** — the engine uses last-match-wins. Deny after allows means deny never fires.

```yaml
# Correct:
read:
  "*": "deny"                          # FIRST
  ".opencode/context/**": "allow"      # then allow

# Wrong:
read:
  ".opencode/context/**": "allow"
  "*": "deny"                          # TOO LATE
```

### max_tokens
Never cap `max_tokens` on code-generation agents (BackendDeveloper, FrontendDeveloper*, TestEngineer, ShellDeveloper) — mid-file truncation produces broken code. Safe to cap only on orchestrators/reporters (Master, QAAnalyst, CodeReviewer).

### Provider timeout
Set to 600000 ms (10 min) on all providers. 10-hour timeouts silently stall the pipeline because the fallback plugin never triggers.

### Fallback models
Every agent must have `fallbackModels` in `config/agent-fallback.json`. Empty `[]` leaves that agent with no recovery path.

### Plugin name
The token-logger plugin is `opencode-token-logger`. Any reference to `opencode-token-monitor@latest` in `opencode.json` is stale and must be corrected before running `build-installer.sh`.

## Key files

| File | Purpose |
|------|---------|
| `opencode.json` | OpenCode agent models & timeouts (do not swap models without reason — mapping is cost/quality tuned) |
| `AGENTS.md` | Dev guidance for repo maintenance (authoritative, read this first) |
| `GUIDE.md` | Full end-user documentation (10 sections) — note: some sections may still reference the now-removed `claude/` directory, pending cleanup |
| `config/agent-fallback.json` | Per-agent fallback model mapping |
| `config/agent-metadata.json` | Agent taxonomy |
