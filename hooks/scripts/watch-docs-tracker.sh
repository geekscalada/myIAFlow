#!/usr/bin/env bash
# watch-docs-tracker.sh
# Run this in a separate terminal to watch /docs reads live:
#   bash .github/hooks/scripts/watch-docs-tracker.sh

LOG_FILE="/tmp/docs-tracker.log"

touch "$LOG_FILE"
echo "Watching docs reads... (Ctrl+C to stop)"
echo "Log: $LOG_FILE"
echo "─────────────────────────────────────────────────"
tail -f "$LOG_FILE"
