#!/usr/bin/env bash
# agent-models.sh — Gerenciador interativo de modelos por agente
# opencode-workflow

set -euo pipefail

trap cleanup EXIT

# ─── Constantes ────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly AGENT_DIR="${ROOT_DIR}/agent"
readonly CONFIG_FILE="${ROOT_DIR}/opencode.json"

readonly -a MODELS=(
    "opencode/minimax-m2.5-free"
    "zai-coding-plan/glm-4.6"
    "zai-coding-plan/glm-4.7"
    "zai-coding-plan/glm-5"
    "zai-coding-plan/glm-5.1"
)

readonly -a MODEL_LABELS=(
    "Gratuito       — mecânico / retrieval"
    "Econômico      — tarefas estruturadas"
    "Intermediário  — código de produção"
    "Premium        — máxima precisão"
    "Premium+       — ultra-precisão"
)

# Arrays de estado global
AGENT_NAMES=()
AGENT_FILES=()
AGENT_MODELS_INFO=()
SELECTED_MODEL=""
SELECTED_AGENT_IDX=0
TEMP_FILES=()

# ─── Limpeza ───────────────────────────────────────────────────────────────────
cleanup() {
    local f
    for f in "${TEMP_FILES[@]+"${TEMP_FILES[@]}"}"; do
        if [[ -f "${f}" ]]; then
            rm -f "${f}"
        fi
    done
}

# ─── Logging ───────────────────────────────────────────────────────────────────
logInfo()  { printf "\n  ℹ️   %s\n"  "$*"; }
logWarn()  { printf "\n  ⚠️   %s\n"  "$*" >&2; }
logError() { printf "\n  ❌  %s\n"   "$*" >&2; }
logOk()    { printf "\n  ✅  %s\n"   "$*"; }

# ─── Display ───────────────────────────────────────────────────────────────────
printHeader() {
    local title="$1"
    local sep="═══════════════════════════════════════════════════════"
    printf "\n╔%s╗\n" "${sep}"
    printf "║  %-53s  ║\n" "${title}"
    printf "╚%s╝\n\n" "${sep}"
}

pressEnter() {
    printf "\n  Pressione ENTER para continuar..."
    read -r
}

# ─── Frontmatter ──────────────────────────────────────────────────────────────
readFrontmatterField() {
    local filepath="$1"
    local field="$2"
    awk -v field="${field}" '
        BEGIN { n=0 }
        /^---$/ { n++; if (n==2) exit }
        n==1 && match($0, "^" field ":") {
            sub("^" field ":[ \t]*", "")
            print; exit
        }
    ' "${filepath}"
}

setFrontmatterModel() {
    local filepath="$1"
    local model="$2"
    local tmpFile
    tmpFile="$(mktemp)"
    TEMP_FILES+=("${tmpFile}")

    if grep -q "^model:" "${filepath}"; then
        sed "s|^model:.*|model: ${model}|" "${filepath}" > "${tmpFile}"
    else
        sed "s|^\(temperature:.*\)$|\1\nmodel: ${model}|" "${filepath}" > "${tmpFile}"
    fi

    mv "${tmpFile}" "${filepath}"
}

resetFrontmatterModel() {
    local filepath="$1"
    local tmpFile
    tmpFile="$(mktemp)"
    TEMP_FILES+=("${tmpFile}")
    sed "/^model:/d" "${filepath}" > "${tmpFile}"
    mv "${tmpFile}" "${filepath}"
}

# ─── opencode.json ─────────────────────────────────────────────────────────────
getGlobalModel() {
    python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    c = json.load(f)
print(c.get('model', 'unknown'))
" "${CONFIG_FILE}"
}

setGlobalModel() {
    local model="$1"
    python3 -c "
import json, sys
path, model = sys.argv[1], sys.argv[2]
with open(path) as f:
    c = json.load(f)
c['model'] = model
with open(path, 'w') as f:
    json.dump(c, f, indent=2)
    f.write('\n')
" "${CONFIG_FILE}" "${model}"
}

# ─── Carregamento de agentes ───────────────────────────────────────────────────
getAgentFiles() {
    find "${AGENT_DIR}" -name "*.md" -not -path "*/shared/*" | sort
}

loadAgents() {
    AGENT_NAMES=()
    AGENT_FILES=()
    AGENT_MODELS_INFO=()

    local globalModel
    globalModel="$(getGlobalModel)"

    while IFS= read -r filepath; do
        local name model
        name="$(readFrontmatterField "${filepath}" "name")"
        if [[ -z "${name}" ]]; then continue; fi
        model="$(readFrontmatterField "${filepath}" "model")"

        AGENT_NAMES+=("${name}")
        AGENT_FILES+=("${filepath}")
        if [[ -n "${model}" ]]; then
            AGENT_MODELS_INFO+=("${model}|override")
        else
            AGENT_MODELS_INFO+=("${globalModel}|default")
        fi
    done < <(getAgentFiles)
}

# ─── Ação: Listar ──────────────────────────────────────────────────────────────
listAllAgents() {
    logInfo "Carregando agentes..."
    loadAgents

    printHeader "📋 Modelos por Agente"
    printf "  %-32s %s\n" "Agente" "Modelo"
    printf "  %s\n" "────────────────────────────────────────────────────────────────────────────"

    local i
    for i in "${!AGENT_NAMES[@]}"; do
        local model
        model="${AGENT_MODELS_INFO[$i]%|*}"
        printf "  %-32s %s\n" "${AGENT_NAMES[$i]}" "${model}"
    done
}

# ─── Menu: selecionar modelo ───────────────────────────────────────────────────
menuSelectModel() {
    local prompt="${1:-Selecione o modelo}"

    printHeader "🤖 Modelos Disponíveis"

    local i
    for i in "${!MODELS[@]}"; do
        printf "  %d. %s\n     %s\n\n" \
            "$((i+1))" "${MODELS[$i]}" "${MODEL_LABELS[$i]}"
    done
    printf "  0. 🚪 Cancelar\n\n"

    local choice
    while true; do
        printf "  %s [0-%d]: " "${prompt}" "${#MODELS[@]}"
        read -r choice

        if [[ "${choice}" == "0" ]]; then
            return 1
        fi

        if [[ "${choice}" =~ ^[0-9]+$ ]] && \
           [[ "${choice}" -ge 1 ]] && \
           [[ "${choice}" -le "${#MODELS[@]}" ]]; then
            SELECTED_MODEL="${MODELS[$((choice-1))]}"
            return 0
        fi

        logError "Opção inválida. Digite entre 0 e ${#MODELS[@]}."
    done
}

# ─── Menu: selecionar agente ───────────────────────────────────────────────────
menuSelectAgent() {
    loadAgents
    printHeader "🤖 Selecionar Agente"

    local i
    for i in "${!AGENT_NAMES[@]}"; do
        local modelInfo model
        modelInfo="${AGENT_MODELS_INFO[$i]}"
        model="${modelInfo%|*}"
        printf "  %2d. %-30s  %s\n" "$((i+1))" "${AGENT_NAMES[$i]}" "${model}"
    done
    printf "\n   0. 🚪 Voltar\n\n"

    local choice total="${#AGENT_NAMES[@]}"
    while true; do
        printf "  Selecione [0-%d]: " "${total}"
        read -r choice

        if [[ "${choice}" == "0" ]]; then
            return 1
        fi

        if [[ "${choice}" =~ ^[0-9]+$ ]] && \
           [[ "${choice}" -ge 1 ]] && \
           [[ "${choice}" -le "${total}" ]]; then
            SELECTED_AGENT_IDX=$((choice-1))
            return 0
        fi

        logError "Opção inválida. Digite entre 0 e ${total}."
    done
}

# ─── Ação: alterar modelo de um agente ────────────────────────────────────────
actionSetAgentModel() {
    if ! menuSelectAgent; then return 0; fi

    local agentName agentFile
    agentName="${AGENT_NAMES[$SELECTED_AGENT_IDX]}"
    agentFile="${AGENT_FILES[$SELECTED_AGENT_IDX]}"

    printHeader "🔧 Alterar Modelo: ${agentName}"
    if ! menuSelectModel "Novo modelo"; then return 0; fi

    printf "  ⚠️  Confirmar: %s → %s ? [s/N]: " "${agentName}" "${SELECTED_MODEL}"
    local confirm
    read -r confirm

    if [[ "${confirm}" != "s" ]] && [[ "${confirm}" != "S" ]]; then
        logWarn "Operação cancelada."
        return 0
    fi

    setFrontmatterModel "${agentFile}" "${SELECTED_MODEL}"
    logOk "${agentName} → ${SELECTED_MODEL}"
}

# ─── Ação: remover modelo de um agente ────────────────────────────────────────
actionResetAgentModel() {
    if ! menuSelectAgent; then return 0; fi

    local agentName agentFile globalModel
    agentName="${AGENT_NAMES[$SELECTED_AGENT_IDX]}"
    agentFile="${AGENT_FILES[$SELECTED_AGENT_IDX]}"
    globalModel="$(getGlobalModel)"

    printf "\n  ⚠️  Remove o campo 'model:' de '%s'.\n" "${agentName}"
    printf "  O agente passará a usar o padrão global (%s). [s/N]: " "${globalModel}"
    local confirm
    read -r confirm

    if [[ "${confirm}" != "s" ]] && [[ "${confirm}" != "S" ]]; then
        logWarn "Operação cancelada."
        return 0
    fi

    resetFrontmatterModel "${agentFile}"
    logWarn "${agentName} → model: removido (usando global: ${globalModel})"
}

# ─── Ação: alterar modelo global ──────────────────────────────────────────────
actionSetGlobalModel() {
    local currentModel
    currentModel="$(getGlobalModel)"

    printHeader "🌐 Alterar Modelo Global"
    printf "  Modelo atual: %s\n\n" "${currentModel}"

    if ! menuSelectModel "Novo modelo global"; then return 0; fi

    printf "\n  ⚠️  Alterar padrão global para '%s'?\n" "${SELECTED_MODEL}"
    printf "  (Afeta todos os agentes sem override) [s/N]: "
    local confirm
    read -r confirm

    if [[ "${confirm}" != "s" ]] && [[ "${confirm}" != "S" ]]; then
        logWarn "Operação cancelada."
        return 0
    fi

    setGlobalModel "${SELECTED_MODEL}"
    logOk "Modelo global → ${SELECTED_MODEL} (opencode.json)"
}

# ─── Menu principal ────────────────────────────────────────────────────────────
menuMain() {
    while true; do
        clear
        printHeader "🤖 Agent Model Manager — opencode-workflow"
        printf "  1. 📋  Listar todos os agentes e modelos\n"
        printf "  2. 🔧  Alterar modelo de um agente\n"
        printf "  3. 🔄  Remover modelo de um agente (volta ao default global)\n"
        printf "  4. 🌐  Alterar modelo global (opencode.json)\n"
        printf "\n"
        printf "  0. 🚪  Sair\n\n"
        printf "  Escolha [0-4]: "

        local choice
        read -r choice

        case "${choice}" in
            1) listAllAgents;         pressEnter ;;
            2) actionSetAgentModel;   pressEnter ;;
            3) actionResetAgentModel; pressEnter ;;
            4) actionSetGlobalModel;  pressEnter ;;
            0) printf "\n  👋 Até logo!\n\n"; exit 0 ;;
            *) logError "Opção inválida. Digite entre 0 e 4." ;;
        esac
    done
}

# ─── Validações ────────────────────────────────────────────────────────────────
checkDependencies() {
    if ! command -v python3 > /dev/null 2>&1; then
        logError "python3 não encontrado (necessário para ler opencode.json)."
        exit 1
    fi
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        logError "opencode.json não encontrado: ${CONFIG_FILE}"
        exit 1
    fi
    if [[ ! -d "${AGENT_DIR}" ]]; then
        logError "Diretório de agentes não encontrado: ${AGENT_DIR}"
        exit 1
    fi
}

# ─── Entrada ───────────────────────────────────────────────────────────────────
main() {
    checkDependencies
    menuMain
}

main "$@"
