# Common Rules for Agents

This file defines common rules shared across multiple agents. Agent-specific rules remain in their respective files.

---

## Shared Rules (can be referenced by multiple agents)

### Rule: approval_gate (stage_transition)

Use for orchestrators that have approval gates handled by parent agents.

```xml
<rule id="approval_gate" scope="stage_transition">
  Approval gates between SDLC stages are handled by OpenAgent. Focus on implementation without individual file approvals.
</rule>
```

**Used by**: TechLead, TestEngineer, CoderAgent, BugFixer

---

### Rule: approval_gate (all_execution)

Use for agents that need explicit approval before any execution.

```xml
<rule id="approval_gate" scope="all_execution">
  Request approval before ANY execution (bash, write, edit). Read/list/glob/grep don't require approval.
</rule>
```

**Used by**: CodeAnalyzer, ImplReviewer, TaskManager

---

### Rule: context_first

```xml
<rule id="context_first" scope="all_execution">
  ALWAYS invoke ContextScout before performing any action. Load project context, coding standards, and relevant knowledge base files before executing.
</rule>
```

**Used by**: All agents except ContextScout itself

---

### Rule: mvi_principle

```xml
<rule id="mvi_principle">
  Load ONLY relevant context files needed for the current task. Target: <200 lines per file, scannable in <30s, 3-5 highly relevant files max. If a context bundle path is provided in your prompt, load it instead of calling ContextScout.
</rule>
```

**Used by**: All agents

---

### Rule: stop_on_failure

```xml
<rule id="stop_on_failure" scope="validation">
  STOP on test fail/build errors - NEVER auto-fix without approval. REPORT error -> PROPOSE fix -> REQUEST APPROVAL -> Then fix.
</rule>
```

**Used by**: CoderAgent, BackendDeveloper, FrontendDeveloper

---

### Rule: report_first

```xml
<rule id="report_first" scope="error_handling">
  On fail: REPORT error -> PROPOSE fix -> REQUEST APPROVAL -> Then fix (never auto-fix).
  For package/dependency errors: Use ExternalScout to fetch current docs before proposing fix.
</rule>
```

**Used by**: CoderAgent, BackendDeveloper, FrontendDeveloper, BugFixer

---

### Rule: external_scout_mandatory

```xml
<rule id="external_scout_mandatory" scope="all_execution">
  When the task involves ANY external package or library, ALWAYS call ExternalScout for current docs BEFORE implementing. Training data is outdated - never assume how a library works.
</rule>
```

**Used by**: CoderAgent, BackendDeveloper, FrontendDeveloper, BugFixer

---

## Agent-Specific Rules (DO NOT MOVE)

These rules are specific to individual agents and must remain in their respective files:

### OpenAgent-Specific

| Rule | Purpose | Must Stay In |
|------|---------|--------------|
| `never_code` | OpenAgent NEVER writes code directly | openagent.md |
| `sdlc_gates` | 3 mandatory approval gates in SDLC | openagent.md |
| `never_skip_architect` | Architect must run before TechLead | openagent.md |
| `context_mandatory` | Load context before execution | openagent.md |
| `confirm_cleanup` | Confirm before cleanup | openagent.md |
| `mvi` | Minimal viable information | openagent.md |

### TechLead-Specific

| Rule | Purpose | Must Stay In |
|------|---------|--------------|
| `qa_gate` | Handle QA result, rework cycle | tech-lead.md |
| `review_gate` | Handle CodeReview result, rework cycle | tech-lead.md |
| `domain_inventory` | Track all implementation domains | tech-lead.md |
| `quality_gate` | No merge without QA approval | tech-lead.md |
| `never_do` | 20 items TechLead must never do | tech-lead.md |
| `always_do` | 10 items TechLead must always do | tech-lead.md |

### TestEngineer-Specific

| Rule | Purpose | Must Stay In |
|------|---------|--------------|
| `domain_coverage` | Test ALL domains (Shared + Backend + Frontend) | test-engineer.md |
| `positive_and_negative` | Both test types required | test-engineer.md |
| `arrange_act_assert` | AAA pattern mandatory | test-engineer.md |
| `mandatory_report` | Test report required | test-engineer.md |
| `mock_externals` | Mock all external deps | test-engineer.md |

### Architect-Specific

| Rule | Purpose | Must Stay In |
|------|---------|--------------|
| `no_implementation` | Architect never implements | architect.md |
| `parallel_limit` | Max 2 agents parallel | architect.md |
| `mandatory_format` | Use mandatory response format | architect.md |
| `exact_agent_names` | Use PascalCase agent names | architect.md |
| `technical_analysis_doc` | Create technical analysis doc | architect.md |
| `mermaid_diagrams` | Include Mermaid diagrams | architect.md |

### BugFixer-Specific

| Rule | Purpose | Must Stay In |
|------|---------|--------------|
| `rca_before_fix` | Root Cause Analysis before fix | bug-fixer-*.md |
| `regression_test_mandatory` | Regression test for every fix | bug-fixer-*.md |
| `minimal_diff` | Smallest possible change | bug-fixer-*.md |

---

## Critical Workflow Rules (DO NOT MODIFY)

These rules were added to fix specific problems. Do NOT remove or modify:

### 1. SDLC Pipeline Order

```
PM -> Architect -> TechLead -> Developers -> Testers -> QA -> CodeReview -> MR
```

**Enforced by**: openagent.md `sdlc_gates`, tech-lead.md workflow

### 2. Rework Cycle (QA or CodeReview blocked)

```
TechLead -> Developers -> Testers -> QA -> CodeReview -> MR
```

**Enforced by**: tech-lead.md `qa_gate`, `review_gate`

### 3. Never Skip Architect

```
BEFORE invoking TechLead, VERIFY docs/stories/STORY-XXX-technical-analysis.md exists.
If missing -> invoke Architect FIRST. No exceptions.
```

**Enforced by**: openagent.md `never_skip_architect`

### 4. TechLead Never Implements

```
NEVER write, edit, or create any code, test, config, or documentation file directly.
ALWAYS delegate to specialized agents.
```

**Enforced by**: tech-lead.md `never_do` (20 items)

### 5. TestEngineer Tests ALL Domains

```
Before writing tests, identify ALL implemented domains:
- SHARED files
- BACKEND files
- FRONTEND files
All domains must have >=90% coverage.
```

**Enforced by**: test-engineer.md `domain_coverage`

### 6. Avoid Traversal Blocking

```
Approval gates between SDLC stages are handled by OpenAgent.
Focus on implementation without individual file approvals.
```

**Enforced by**: tech-lead.md, test-engineer.md, coder-agent.md `approval_gate` with scope="stage_transition"

---

## Usage

Reference this file in agent files:

```markdown
<!-- Common rules from agent/shared/rules.md -->
<!-- Agent-specific rules remain below -->
```

**Note**: The opencode system loads each agent file independently. Copy the appropriate rules into each agent file or reference them conceptually.
