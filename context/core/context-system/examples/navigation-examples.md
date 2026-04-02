<!-- Context: core/navigation-examples | Priority: high | Version: 2.1 | Updated: 2026-03-29 -->

# Examples: Navigation Files

**Purpose**: Patterns for token-efficient navigation files (200-300 tokens target)

---

## Essential Pattern: Category Navigation

**File**: `project-intelligence/navigation.md` (~250 tokens)
```markdown
# Project Intelligence Navigation

**Purpose**: Navigate project-specific context

---

## Structure

project-intelligence/
├── navigation.md
├── quick-start.md
├── core-concepts/  (agent-architecture, eval-framework, registry-system)
├── guides/         (adding-agent, testing-agent, debugging-issues)
├── lookup/         (commands, file-locations)
└── errors/         (tool-permission-errors)

## Quick Routes

| Task | Path |
|------|------|
| **Add agent** | `guides/adding-agent.md` |
| **Test agent** | `guides/testing-agent.md` |
| **Find files** | `lookup/file-locations.md` |

## By Type

**Core Concepts** → Foundational understanding
**Guides** → Step-by-step workflows
**Lookup** → Quick reference tables
**Errors** → Troubleshooting
```

---

## Example: Concern-Based Navigation

**File**: `development/navigation.md` (~280 tokens)
```markdown
# Development Navigation

**Purpose**: Software development across all stacks

---

## Structure

development/
├── navigation.md
├── ui-navigation.md
├── backend-navigation.md
│
├── principles/
│   ├── clean-code.md
│   └── api-design.md
│
├── frontend/
│   ├── react/
│   └── vue/
│
├── backend/
│   ├── api-patterns/
│   ├── nodejs/
│   └── authentication/
│
└── data/
    ├── sql-patterns/
    └── orm-patterns/

---

## Quick Routes

| Task | Path |
|------|------|
| **UI/Frontend** | `ui-navigation.md` |
| **Backend/API** | `backend-navigation.md` |
| **Clean code** | `principles/clean-code.md` |
| **API design** | `principles/api-design.md` |

---

## By Concern

**Principles** → Universal development practices
**Frontend** → React, Vue, state management
**Backend** → APIs, Node.js, Python, auth
**Data** → SQL, NoSQL, ORMs
```

---

## Pattern Variants

| Pattern | When to Use | Key Feature | Example File |
|---------|-------------|-------------|--------------|
| **Function-based** | Repository-specific categories | By type (concepts/guides/lookup) | `project-intelligence/navigation.md` |
| **Concern-based** | Multi-technology categories | By domain (frontend/backend/data) | `development/navigation.md` |
| **Cross-cutting** | Spans multiple categories | Multi-source paths | `development/ui-navigation.md` |
| **Workflow-focused** | Full-stack dev | Stack combos + workflows | `development/fullstack-navigation.md` |
| **Minimal** | Few files (<5) | Simple tree + routes | `content/navigation.md` |

---

## Required Structure (all patterns)

1. **ASCII tree** — Shows hierarchy (~50-100 tokens)
2. **Quick Routes table** — 5-10 common tasks with bold labels
3. **By Type/Concern section** — 3-5 word descriptions per category

---

## Anti-Patterns

| Problem | Example | Fix |
|---------|---------|-----|
| **Too verbose** | 800+ token intro paragraphs | Use trees + tables, not prose |
| **Missing structure** | Flat list of filenames | Add ASCII tree + quick routes |
| **Too detailed** | Full docs inside navigation | Point to files, don't duplicate |

---

## Checklist

- [ ] 200-300 tokens total?
- [ ] ASCII tree included?
- [ ] Quick routes table with bold tasks?
- [ ] By concern/type section?
- [ ] Descriptions 3-5 words?
- [ ] No duplicated content?

---

## Related

- `../guides/navigation-design-basics.md` - How to create navigation files
- `../guides/organizing-context.md` - Organizational patterns
- `../standards/mvi.md` - MVI principle