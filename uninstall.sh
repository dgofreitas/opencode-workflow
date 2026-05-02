#!/bin/bash

# ==============================================================================
# New OpenCode Workflow — Uninstaller (Local apenas)
# ==============================================================================
# Uso: bash uninstall.sh [--dest <path>] [--help]
#
# Remove uma instalação local em <project>/.opencode/.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_PROJECT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dest)
            [[ -z "${2:-}" ]] && { echo -e "${RED}--dest requer caminho${NC}"; exit 1; }
            TARGET_PROJECT="$2"
            shift 2
            ;;
        --help)
            echo "Uso: bash uninstall.sh [OPÇÃO]"
            echo ""
            echo "Opções:"
            echo "  -d, --dest <path>    Diretório do projeto (padrão: pwd)"
            echo "  --help               Mostrar esta ajuda"
            exit 0
            ;;
        # Compatibilidade: avisa e ignora flags removidas
        -g|--global|-l|--local|-a|--all)
            echo -e "${YELLOW}Flag '$1' foi removida — apenas desinstalação local é suportada${NC}"
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
LOCAL_DIR="${TARGET_PROJECT}/.opencode"

if [[ ! -d "$LOCAL_DIR" ]]; then
    echo -e "${YELLOW}Nenhuma instalação local encontrada em ${LOCAL_DIR}${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Aviso: isso removerá o workflow OpenCode em ${LOCAL_DIR}${NC}"
read -p "Continuar? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo -e "${BLUE}Removendo instalação local...${NC}"
rm -rf "$LOCAL_DIR"
echo -e "${GREEN}✓ Instalação local removida${NC}"

# Limpar .gitignore do projeto
GITIGNORE="${TARGET_PROJECT}/.gitignore"
if [[ -f "$GITIGNORE" ]] && grep -q ".opencode/node_modules" "$GITIGNORE" 2>/dev/null; then
    read -p "Remover entradas do .opencode no .gitignore? [y/N]: " remove_gitignore
    if [[ "$remove_gitignore" =~ ^[Yy]$ ]]; then
        sed -i '/# OpenCode workflow/d' "$GITIGNORE"
        sed -i '/.opencode\/node_modules/d' "$GITIGNORE"
        echo -e "${GREEN}✓ .gitignore atualizado${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Uninstall concluído.${NC}"
