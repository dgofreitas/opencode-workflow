#!/bin/bash

# New OpenCode Workflow Updater
# Usage: bash update.sh [--global|--local]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$SCRIPT_DIR"

UPDATE_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            UPDATE_TYPE="global"
            shift
            ;;
        --local|-l)
            UPDATE_TYPE="local"
            shift
            ;;
        --help)
            echo "Usage: bash update.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --global, -g    Update global installation"
            echo "  --local, -l    Update local installation"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Interactive mode
if [[ -z "$UPDATE_TYPE" ]]; then
    echo -e "${BLUE}What do you want to update?${NC}"
    echo ""
    echo "  1) Global installation (~/.config/opencode/)"
    echo "  2) Local installation (./.opencode/)"
    echo ""
    read -p "Enter choice [1-2]: " choice
    
    case $choice in
        1) UPDATE_TYPE="global" ;;
        2) UPDATE_TYPE="local" ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            exit 1
            ;;
    esac
fi

# Update global
update_global() {
    local TARGET_DIR="$HOME/.config/opencode"
    
    if [[ ! -d "$TARGET_DIR/agent" ]]; then
        echo -e "${RED}No global installation found at $TARGET_DIR${NC}"
        echo "Run 'bash install.sh --global' first."
        exit 1
    fi
    
    echo -e "${BLUE}Updating global installation...${NC}"
    
    # Backup config
    if [[ -f "$TARGET_DIR/config/agent-metadata.json" ]]; then
        cp "$TARGET_DIR/config/agent-metadata.json" /tmp/agent-metadata.json.bak
    fi
    
    # Update files
    echo "Copying new files..."
    cp -r "$WORKFLOW_DIR/agent" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/command" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/config" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/context/core" "$TARGET_DIR/context/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/skills" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/tool" "$TARGET_DIR/"
    cp "$WORKFLOW_DIR/package.json" "$TARGET_DIR/"
    
    # Reinstall dependencies
    echo "Updating dependencies..."
    cd "$TARGET_DIR"
    bun install
    
    echo -e "${GREEN}✓ Global installation updated${NC}"
}

# Update local
update_local() {
    local TARGET_DIR="$(pwd)/.opencode"
    
    if [[ ! -d "$TARGET_DIR/agent" ]]; then
        echo -e "${RED}No local installation found at $TARGET_DIR${NC}"
        echo "Run 'bash install.sh --local' first."
        exit 1
    fi
    
    echo -e "${BLUE}Updating local installation...${NC}"
    
    # Backup project intelligence
    local backup_dir="/tmp/opencode-backup-$(date +%s)"
    if [[ -d "$TARGET_DIR/context/project-intelligence" ]]; then
        mkdir -p "$backup_dir"
        cp -r "$TARGET_DIR/context/project-intelligence" "$backup_dir/"
        cp -r "$TARGET_DIR/context/project" "$backup_dir/" 2>/dev/null || true
    fi
    
    # Update files
    echo "Copying new files..."
    cp -r "$WORKFLOW_DIR/agent" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/command" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/config" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/context/core" "$TARGET_DIR/context/" 2>/dev/null || true
    cp -r "$WORKFLOW_DIR/skills" "$TARGET_DIR/"
    cp -r "$WORKFLOW_DIR/tool" "$TARGET_DIR/"
    cp "$WORKFLOW_DIR/package.json" "$TARGET_DIR/"
    
    # Restore project intelligence
    if [[ -d "$backup_dir/project-intelligence" ]]; then
        cp -r "$backup_dir/project-intelligence" "$TARGET_DIR/context/"
        cp -r "$backup_dir/project" "$TARGET_DIR/context/" 2>/dev/null || true
        rm -rf "$backup_dir"
    fi
    
    # Reinstall dependencies
    echo "Updating dependencies..."
    cd "$TARGET_DIR"
    bun install
    
    echo -e "${GREEN}✓ Local installation updated${NC}"
    echo -e "${GREEN}✓ Project intelligence preserved${NC}"
}

# Execute
echo ""
case $UPDATE_TYPE in
    global)
        update_global
        ;;
    local)
        update_local
        ;;
esac

echo ""
echo -e "${GREEN}Update complete.${NC}"
