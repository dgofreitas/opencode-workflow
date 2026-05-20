#!/usr/bin/env bash
# opencode-batch.sh — Run multiple stories sequentially with fresh sessions
# Usage:
#   opencode-batch.sh "stories 8,9,10"
#   opencode-batch.sh "stories 8-10"
#   opencode-batch.sh "story-theme 5-8"

set -euo pipefail

BATCH_STATE_FILE=".opencode/.batch-state"
LOG_FILE="/tmp/opencode-batch.log"

log() {
    echo "[batch] $(date '+%Y-%m-%dT%H:%M:%S%z') $*" | tee -a "$LOG_FILE"
}

# Parses input into "PREFIX:n" pairs, space-separated
# Examples:
#   "story-theme 5-8"    → "story-theme:5 story-theme:6 story-theme:7 story-theme:8"
#   "stories 8,9,10"     → "8 9 10"
#   "stories 8-10"       → "8 9 10"
#   "story-i18n 7,8,9"   → "story-i18n:7 story-i18n:8 story-i18n:9"
parse_stories() {
    local raw="$1"
    local prefix=""
    local nums=""
    local out=""

    # Detect if there's a story prefix before the numbers
    # Match: <optional stories/story> <optional STORY-thing> <numbers or range>
    if [[ "$raw" =~ ^[[:space:]]*([Ss]tories?[[:space:]]+)?([Ss][Tt][Oo][Rr][Yy][-_.a-zA-Z0-9]*)?[[:space:]]*([0-9, -]+)$ ]]; then
        prefix="${BASH_REMATCH[2]}"
        nums="${BASH_REMATCH[3]}"
    else
        echo "Error: Could not parse story specification: $raw" >&2
        return 1
    fi

    # Clean prefix
    prefix="$(echo "$prefix" | sed -E 's/^[Ss][Tt][Oo][Rr][Yy]//; s/^[-_ ]+//' | tr '[:upper:]' '[:lower:]')"

    # Parse numbers
    nums="${nums//,/ }"

    for token in $nums; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            for ((n=start; n<=end; n++)); do
                if [[ -n "$prefix" ]]; then
                    out="$out$prefix:$n "
                else
                    out="$out$n "
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            if [[ -n "$prefix" ]]; then
                out="$out$prefix:$token "
            else
                out="$out$token "
            fi
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
    mkdir -p "$PROJECT_ROOT/.opencode"
    echo "$stories" > "$PROJECT_ROOT/$BATCH_STATE_FILE"
fi

# Loop through all stories
for entry in $stories; do
    remaining="$(echo "$stories" | cut -d' ' -f2-)"

    # Reconstruct story name for opencode
    local story_prefix="${entry%:*}"
    local story_num="${entry#*:}"
    if [[ "$story_prefix" == "$entry" ]]; then
        local prompt="batch stories $entry"
        log "=== STORY-$entry STARTING ==="
    else
        local prompt="batch stories story-$story_prefix $story_num"
        log "=== STORY-story-$story_prefix:$story_num STARTING ==="
    fi

    (cd "$PROJECT_ROOT" && opencode run "--agent" "Master" "$prompt")

    if [[ -z "$remaining" ]]; then
        log "=== ALL STORIES COMPLETE ==="
        rm -f "$PROJECT_ROOT/$BATCH_STATE_FILE"
        exit 0
    fi

    echo "$remaining" > "$PROJECT_ROOT/$BATCH_STATE_FILE"
    stories="$remaining"
    log "=== $entry DONE — remaining: $remaining ==="
done

log "=== BATCH FINISHED ==="
rm -f "$PROJECT_ROOT/$BATCH_STATE_FILE"
