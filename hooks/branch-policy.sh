#!/usr/bin/env bash
# PreToolUse hook：阻擋繞過 ai-dev-team workflow 嘅操作
#
# 觸發時機：Bash / Edit / Write tool 即將執行前
# 行為：
#   [Bash matcher]
#     - `git commit` 喺 main / master / develop → BLOCK
#     - `git push --force` 至 protected branch → BLOCK
#     - `git reset --hard` 喺 protected branch → BLOCK
#     - merge --no-ff feature/fix/refactor/hotfix → 放行
#   [Edit / Write matcher]
#     - 喺 main / master / develop 上 Edit/Write 任何 git-tracked 檔案 → BLOCK
#       （唔等到 commit 先 catch，prevent「白寫一輪先發現 branch 錯」）
#
# 繞行訊號：
#   - 環境變數 CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1 → 跳過所有檢查
#   - ~/.claude/ 路徑下嘅 repo（team config / dotfiles）→ 自動豁免
#
# Exit codes:
#   0 → 放行
#   2 → BLOCK（Claude 收到 stderr 訊息並停手）

set -u

# Tool input 透過 stdin 傳入（JSON）
TOOL_INPUT=$(cat 2>/dev/null || echo '{}')
TOOL_NAME=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# 繞行訊號 1：環境變數
if [[ "${CLAUDE_HOOK_BYPASS_BRANCH_POLICY:-0}" == "1" ]]; then
  exit 0
fi

# 提取 cwd / branch / git_root
CWD=$(printf '%s' "$TOOL_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$CWD" ]] && CWD=$(pwd)
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0
GIT_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)

# 繞行訊號 2：~/.claude/ 內嘅 infrastructure repo（team config、dotfiles）
CLAUDE_HOME="${HOME}/.claude"
if [[ -n "$GIT_ROOT" && "$GIT_ROOT" == "${CLAUDE_HOME}"* ]]; then
  exit 0
fi

# 標記 protected branch
PROTECTED_BRANCH=0
case "$BRANCH" in
  main|master|develop) PROTECTED_BRANCH=1 ;;
esac

# Helper：輸出 block 訊息
block() {
  local reason="$1"
  local guidance="$2"
  local detail="${3:-}"
  cat >&2 <<EOF
⛔ BLOCKED by branch-policy hook

Reason  : $reason
Branch  : $BRANCH
Tool    : $TOOL_NAME
$detail
Required action:
$guidance

Bypass options (only when justified):
  - Set environment variable: CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1
EOF
  exit 2
}

# ─────────────────────────────────────────────────────────────────────────────
# Tool-specific checks
# ─────────────────────────────────────────────────────────────────────────────

case "$TOOL_NAME" in

  Bash)
    CMD=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [[ -z "$CMD" ]] && exit 0
    # 非 git 命令直接放行
    echo "$CMD" | grep -qE '\bgit\b' || exit 0

    DETAIL="Command : $(echo "$CMD" | head -c 200)
"

    # Rule 1：禁止喺 protected branch 直接 git commit
    if [[ $PROTECTED_BRANCH -eq 1 ]]; then
      if echo "$CMD" | grep -qE '\bgit[[:space:]]+(-c[[:space:]]+[^ ]+[[:space:]]+)*commit\b'; then
        block \
          "Direct commit to protected branch ($BRANCH) is forbidden by ai-dev-team workflow." \
          "  1. Create a feature/fix/refactor branch from develop:
       git checkout develop && git checkout -b feature/<scope>/<description>
  2. Make your changes there
  3. Use the /feature or /fix workflow to merge back via Code Reviewer + QA + DevOps" \
          "$DETAIL"
      fi
    fi

    # Rule 2：禁止 force push 至 protected branch
    if echo "$CMD" | grep -qE '\bgit[[:space:]]+push\b.*(--force\b|-f\b|--force-with-lease)'; then
      if echo "$CMD" | grep -qE '\b(main|master|develop)\b'; then
        block \
          "Force push to protected branch detected." \
          "  Force pushing main/develop destroys upstream history.
  If a hotfix is required, use the /hotfix workflow which goes through DevOps." \
          "$DETAIL"
      fi
    fi

    # Rule 3：禁止 git reset --hard 喺 protected branch
    if [[ $PROTECTED_BRANCH -eq 1 ]] && echo "$CMD" | grep -qE '\bgit[[:space:]]+reset[[:space:]]+--hard\b'; then
      block \
        "git reset --hard on protected branch ($BRANCH) is forbidden." \
        "  Use git revert (creates new commit) or branch off and rebuild safely." \
        "$DETAIL"
    fi
    ;;

  Edit|Write)
    # 只有喺 protected branch 上至 block；其他 branch 全放行
    [[ $PROTECTED_BRANCH -eq 0 ]] && exit 0

    FILE_PATH=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    [[ -z "$FILE_PATH" ]] && exit 0

    # 解析絕對路徑（portable：macOS BSD realpath 無 -m，需 fallback）
    EXPANDED_FILE="${FILE_PATH/#\~/$HOME}"
    if [[ "$EXPANDED_FILE" != /* ]]; then
      EXPANDED_FILE="$CWD/$EXPANDED_FILE"
    fi
    ABS_FILE=$(realpath -m "$EXPANDED_FILE" 2>/dev/null) || {
      # Fallback：cd 入 parent dir 再 pwd -P 取得 canonical path
      _dir="${EXPANDED_FILE%/*}"; _base="${EXPANDED_FILE##*/}"
      [[ -z "$_dir" ]] && _dir="/"
      if [[ -d "$_dir" ]] && _resolved=$(cd "$_dir" 2>/dev/null && pwd -P); then
        ABS_FILE="$_resolved/$_base"
      else
        ABS_FILE="$EXPANDED_FILE"
      fi
    }

    # Gitignored 檔案唔係 git-tracked → 放行（符合 hook 設計意圖：只 block tracked file）
    if git -C "$GIT_ROOT" check-ignore -q "$ABS_FILE" 2>/dev/null; then
      exit 0
    fi

    # 只有當 target file 喺當前 protected git repo 內至 block
    # （file 喺其他 repo / 非 git 目錄 → 唔關呢個 repo 事，由 project-boundary.sh 處理）
    if [[ -n "$GIT_ROOT" && ( "$ABS_FILE" == "$GIT_ROOT/"* || "$ABS_FILE" == "$GIT_ROOT" ) ]]; then
      block \
        "Edit/Write to file inside protected branch ($BRANCH) is forbidden." \
        "  1. Create a feature/fix/refactor branch from develop FIRST:
       git checkout develop && git checkout -b feature/<scope>/<description>
  2. Then perform Edit/Write on your branch
  3. Use the /feature or /fix workflow to merge back via Code Reviewer + QA + DevOps" \
        "File    : $ABS_FILE
"
    fi
    ;;
esac

exit 0
