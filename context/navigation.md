<!-- Context: navigation | Priority: critical | Version: 3.0 | Updated: 2026-05-02 -->
# Context Navigation

This system uses a **flat semantic index** for navigation. There are no
subdirectory `navigation.md` files — a single index maps every leaf file.

→ **Always consult `INDEX.md` at the root of this directory.**

The `INDEX.md` contains every leaf context file tagged with semantic
keywords and a one-line summary, so discovery is a single read.

---

## Structure

```
context/
├── INDEX.md                # ← Start here. Flat index of every leaf file.
├── navigation.md           # This file (pointer to INDEX).
├── core/                   # Universal standards, workflows, patterns
├── development/            # Software development (all stacks)
├── project/                # Project-specific context
└── project-intelligence/   # Living notes, decisions, ADRs
```

---

## For agents

1. `read(".opencode/context/INDEX.md")` — 1 read.
2. Match user intent against tags and summaries.
3. Read only the leaf files that match. Return up to 5 files ranked by
   priority. No subdirectory walks.
