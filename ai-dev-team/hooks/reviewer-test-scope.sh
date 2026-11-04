#!/usr/bin/env bash
# PreToolUse hook (Bash): Code Reviewer 唔准跑 full suite / e2e（Hard Rule #7、#9）
#
# 觸發：任何 Bash tool call；只喺 stdin JSON 嘅 agent_type 係 code-reviewer 先檢查
#       （agent_type 只會喺 subagent 入面出現；main agent / 其他 agent 一律放行）
# Block：
#   - full suite：`npm|pnpm|yarn|bun [run] test|t|test:*`（冇 `-- <file>`）、`bun test` / `vitest` / `jest` /
#     `node --test` / `pytest` 冇檔案參數、`make test`
#     （`-t` `--reporter` `--config` `-c` `--project` 等 flag 會食埋下一個值；directory 唔算檔案）
#   - e2e / browser suite：playwright、cypress、`e2e/`、`run-all.sh`、`test:e2e` / `run e2e`
# 放行：`vitest related`、`vitest run <files>`、`jest --findRelatedTests`、`npm test -- <file>`、單一 node test 檔
# 檔案參數：有副檔名或者有 `/`，而且唔係 directory（有 payload `.cwd` 就用 `-d` 檢查，冇就一定要有副檔名）
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

# 引號入面嘅字換成 placeholder（例如 grep 'npm test' docs/），避免誤判；
# 留低一個 token，等 `-t "a b"` 嘅 value flag 仍然食到一個值
readonly QUOTED_PLACEHOLDER="_quoted_"
UNQUOTED=$(printf '%s' "$COMMAND" | sed -E "s/'[^']*'/${QUOTED_PLACEHOLDER}/g; s/\"[^\"]*\"/${QUOTED_PLACEHOLDER}/g")

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

# ── full suite：逐段（&& || ; |）睇 command word ────────────────────────
# 呢啲 flag 會食埋下一個 token（唔係檔案參數）
readonly VALUE_FLAGS=" -t --reporter --config -c --project --testNamePattern --outputFile --shard -k -m "
readonly EXEC_WORDS=" exec dlx x "
readonly ENV_ASSIGN_RE='^[A-Za-z_][A-Za-z0-9_]*='
PAYLOAD_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

in_list() { [[ "$2" == *" $1 "* ]]; }

is_file_arg() { # token → 0 if it looks like a file path (has extension or `/`, not a directory)
    local tok="$1" abs has_ext=1
    [[ -z "$tok" || "$tok" == -* || "$tok" == *">"* || "$tok" == */ ]] && return 1
    [[ "${tok##*/}" == ?*.?* ]] && has_ext=0
    # 冇 cwd 就判斷唔到係咪 directory → 一定要有副檔名
    [[ -z "$PAYLOAD_CWD" ]] && return "$has_ext"
    abs="$tok"
    [[ "$tok" != /* ]] && abs="$PAYLOAD_CWD/$tok"
    [[ -d "$abs" ]] && return 1
    [[ "$has_ext" -eq 0 || "$tok" == */* ]]
}

has_file_args() { # tokens... → 0 if any positional token is a file path
    local skip=0 tok
    for tok in "$@"; do
        if [[ "$skip" -eq 1 ]]; then skip=0; continue; fi
        if in_list "$tok" "$VALUE_FLAGS"; then skip=1; continue; fi
        is_file_arg "$tok" && return 0
    done
    return 1
}

check_vitest_jest() { # args... → block unless related / findRelatedTests / file args
    local tok
    for tok in "$@"; do
        [[ "$tok" == "related" || "$tok" == "--findRelatedTests" ]] && return 0
    done
    has_file_args "$@" || block "vitest / jest 冇指定 test 檔 = full suite"
}

check_tool() { # tool args... (npx / pnpm exec / direct)
    local tool="${1##*/}"
    shift
    case "$tool" in
        vitest | jest) check_vitest_jest "$@" ;;
        playwright | cypress) block "e2e / browser suite 屬 QA 同 CI" ;;
    esac
    return 0
}

check_npx() { # args after npx → skip npx's own flags, then check the tool
    while [[ $# -gt 0 && "$1" == -* ]]; do shift; done
    [[ $# -gt 0 ]] && check_tool "$@"
    return 0
}

pm_test_is_scoped() { # args after `test` → 0 if `-- <file>`
    local after=0 tok
    for tok in "$@"; do
        [[ "$after" -eq 1 ]] && { is_file_arg "$tok"; return; }
        [[ "$tok" == "--" ]] && after=1
    done
    return 1
}

check_pm() { # pm args... (npm / pnpm / yarn / bun)
    local pm="$1" script="${2:-}" via_run=0
    shift 2 2>/dev/null || shift
    if [[ "$script" == "run" || "$script" == "run-script" ]]; then
        via_run=1; script="${1:-}"; shift 2>/dev/null
    fi
    in_list "$script" "$EXEC_WORDS" && { check_npx "$@"; return 0; }
    case "$script" in
        *e2e*) block "e2e / browser suite 屬 QA 同 CI" ;;
        t | test | test:*)
            # bun test（唔經 run）= bun 自己嘅 runner，直接收檔案參數
            if [[ "$pm" == "bun" && "$via_run" -eq 0 && "$script" == "test" ]]; then
                has_file_args "$@" || block "bun test 冇指定 test 檔 = full suite"
            else
                pm_test_is_scoped "$@" || block "package-manager test script 會跑 full suite"
            fi ;;
        vitest | jest | playwright | cypress) check_tool "$script" "$@" ;;
    esac
    return 0
}

check_node() { # args after node
    local tok
    for tok in "$@"; do
        [[ "$tok" == "--test" ]] || continue
        has_file_args "$@" || block "node --test 冇指定 test 檔 = full suite"
    done
    return 0
}

check_make() { # make targets
    local tok
    for tok in "$@"; do
        case "$tok" in
            -*) ;;
            *e2e*) block "e2e / browser suite 屬 QA 同 CI" ;;
            test | tests | test-* | test_*) block "make test target 會跑 full suite" ;;
        esac
    done
    return 0
}

check_segment() { # one command segment (no && || ; |)
    local -a tokens
    read -ra tokens <<<"$1"
    [[ ${#tokens[@]} -eq 0 ]] && return 0
    set -- "${tokens[@]}"
    # 跳過 FOO=1 呢類 env assignment
    while [[ $# -gt 0 && "$1" =~ $ENV_ASSIGN_RE ]]; do shift; done
    [[ $# -eq 0 ]] && return 0
    local word="${1##*/}"
    shift
    case "$word" in
        npm | pnpm | yarn | bun) check_pm "$word" "$@" ;;
        npx | bunx) check_npx "$@" ;;
        vitest | jest | playwright | cypress) check_tool "$word" "$@" ;;
        node) check_node "$@" ;;
        make) check_make "$@" ;;
        pytest) has_file_args "$@" || block "pytest 冇指定 test 檔 = full suite" ;;
    esac
    return 0
}

# awk 拆段（BSD / bash 3.2 安全，唔靠 sed 嘅 \n）
while IFS= read -r segment; do
    check_segment "$segment"
done < <(printf '%s\n' "$UNQUOTED" | awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }')

exit "$EXIT_ALLOW"
