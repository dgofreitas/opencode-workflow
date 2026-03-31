#!/bin/bash

# ==============================================================================
# New OpenCode Workflow Installer
# ==============================================================================
# Compatible with: Debian, Ubuntu, Linux Mint
# Usage: bash install.sh [--global|--local|--hybrid] [--dest <path>]
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURAÇÃO - Constantes globais (SNAKE_CASE)
# ==============================================================================
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="OpenCode Workflow Installer"

# SCRIPT_DIR pode ser sobrescrito pelo stub de auto-extração
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Diretórios padrão
readonly DEFAULT_GLOBAL_DIR="$HOME/.config/opencode"
readonly DEFAULT_LOCAL_DIR=".opencode"

# Variáveis de estado (modificadas durante execução)
INSTALL_TYPE=""
INSTALL_DEST=""
VERBOSE=false

# ==============================================================================
# FUNÇÕES DE LOG - Timestamp ISO-8601 + nível + mensagem
# ==============================================================================

logInfo() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo -e "${CYAN}[${timestamp}] [INFO]${NC} $*"
}

logWarn() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo -e "${YELLOW}[${timestamp}] [WARN]${NC} $*" >&2
}

logError() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo -e "${RED}[${timestamp}] [ERROR]${NC} $*" >&2
}

logSuccess() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo -e "${GREEN}[${timestamp}] [OK]${NC} $*"
}

logStep() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo -e "${BLUE}[${timestamp}] [STEP]${NC} $*"
}

# ==============================================================================
# FUNÇÕES DE UI - Banner e Menu padronizados
# ==============================================================================

printBanner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        🚀 OpenCode Workflow - Instalador v${SCRIPT_VERSION}                ║"
    echo "║        42 Agents | 12 Commands | Full SDLC Pipeline            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

printMenu() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    📋 TIPO DE INSTALAÇÃO                       ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  1️⃣  Global                                                     ║"
    echo "║      Instalar em ~/.config/opencode/                           ║"
    echo "║      Disponível em todos os projetos                           ║"
    echo "║                                                                ║"
    echo "║  2️⃣  Local                                                      ║"
    echo "║      Instalar em .opencode/ no diretório do projeto            ║"
    echo "║      Específico do projeto, compartilhável via Git             ║"
    echo "║                                                                ║"
    echo "║  3️⃣  Híbrido (Recomendado)                                      ║"
    echo "║      Global: core agents + Local: inteligência do projeto      ║"
    echo "║      Ideal para equipes                                        ║"
    echo "║                                                                ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║  0️⃣  🚪 Sair                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

printHelp() {
    echo "Uso: bash install.sh [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  -g, --global          Instalar globalmente em ~/.config/opencode/"
    echo "  -l, --local [DIR]     Instalar localmente (DIR opcional, padrão: .opencode)"
    echo "  -H, --hybrid          Instalar modo híbrido"
    echo "  -d, --dest <path>     Diretório destino para instalação local"
    echo "  -v, --verbose         Modo verboso"
    echo "  -h, --help            Mostrar esta ajuda"
    echo "  --version             Mostrar versão"
    echo ""
    echo "Se nenhuma opção for fornecida, executa em modo interativo."
}

# ==============================================================================
# FUNÇÕES DE VALIDAÇÃO
# ==============================================================================

checkPrerequisites() {
    logStep "Verificando pré-requisitos..."
    
    local -a missing=()
    
    # Verificar OpenCode CLI
    if ! command -v opencode > /dev/null 2>&1; then
        missing+=("opencode")
        logWarn "OpenCode CLI não encontrado"
        logInfo "  Instale em: https://opencode.ai/docs"
    else
        local version
        version=$(opencode --version 2>/dev/null || echo "instalado")
        logSuccess "OpenCode CLI: ${version}"
    fi
    
    # Verificar Bun
    if ! command -v bun > /dev/null 2>&1; then
        missing+=("bun")
        logWarn "Bun não encontrado"
        logInfo "  Instale com: curl -fsSL https://bun.sh/install | bash"
    else
        logSuccess "Bun: $(bun --version)"
    fi
    
    # Verificar Git (opcional)
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
# FUNÇÕES DE INSTALAÇÃO - Cada função ≤45 linhas
# ==============================================================================

copyWorkflowFiles() {
    local targetDir="$1"
    logStep "Copiando arquivos para: ${targetDir}"
    
    mkdir -p "${targetDir}"
    
    cp -r "${SCRIPT_DIR}/agent" "${targetDir}/"
    cp -r "${SCRIPT_DIR}/command" "${targetDir}/"
    cp -r "${SCRIPT_DIR}/config" "${targetDir}/"
    cp -r "${SCRIPT_DIR}/context" "${targetDir}/"
    cp -r "${SCRIPT_DIR}/skills" "${targetDir}/"
    cp -r "${SCRIPT_DIR}/tool" "${targetDir}/"
    cp "${SCRIPT_DIR}/package.json" "${targetDir}/"
    
    logSuccess "Arquivos copiados"
}

installDependencies() {
    local targetDir="$1"
    logStep "Instalando dependências em: ${targetDir}"
    
    cd "${targetDir}"
    bun install
    cd - > /dev/null
    
    logSuccess "Dependências instaladas"
}

removeExistingInstallation() {
    local targetDir="$1"
    logStep "Removendo instalação existente: ${targetDir}"
    
    rm -rf "${targetDir}/agent" "${targetDir}/command" "${targetDir}/config" \
           "${targetDir}/context" "${targetDir}/skills" "${targetDir}/tool" \
           "${targetDir}/package.json" "${targetDir}/node_modules"
    
    logSuccess "Instalação anterior removida"
}

confirmOverwrite() {
    local targetDir="$1"
    
    if [[ ! -d "${targetDir}/agent" ]]; then
        return 0
    fi
    
    logWarn "Instalação existente encontrada em: ${targetDir}"
    read -p "Sobrescrever? [y/N]: " -r overwrite
    
    if [[ ! "${overwrite}" =~ ^[Yy]$ ]]; then
        logInfo "Instalação cancelada pelo usuário"
        return 1
    fi
    
    return 0
}

askLocalDestination() {
    local defaultDest="${INSTALL_DEST:-$(pwd)/${DEFAULT_LOCAL_DIR}}"
    
    logInfo "Diretório destino padrão: ${defaultDest}"
    read -p "Informe o diretório destino [ENTER para padrão]: " -r userDest
    
    if [[ -n "${userDest}" ]]; then
        # Converter caminho relativo para absoluto
        if [[ "${userDest}" != /* ]]; then
            INSTALL_DEST="$(pwd)/${userDest}"
        else
            INSTALL_DEST="${userDest}"
        fi
    else
        INSTALL_DEST="${defaultDest}"
    fi
    
    logInfo "Diretório destino: ${INSTALL_DEST}"
}

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO - Global, Local, Híbrido
# ==============================================================================

installGlobal() {
    local targetDir="${DEFAULT_GLOBAL_DIR}"
    
    logStep "Instalação GLOBAL em: ${targetDir}"
    
    if ! confirmOverwrite "${targetDir}"; then
        return 1
    fi
    
    if [[ -d "${targetDir}/agent" ]]; then
        removeExistingInstallation "${targetDir}"
    fi
    
    copyWorkflowFiles "${targetDir}"
    installDependencies "${targetDir}"
    
    logSuccess "Instalação global concluída!"
    logInfo "Para usar: opencode --agent OpenAgent"
}

installLocal() {
    # Perguntar diretório destino se não especificado
    if [[ -z "${INSTALL_DEST}" ]]; then
        askLocalDestination
    fi
    
    local targetDir="${INSTALL_DEST}"
    
    # Validar se é um diretório de projeto
    local projectRoot
    projectRoot=$(dirname "${targetDir}")
    
    if [[ ! -f "${projectRoot}/package.json" && ! -d "${projectRoot}/.git" ]]; then
        logWarn "Diretório não parece ser um projeto (sem package.json ou .git)"
        read -p "Continuar mesmo assim? [y/N]: " -r continueAnyway
        if [[ ! "${continueAnyway}" =~ ^[Yy]$ ]]; then
            logInfo "Instalação cancelada"
            return 1
        fi
    fi
    
    logStep "Instalação LOCAL em: ${targetDir}"
    
    if ! confirmOverwrite "${targetDir}"; then
        return 1
    fi
    
    if [[ -d "${targetDir}/agent" ]]; then
        removeExistingInstallation "${targetDir}"
    fi
    
    copyWorkflowFiles "${targetDir}"
    installDependencies "${targetDir}"
    updateGitignore "${projectRoot}"
    
    logSuccess "Instalação local concluída!"
    logInfo "Para compartilhar: git add .opencode/ && git commit -m 'Add OpenCode workflow'"
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

# ==============================================================================
# INSTALAÇÃO HÍBRIDA - Global + Local
# ==============================================================================

installHybrid() {
    local globalDir="${DEFAULT_GLOBAL_DIR}"
    local localDir="${INSTALL_DEST:-$(pwd)/${DEFAULT_LOCAL_DIR}}"
    
    logStep "Instalação HÍBRIDA"
    logInfo "  Global: ${globalDir} (core agents, standards)"
    logInfo "  Local:  ${localDir} (inteligência do projeto)"
    
    # Parte 1: Global
    logStep "[1/2] Instalando componentes globais..."
    
    if [[ -d "${globalDir}/agent" ]]; then
        if ! confirmOverwrite "${globalDir}"; then
            logInfo "Mantendo instalação global existente"
        else
            removeExistingInstallation "${globalDir}"
            copyWorkflowFiles "${globalDir}"
            installDependencies "${globalDir}"
        fi
    else
        copyWorkflowFiles "${globalDir}"
        installDependencies "${globalDir}"
    fi
    
    # Parte 2: Local
    logStep "[2/2] Configurando inteligência local do projeto..."
    
    setupLocalIntelligence "${localDir}"
    updateGitignore "$(dirname "${localDir}")"
    
    logSuccess "Instalação híbrida concluída!"
    logInfo "Próximos passos:"
    logInfo "  1. Edite .opencode/context/project/project-context.md"
    logInfo "  2. Commit .opencode/ para compartilhar com a equipe"
    logInfo "  3. Execute: opencode --agent OpenAgent"
}

setupLocalIntelligence() {
    local localDir="$1"
    
    mkdir -p "${localDir}/context/project-intelligence"
    mkdir -p "${localDir}/context/project"
    
    # Criar template de contexto do projeto
    cat > "${localDir}/context/project/project-context.md" << 'EOF'
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
    
    # Criar template de living notes
    cat > "${localDir}/context/project-intelligence/living-notes.md" << 'EOF'
# Living Notes

> Document discoveries, patterns, and decisions as you work on this project.

## Discovered Patterns
<!-- Add patterns you discover in the codebase -->

## Technical Decisions
<!-- Document important technical decisions -->

## Gotchas
<!-- Document tricky parts and how to handle them -->
EOF
    
    logSuccess "Inteligência local configurada"
}

# ==============================================================================
# VERIFICAÇÃO DE INSTALAÇÃO
# ==============================================================================

verifyInstallation() {
    local targetDir="$1"
    
    logStep "Verificando instalação em: ${targetDir}"
    
    local errors=0
    
    # Verificar agents
    local agentCount
    agentCount=$(find "${targetDir}/agent" -name "*.md" 2>/dev/null | wc -l)
    if [[ ${agentCount} -ge 41 ]]; then
        logSuccess "Agents: ${agentCount}"
    else
        logError "Agents: ${agentCount} (esperado: ≥41)"
        ((errors++))
    fi
    
    # Verificar commands
    local commandCount
    commandCount=$(find "${targetDir}/command" -name "*.md" 2>/dev/null | wc -l)
    if [[ ${commandCount} -ge 12 ]]; then
        logSuccess "Commands: ${commandCount}"
    else
        logError "Commands: ${commandCount} (esperado: ≥12)"
        ((errors++))
    fi
    
    # Verificar config
    if [[ -f "${targetDir}/config/agent-metadata.json" ]]; then
        logSuccess "Config: agent-metadata.json"
    else
        logError "Config: não encontrado"
        ((errors++))
    fi
    
    # Verificar context
    if [[ -d "${targetDir}/context/core" ]]; then
        logSuccess "Context: core presente"
    else
        logError "Context: não encontrado"
        ((errors++))
    fi
    
    # Verificar node_modules
    if [[ -d "${targetDir}/node_modules" ]]; then
        logSuccess "Dependências: instaladas"
    else
        logError "Dependências: não instaladas"
        ((errors++))
    fi
    
    if [[ ${errors} -eq 0 ]]; then
        logSuccess "Instalação verificada com sucesso!"
        return 0
    else
        logError "Instalação com ${errors} erro(s)"
        return 1
    fi
}

# ==============================================================================
# MENU INTERATIVO
# ==============================================================================

showMenu() {
    while true; do
        printMenu
        read -p "Escolha uma opção [0-3]: " -r choice
        
        case "${choice}" in
            0)
                logInfo "Saindo..."
                exit 0
                ;;
            1)
                INSTALL_TYPE="global"
                break
                ;;
            2)
                INSTALL_TYPE="local"
                break
                ;;
            3)
                INSTALL_TYPE="hybrid"
                break
                ;;
            *)
                logError "Opção inválida: ${choice}"
                ;;
        esac
    done
}

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

parseArguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--global)
                INSTALL_TYPE="global"
                shift
                ;;
            -l|--local)
                INSTALL_TYPE="local"
                shift
                # Verificar se próximo argumento é um diretório
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    INSTALL_DEST="$1"
                    shift
                fi
                ;;
            -H|--hybrid)
                INSTALL_TYPE="hybrid"
                shift
                ;;
            -d|--dest)
                if [[ -z "${2:-}" ]]; then
                    logError "Opção --dest requer um caminho"
                    exit 1
                fi
                INSTALL_DEST="$2"
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
            *)
                logError "Opção desconhecida: $1"
                logInfo "Use --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done
}

# ==============================================================================
# MAIN - Ponto de entrada (toda execução aqui)
# ==============================================================================

main() {
    printBanner
    
    if ! checkPrerequisites; then
        exit 1
    fi
    
    # Se nenhum tipo especificado, mostrar menu interativo
    if [[ -z "${INSTALL_TYPE}" ]]; then
        showMenu
    fi
    
    logStep "Tipo de instalação: ${INSTALL_TYPE}"
    
    case "${INSTALL_TYPE}" in
        global)
            installGlobal
            verifyInstallation "${DEFAULT_GLOBAL_DIR}"
            ;;
        local)
            installLocal
            if [[ -n "${INSTALL_DEST}" ]]; then
                verifyInstallation "${INSTALL_DEST}"
            fi
            ;;
        hybrid)
            installHybrid
            logStep "Verificando instalação global..."
            verifyInstallation "${DEFAULT_GLOBAL_DIR}"
            ;;
    esac
    
    echo ""
    logSuccess "═══════════════════════════════════════════════════════════════"
    logSuccess "  Instalação concluída!"
    logSuccess "═══════════════════════════════════════════════════════════════"
    logInfo "Para começar: opencode --agent OpenAgent"
}

# ==============================================================================
# PONTO DE ENTRADA
# ==============================================================================
parseArguments "$@"
main
