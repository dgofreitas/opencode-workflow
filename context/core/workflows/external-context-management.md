<!-- Context: workflows/external-context | Priority: high | Version: 1.0 | Updated: 2026-01-28 -->
# External Context Management

## Overview

External context is live documentation fetched from external libraries and frameworks (via Context7 API or official docs). Instead of re-fetching on every task, we **persist external context** to `.tmp/external-context/` so main agents can pass it to subagents.

**Key Principle**: ExternalScout fetches once → persists to disk → main agents reference → subagents read (no re-fetching)

---

## Directory Structure

```
.tmp/external-context/
├── .manifest.json                    # Metadata about all cached external docs
├── drizzle-orm/
│   ├── modular-schemas.md           # Fetched: "How to organize schemas modularly"
│   ├── postgresql-setup.md          # Fetched: "PostgreSQL setup with Drizzle"
│   └── typescript-config.md         # Fetched: "TypeScript configuration"
├── better-auth/
│   ├── nextjs-integration.md        # Fetched: "Better Auth + Next.js setup"
│   ├── drizzle-adapter.md           # Fetched: "Drizzle adapter for Better Auth"
│   └── session-management.md        # Fetched: "Session handling"
├── next.js/
│   ├── app-router-setup.md          # Fetched: "App Router basics"
│   ├── server-actions.md            # Fetched: "Server Actions patterns"
│   └── middleware.md                # Fetched: "Middleware configuration"
└── tanstack-query/
    ├── server-components.md         # Fetched: "TanStack Query + Server Components"
    └── prefetching.md               # Fetched: "Prefetching strategies"
```

### Naming Conventions

- **Package name** (directory): Exact npm package name (kebab-case)
  - ✅ `drizzle-orm`, `better-auth`, `next.js`, `@tanstack/react-query`
  - ❌ `drizzle`, `nextjs`, `tanstack-query`

- **File name** (topic): Kebab-case description of the topic
  - ✅ `modular-schemas.md`, `nextjs-integration.md`, `server-components.md`
  - ❌ `modular schemas.md`, `NextJS Integration.md`, `ServerComponents.md`

---

## Manifest File

**Location**: `.tmp/external-context/.manifest.json`

**Purpose**: Track what's cached, when it was fetched, and from which source

**Structure**:
```json
{
  "last_updated": "2026-01-28T14:30:22Z",
  "packages": {
    "drizzle-orm": {
      "files": [
        "modular-schemas.md",
        "postgresql-setup.md",
        "typescript-config.md"
      ],
      "last_updated": "2026-01-28T14:30:22Z",
      "source": "Context7 API",
      "official_docs": "https://orm.drizzle.team"
    },
    "better-auth": {
      "files": [
        "nextjs-integration.md",
        "drizzle-adapter.md",
        "session-management.md"
      ],
      "last_updated": "2026-01-28T14:25:10Z",
      "source": "Context7 API",
      "official_docs": "https://better-auth.com"
    },
    "next.js": {
      "files": [
        "app-router-setup.md",
        "server-actions.md",
        "middleware.md"
      ],
      "last_updated": "2026-01-28T14:20:05Z",
      "source": "Context7 API",
      "official_docs": "https://nextjs.org"
    }
  }
}
```

---

## File Format

Each external context file has a metadata header followed by the documentation content.

**Template**:
```markdown
---
source: Context7 API
library: Drizzle ORM
package: drizzle-orm
topic: modular-schemas
fetched: 2026-01-28T14:30:22Z
official_docs: https://orm.drizzle.team/docs/goodies#multi-file-schemas
---

# Modular Schemas in Drizzle ORM

[Filtered documentation content from Context7 API]

## Key Concepts

[Relevant sections only]

## Code Examples

[Practical examples from official docs]

---

**Source**: Context7 API (live, version-specific)
**Official Docs**: https://orm.drizzle.team/docs/goodies#multi-file-schemas
**Fetched**: 2026-01-28T14:30:22Z
```

---

## Workflow & Task Delegation

For the complete integration workflow (6 stages), session context format, subtask JSON format, and implementation details with code examples, see:

→ **`external-context-integration.md`** — Full workflow, code examples, session templates, subtask JSON patterns

---

## Cleanup & Maintenance

### When to Clean Up

External context files should be cleaned up when:
1. Task is complete and session is deleted
2. External docs become stale (>7 days old)
3. User explicitly requests cleanup
4. Disk space is needed

### How to Clean Up

**Manual cleanup** (ask user first):
```bash
rm -rf .tmp/external-context/{package-name}/
# Update .manifest.json to remove package entry
```

**Automatic cleanup** (future enhancement):
- Add cleanup script that removes files older than 7 days
- Run as part of session cleanup process
- Update manifest after cleanup

### Manifest Cleanup

After deleting external context files, update `.manifest.json`:
```json
{
  "last_updated": "2026-01-28T15:00:00Z",
  "packages": {
    // Remove entries for deleted packages
  }
}
```

---

## Best Practices

For detailed DO/DON'T rules per role (Main Agent, ExternalScout, TaskManager, Subagents), see:

→ **`external-context-integration.md`** — Best Practices section

**Key rules for this file's scope (management)**:
1. **ExternalScout**: Always persist to `.tmp/external-context/`, update `.manifest.json`, include metadata header, filter aggressively
2. **Cleanup**: Delete stale files (>7 days), update manifest after deletions
3. **All agents**: Never modify external context files — they're read-only

---

## Troubleshooting

For full troubleshooting (files not found, stale context, manifest sync), see:

→ **`external-context-integration.md`** — Troubleshooting section

---

## References

- **ExternalScout**: `.opencode/agent/subagents/core/externalscout.md` — Fetches and persists external docs
- **Task Delegation**: `.opencode/context/core/workflows/task-delegation-basics.md` — How to reference external context in sessions
- **Session Management**: `.opencode/context/core/workflows/session-management.md` — Session lifecycle
- **Library Registry**: `.opencode/skills/context7/library-registry.md` — Supported libraries and query patterns
