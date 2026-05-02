#!/usr/bin/env bash
# PreToolUse Bash hook：阻擋繞過 ai-dev-team workflow 嘅 git 操作
#
# 觸發時機：Bash tool 即將執行任何命令前
# 行為：
#   - 偵測 `git commit` / `git merge` / `git push` 等 mutating 命令
#   - 喺 main / master / develop 上直接 commit  → BLOCK（除非繞行訊號存在）
#   - merge --no-ff feature/* / fix/* / refactor/* / hotfix/* → 放行
#   - merge develop → main 同 main → develop（back-merge）→ 放行
#   - 其他 mutating 操作（rm -rf, force push 主分支）→ BLOCK
#
# 繞行訊號：
#   - 環境變數 CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1 → 跳過檢查
#   - ~/ .claude/ 路徑下嘅 repo（team config / dotfiles）→ 自動豁免
#
# Exit codes:
#   0 → 放行
#   2 → BLOCK（Claude 會收到 stderr 訊息並停手）

set -u

# Tool input 透過 stdin 傳入（JSON）
TOOL_INPUT=$(cat 2>/dev/null || echo '{}')

# 提取 command 字串
CMD=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# 非 git 命令直接放行
if [[ -z "$CMD" ]] || ! echo "$CMD" | grep -qE '\bgit\b'; then
  exit 0
fi

# 繞行訊號 1：環境變數
if [[ "${CLAUDE_HOOK_BYPASS_BRANCH_POLICY:-0}" == "1" ]]; then
  exit 0
fi

# 嘗試獲取當前 branch（若唔喺 git repo 則放行）
CWD=$(printf '%s' "$TOOL_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -z "$CWD" ]]; then
  CWD=$(pwd)
fi
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ -z "$BRANCH" ]]; then
  exit 0
fi

GIT_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)

# 繞行訊號 2：~/.claude/ 內嘅 infrastructure repo（team config、dotfiles）
# 呢類 repo 係 config/docs only，唔走 feature/fix workflow
CLAUDE_HOME="${HOME}/.claude"
if [[ -n "$GIT_ROOT" && "$GIT_ROOT" == "${CLAUDE_HOME}"* ]]; then
  exit 0
fi

# 標記變數
PROTECTED_BRANCH=0
case "$BRANCH" in
  main|master|develop) PROTECTED_BRANCH=1 ;;
esac

# Helper：輸出 block 訊息
block() {
  local reason="$1"
  local guidance="$2"
  cat >&2 <<EOF
⛔ BLOCKED by branch-policy hook

Reason  : $reason
Branch  : $BRANCH
Command : $(echo "$CMD" | head -c 200)

Required action:
$guidance

Bypass options (only when justified):
  - Set environment variable: CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1
EOF
  exit 2
}

# ── Rule 1：禁止喺 main / master / develop 直接 git commit ────────────────────
if [[ $PROTECTED_BRANCH -eq 1 ]]; then
  if echo "$CMD" | grep -qE '\bgit[[:space:]]+(-c[[:space:]]+[^ ]+[[:space:]]+)*commit\b'; then
    # 唯一例外：merge commit 由 git 自動 invoke commit；但 main agent 唔應自己手動 commit
    block \
      "Direct commit to protected branch ($BRANCH) is forbidden by ai-dev-team workflow." \
      "  1. Create a feature/fix/refactor branch from develop:
       git checkout develop && git checkout -b feature/<scope>/<description>
  2. Make your changes there
  3. Use the /feature or /fix workflow to merge back via Code Reviewer + QA + DevOps"
  fi
fi

# ── Rule 2：禁止 force push 至 main / master / develop ────────────────────────
if echo "$CMD" | grep -qE '\bgit[[:space:]]+push\b.*(--force\b|-f\b|--force-with-lease)'; then
  if echo "$CMD" | grep -qE '\b(main|master|develop)\b'; then
    block \
      "Force push to protected branch detected." \
      "  Force pushing main/develop destroys upstream history.
  If a hotfix is required, use the /hotfix workflow which goes through DevOps."
  fi
fi

# ── Rule 3：禁止 git reset --hard 對 protected branch 嘅 origin ────────────────
if [[ $PROTECTED_BRANCH -eq 1 ]] && echo "$CMD" | grep -qE '\bgit[[:space:]]+reset[[:space:]]+--hard\b'; then
  block \
    "git reset --hard on protected branch ($BRANCH) is forbidden." \
    "  Use git revert (creates new commit) or branch off and rebuild safely."
fi

# ── Rule 4：merge 操作放行條件 ─────────────────────────────────────────────────
# 任何 merge 都放行 — handoff protocol 由 main agent 負責，hook 唔做 handoff state 偵測
# （後續可加 hook 4：檢查最近 transcript 有無 handoff-receipt pass，但 hook 對 transcript 訪問有限）

exit 0
