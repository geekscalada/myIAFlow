#!/usr/bin/env bash
# docs-tracker.sh
# PostToolUse hook: tracks file-reading tools on configured path prefixes.
# Writes a colored, timestamped line to:
#   - $LOG_FILE  (persistent; watch with: tail -f /tmp/docs-tracker.log)
#   - stderr     (visible in VS Code Output panel)
#
# Configuration: .github/hooks/docs-tracker.env

# Resolve config relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../docs-tracker.env"

# Defaults (overridden by config file)
TRACKED_PATHS="/docs"
LOG_FILE="/tmp/docs-tracker.log"

# Load config if present
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# --- Read stdin (JSON payload from the hook engine) ---
PAYLOAD=$(cat)

# --- Extract fields with python3 (always available) ---
read -r TOOL_NAME TOOL_PATH TOOL_LINES <<< "$(python3 - "$PAYLOAD" << 'PYEOF'
import sys, json

payload = json.loads(sys.argv[1])
tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", {})

if not isinstance(tool_input, dict):
    sys.exit(0)

path = tool_input.get("filePath") or tool_input.get("path") or ""
start = tool_input.get("startLine", "")
end = tool_input.get("endLine", "")
lines = f"L{start}-L{end}" if start and end else ""

print(f"{tool_name} {path} {lines}")
PYEOF
)"

# --- Guard: only track configured path prefixes ---
path_matched=false
for prefix in $TRACKED_PATHS; do
    # Normalize: strip trailing slash
    prefix="${prefix%/}"
    # Match: path equals prefix, or path has prefix as a segment anywhere
    if [[ "$TOOL_PATH" == "$prefix" || "$TOOL_PATH" == "$prefix/"* || \
          "$TOOL_PATH" == *"$prefix" || "$TOOL_PATH" == *"$prefix/"* ]]; then
        path_matched=true
        break
    fi
done
if [[ "$path_matched" == false ]]; then
    exit 0
fi

# --- Guard: only track file-reading tools ---
if [[ "$TOOL_NAME" != "read_file" && "$TOOL_NAME" != "grep_search" && "$TOOL_NAME" != "file_search" ]]; then
    exit 0
fi

# --- Format output ---
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Plain version for log file
PLAIN_LINE="[$TIMESTAMP] $TOOL_NAME  →  $TOOL_PATH  $TOOL_LINES"

# Colored version for terminal (ANSI codes, stripped in log)
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
COLOR_LINE="${CYAN}[$TIMESTAMP]${RESET} ${YELLOW}${TOOL_NAME}${RESET}  →  ${GREEN}${TOOL_PATH}${RESET}  ${TOOL_LINES}"

# --- Append to persistent log ---
echo "$PLAIN_LINE" >> "$LOG_FILE"

# --- Print to stderr so it appears in the hook runner output ---
echo -e "$COLOR_LINE" >&2

# --- Always exit 0 (non-blocking) ---
exit 0
