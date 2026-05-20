#!/usr/bin/env bash
# opencode-batch.sh — Run multiple stories sequentially with fresh sessions
# Usage:
#   opencode-batch.sh start "stories 8,9,10"   (or "stories 8-10")
#   opencode-batch.sh next                      (called by Master after each story)

set -euo pipefail

BATCH_STATE_FILE=".opencode/.batch-state"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

CMD_NEXT="next"
CMD_START="start"

log() {
    echo "[batch] $(date '+%Y-%m-%dT%H:%M:%S%z') $*"
}

parse_stories() {
    local raw="$1"
    # Accept: "stories 8,9,10", "stories 8-10", "8,9,10", "8-10"
    raw="${raw#stories }"
    raw="${raw#stories}"
    raw="$(echo "$raw" | tr ',' ' ')"
    if [[ "$raw" == *-* ]]; then
        local start="${raw%-*}"
        local end="${raw#*-}"
        seq -s ' ' "$start" "$end"
    else
        echo "$raw"
    fi
}

cmd_start() {
    local input="$1"
    local stories
    stories="$(parse_stories "$input")"

    if [[ -z "$stories" ]]; then
        echo "Usage: opencode-batch.sh start \"stories 8,9,10\" (or \"stories 8-10\")"
        exit 1
    fi

    log "Batch mode — stories: $stories"
    log "Project: $PROJECT_ROOT"

    # Save state
    echo "$stories" > "$PROJECT_ROOT/$BATCH_STATE_FILE"

    log "Starting story $(echo "$stories" | awk '{print $1}')"
    log "Running: opencode --agent Master \"stories $input\""
    opencode --agent Master "stories $input"
}

cmd_next() {
    if [[ ! -f "$PROJECT_ROOT/$BATCH_STATE_FILE" ]]; then
        echo "No batch in progress. Start with: opencode-batch.sh start \"stories N,M,O\""
        exit 1
    fi

    local remaining
    remaining="$(cat "$PROJECT_ROOT/$BATCH_STATE_FILE")"

    # Remove first word (completed story)
    local next="$(echo "$remaining" | awk '{print $1}')"
    remaining="$(echo "$remaining" | cut -d' ' -f2-)"

    if [[ -z "$remaining" ]]; then
        log "All stories complete!"
        rm -f "$PROJECT_ROOT/$BATCH_STATE_FILE"
        exit 0
    fi

    echo "$remaining" > "$PROJECT_ROOT/$BATCH_STATE_FILE"

    local prev=$((next - 1))
    log "Continuing from STORY-$prev → STORY-$next"
    log "Running: opencode --agent Master \"stories $next\""
    opencode --agent Master "stories $next"
}

case "${1:-}" in
    "$CMD_START")
        shift
        cmd_start "$*"
        ;;
    "$CMD_NEXT")
        cmd_next
        ;;
    *)
        echo "Usage:"
        echo "  opencode-batch.sh start \"stories 8,9,10\""
        echo "  opencode-batch.sh next"
        exit 1
        ;;
esac
