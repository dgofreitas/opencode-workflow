#!/bin/bash

# New OpenCode Workflow Installer
# Compatible with: Debian, Ubuntu, Linux Mint
# Usage: bash install.sh [--global|--local|--hybrid]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$SCRIPT_DIR"

# Default installation type
INSTALL_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            INSTALL_TYPE="global"
            shift
            ;;
        --local|-l)
            INSTALL_TYPE="local"
            shift
            ;;
        --hybrid|-h)
            INSTALL_TYPE="hybrid"
            shift
            ;;
        --help)
            echo "Usage: bash install.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --global, -g    Install globally to ~/.config/opencode/"
            echo "  --local, -l     Install locally to .opencode/ in current project"
            echo "  --hybrid, -h    Install hybrid (global core + local project)"
            echo "  --help          Show this help message"
            echo ""
            echo "If no option is provided, runs in interactive mode."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Run 'bash install.sh --help' for usage."
            exit 1
            ;;
    esac
done

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║       New OpenCode Workflow - Installer                 ║"
    echo "║       41 Agents | 12 Commands | Full SDLC Pipeline     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    local missing=()
    
    # Check OpenCode CLI
    if ! command -v opencode &> /dev/null; then
        missing+=("opencode")
        echo -e "  ${YELLOW}⚠ OpenCode CLI not found${NC}"
        echo -e "    Install from: ${BLUE}https://opencode.ai/docs${NC}"
    else
        echo -e "  ${GREEN}✓ OpenCode CLI: $(opencode --version 2>/dev/null || echo 'installed')${NC}"
    fi
    
    # Check Bun
    if ! command -v bun &> /dev/null; then
        missing+=("bun")
        echo -e "  ${YELLOW}⚠ Bun not found${NC}"
        echo -e "    Install with: ${BLUE}curl -fsSL https://bun.sh/install | bash${NC}"
    else
        echo -e "  ${GREEN}✓ Bun: $(bun --version)${NC}"
    fi
    
    # Check Git (optional but recommended)
    if ! command -v git &> /dev/null; then
        echo -e "  ${YELLOW}⚠ Git not found (recommended for team workflows)${NC}"
    else
        echo -e "  ${GREEN}✓ Git: $(git --version | cut -d' ' -f3)${NC}"
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Missing required dependencies: ${missing[*]}${NC}"
        echo "Please install them before continuing."
        exit 1
    fi
    
    echo ""
}

# Interactive mode - ask user for installation type
ask_install_type() {
    echo -e "${BLUE}Choose installation type:${NC}"
    echo ""
    echo "  1) Global     - Install to ~/.config/opencode/"
    echo "                 Use in all your projects"
    echo ""
    echo "  2) Local     - Install to .opencode/ in current directory"
    echo "                 Project-specific, share with team via Git"
    echo ""
    echo "  3) Hybrid    - Global core + Local project intelligence"
    echo "                 Best for teams (recommended)"
    echo ""
    
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1) INSTALL_TYPE="global" ;;
        2) INSTALL_TYPE="local" ;;
        3) INSTALL_TYPE="hybrid" ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
    
    echo ""
}

# Install globally
install_global() {
    local TARGET_DIR="$HOME/.config/opencode"
    
    echo -e "${BLUE}Installing globally to: ${TARGET_DIR}${NC}"
    echo ""
    
    # Create directory if not exists
    mkdir -p "$TARGET_DIR"
    
    # Check if already installed
    if [[ -d "$TARGET_DIR/agent" ]]; then
        echo -e "${YELLOW}Existing installation found at ${TARGET_DIR}${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        echo "Removing existing installation..."
        rm -rf "$TARGET_DIR/agent" "$TARGET_DIR/command" "$TARGET_DIR/config" \
               "$TARGET_DIR/context" "$TARGET_DIR/skills" "$TARGET_DIR/tool" \
               "$TARGET_DIR/package.json" "$TARGET_DIR/node_modules"
    fi
    
    # Copy files
    echo "Copying files..."
    cp -r "$WORKFLOW_DIR/agent" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/command" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/config" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/context" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/skills" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/tool" "$TARGET_DIR/"
    cp "$WORKFLOW_DIR/package.json" "$TARGET_DIR/"
    
    # Install dependencies
    echo "Installing dependencies..."
    cd "$TARGET_DIR"
    bun install
    
    echo ""
    echo -e "${GREEN}✓ Global installation complete!${NC}"
    echo ""
    echo "To use, run:"
    echo -e "  ${BLUE}opencode --agent OpenAgent${NC}"
    echo ""
}

# Install locally
install_local() {
    local TARGET_DIR="$(pwd)/.opencode"
    
    echo -e "${BLUE}Installing locally to: ${TARGET_DIR}${NC}"
    echo ""
    
    # Check if already in a project
    if [[ ! -f "$(pwd)/package.json" && ! -d "$(pwd)/.git" ]]; then
        echo -e "${YELLOW}Warning: Current directory doesn't appear to be a project root.${NC}"
        read -p "Continue anyway? [y/N]: " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
    
    # Check if already installed
    if [[ -d "$TARGET_DIR/agent" ]]; then
        echo -e "${YELLOW}Existing installation found at ${TARGET_DIR}${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        echo "Removing existing installation..."
        rm -rf "$TARGET_DIR/agent" "$TARGET_DIR/command" "$TARGET_DIR/config" \
               "$TARGET_DIR/context" "$TARGET_DIR/skills" "$TARGET_DIR/tool" \
               "$TARGET_DIR/package.json" "$TARGET_DIR/node_modules"
    fi
    
    # Create directory
    mkdir -p "$TARGET_DIR"
    
    # Copy files
    echo "Copying files..."
    cp -r "$WORKFLOW_DIR/agent" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/command" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/config" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/context" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/skills" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/tool" "$TARGET_DIR/"
    cp "$WORKFLOW_DIR/package.json" "$TARGET_DIR/"
    
    # Install dependencies
    echo "Installing dependencies..."
    cd "$TARGET_DIR"
    bun install
    
    # Update .gitignore
    cd "$(dirname "$TARGET_DIR")"
    if [[ -f ".gitignore" ]]; then
        if ! grep -q ".opencode/node_modules" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# OpenCode workflow" >> .gitignore
            echo ".opencode/node_modules/" >> .gitignore
            echo "Added .opencode/node_modules/ to .gitignore"
        fi
    else
        echo ".opencode/node_modules/" > .gitignore
        echo "Created .gitignore"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Local installation complete!${NC}"
    echo ""
    echo "To share with your team:"
    echo -e "  ${BLUE}git add .opencode/${NC}"
    echo -e "  ${BLUE}git commit -m 'Add OpenCode workflow'${NC}"
    echo -e "  ${BLUE}git push${NC}"
    echo ""
    echo "To use, run from project root:"
    echo -e "  ${BLUE}opencode --agent OpenAgent${NC}"
    echo ""
}

# Install hybrid
install_hybrid() {
    local GLOBAL_DIR="$HOME/.config/opencode"
    local LOCAL_DIR="$(pwd)/.opencode"
    
    echo -e "${BLUE}Installing hybrid mode...${NC}"
    echo ""
    echo "  Global: $GLOBAL_DIR (core agents, standards)"
    echo "  Local:  $LOCAL_DIR (project intelligence)"
    echo ""
    
    # Install global part
    echo -e "${BLUE}[1/2] Installing global components...${NC}"
    mkdir -p "$GLOBAL_DIR"
    
    # Check existing global
    if [[ -d "$GLOBAL_DIR/agent" ]]; then
        echo -e "${YELLOW}Existing global installation found${NC}"
        read -p "Overwrite global? [y/N]: " overwrite_global
        if [[ "$overwrite_global" =~ ^[Yy]$ ]]; then
            rm -rf "$GLOBAL_DIR/agent" "$GLOBAL_DIR/command" "$GLOBAL_DIR/config" \
                   "$GLOBAL_DIR/context" "$GLOBAL_DIR/skills" "$GLOBAL_DIR/tool" \
                   "$GLOBAL_DIR/package.json" "$GLOBAL_DIR/node_modules"
        fi
    fi
    
    # Copy global files
    echo "Copying global files..."
    cp -r "$WORKFLOW_DIR/agent" "$GLOBAL_DIR/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/command" "$GLOBAL_DIR/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/config" "$GLOBAL_DIR/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/context/core" "$GLOBAL_DIR/context/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/skills" "$GLOBAL_DIR/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/tool" "$GLOBAL_DIR/" 2>/dev/null || true
    cp "$WORKFLOW_DIR/package.json" "$GLOBAL_DIR/" 2>/dev/null || true
    
    # Install global dependencies
    echo "Installing global dependencies..."
    cd "$GLOBAL_DIR"
    bun install
    
    echo ""
    
    # Install local part
    echo -e "${BLUE}[2/2] Setting up local project intelligence...${NC}"
    
    mkdir -p "$LOCAL_DIR/context/project-intelligence"
    mkdir -p "$LOCAL_DIR/context/project"
    
    # Create project context template
    cat > "$LOCAL_DIR/context/project/project-context.md" << 'EOF'
# Project Context

> Fill in this file with your project's specific patterns and conventions.
> Agents will load this context to generate code that matches your project.

## Tech Stack
<!-- Example: React 18 + TypeScript + Tailwind + Node.js + Express + PostgreSQL -->

## API Patterns
<!-- Example: Zod validation, error handling, response format -->

## Component Patterns
<!-- Example: Functional components, Tailwind styling, React Query -->

## Naming Conventions
<!-- Example: kebab-case files, PascalCase components -->

## Security
<!-- Example: Input validation, authentication method -->
EOF
    
    # Create living notes template
    cat > "$LOCAL_DIR/context/project-intelligence/living-notes.md" << 'EOF'
# Living Notes

> Document discoveries, patterns, and decisions as you work on this project.

## Discovered Patterns
<!-- Add patterns you discover in the codebase -->

## Technical Decisions
<!-- Document important technical decisions -->

## Gotchas
<!-- Document tricky parts and how to handle them -->
EOF
    
    # Update .gitignore
    cd "$(dirname "$LOCAL_DIR")"
    if [[ -f ".gitignore" ]]; then
        if ! grep -q ".opencode/node_modules" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# OpenCode workflow" >> .gitignore
            echo ".opencode/node_modules/" >> .gitignore
        fi
    else
        echo ".opencode/node_modules/" > .gitignore
    fi
    
    echo ""
    echo -e "${GREEN}✓ Hybrid installation complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .opencode/context/project/project-context.md with your project info"
    echo "  2. Commit .opencode/ to share with your team"
    echo "  3. Run: opencode --agent OpenAgent"
    echo ""
}

# Verify installation
verify_installation() {
    local TARGET_DIR="$1"
    
    echo -e "${BLUE}Verifying installation...${NC}"
    
    local errors=0
    
    # Check agents
    local agent_count=$(find "$TARGET_DIR/agent" -name "*.md" 2>/dev/null | wc -l)
    if [[ $agent_count -eq 41 ]]; then
        echo -e "  ${GREEN}✓ Agents: $agent_count${NC}"
    else
        echo -e "  ${RED}✗ Agents: $agent_count (expected 41)${NC}"
        ((errors++))
    fi
    
    # Check commands
    local command_count=$(find "$TARGET_DIR/command" -name "*.md" 2>/dev/null | wc -l)
    if [[ $command_count -eq 12 ]]; then
        echo -e "  ${GREEN}✓ Commands: $command_count${NC}"
    else
        echo -e "  ${RED}✗ Commands: $command_count (expected 12)${NC}"
        ((errors++))
    fi
    
    # Check config
    if [[ -f "$TARGET_DIR/config/agent-metadata.json" ]]; then
        echo -e "  ${GREEN}✓ Config: agent-metadata.json${NC}"
    else
        echo -e "  ${RED}✗ Config: missing${NC}"
        ((errors++))
    fi
    
    # Check context
    if [[ -d "$TARGET_DIR/context/core" ]]; then
        echo -e "  ${GREEN}✓ Context: core files present${NC}"
    else
        echo -e "  ${RED}✗ Context: missing${NC}"
        ((errors++))
    fi
    
    # Check node_modules
    if [[ -d "$TARGET_DIR/node_modules" ]]; then
        echo -e "  ${GREEN}✓ Dependencies: installed${NC}"
    else
        echo -e "  ${RED}✗ Dependencies: not installed${NC}"
        ((errors++))
    fi
    
    echo ""
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}Installation verified successfully!${NC}"
        return 0
    else
        echo -e "${RED}Installation has $errors error(s)${NC}"
        return 1
    fi
}

# Main
main() {
    print_banner
    
    check_prerequisites
    
    # If no install type specified, ask interactively
    if [[ -z "$INSTALL_TYPE" ]]; then
        ask_install_type
    fi
    
    echo -e "${BLUE}Installing: $INSTALL_TYPE${NC}"
    echo ""
    
    case $INSTALL_TYPE in
        global)
            install_global
            verify_installation "$HOME/.config/opencode"
            ;;
        local)
            install_local
            verify_installation "$(pwd)/.opencode"
            ;;
        hybrid)
            install_hybrid
            echo ""
            echo "Verifying global..."
            verify_installation "$HOME/.config/opencode"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Quick start:"
    echo -e "  ${BLUE}opencode --agent OpenAgent${NC}"
    echo ""
    echo "Documentation:"
    echo "  - INSTALLATION.md"
    echo "  - HOW_IT_WORKS.md"
    echo "  - QUICK_REFERENCE.md"
    echo ""
}

main "$@"
