#!/usr/bin/env bash
# Enforce project boundary for Write/Edit operations.
# Within project dir (or additionalDirectories) → allow (exit 0, normal flow).
# Outside → BLOCK (exit 2). Use CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1 to override.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && exit 0

expand_path() {
  local p="${1/#\~/$HOME}"
  realpath -m "$p" 2>/dev/null || echo "$p"
}

ABS_CWD=$(expand_path "$CWD")

# Resolve file path (handle relative paths relative to CWD)
EXPANDED_FILE="${FILE_PATH/#\~/$HOME}"
if [[ "$EXPANDED_FILE" != /* ]]; then
  EXPANDED_FILE="$ABS_CWD/$EXPANDED_FILE"
fi
ABS_FILE=$(realpath -m "$EXPANDED_FILE" 2>/dev/null || echo "$EXPANDED_FILE")

# 1. Within project directory → allow
if [[ "$ABS_FILE" == "$ABS_CWD/"* ]] || [[ "$ABS_FILE" == "$ABS_CWD" ]]; then
  exit 0
fi

# 2. Within additionalDirectories (global + project settings) → allow
is_in_additional_dirs() {
  local file="$1" cwd="$2" settings_file abs_dir dir
  for settings_file in \
    "$HOME/.claude/settings.json" \
    "$cwd/.claude/settings.json" \
    "$cwd/.claude/settings.local.json"; do
    [[ ! -f "$settings_file" ]] && continue
    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      abs_dir=$(expand_path "$dir")
      if [[ "$file" == "$abs_dir/"* ]] || [[ "$file" == "$abs_dir" ]]; then
        return 0
      fi
    done < <(jq -r '.permissions.additionalDirectories[]? // empty' "$settings_file" 2>/dev/null)
  done
  return 1
}

if is_in_additional_dirs "$ABS_FILE" "$ABS_CWD"; then
  exit 0
fi

# 繞行訊號：與 branch-policy 共用同一環境變數
if [[ "${CLAUDE_HOOK_BYPASS_BRANCH_POLICY:-0}" == "1" ]]; then
  exit 0
fi

# 3. Outside project → BLOCK
cat >&2 <<EOF
⛔ BLOCKED by project-boundary hook

File    : $ABS_FILE
Project : $ABS_CWD

The target file is outside the project folder and its additionalDirectories.

Bypass (only when justified):
  - Set environment variable: CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1
EOF
exit 2
