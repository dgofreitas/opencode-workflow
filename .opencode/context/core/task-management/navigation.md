<!-- Context: core/task-management/navigation | Priority: critical | Version: 2.0 | Updated: 2026-03-29 -->

# Task Management Navigation

**Purpose**: JSON-driven task breakdown and tracking system

---

## Structure

```
core/task-management/
├── navigation.md
├── standards/
│   └── task-schema.md           # JSON schema (v1.0)
├── guides/
│   ├── splitting-tasks.md       # Task decomposition
│   └── managing-tasks.md        # Workflow guide
└── lookup/
    └── task-commands.md         # CLI script reference
```

---

## Quick Routes

| Task | Path | Priority |
|------|------|----------|
| **Understand schema** | `standards/task-schema.md` | ⭐⭐⭐⭐⭐ |
| **Split a feature** | `guides/splitting-tasks.md` | ⭐⭐⭐⭐⭐ |
| **Manage task lifecycle** | `guides/managing-tasks.md` | ⭐⭐⭐⭐ |
| **Use CLI commands** | `lookup/task-commands.md` | ⭐⭐⭐⭐ |

---

## Loading Strategy

### For Creating Tasks:
1. Load `standards/task-schema.md` (understand structure)
2. Load `guides/splitting-tasks.md` (decomposition approach)
3. Reference `lookup/task-commands.md` (validate after creation)

### For Managing Tasks:
1. Load `guides/managing-tasks.md` (workflow)
2. Reference `lookup/task-commands.md` (CLI usage)

---

## Related

- **Active tasks** → `.tmp/tasks/{feature}/` (at project root)
- **Completed tasks** → `.tmp/tasks/completed/{feature}/`
- **TaskManager agent** → `.opencode/agent/subagents/core/task-manager.md`
- **Core navigation** → `../navigation.md`
