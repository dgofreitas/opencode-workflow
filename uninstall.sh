#!/bin/bash

# New OpenCode Workflow Uninstaller
# Usage: bash uninstall.sh [--global|--local|--all]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

UNINSTALL_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            UNINSTALL_TYPE="global"
            shift
            ;;
        --local|-l)
            UNINSTALL_TYPE="local"
            shift
            ;;
        --all|-a)
            UNINSTALL_TYPE="all"
            shift
            ;;
        --help)
            echo "Usage: bash uninstall.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --global, -g    Remove global installation (~/.config/opencode/)"
            echo "  --local, -l     Remove local installation (./.opencode/)"
            echo "  --all, -a       Remove both global and local"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Interactive mode
if [[ -z "$UNINSTALL_TYPE" ]]; then
    echo -e "${BLUE}What do you want to uninstall?${NC}"
    echo ""
    echo "  1) Global only (~/.config/opencode/)"
    echo "  2) Local only (./.opencode/)"
    echo "  3) Both global and local"
    echo ""
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1) UNINSTALL_TYPE="global" ;;
        2) UNINSTALL_TYPE="local" ;;
        3) UNINSTALL_TYPE="all" ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            exit 1
            ;;
    esac
fi

# Confirm
echo ""
echo -e "${YELLOW}Warning: This will remove the OpenCode workflow installation.${NC}"
read -p "Continue? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Uninstall global
uninstall_global() {
    local GLOBAL_DIR="$HOME/.config/opencode"
    
    if [[ -d "$GLOBAL_DIR/agent" ]]; then
        echo -e "${BLUE}Removing global installation...${NC}"
        rm -rf "$GLOBAL_DIR/agent" "$GLOBAL_DIR/command" "$GLOBAL_DIR/config" \
               "$GLOBAL_DIR/context" "$GLOBAL_DIR/skills" "$GLOBAL_DIR/tool" \
               "$GLOBAL_DIR/package.json" "$GLOBAL_DIR/node_modules" \
               "$GLOBAL_DIR/bun.lock"
        echo -e "${GREEN}✓ Global installation removed${NC}"
    else
        echo -e "${YELLOW}No global installation found${NC}"
    fi
}

# Uninstall local
uninstall_local() {
    local LOCAL_DIR="$(pwd)/.opencode"
    
    if [[ -d "$LOCAL_DIR" ]]; then
        echo -e "${BLUE}Removing local installation...${NC}"
        rm -rf "$LOCAL_DIR"
        echo -e "${GREEN}✓ Local installation removed${NC}"
        
        # Optionally remove from .gitignore
        if [[ -f ".gitignore" ]]; then
            if grep -q ".opencode/node_modules" .gitignore 2>/dev/null; then
                read -p "Remove .opencode entries from .gitignore? [y/N]: " remove_gitignore
                if [[ "$remove_gitignore" =~ ^[Yy]$ ]]; then
                    sed -i '/# OpenCode workflow/d' .gitignore
                    sed -i '/.opencode\/node_modules/d' .gitignore
                    echo -e "${GREEN}✓ .gitignore updated${NC}"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}No local installation found${NC}"
    fi
}

# Execute
echo ""
case $UNINSTALL_TYPE in
    global)
        uninstall_global
        ;;
    local)
        uninstall_local
        ;;
    all)
        uninstall_global
        uninstall_local
        ;;
esac

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
