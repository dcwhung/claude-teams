#!/usr/bin/env bash
# Stop hook (ai-dev-team plugin)：記錄今次 session 嘅 token usage，供 /showcase 統計
#
# 觸發時機：每次 Claude 完成一個 turn（Stop）
# 行為：
#   - 由 stdin JSON 讀 session_id / transcript_path / cwd（SK-003：hook input 經 stdin）
#   - 加總主 transcript + subagents/*.jsonl 嘅 assistant usage（按 message.id 去重，
#     因為 streaming 會將同一 message 寫多次）
#   - 寫入 <git-root>/.claude/usage/<session_id>.json（覆寫 → idempotent）
#   - 只寫檔，唔 commit；commit 由 /session-log 負責
#
# 跳過：cwd 唔係 git repo、repo 喺 ~/.claude/ 之下、transcript 唔存在
# Bypass: CLAUDE_HOOK_BYPASS_USAGE_LOGGER=1
# Exit code 永遠 0 —— 記錄失敗唔可以阻住 session

set -uo pipefail

[[ "${CLAUDE_HOOK_BYPASS_USAGE_LOGGER:-0}" == "1" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

USAGE_SUBDIR='.claude/usage'

HOOK_INPUT=$(cat 2>/dev/null || echo '{}')
SESSION_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
CWD=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$SESSION_ID" || -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0
[[ -z "$CWD" ]] && CWD=$(pwd)

GIT_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -z "$GIT_ROOT" || "$GIT_ROOT" == "${HOME}/.claude"* ]] && exit 0

SUBAGENT_DIR="${TRANSCRIPT%.jsonl}/subagents"
TRANSCRIPTS=("$TRANSCRIPT")
if compgen -G "$SUBAGENT_DIR/*.jsonl" >/dev/null; then
  TRANSCRIPTS+=("$SUBAGENT_DIR"/*.jsonl)
fi

USAGE_JSON=$(cat "${TRANSCRIPTS[@]}" 2>/dev/null \
  | jq -c 'select(.type == "assistant" and .message.usage != null and .message.id != null)
           | {id: .message.id, model: .message.model, u: .message.usage}' 2>/dev/null \
  | jq -s --arg sid "$SESSION_ID" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
      unique_by(.id) as $msgs
      | ($msgs | map(.u.input_tokens // 0) | add // 0) as $in
      | ($msgs | map(.u.output_tokens // 0) | add // 0) as $out
      | ($msgs | map(.u.cache_creation_input_tokens // 0) | add // 0) as $cw
      | ($msgs | map(.u.cache_read_input_tokens // 0) | add // 0) as $cr
      | {
          session_id: $sid,
          updated_at: $now,
          messages: ($msgs | length),
          models: ($msgs | map(.model) | unique),
          input_tokens: $in, output_tokens: $out,
          cache_creation_input_tokens: $cw, cache_read_input_tokens: $cr,
          total_tokens: ($in + $out + $cw + $cr)
        }' 2>/dev/null) || exit 0

[[ -z "$USAGE_JSON" ]] && exit 0
mkdir -p "$GIT_ROOT/$USAGE_SUBDIR" 2>/dev/null || exit 0
printf '%s\n' "$USAGE_JSON" > "$GIT_ROOT/$USAGE_SUBDIR/${SESSION_ID}.json" 2>/dev/null
exit 0
