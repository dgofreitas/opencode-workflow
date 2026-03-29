<!-- Context: workflows/delegation-specialists | Priority: high | Version: 2.0 | Updated: 2026-03-29 -->
# When to Delegate to Specialists

**Purpose**: Guidance on when to delegate to specific specialist agents

---

## FrontendDeveloper / UXDesigner - UI/UX Design

**✅ DELEGATE when:**
- Creating new UI/UX designs (landing pages, dashboards) → **UXDesigner**
- Building design systems (components, themes, style guides) → **UXDesigner**
- Complex layouts requiring responsive design → **FrontendDeveloper** or framework variant
- Visual polish (animations, transitions, micro-interactions) → **UXDesigner**
- Brand-focused pages (marketing, product showcases) → **UXDesigner**
- Accessibility-critical UI → **FrontendDeveloper** or **UXDesigner**

**Framework routing:**
- React/Next.js → `FrontendDeveloperReact`
- Vue/Nuxt → `FrontendDeveloperVue`
- Angular → `FrontendDeveloperAngular`
- Generic/multi-framework → `FrontendDeveloper`
- Design/wireframe/UX spec → `UXDesigner`

**Delegation pattern:**
```javascript
task(
  subagent_type="FrontendDeveloperReact",
  description="Implement {feature} UI",
  prompt="Load context via ContextScout.

  Implement {feature} following project patterns.
  Requirements: responsive, accessible, tested.
  Request approval before writing files."
)
```

**Why?** Specialized agents know framework-specific patterns, testing tools, and accessibility requirements.

---

## TestEngineer - Test Authoring

**✅ DELEGATE when:**
- Writing comprehensive test suites
- TDD workflows (tests before implementation)
- Complex test scenarios (edge cases, error handling)
- Integration tests across multiple components

**Language routing:**
- Node.js/TypeScript → `TestEngineer`
- Python → `TestEngineerPython`
- C → `TestEngineerC`
- Python (advanced pytest) → `PytestTestEngineer`

**Delegation pattern:**
```javascript
task(
  subagent_type="TestEngineer",
  description="Write tests for {feature}",
  prompt="Load context via ContextScout.

  Write comprehensive tests for {feature}
  Files to test: {file list}
  Follow test coverage standards from context."
)
```

---

## CodeReviewer - Quality Assurance

**✅ DELEGATE when:**
- Reviewing complex implementations
- Security-critical code review
- Pre-merge quality checks
- Architecture validation

**Language routing:**
- Node.js/TypeScript → `CodeReviewer`
- Python → `CodeReviewerPython`
- C → `CodeReviewerC`

**Delegation pattern:**
```javascript
task(
  subagent_type="CodeReviewer",
  description="Review {feature}",
  prompt="Load context via ContextScout.

  Review {feature} against standards
  Files: {file list}
  Focus: security, performance, maintainability"
)
```

---

## CoderAgent - Focused Implementation

**✅ DELEGATE when:**
- Implementing atomic subtasks from TaskManager
- Isolated feature work (single component/module)
- Following specific implementation specs

**Language routing:**
- Node.js/TypeScript → `CoderAgent`
- Python → `CoderAgentPython`
- C → `CoderAgentC`

**Delegation pattern:**
```javascript
task(
  subagent_type="CoderAgent",
  description="Implement {subtask}",
  prompt="Load context via ContextScout.

  Implement subtask: {description}
  Follow implementation spec exactly.
  Mark subtask complete when done."
)
```

---

## BackendDeveloper - Server-Side Development

**✅ DELEGATE when:**
- API endpoint implementation
- Database integration
- Authentication/authorization
- Server-side business logic

**Language routing:**
- Node.js/TypeScript → `BackendDeveloper`
- Python (Django/FastAPI/Flask) → `BackendDeveloperPython`
- C (systems/POSIX) → `BackendDeveloperC`

---

## BugFixer - Debugging & Root Cause Analysis

**✅ DELEGATE when:**
- Complex bug investigation
- Root cause analysis
- Regression debugging

**Language routing:**
- Node.js/TypeScript → `BugFixerNodejs`
- Python → `BugFixerPython`
- C (memory/systems) → `BugFixerC`

---

## Decision Matrix

| Scenario | Agent | Why |
|----------|-------|-----|
| New landing page | UXDesigner → FrontendDeveloperReact | UX spec then implementation |
| React component | FrontendDeveloperReact | Framework-specific patterns |
| Test suite for auth | TestEngineer | Comprehensive coverage |
| Security review | CodeReviewer | Security focus |
| Single API endpoint | CoderAgent | Focused implementation |
| Complex multi-file feature | TaskManager → CoderAgent | Breakdown then implement |
| Django API | BackendDeveloperPython | Python backend patterns |
| Memory leak in C | BugFixerC | C-specific debugging |

---

## Key Principle

**TestEngineer and CodeReviewer should ALWAYS receive context via ContextScout.** This ensures they review against the same standards used during implementation.

---

## Related

- `task-delegation-basics.md` - Core delegation workflow
- `task-delegation-caching.md` - Context caching
