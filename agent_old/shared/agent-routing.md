# Agent Routing by Language

Route tasks to language-specific agents based on detected project language.

## Routing Table

| Task | Description | Node.js | Python | C |
|------|-------------|---------|--------|---|
| Code Analysis | Analyze codebase | CodeAnalyzer | CodeAnalyzerPython | CodeAnalyzerC |
| Backend Impl. | Implement backend | BackendDeveloper | BackendDeveloperPython | BackendDeveloperC |
| Coding | Execute subtasks | CoderAgent | CoderAgentPython | CoderAgentC |
| Testing | Write/run tests | TestEngineer | TestEngineerPython | TestEngineerC |
| QA | Validate AC | QAAnalyst | QAAnalyst | QAAnalyst |
| Code Review | Quality review | CodeReviewer | CodeReviewerPython | CodeReviewerC |
| Bug Fix | Fix bugs | BugFixerNodejs | BugFixerPython | BugFixerC |
| MR | Create PR | MergeRequestCreator | MergeRequestCreator | MergeRequestCreator |

---

## Frontend Routing (by Framework)

| Task | React | Vue | Angular | Generic |
|------|-------|-----|---------|---------|
| UI Implementation | FrontendDeveloperReact | FrontendDeveloperVue | FrontendDeveloperAngular | FrontendDeveloper |
| UX Design | UXDesigner | UXDesigner | UXDesigner | UXDesigner |

---

## Frontend-Backend Integration

When story involves both backend AND frontend, include integration guidelines:

| Backend | Integration Pattern |
|---------|--------------------|
| **Node.js** fullstack | Shared TypeScript types, Server Components/Actions, tRPC, single server (`next dev`/`nuxt dev`), NextAuth/nuxt-auth |
| **Node.js** SPA mode | Typed API client (axios + shared interfaces), single repo, Vite proxy to Express/Fastify |
| **Python** (always SPA) | Vite dev + proxy to uvicorn/gunicorn, CORS config required, `openapi-typescript` for type generation, JWT manual handling, separate deployment |

---

## Parallelization Rules

- **Backend + Frontend**: CAN run in parallel if no shared contracts
- **Multiple Backend services**: MUST be sequential (DB/Redis conflicts)
- **Multiple Frontend components**: CAN run in parallel if independent
- **API Contract changes**: Backend MUST complete before Frontend

---

## Usage

After detecting language (see `language-detection.md`), route tasks:

```markdown
1. Identify task type (coding, testing, review, etc.)
2. Look up agent in routing table
3. Delegate to language-specific agent
4. For UI work, also detect frontend framework
```
