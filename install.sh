#!/bin/bash

# ==============================================================================
# New OpenCode Workflow — Instalador Local
# ==============================================================================
# Compatível com: Debian, Ubuntu, Linux Mint
# Uso: bash install.sh [--dest <path>] [--verbose] [--help]
#
# Modo: LOCAL apenas. Instala em <project>/.opencode/.
# Se --dest não for informado, instala no cwd/.opencode.
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURAÇÃO
# ==============================================================================
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="OpenCode Workflow Installer"

if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

readonly DEFAULT_LOCAL_DIR=".opencode"

readonly WORKFLOW_REQUIRED_ITEMS=(
    "agent"
    "command"
    "config"
    "context"
    "plugins"
    "skills"
    "tool"
    "package.json"
    "opencode.json"
    "instructions.md"
    "bin"
)

COUNT_AGENTS=0
COUNT_COMMANDS=0
COUNT_SKILLS=0
COUNT_PLUGINS=0
COUNT_CONTEXT=0

INSTALL_DEST=""
VERBOSE=false

# ==============================================================================
# LOG
# ==============================================================================

logInfo()    { echo -e "${CYAN}[$(date '+%Y-%m-%dT%H:%M:%S%z')] [INFO]${NC} $*"; }
logWarn()    { echo -e "${YELLOW}[$(date '+%Y-%m-%dT%H:%M:%S%z')] [WARN]${NC} $*" >&2; }
logError()   { echo -e "${RED}[$(date '+%Y-%m-%dT%H:%M:%S%z')] [ERROR]${NC} $*" >&2; }
logSuccess() { echo -e "${GREEN}[$(date '+%Y-%m-%dT%H:%M:%S%z')] [OK]${NC} $*"; }
logStep()    { echo -e "${BLUE}[$(date '+%Y-%m-%dT%H:%M:%S%z')] [STEP]${NC} $*"; }

# ==============================================================================
# UI
# ==============================================================================

calculateMetrics() {
    local baseDir="${SCRIPT_DIR}"
    COUNT_AGENTS=$(find "${baseDir}/agent"   -name "*.md"     2>/dev/null | wc -l)
    COUNT_COMMANDS=$(find "${baseDir}/command" -name "*.md"   2>/dev/null | wc -l)
    COUNT_SKILLS=$(find "${baseDir}/skills"  -name "SKILL.md" 2>/dev/null | wc -l)
    COUNT_PLUGINS=$(find "${baseDir}/plugins" -name "*.ts"    2>/dev/null | wc -l)
    COUNT_CONTEXT=$(find "${baseDir}/context" -name "*.md"    2>/dev/null | wc -l)
    COUNT_BIN=$(ls "${baseDir}/bin"    2>/dev/null | wc -l)
}

printBanner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║        🚀 OpenCode Workflow - Instalador v${SCRIPT_VERSION}                   ║"
    echo "║                                                                           ║"
    echo "║  🤖 Agentes: ${COUNT_AGENTS} | ⌨️  Comandos: ${COUNT_COMMANDS} | 🛠️  Skills: ${COUNT_SKILLS}                ║"   
    echo "║  🔌 Plugins: ${COUNT_PLUGINS} | 📂 Contexto: ${COUNT_CONTEXT} | 🧰 Bin: ${COUNT_BIN}                  ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

printHelp() {
    echo "Uso: bash install.sh [OPÇÃO]"
    echo ""
    echo "Modo único: instalação LOCAL no projeto (.opencode/)."
    echo ""
    echo "Opções:"
    echo "  -d, --dest <path>     Diretório do projeto destino (padrão: pwd)"
    echo "                        Resultado: <path>/.opencode/"
    echo "  -v, --verbose         Modo verboso"
    echo "  -h, --help            Mostrar esta ajuda"
    echo "  --version             Mostrar versão"
    echo ""
    echo "Sem --dest: instala em <cwd>/.opencode/ (interativo confirma o caminho)."
}

# ==============================================================================
# PRÉ-REQUISITOS
# ==============================================================================

checkPrerequisites() {
    logStep "Verificando pré-requisitos..."

    local -a missing=()

    if ! command -v opencode > /dev/null 2>&1; then
        missing+=("opencode")
        logWarn "OpenCode CLI não encontrado"
        logInfo "  Instale em: https://opencode.ai/docs"
    else
        local version
        version=$(opencode --version 2>/dev/null || echo "instalado")
        logSuccess "OpenCode CLI: ${version}"
    fi

    if ! command -v bun > /dev/null 2>&1; then
        missing+=("bun")
        logWarn "Bun não encontrado"
        logInfo "  Instale com: curl -fsSL https://bun.sh/install | bash"
    else
        logSuccess "Bun: $(bun --version)"
    fi

    if ! command -v git > /dev/null 2>&1; then
        logWarn "Git não encontrado (recomendado para workflows em equipe)"
    else
        logSuccess "Git: $(git --version | cut -d' ' -f3)"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        logError "Dependências faltando: ${missing[*]}"
        return 1
    fi
    return 0
}

# ==============================================================================
# INSTALAÇÃO
# ==============================================================================

copyWorkflowFiles() {
    local targetDir="$1"
    logStep "Copiando arquivos para: ${targetDir}"

    mkdir -p "${targetDir}"

    for item in "${WORKFLOW_REQUIRED_ITEMS[@]}"; do
        if [[ -e "${SCRIPT_DIR}/${item}" ]]; then
            cp -r "${SCRIPT_DIR}/${item}" "${targetDir}/"
            logInfo "  Copiado: ${item}"
        else
            logWarn "  Item ignorado (não encontrado na fonte): ${item}"
        fi
    done

    logSuccess "Arquivos copiados com sucesso"
}

installDependencies() {
    local targetDir="$1"
    logStep "Instalando dependências em: ${targetDir}"
    (cd "${targetDir}" && bun install)
    logSuccess "Dependências instaladas"
}

removeExistingInstallation() {
    local targetDir="$1"
    logStep "Removendo instalação existente em: ${targetDir}"

    for item in "${WORKFLOW_REQUIRED_ITEMS[@]}"; do
        rm -rf "${targetDir}/${item}"
    done
    rm -rf "${targetDir}/node_modules"

    logSuccess "Instalação anterior removida"
}

confirmOverwrite() {
    local targetDir="$1"
    [[ ! -d "${targetDir}/agent" ]] && return 0

    logWarn "Instalação existente encontrada em: ${targetDir}"
    read -p "Sobrescrever? [y/N]: " -r overwrite
    [[ "${overwrite}" =~ ^[Yy]$ ]] || { logInfo "Instalação cancelada"; return 1; }
    return 0
}

askLocalDestination() {
    local defaultDest="${INSTALL_DEST:-$(pwd)/${DEFAULT_LOCAL_DIR}}"

    logInfo "Diretório destino padrão: ${defaultDest}"
    read -p "Informe o diretório do projeto [ENTER para usar ${defaultDest}]: " -r userDest

    if [[ -n "${userDest}" ]]; then
        # Expandir ~ (read não expande tilde)
        if [[ "${userDest}" == "~/"* ]]; then
            userDest="${HOME}/${userDest#\~/}"
        elif [[ "${userDest}" == "~" ]]; then
            userDest="${HOME}"
        fi
        # Caminho relativo → absoluto
        if [[ "${userDest}" != /* ]]; then
            userDest="$(pwd)/${userDest}"
        fi
        # Usuário informa o projeto — adicionar subdiretório de instalação
        INSTALL_DEST="${userDest}/${DEFAULT_LOCAL_DIR}"
    else
        INSTALL_DEST="${defaultDest}"
    fi

    logInfo "Diretório destino: ${INSTALL_DEST}"
}

updateGitignore() {
    local projectRoot="$1"
    local gitignoreFile="${projectRoot}/.gitignore"

    logStep "Atualizando .gitignore"

    if [[ -f "${gitignoreFile}" ]]; then
        if grep -q ".opencode/node_modules" "${gitignoreFile}" 2>/dev/null; then
            logInfo ".gitignore já contém entrada para .opencode/node_modules"
            return 0
        fi
        echo "" >> "${gitignoreFile}"
        echo "# OpenCode workflow" >> "${gitignoreFile}"
        echo ".opencode/node_modules/" >> "${gitignoreFile}"
    else
        echo "# OpenCode workflow" > "${gitignoreFile}"
        echo ".opencode/node_modules/" >> "${gitignoreFile}"
    fi

    logSuccess ".gitignore atualizado"
}

installLocal() {
    if [[ -z "${INSTALL_DEST}" ]]; then
        askLocalDestination
    fi

    local targetDir="${INSTALL_DEST}"
    local projectRoot
    projectRoot=$(dirname "${targetDir}")

    if [[ ! -f "${projectRoot}/package.json" && ! -d "${projectRoot}/.git" ]]; then
        logWarn "Diretório não parece ser um projeto (sem package.json ou .git)"
        read -p "Continuar mesmo assim? [y/N]: " -r continueAnyway
        [[ "${continueAnyway}" =~ ^[Yy]$ ]] || { logInfo "Instalação cancelada"; return 1; }
    fi

    logStep "Instalação LOCAL em: ${targetDir}"

    confirmOverwrite "${targetDir}" || return 1

    if [[ -d "${targetDir}/agent" ]]; then
        removeExistingInstallation "${targetDir}"
    fi

    copyWorkflowFiles "${targetDir}"
    installDependencies "${targetDir}"
    updateGitignore "${projectRoot}"

    logSuccess "Instalação local concluída!"
    logInfo "Para compartilhar: git add .opencode/ && git commit -m 'Add OpenCode workflow'"
}

# ==============================================================================
# VERIFICAÇÃO
# ==============================================================================

verifyInstallation() {
    local targetDir="$1"
    logStep "Verificando integridade em: ${targetDir}"

    local errors=0

    for item in "${WORKFLOW_REQUIRED_ITEMS[@]}"; do
        if [[ -e "${targetDir}/${item}" ]]; then
            logSuccess "  Presente: ${item}"
        else
            logError "  Faltando: ${item}"
            ((errors++))
        fi
    done

    local agentCount
    agentCount=$(find "${targetDir}/agent" -name "*.md" 2>/dev/null | wc -l)
    if [[ ${agentCount} -ge 25 ]]; then
        logInfo "  Contagem de Agentes: ${agentCount} (OK)"
    else
        logError "  Contagem de Agentes: ${agentCount} (esperado: ≥25)"
        ((errors++))
    fi

    if [[ -d "${targetDir}/node_modules" ]]; then
        logSuccess "  Dependências Node.js: OK"
    else
        logError "  Dependências Node.js: Não instaladas"
        ((errors++))
    fi

    if [[ ${errors} -eq 0 ]]; then
        logSuccess "Instalação verificada com sucesso!"
        return 0
    fi
    logError "Instalação com ${errors} erro(s)"
    return 1
}

# ==============================================================================
# PARSING
# ==============================================================================

parseArguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dest)
                [[ -z "${2:-}" ]] && { logError "Opção --dest requer um caminho"; exit 1; }
                INSTALL_DEST="$2/${DEFAULT_LOCAL_DIR}"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                printHelp
                exit 0
                ;;
            --version)
                echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
                exit 0
                ;;
            # Compatibilidade: avisa e ignora flags removidas
            -g|--global|-H|--hybrid|-l|--local)
                logWarn "Flag '$1' foi removida — apenas instalação local é suportada"
                shift
                ;;
            *)
                logError "Opção desconhecida: $1"
                logInfo "Use --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    calculateMetrics
    printBanner

    if ! checkPrerequisites; then
        exit 1
    fi

    installLocal

    if [[ -n "${INSTALL_DEST}" ]]; then
        verifyInstallation "${INSTALL_DEST}"
    fi

    echo ""
    logSuccess "═══════════════════════════════════════════════════════════════"
    logSuccess "  Instalação concluída!"
    logSuccess "═══════════════════════════════════════════════════════════════"
    logInfo "Para começar: opencode --agent Master"
}

parseArguments "$@"
main
