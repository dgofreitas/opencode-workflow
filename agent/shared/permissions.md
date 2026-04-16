# Permission Templates for Agents

This file defines permission templates for different agent categories. Each agent should reference the appropriate template.

## Template Categories

| Category | Agents | Description |
|----------|--------|-------------|
| `orchestrator` | OpenAgent, OpenCoder, TechLead, Architect | Full task delegation, no code write |
| `coder` | BackendDeveloper*, FrontendDeveloper*, CoderAgent*, BugFixer* | Full write/edit for code |
| `tester` | TestEngineer*, PytestTestEngineer | Write tests, run commands |
| `reviewer` | CodeReviewer*, ImplReviewer*, QAAnalyst | Read-only review, limited bash |
| `analyzer` | CodeAnalyzer* | Read-only analysis, save reports |
| `scout` | ContextScout, ExternalScout | Read-only discovery |
| `manager` | TaskManager, ProductManager, MergeRequestCreator | Limited write to specific paths |

---

## Template: Orchestrator

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mkdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
  edit:
    "**/*": "deny"
    "docs/stories/**": "allow"
  write:
    "**/*": "deny"
    "docs/stories/**": "allow"
  task:
    contextscout: "allow"
    externalscout: "allow"
    ShellDeveloper: "allow"
    OpenAgent: "allow"
    OpenCoder: "allow"
    TaskManager: "allow"
    ProductManager: "allow"
    Architect: "allow"
    TechLead: "allow"
    BackendDeveloper: "allow"
    BackendDeveloperPython: "allow"
    BackendDeveloperC: "allow"
    FrontendDeveloper: "allow"
    FrontendDeveloperReact: "allow"
    FrontendDeveloperVue: "allow"
    FrontendDeveloperAngular: "allow"
    CoderAgent: "allow"
    CoderAgentPython: "allow"
    CoderAgentC: "allow"
    BugFixerNodejs: "allow"
    BugFixerPython: "allow"
    BugFixerC: "allow"
    TestEngineer: "allow"
    TestEngineerPython: "allow"
    TestEngineerC: "allow"
    PytestTestEngineer: "allow"
    CodeReviewer: "allow"
    CodeReviewerPython: "allow"
    CodeReviewerC: "allow"
    ImplReviewerNodejs: "allow"
    ImplReviewerPython: "allow"
    ImplReviewerC: "allow"
    CodeAnalyzer: "allow"
    CodeAnalyzerPython: "allow"
    CodeAnalyzerC: "allow"
    QAAnalyst: "allow"
    DevopsSpecialist: "allow"
    UXDesigner: "allow"
    MergeRequestCreator: "allow"
    DocWriter: "allow"
    Documentation: "allow"
    BuildAgent: "allow"
    ContextOrganizer: "allow"
```

---

## Template: Coder

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
  write:
    "*": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  edit:
    "*": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  task:
    contextscout: "allow"
    externalscout: "allow"
    ShellDeveloper: "allow"
    TechLead: "allow"
    OpenAgent: "allow"
    OpenCoder: "allow"
    BackendDeveloper: "allow"
    BackendDeveloperPython: "allow"
    BackendDeveloperC: "allow"
    FrontendDeveloper: "allow"
    FrontendDeveloperReact: "allow"
    FrontendDeveloperVue: "allow"
    FrontendDeveloperAngular: "allow"
    CoderAgent: "allow"
    CoderAgentPython: "allow"
    CoderAgentC: "allow"
    BugFixerNodejs: "allow"
    BugFixerPython: "allow"
    BugFixerC: "allow"
    TestEngineer: "allow"
    TestEngineerPython: "allow"
    TestEngineerC: "allow"
    PytestTestEngineer: "allow"
    CodeReviewer: "allow"
    CodeReviewerPython: "allow"
    CodeReviewerC: "allow"
    ImplReviewerNodejs: "allow"
    ImplReviewerPython: "allow"
    ImplReviewerC: "allow"
    QAAnalyst: "allow"
    DevopsSpecialist: "allow"
    UXDesigner: "allow"
    BuildAgent: "allow"
```

---

## Template: Tester

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
  write:
    "*": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  edit:
    "*": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  task:
    contextscout: "allow"
    externalscout: "allow"
    ShellDeveloper: "allow"
    TechLead: "allow"
    OpenAgent: "allow"
    OpenCoder: "allow"
    BackendDeveloper: "allow"
    BackendDeveloperPython: "allow"
    BackendDeveloperC: "allow"
    FrontendDeveloper: "allow"
    FrontendDeveloperReact: "allow"
    FrontendDeveloperVue: "allow"
    FrontendDeveloperAngular: "allow"
    CoderAgent: "allow"
    CoderAgentPython: "allow"
    CoderAgentC: "allow"
    BugFixerNodejs: "allow"
    BugFixerPython: "allow"
    BugFixerC: "allow"
    TestEngineer: "allow"
    TestEngineerPython: "allow"
    TestEngineerC: "allow"
    PytestTestEngineer: "allow"
    CodeReviewer: "allow"
    CodeReviewerPython: "allow"
    CodeReviewerC: "allow"
    ImplReviewerNodejs: "allow"
    ImplReviewerPython: "allow"
    ImplReviewerC: "allow"
    QAAnalyst: "allow"
    DevopsSpecialist: "allow"
    UXDesigner: "allow"
    BuildAgent: "allow"
```

---

## Template: Reviewer

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mkdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
  write:
    "**/*": "deny"
  edit:
    "**/*": "deny"
  task:
    contextscout: "allow"
    externalscout: "allow"
    TechLead: "allow"
    OpenAgent: "allow"
    QAAnalyst: "allow"
    CodeReviewer: "allow"
    CodeReviewerPython: "allow"
    CodeReviewerC: "allow"
    ImplReviewerNodejs: "allow"
    ImplReviewerPython: "allow"
    ImplReviewerC: "allow"
```

---

## Template: Analyzer

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mkdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
  write:
    "**/*": "deny"
    "docs/stories/**": "allow"
  edit:
    "**/*": "deny"
    "docs/stories/**": "allow"
  task:
    contextscout: "allow"
    externalscout: "allow"
    Architect: "allow"
    TechLead: "allow"
    OpenAgent: "allow"
    CodeAnalyzer: "allow"
    CodeAnalyzerPython: "allow"
    CodeAnalyzerC: "allow"
```

---

## Template: Scout

```yaml
permission:
  bash:
    "ls *": "allow"
    "cat *": "allow"
    "find *": "allow"
    "grep *": "allow"
    "git status*": "allow"
    "git log*": "allow"
    "git branch*": "allow"
    "*": "deny"
  write:
    "**/*": "deny"
  edit:
    "**/*": "deny"
  task: {}
```

---

## Template: Manager (TaskManager)

```yaml
permission:
  bash:
    "*": "deny"
    "npx ts-node*task-cli*": "allow"
    "mkdir -p .tmp/**": "allow"
    "mv .tmp/**": "allow"
  write:
    "*": "deny"
    ".tmp/**": "allow"
  edit:
    "*": "deny"
    ".tmp/**": "allow"
  task:
    contextscout: "allow"
    externalscout: "allow"
    "*": "deny"
  skill:
    "*": "deny"
    "task-management": "allow"
```

---

## Template: MergeRequestCreator

```yaml
permission:
  bash:
    "*": "allow"
    "rm *": "deny"
    "rm -rf *": "deny"
    "rmdir *": "deny"
    "mkdir *": "deny"
    "mv *": "deny"
    "cp *": "deny"
    "dd *": "deny"
    "mkfs *": "deny"
    "kill *": "deny"
    "pkill *": "deny"
    "killall *": "deny"
    "sudo *": "deny"
    "su *": "deny"
    "> /dev/*": "deny"
    "git push --force*": "ask"
    "git push -f*": "ask"
    "git push *": "ask"
  edit:
    "**/*.md": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  write:
    "**/*.md": "allow"
    "**/*.env*": "deny"
    "**/*.key": "deny"
    "**/*.secret": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  task:
    contextscout: "allow"
    externalscout: "allow"
    TechLead: "allow"
    OpenAgent: "allow"
    QAAnalyst: "allow"
    CodeReviewer: "allow"
    CodeReviewerPython: "allow"
    CodeReviewerC: "allow"
    ImplReviewerNodejs: "allow"
    ImplReviewerPython: "allow"
    ImplReviewerC: "allow"
```

---

## Usage

In agent files, use the appropriate template:

```yaml
# At the top of agent file, after frontmatter:
# Uses: agent/shared/permissions.md#template-orchestrator
```

**Note**: The opencode system loads each agent file independently. The templates above are reference documentation. Copy the appropriate template into each agent file.
