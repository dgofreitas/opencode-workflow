#!/usr/bin/env bash
# opencode-batch.sh — Run multiple stories sequentially with fresh sessions
# Usage:
#   opencode-batch.sh "stories 8,9,10"
#   opencode-batch.sh "stories 8-10"

set -euo pipefail

BATCH_STATE_FILE=".opencode/.batch-state"
LOG_FILE="/tmp/opencode-batch.log"

log() {
    echo "[batch] $(date '+%Y-%m-%dT%H:%M:%S%z') $*" | tee -a "$LOG_FILE"
}

parse_stories() {
    local raw="$1"
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
total=0
for story in $stories; do
    remaining="$(echo "$stories" | cut -d' ' -f2-)"
    log "=== STORY-$story STARTING ==="

    # Run opencode for this story
    opencode --agent Master "stories $story"

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
