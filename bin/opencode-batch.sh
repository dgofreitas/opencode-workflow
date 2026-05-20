#!/usr/bin/env bash
# opencode-batch.sh — Run multiple stories sequentially with fresh sessions
# Usage:
#   opencode-batch.sh "stories 8,9,10"
#   opencode-batch.sh "stories 8-10"
#   opencode-batch.sh "STORY-theme 3-8"

set -euo pipefail

BATCH_STATE_FILE=".opencode/.batch-state"
LOG_FILE="/tmp/opencode-batch.log"

log() {
    echo "[batch] $(date '+%Y-%m-%dT%H:%M:%S%z') $*" | tee -a "$LOG_FILE"
}

parse_stories() {
    local raw="$1"
    local out=""

    # Strip known english prefix words (case-insensitive)
    raw="$(echo "$raw" | sed -E 's/^(stories|story|STORY[^ ]*) *//i')"

    # Replace commas with spaces
    raw="${raw//,/ }"

    for token in $raw; do
        # Detect range: N-M where N and M are integers
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            out="$out$(seq -s ' ' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}") "
            break
        fi
        # Single number
        if [[ "$token" =~ ^[0-9]+$ ]]; then
            out="$out$token "
        fi
    done

    echo "${out% }"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: opencode-batch.sh \"stories 8,9,10\" (or \"stories 8-10\")"
    exit 1
fi

input="$*"
stories="$(parse_stories "$input")"

if [[ -z "$stories" ]]; then
    echo "Usage: opencode-batch.sh \"stories 8,9,10\" (or \"stories 8-10\")"
    exit 1
fi

# Check if resuming
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ -f "$PROJECT_ROOT/$BATCH_STATE_FILE" ]]; then
    stories="$(cat "$PROJECT_ROOT/$BATCH_STATE_FILE")"
    log "Resuming batch from saved state: $stories"
else
    log "Batch mode — stories: $stories"
    log "Project: $PROJECT_ROOT"
    echo "$stories" > "$PROJECT_ROOT/$BATCH_STATE_FILE"
fi

# Loop through all stories
for story in $stories; do
    remaining="$(echo "$stories" | cut -d' ' -f2-)"
    log "=== STORY-$story STARTING ==="

    (cd "$PROJECT_ROOT" && opencode run "--agent" "Master" "stories $story")

    if [[ -z "$remaining" ]]; then
        log "=== ALL STORIES COMPLETE ==="
        rm -f "$PROJECT_ROOT/$BATCH_STATE_FILE"
        exit 0
    fi

    echo "$remaining" > "$PROJECT_ROOT/$BATCH_STATE_FILE"
    stories="$remaining"
    log "=== STORY-$story DONE — remaining: $remaining ==="
done

log "=== BATCH FINISHED ==="
rm -f "$PROJECT_ROOT/$BATCH_STATE_FILE"
