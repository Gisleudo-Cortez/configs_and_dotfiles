#!/usr/bin/env bash
# Creates a well-structured Neovim config dump for LLMs.

set -euo pipefail

BASE_DIR="/home/nero/Documents/configs_and_dotfiles/nvim/.config/nvim"
OUTPUT_FILE="nvim_config_dump.txt"
INCLUDE_LOCK=false
MAX_FILE_SIZE=$((1024 * 1024 * 2)) # 2MB safety guard

# --------------- ARG PARSING ----------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-lock) INCLUDE_LOCK=true; shift ;;
    --out) OUTPUT_FILE="$2"; shift 2 ;;
    --base) BASE_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: Base directory not found: $BASE_DIR"
  exit 1
fi

: > "$OUTPUT_FILE"

# --------------- CONTEXT HEADER ----------------
{
echo "########## NEOVIM CONFIGURATION CONTEXT ##########"
echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Base directory: $BASE_DIR"
echo
echo "## System Information:"
uname -a || true
echo
echo "## Tool Versions:"
command -v nvim >/dev/null && nvim --version | head -n 3
command -v lua >/dev/null && lua -v
command -v rustfmt >/dev/null && rustfmt --version
command -v rust-analyzer >/dev/null && rust-analyzer --version
command -v cargo >/dev/null && cargo --version
command -v node >/dev/null && node --version
command -v go >/dev/null && go version
command -v python3 >/dev/null && python3 --version
echo
echo "## Directory Tree:"
if command -v tree >/dev/null; then
  tree -a -I '.git|node_modules|target' "$BASE_DIR"
else
  (cd "$BASE_DIR" && find . -type f | sort)
fi
echo
} >> "$OUTPUT_FILE"

# --------------- FILE CONTENTS ----------------
echo "## Files and Their Contents:" >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

find "$BASE_DIR" \
  -type f \( -name "*.lua" -o -name "*.json" -o -name "*.vim" \) \
  | sort \
  | while read -r file; do
    if ! $INCLUDE_LOCK && [[ "$(basename "$file")" == "lazy-lock.json" ]]; then
      continue
    fi
    FILE_SIZE=$(wc -c < "$file")
    if (( FILE_SIZE > MAX_FILE_SIZE )); then
      echo "### FILE: ${file#$BASE_DIR/} (SKIPPED: ${FILE_SIZE} bytes > $MAX_FILE_SIZE)" >> "$OUTPUT_FILE"
      echo >> "$OUTPUT_FILE"
      continue
    fi

    {
      echo "------------------------------------------------------------"
      echo "### FILE NAME: $(basename "$file")"
      echo "### FILE PATH: $file"
      echo "------------------------------------------------------------"
      echo '```'
      cat "$file"
      echo '```'
      echo
    } >> "$OUTPUT_FILE"
done

echo "########## END OF CONFIG DUMP ##########" >> "$OUTPUT_FILE"

echo "Config dump saved to $OUTPUT_FILE"
