#!/bin/bash

# ==============================================================================
# New OpenCode Workflow — Updater (Local apenas)
# ==============================================================================
# Uso: bash update.sh [--dest <path>] [--help]
#
# Atualiza uma instalação local existente em <project>/.opencode/.
# Preserva contexto do projeto (context/project/).
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$SCRIPT_DIR"

TARGET_PROJECT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dest)
            [[ -z "${2:-}" ]] && { echo -e "${RED}--dest requer caminho${NC}"; exit 1; }
            TARGET_PROJECT="$2"
            shift 2
            ;;
        --help)
            echo "Uso: bash update.sh [OPÇÃO]"
            echo ""
            echo "Opções:"
            echo "  -d, --dest <path>    Diretório do projeto a atualizar (padrão: pwd)"
            echo "  --help               Mostrar esta ajuda"
            exit 0
            ;;
        # Compatibilidade: avisa e ignora flags removidas
        -g|--global|-H|--hybrid|-l|--local)
            echo -e "${YELLOW}Flag '$1' foi removida — apenas atualização local é suportada${NC}"
            shift
            ;;
        *)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_PROJECT" ]]; then
    TARGET_PROJECT="$(pwd)"
fi
TARGET_DIR="${TARGET_PROJECT}/.opencode"

if [[ ! -d "$TARGET_DIR/agent" ]]; then
    echo -e "${RED}Nenhuma instalação local encontrada em ${TARGET_DIR}${NC}"
    echo "Execute 'bash install.sh' primeiro."
    exit 1
fi

echo -e "${BLUE}Atualizando instalação local em ${TARGET_DIR}...${NC}"

# Backup do contexto do projeto (sobrevive ao update)
backup_dir="/tmp/opencode-backup-$(date +%s)"
if [[ -d "$TARGET_DIR/context/project" ]]; then
    mkdir -p "$backup_dir"
    cp -r "$TARGET_DIR/context/project" "$backup_dir/"
    echo "Contexto do projeto preservado em: $backup_dir"
fi

# Update files (todos os componentes do workflow)
echo "Copiando novos arquivos..."
for item in agent command config context plugins skills tool package.json opencode.json instructions.md; do
    if [[ -e "$WORKFLOW_DIR/$item" ]]; then
        rm -rf "$TARGET_DIR/$item"
        cp -r "$WORKFLOW_DIR/$item" "$TARGET_DIR/"
    fi
done

# Restaurar contexto do projeto (sobrescreve se o update trouxer template novo)
if [[ -d "$backup_dir/project" ]]; then
    rm -rf "$TARGET_DIR/context/project"
    cp -r "$backup_dir/project" "$TARGET_DIR/context/"
    rm -rf "$backup_dir"
    echo -e "${GREEN}✓ Contexto do projeto restaurado${NC}"
fi

# Reinstalar dependências
echo "Atualizando dependências..."
(cd "$TARGET_DIR" && bun install)

echo ""
echo -e "${GREEN}✓ Instalação local atualizada${NC}"
echo -e "${GREEN}Update concluído.${NC}"
