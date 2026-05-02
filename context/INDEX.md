<!-- Context: INDEX | Priority: critical | Version: 1.0 | Updated: 2026-05-02 -->
# Context Index

> **Flat semantic index of every leaf context file.** Format per line:
> `path | tags: ... | summary: one-line description`
>
> This is the **single navigation entry point**. Read this file first; then
> read only the leaf files matching the task. No subdirectory navigation.md
> files exist — the index is the only map.

---

## core / system & overview

- `core/essential-patterns.md` | tags: patterns, core, fundamentals | summary: Cross-cutting patterns every agent should know.
- `core/context-system.md` | tags: context, system, overview | summary: What the context system is and how agents use it.
- `core/system/context-guide.md` | tags: context, guide, usage | summary: How to consume context files during tasks.
- `core/system/context-paths.md` | tags: paths, structure | summary: Canonical paths and where different context lives.

## core / standards

- `core/standards/code-quality.md` | tags: quality, code, review, critical | summary: Universal code quality rules for writing/reviewing code.
- `core/standards/test-coverage.md` | tags: tests, coverage, critical | summary: Testing standards across stacks.
- `core/standards/documentation.md` | tags: docs, writing | summary: Documentation standards.
- `core/standards/security-patterns.md` | tags: security, patterns | summary: Security best practices and review checklist.
- `core/standards/code-analysis.md` | tags: analysis, code, debugging | summary: Code analysis approaches for debugging and review.
- `core/standards/project-intelligence.md` | tags: intelligence, decisions, onboarding | summary: What project intelligence is and why it matters.
- `core/standards/project-intelligence-management.md` | tags: intelligence, management | summary: How to maintain project intelligence files.

## core / task-management

- `core/task-management/standards/task-schema.md` | tags: tasks, schema, json | summary: JSON schema v1.0 for task files.
- `core/task-management/guides/managing-tasks.md` | tags: tasks, lifecycle, workflow | summary: Task workflow and lifecycle guide.
- `core/task-management/guides/splitting-tasks.md` | tags: tasks, decomposition, splitting | summary: How to break features into tasks.
- `core/task-management/lookup/task-commands.md` | tags: tasks, cli, commands, lookup | summary: CLI commands for task management.

## core / workflows

- `core/workflows/code-review.md` | tags: review, code, workflow | summary: Code review process.
- `core/workflows/review.md` | tags: review, patterns | summary: General review patterns.
- `core/workflows/feature-breakdown.md` | tags: features, breakdown, planning | summary: Breaking complex features into 4+ files.
- `core/workflows/component-planning.md` | tags: planning, component | summary: Component-level planning workflow.
- `core/workflows/session-management.md` | tags: session, init, cleanup | summary: Session lifecycle and cleanup.
- `core/workflows/delegation.md` | tags: delegation, agents, patterns | summary: Delegation patterns overview.
- `core/workflows/task-delegation-basics.md` | tags: delegation, basics, task-tool | summary: Core delegation workflow using the task tool.
- `core/workflows/task-delegation-specialists.md` | tags: delegation, specialists, routing | summary: Choosing the right specialist agent.
- `core/workflows/task-delegation-caching.md` | tags: delegation, caching | summary: Context caching for repeated delegated tasks.
- `core/workflows/external-libraries.md` | tags: external, docs, fetch, cache, libraries, context7 | summary: Complete workflow for ExternalScout — fetching, caching, scenarios, FAQ.

## core / context-system / guides

- `core/context-system/guides/compact.md` | tags: compact, mvi, onboarding | summary: Compact onboarding to the context system.
- `core/context-system/guides/creation.md` | tags: creation, new-context | summary: How to create a new context file.
- `core/context-system/guides/organizing-context.md` | tags: organizing, structure | summary: How to organize context across domains.
- `core/context-system/guides/navigation-design-basics.md` | tags: navigation, design, basics | summary: Principles for designing navigation (legacy — now replaced by INDEX).
- `core/context-system/guides/navigation-templates.md` | tags: navigation, templates | summary: Templates for navigation files (legacy).
- `core/context-system/guides/workflows.md` | tags: workflows, context-system | summary: Workflows for operating the context system.

## core / context-system / standards

- `core/context-system/standards/mvi.md` | tags: mvi, standards, limits | summary: Minimum Viable Info standard (<200 lines, <30s scan).
- `core/context-system/standards/structure.md` | tags: structure, standards | summary: File and directory structure standards.
- `core/context-system/standards/frontmatter.md` | tags: frontmatter, metadata | summary: Frontmatter schema for context files.
- `core/context-system/standards/templates.md` | tags: templates, standards | summary: Standard templates for new context files.
- `core/context-system/standards/codebase-references.md` | tags: references, citations | summary: How to cite codebase paths in context files.

## core / context-system / operations

- `core/context-system/operations/error.md` | tags: error, handling | summary: Error handling in context operations.
- `core/context-system/operations/extract.md` | tags: extract, operations | summary: Extracting context from existing content.
- `core/context-system/operations/harvest.md` | tags: harvest, operations | summary: Harvesting reusable patterns.
- `core/context-system/operations/migrate.md` | tags: migrate, operations | summary: Migrating context (e.g., global → local).
- `core/context-system/operations/organize.md` | tags: organize, operations | summary: Organizing context files.
- `core/context-system/operations/update.md` | tags: update, operations | summary: Updating existing context.

## core / context-system / examples

- `core/context-system/examples/navigation-examples.md` | tags: examples, navigation | summary: Working examples of navigation design (legacy).

## development / frontend

- `development/frontend/when-to-delegate.md` | tags: delegation, frontend | summary: When to delegate frontend tasks.
- `development/frontend/design-systems.md` | tags: design, ui, systems | summary: Design systems standards.
- `development/frontend/ui-styling-standards.md` | tags: styling, ui, css, standards | summary: UI styling standards.
- `development/frontend/react/react-patterns.md` | tags: react, patterns, nextjs | summary: React/Next.js patterns and best practices.

## development / backend

- `development/backend/nodejs/project-structure.md` | tags: nodejs, backend, structure, mandatory | summary: Mandatory project structure for new Node.js services.

## development / principles

- `development/principles/clean-code.md` | tags: clean-code, principles | summary: Clean code practices, language-agnostic.
- `development/principles/api-design.md` | tags: api, design, principles | summary: API design principles.

## development / ai / mastra-ai

- `development/ai/mastra-ai/concepts/core.md` | tags: mastra, ai, core | summary: Mastra AI core concepts.
- `development/ai/mastra-ai/concepts/agents-tools.md` | tags: mastra, ai, agents, tools | summary: Mastra agents and tools model.
- `development/ai/mastra-ai/concepts/workflows.md` | tags: mastra, ai, workflows | summary: Mastra workflow concepts.
- `development/ai/mastra-ai/concepts/storage.md` | tags: mastra, ai, storage | summary: Mastra storage layer.
- `development/ai/mastra-ai/concepts/evaluations.md` | tags: mastra, ai, evaluations | summary: Mastra evaluations.
- `development/ai/mastra-ai/guides/modular-building.md` | tags: mastra, ai, modular | summary: Guide to building modular Mastra apps.
- `development/ai/mastra-ai/guides/testing.md` | tags: mastra, ai, tests | summary: Testing guide for Mastra.
- `development/ai/mastra-ai/guides/workflow-step-structure.md` | tags: mastra, ai, workflow, steps | summary: Workflow step structure in Mastra.
- `development/ai/mastra-ai/examples/workflow-example.md` | tags: mastra, ai, example | summary: Concrete workflow example.
- `development/ai/mastra-ai/errors/mastra-errors.md` | tags: mastra, ai, errors | summary: Common Mastra errors and resolutions.
- `development/ai/mastra-ai/lookup/mastra-config.md` | tags: mastra, ai, config, lookup | summary: Mastra configuration reference.

## development / cross-cutting (topic hubs)

- `development/ui-navigation.md` | tags: ui, hub, routes | summary: Entry hub for UI development tasks.
- `development/backend-navigation.md` | tags: backend, hub, routes | summary: Entry hub for backend development tasks.
- `development/fullstack-navigation.md` | tags: fullstack, hub, routes | summary: Entry hub for fullstack tasks.

## project

- `project/project-context.md` | tags: project, context, overview | summary: Project-specific overview and conventions.

## project-intelligence

- `project-intelligence/business-domain.md` | tags: business, domain | summary: Business domain knowledge.
- `project-intelligence/technical-domain.md` | tags: technical, domain | summary: Technical domain knowledge.
- `project-intelligence/decisions-log.md` | tags: decisions, log, adr | summary: Log of architectural and product decisions.
- `project-intelligence/living-notes.md` | tags: notes, living | summary: Living notes — evolving project insights.
- `project-intelligence/business-tech-bridge.md` | tags: business, tech, bridge | summary: How business goals map to technical decisions.

---

## How to use this index

1. Read `INDEX.md` (this file) — 1 read.
2. Filter entries by the tags matching the user's intent.
3. Return up to **5 leaf files** ranked by relevance. If more match, report "N additional files available on demand".
4. Priority order: `critical` tag → `mandatory` tag → everything else.
5. If a framework/library is mentioned and **no entry matches**, recommend ExternalScout.
