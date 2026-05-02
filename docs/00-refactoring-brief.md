# Briefing: Refatoração do Context System

## Objetivo

Reduzir o consumo de tokens por consulta eliminando navegação encadeada de `navigation.md` e consolidando arquivos redundantes. Meta: de ~5–7 reads por consulta para ~2 reads fixos.

---

## Tarefa 1 — Criar `INDEX.md` na raiz do contexto

**Caminho**: `.opencode/context/INDEX.md`

Criar um índice semântico flat com **uma linha por arquivo folha relevante**, no formato:

```
- <path relativo ao context/> | tags: <palavras-chave de domínio>
```

Exemplo de estrutura esperada:

```markdown
# Context Index

## core / system
- core/essential-patterns.md          | tags: patterns, core, fundamentals
- core/context-system.md              | tags: context, system, overview
- core/system/context-guide.md        | tags: context, guide, usage
- core/system/context-paths.md        | tags: paths, structure

## core / standards
- core/standards/code-quality.md      | tags: quality, code, review
- core/standards/code-analysis.md     | tags: analysis, code
- core/standards/documentation.md     | tags: docs, writing
- core/standards/security-patterns.md | tags: security
- core/standards/test-coverage.md     | tags: tests, coverage
- core/standards/project-intelligence.md | tags: intelligence, decisions

## core / task-management
- core/task-management/guides/managing-tasks.md  | tags: tasks, managing
- core/task-management/guides/splitting-tasks.md | tags: tasks, splitting
- core/task-management/lookup/task-commands.md   | tags: tasks, commands, lookup
- core/task-management/standards/task-schema.md  | tags: tasks, schema

## core / workflows
- core/workflows/code-review.md               | tags: review, code
- core/workflows/component-planning.md        | tags: planning, component
- core/workflows/delegation.md                | tags: delegation, agents
- core/workflows/feature-breakdown.md         | tags: features, breakdown
- core/workflows/session-management.md        | tags: session, init
- core/workflows/review.md                   | tags: review
- core/workflows/external-libraries.md        | tags: external, docs, fetch, cache, libraries (VER TAREFA 2)
- core/workflows/task-delegation-basics.md    | tags: delegation, basics
- core/workflows/task-delegation-caching.md   | tags: delegation, cache
- core/workflows/task-delegation-specialists.md | tags: delegation, specialists

## core / context-system / guides
- core/context-system/guides/compact.md              | tags: compact, mvi
- core/context-system/guides/creation.md             | tags: creation, new context
- core/context-system/guides/navigation-design-basics.md | tags: navigation, design
- core/context-system/guides/organizing-context.md   | tags: organizing, structure
- core/context-system/guides/workflows.md            | tags: workflows, context

## core / context-system / standards
- core/context-system/standards/mvi.md               | tags: mvi, standards
- core/context-system/standards/structure.md         | tags: structure, standards
- core/context-system/standards/frontmatter.md       | tags: frontmatter, metadata
- core/context-system/standards/templates.md         | tags: templates

## core / context-system / operations
- core/context-system/operations/error.md    | tags: error, handling
- core/context-system/operations/extract.md  | tags: extract
- core/context-system/operations/harvest.md  | tags: harvest
- core/context-system/operations/migrate.md  | tags: migrate
- core/context-system/operations/organize.md | tags: organize
- core/context-system/operations/update.md   | tags: update

## development / frontend
- development/frontend/design-systems.md        | tags: design, ui, systems
- development/frontend/ui-styling-standards.md  | tags: styling, ui, standards
- development/frontend/when-to-delegate.md      | tags: delegation, frontend
- development/frontend/react/react-patterns.md  | tags: react, patterns

## development / backend
- development/backend/nodejs/project-structure.md | tags: nodejs, backend, structure

## development / principles
- development/principles/api-design.md  | tags: api, design
- development/principles/clean-code.md  | tags: clean code, principles

## development / ai
- development/ai/mastra-ai/ (navegar internamente) | tags: mastra, ai, agents

## project
- project/project-context.md | tags: project, context, overview

## project-intelligence
- project-intelligence/business-domain.md      | tags: business, domain
- project-intelligence/technical-domain.md     | tags: technical, domain
- project-intelligence/decisions-log.md        | tags: decisions, log
- project-intelligence/living-notes.md         | tags: notes, living
- project-intelligence/business-tech-bridge.md | tags: business, tech, bridge
```

**Obs**: popular com os paths reais lidos do filesystem — ajustar conforme arquivos existentes.

---

## Tarefa 2 — Mergear 4 arquivos de external-libraries em 1

**Arquivos a apagar/consolidar**:
- `core/workflows/external-context-integration.md`
- `core/workflows/external-context-management.md`
- `core/workflows/external-libraries-faq.md`
- `core/workflows/external-libraries-scenarios.md`

**Arquivo destino**: `core/workflows/external-libraries.md`

Ler os 4 arquivos, consolidar o conteúdo em seções internas respeitando MVI (< 200 linhas), estrutura sugerida:

```markdown
---
# frontmatter existente
---

# External Libraries

## Overview
(conteúdo de integration + management — parte conceitual)

## Workflow
(como buscar, cachear, integrar — de integration)

## FAQ
(perguntas frequentes — de faq)

## Scenarios
(casos de uso concretos — de scenarios)
```

Após criar o arquivo consolidado, **apagar os 4 originais**.

---

## Tarefa 3 — Apagar todos os `navigation.md` internos (exceto o da raiz)

Arquivos a apagar (os `navigation.md` intermediários que não são mais necessários com o INDEX flat):

```
core/config/navigation.md
core/context-system/navigation.md
core/standards/navigation.md
core/system/navigation.md
core/task-management/navigation.md
core/workflows/navigation.md
development/ai/navigation.md
development/backend/navigation.md
development/data/navigation.md
development/frameworks/navigation.md
development/frontend/navigation.md
development/frontend/react/navigation.md
development/infrastructure/navigation.md
development/integration/navigation.md
development/principles/navigation.md
development/navigation.md
project-intelligence/navigation.md
```

**Manter**: `.opencode/context/navigation.md` (raiz) — reescrever para simplesmente apontar para o `INDEX.md`.

**Reescrever `context/navigation.md`** para:

```markdown
---
# frontmatter existente
---

# Context Navigation

Este sistema usa um índice flat para navegação.

→ Consultar sempre: `INDEX.md` na raiz deste diretório.

O INDEX contém todos os arquivos folha com tags semânticas para busca direta.
```

---

## Tarefa 4 — Atualizar o agente ContextScout

Substituir o conteúdo do arquivo `contextscout.md` pelo seguinte:

```markdown
---
name: ContextScout
description: Discovers and recommends context files from .opencode/context/ ranked by priority using a flat semantic index. Suggests ExternalScout when a framework/library is mentioned but not found internally.
mode: subagent
temperature: 0.1
permission:
  read:
    "**/*": "allow"
  grep:
    "*": "allow"
  glob:
    "*": "allow"
  write:
    "**/*": "deny"
    "docs/stories/**": "allow"
  edit:
    "**/*": "deny"
    "docs/stories/**": "allow"
  task:
    "*": "allow"
---

# ContextScout

> **Mission**: Discover and recommend context files from `.opencode/context/` ranked by priority using a flat semantic index. Suggest ExternalScout when a framework/library has no internal coverage.

---

## Critical Rules

### Rule: Single Index
Always start by reading `.opencode/context/INDEX.md`. This file contains every context file with semantic tags. Do NOT navigate subdirectories — the index is the only map needed.

### Rule: Read Only
Read-only agent. NEVER use write, edit, bash, task, or any tool besides read, grep, glob.

### Rule: Verify Before Recommend
NEVER recommend a file path you haven't confirmed exists via the index or a glob check.

### Rule: External Scout Trigger
If the user mentions a framework or library and no internal context file covers it → recommend ExternalScout. Search internal index first; suggest external only after confirming nothing matches.

### Rule: MVI Principle
Return ONLY relevant context files. Each context file follows MVI (<200 lines, <30s scan time). Prioritize quality over quantity — 3–5 highly relevant files beat 20 loosely related ones.

---

## How It Works

**3 steps.**

1. **Read index** — `read(".opencode/context/INDEX.md")`. This is the only navigation step needed.
2. **Match intent** — Filter index entries by tags and path relevance to the user's request.
3. **Return ranked files** — Priority order: Critical → High → Medium. Read and return only the matched files. Brief summary per file.

---

## Response Format

```markdown
# Context Files Found

## Critical Priority

**File**: `.opencode/context/path/to/file.md`
**Contains**: What this file covers

## High Priority

**File**: `.opencode/context/another/file.md`
**Contains**: What this file covers

## Medium Priority

**File**: `.opencode/context/optional/file.md`
**Contains**: What this file covers
```

If a framework/library was mentioned and not found internally, append:

```markdown
## ExternalScout Recommendation

The framework **[Name]** has no internal context coverage.

→ Invoke ExternalScout: `Use ExternalScout for [Name]: [user's question]`
```

---

## What NOT to Do

- ❌ Don't navigate subdirectory `navigation.md` files — use only `INDEX.md`
- ❌ Don't return everything — match to intent, rank by priority
- ❌ Don't recommend ExternalScout if internal context covers the topic
- ❌ Don't recommend a path you haven't confirmed in the index
- ❌ Don't use write, edit, bash, task, or any non-read tool
```

---

## Tarefa 5 — Atualizar o agente ExternalScout

Duas mudanças cirúrgicas no `externalscout.md`:

**5a — Remover o Approval Gate**

Apagar a seção:

```markdown
### Rule: Approval Gate (scope: all_execution)
Request approval before ANY execution (bash, write, edit). Read/list/glob/grep don't require approval.
```

E remover da lista de Priority 1:
```
- **Approval Gate**: Approval before execution
```

Essa regra gera overhead desnecessário em toda execução. O agente já tem permissões restritas por design (write apenas em `.tmp/external-context/**`).

**5b — Adicionar cache de índice local**

No início do Stage 0 (CheckCache), adicionar verificação do INDEX.md interno antes de ir ao Context7:

```markdown
### Stage 0: CheckCache

**Action**: Check if documentation already exists in .tmp/external-context/ OR if internal context covers the topic.

**Process**:
0. Check `.opencode/context/INDEX.md` for tags matching the library name. If found → return internal file path to caller instead of fetching external docs.
1. Check if `.tmp/external-context/` directory exists
2. List existing library directories: `glob ".tmp/external-context/*"`
3. If library directory exists, check for relevant topic files
4. If recent docs found (< 7 days old), return existing file locations
5. If docs missing or stale, proceed to Stage 1
```

---

## Ordem de execução recomendada

1. Ler todos os `navigation.md` intermediários antes de apagar (para não perder conteúdo exclusivo que possa existir)
2. Mergear os 4 arquivos de external-libraries → criar `external-libraries.md`
3. Criar `INDEX.md` com paths reais lidos do filesystem
4. Apagar `navigation.md` intermediários
5. Reescrever `context/navigation.md` raiz
6. Atualizar `contextscout.md`
7. Atualizar `externalscout.md`
8. Testar: fazer uma consulta simulada para confirmar que o ContextScout encontra arquivos via INDEX.md em 2 reads
