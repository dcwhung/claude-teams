#!/usr/bin/env bash
# PreToolUse hook (Bash): Code Reviewer 唔准跑 full suite / e2e（Hard Rule #7、#9）
#
# 觸發：任何 Bash tool call；只喺 stdin JSON 嘅 agent_type 係 code-reviewer 先檢查
#       （agent_type 只會喺 subagent 入面出現；main agent / 其他 agent 一律放行）
# Block：
#   - full suite：`npm|pnpm|yarn [run] test`（冇 `-- <file>`）、`vitest [run]` / `jest` 冇檔案參數
#   - e2e / browser suite：playwright、`e2e/`、`run-all.sh`、`test:e2e` / `run e2e`
# 放行：`vitest related`、`vitest run <files>`、`jest --findRelatedTests`、`npm test -- <file>`、單一 node test 檔
#
# Why：life-in-uk-test 82/93 份 review 自己跑 `run-all.sh`（約 700 s），之後 QA 同 CI 再各跑一次。
# Plugin subagent 嘅 frontmatter `hooks` 會被忽略，所以要放喺 plugin hooks.json，靠 agent_type 分辨。
#
# Bypass：CLAUDE_HOOK_BYPASS_REVIEWER_TEST_SCOPE=1
# Exit：0 放行 / 2 BLOCK

set -u

readonly EXIT_ALLOW=0
readonly EXIT_BLOCK=2
readonly REVIEWER_AGENT_SUFFIX="code-reviewer"

# 先讀晒 stdin（未讀就 exit 會令上游 pipe 收到 SIGPIPE）
INPUT=$(cat 2>/dev/null || echo '{}')

[[ "${CLAUDE_HOOK_BYPASS_REVIEWER_TEST_SCOPE:-0}" == "1" ]] && exit "$EXIT_ALLOW"
AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null)
[[ "$AGENT_TYPE" == *"$REVIEWER_AGENT_SUFFIX" ]] || exit "$EXIT_ALLOW"

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit "$EXIT_ALLOW"

# 去走引號入面嘅字（例如 grep 'npm test' docs/），避免誤判
UNQUOTED=$(printf '%s' "$COMMAND" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

block() {
    cat >&2 <<EOF
⛔ BLOCKED by reviewer-test-scope hook

Command : $COMMAND
Reason  : $1

Code Reviewer 只可以跑 diff 相關嘅 unit test：
  - npx vitest related <changed-files>
  - npx vitest run <test-files...>
  - npx jest --findRelatedTests <changed-files>
Full suite 只喺 QA S3（發佈前）跑一次；e2e 屬 QA S1/S2 同 CI。
見 skills/sw-validation-gate/SKILL.md、Hard Rule #7。

Bypass（只限用戶明確要求）：CLAUDE_HOOK_BYPASS_REVIEWER_TEST_SCOPE=1
EOF
    exit "$EXIT_BLOCK"
}

# ── e2e / browser suite ──────────────────────────────────────────────────
E2E_PATTERN='(^|[^[:alnum:]_-])(playwright|run-all\.sh)([^[:alnum:]_-]|$)|(^|[[:space:]/.])e2e/|test:e2e|(npm|pnpm|yarn)([[:space:]]+run)?[[:space:]]+e2e([^[:alnum:]_-]|$)'
if grep -Eq "$E2E_PATTERN" <<<"$UNQUOTED"; then
    block "e2e / browser suite 屬 QA 同 CI"
fi

# ── full suite via package manager ───────────────────────────────────────
# 逐段（以 && || ; | 分隔）檢查
while IFS= read -r segment; do
    segment="$(sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<<"$segment")"
    [[ -z "$segment" ]] && continue

    if grep -Eq '(^|[[:space:]])(npm|pnpm|yarn)([[:space:]]+run)?[[:space:]]+test([[:space:]]|$)' <<<"$segment"; then
        # 放行：npm test -- <有路徑嘅參數>
        grep -Eq '[[:space:]]--[[:space:]]+[^-[:space:]][^[:space:]]*' <<<"$segment" || block "package-manager test script 會跑 full suite"
    fi

    # vitest / jest：要有 related / findRelatedTests 或者最少一個非 flag 參數（檔案）
    if grep -Eq '(^|[[:space:]/])(vitest|jest)([[:space:]]|$)' <<<"$segment"; then
        args="$(sed -E 's/.*(^|[[:space:]/])(vitest|jest)([[:space:]]|$)//' <<<"$segment")"
        grep -Eq '(^|[[:space:]])(related|--findRelatedTests)([[:space:]]|$)' <<<"$args" && continue
        has_file=0
        for token in $args; do
            [[ "$token" == "run" || "$token" == -* || "$token" == [0-9]* || "$token" == ">"* || "$token" == "2>&1" ]] && continue
            has_file=1
            break
        done
        [[ "$has_file" -eq 1 ]] || block "vitest / jest 冇指定 test 檔 = full suite"
    fi
done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$UNQUOTED")

exit "$EXIT_ALLOW"
