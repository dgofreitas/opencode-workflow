# New OpenCode Workflow

A comprehensive AI agent workflow system for [OpenCode](https://opencode.ai) that combines the OpenCode plugin architecture with a full SDLC multi-agent pipeline. Optimized for **Node.js/TypeScript** development.

## Overview

This workflow provides **26 specialized agents** covering the entire software development lifecycle for Node.js projects.

### SDLC Pipeline

```
/story → /plan → /implement → /review → /qa → /mr
  PM      Architect  TechLead    CodeReviewer  QAAnalyst  MergeRequestCreator
```

### Agent Categories

| Category | Agents | Description |
|----------|--------|-------------|
| **Core** (1) | Master | Primary orchestration agent |
| **SDLC** (5) | ProductManager, Architect, TechLead, QAAnalyst, MergeRequestCreator | Full lifecycle pipeline |
| **Code** (5) | BackendDeveloper, TestEngineer, CodeReviewer, BugFixerNodejs, BuildAgent | Implementation, testing, review |
| **Analysis** (2) | CodeAnalyzer, ImplReviewerNodejs | Pre-planning and post-implementation review |
| **Development** (7) | FrontendDeveloper, FrontendDeveloperReact/Vue/Angular, ShellDeveloper, UXDesigner, DevOpsSpecialist | Frontend, design and infra |
| **Core Subagents** (4) | ContextScout, ExternalScout, TaskManager, Documentation | Context discovery, docs, task management |
| **System** (1) | ContextOrganizer | Knowledge management |

### Node.js Focus

The system is optimized for projects using:
- **TypeScript / JavaScript**
- **React, Vue, Angular**
- **Node.js (Backend)**

## Directory Structure

```
new-opencode-workflow/
  agent/
    core/                    # Master (primary agent)
    subagents/
      analysis/              # CodeAnalyzer, ImplReviewer variants
      code/                  # CoderAgent, BackendDeveloper, TestEngineer,
                             # CodeReviewer, BugFixer, BuildAgent, PytestTestEngineer
      core/                  # ContextScout, ExternalScout, TaskManager, DocWriter
      development/           # FrontendDeveloper variants, ShellDeveloper, UXDesigner
      sdlc/                  # ProductManager, Architect, TechLead, QAAnalyst, MergeRequestCreator
      system-builder/        # ContextOrganizer
  command/
    sdlc/                    # /story, /plan, /implement, /review, /qa, /mr, /bugfix, /analyze
    commit.md, test.md, ...  # Generic commands
  config/
    agent-metadata.json      # Registry of all 26 agents
  context/
    core/                    # Standards, workflows, context system
    development/             # Language-specific development guides
    project-intelligence/    # Living notes, decisions log
    project/                 # Project context
  skills/
    task-management/         # Task decomposition and tracking CLI
    context7/                # External library documentation fetcher
  tool/
    env/                     # Environment variable loader utility
```

## Commands

### SDLC Commands

| Command | Description | Agent |
|---------|-------------|-------|
| `/story` | Create structured user story from request | ProductManager |
| `/plan` | Generate architecture plan and execution strategy | Architect |
| `/implement` | Execute full story implementation | TechLead |
| `/review` | Run code review on changes | CodeReviewer variants |
| `/qa` | Validate against acceptance criteria | QAAnalyst |
| `/mr` | Create merge request with full context | MergeRequestCreator |
| `/bugfix` | Diagnose and fix a bug | BugFixer variants |
| `/analyze` | Analyze codebase architecture and patterns | CodeAnalyzer variants |

### Generic Commands

| Command | Description |
|---------|-------------|
| `/commit` | Create well-formatted conventional commits |
| `/test` | Run the complete testing pipeline |
| `/context` | Manage context system (harvest, extract, organize) |
| `/clean` | Clean codebase with linters and formatters |

## Setup

```bash
bun install
```

## Documentation

| Document | Description |
|----------|-------------|
| **[USAGE_GUIDE.md](USAGE_GUIDE.md)** | **Practical guide: Master agent, natural language, commands** |
| **[INSTALLATION.md](INSTALLATION.md)** | How to install globally, locally, and hybrid setup |
| **[HOW_IT_WORKS.md](HOW_IT_WORKS.md)** | Complete explanation of architecture, agent delegation, and workflow |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Visual quick reference for commands and language routing |

## Quick Start

```bash
# Clone or download this workflow
cd /path/to/new-opencode-workflow

# Run the installer (interactive mode)
bash install.sh

# Or specify installation type:
# bash install.sh --global   # Install to ~/.config/opencode/
# bash install.sh --local    # Install to ./.opencode/
# bash install.sh --hybrid   # Global core + local project

# Run OpenCode
opencode --agent Master
> "Create a finance app with dashboard and charts"
```

See **[INSTALLATION.md](INSTALLATION.md)** for detailed installation options.

## Scripts

| Script | Description |
|--------|-------------|
| `install.sh` | Install workflow (global, local, or hybrid) |
| `update.sh` | Update existing installation |
| `uninstall.sh` | Remove installation |

## Origin

This workflow was created by combining:
- **Agent definitions** from `windsurf-workflow/` (31 SDLC-pipeline agents, originally in Portuguese)
- **Infrastructure** from `opencode-workflow/` (OpenCode plugin format, context system, skills, tooling)

All agents were adapted to the OpenCode format (YAML frontmatter, XML-like tags, granular permissions) and translated to English.
