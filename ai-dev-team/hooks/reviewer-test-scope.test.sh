#!/usr/bin/env bash
# Tests for reviewer-test-scope.sh — run: bash ai-dev-team/hooks/reviewer-test-scope.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/reviewer-test-scope.sh"
readonly HOOK
readonly EXIT_ALLOW=0
readonly EXIT_BLOCK=2
readonly REVIEWER="ai-dev-team:code-reviewer"

PASS_COUNT=0
FAIL_COUNT=0

payload() { # agent_type command
    jq -cn --arg a "$1" --arg c "$2" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}} + (if $a == "" then {} else {agent_type:$a} end)'
}

expect() { # expected_exit agent_type command
    local code
    payload "$2" "$3" | bash "$HOOK" >/dev/null 2>&1
    code=$?
    if [[ "$code" == "$1" ]]; then
        echo "  ✓ [$1] ${2:-main} :: $3"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ [$1 expected, got $code] ${2:-main} :: $3"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

payload_cwd() { # agent_type command cwd
    jq -cn --arg a "$1" --arg c "$2" --arg d "$3" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$d,tool_input:{command:$c},agent_type:$a}'
}

expect_cwd() { # expected_exit agent_type command cwd — directory args resolved against cwd
    local code
    payload_cwd "$2" "$3" "$4" | bash "$HOOK" >/dev/null 2>&1
    code=$?
    if [[ "$code" == "$1" ]]; then
        echo "  ✓ [$1] $2 :: $3 (cwd)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ [$1 expected, got $code] $2 :: $3 (cwd)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

FIXTURE_DIR="$(mktemp -d)"
mkdir -p "$FIXTURE_DIR/src"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

echo "reviewer: blocked (full suite / e2e)"
expect "$EXIT_BLOCK" "$REVIEWER" "npm test"
expect "$EXIT_BLOCK" "$REVIEWER" "npm run test"
expect "$EXIT_BLOCK" "$REVIEWER" "pnpm test 2>&1 | tail -20"
expect "$EXIT_BLOCK" "$REVIEWER" "cd /repo && yarn test"
expect "$EXIT_BLOCK" "$REVIEWER" "npx vitest run"
expect "$EXIT_BLOCK" "$REVIEWER" "npx vitest run --coverage"
expect "$EXIT_BLOCK" "$REVIEWER" "pnpm vitest"
expect "$EXIT_BLOCK" "$REVIEWER" "npx jest"
expect "$EXIT_BLOCK" "$REVIEWER" "bash tests/run-all.sh"
expect "$EXIT_BLOCK" "$REVIEWER" "./tests/run-all.sh --parallel 4"
expect "$EXIT_BLOCK" "$REVIEWER" "npx playwright test"
expect "$EXIT_BLOCK" "$REVIEWER" "node e2e/player.mjs"
expect "$EXIT_BLOCK" "$REVIEWER" "npm run test:e2e"
expect "$EXIT_BLOCK" "$REVIEWER" "npm run e2e"
expect "$EXIT_BLOCK" "code-reviewer" "npm test"

echo "reviewer: blocked (W-904 runners / value flags / dirs)"
expect "$EXIT_BLOCK" "$REVIEWER" "npm t"
expect "$EXIT_BLOCK" "$REVIEWER" "bun test"
expect "$EXIT_BLOCK" "$REVIEWER" "node --test"
expect "$EXIT_BLOCK" "$REVIEWER" "node --test test/"
expect "$EXIT_BLOCK" "$REVIEWER" "make test"
expect "$EXIT_BLOCK" "$REVIEWER" "npm run test:unit"
expect "$EXIT_BLOCK" "$REVIEWER" "yarn test:unit"
expect "$EXIT_BLOCK" "$REVIEWER" "pnpm run test:ci"
expect "$EXIT_BLOCK" "$REVIEWER" "vitest --run --reporter dot"
expect "$EXIT_BLOCK" "$REVIEWER" "npx vitest run --config vitest.config.ts"
expect "$EXIT_BLOCK" "$REVIEWER" "npx jest -c jest.config.js"
expect "$EXIT_BLOCK" "$REVIEWER" "npx vitest run -t foo"
expect "$EXIT_BLOCK" "$REVIEWER" "npx vitest --project unit"
expect "$EXIT_BLOCK" "$REVIEWER" "npx cypress run"
expect "$EXIT_BLOCK" "$REVIEWER" "pytest"
expect_cwd "$EXIT_BLOCK" "$REVIEWER" "npx vitest run src" "$FIXTURE_DIR"

echo "reviewer: allowed (scoped)"
expect "$EXIT_ALLOW" "$REVIEWER" "npx vitest related src/foo.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "npx vitest run src/foo.test.ts src/bar.test.tsx"
expect "$EXIT_ALLOW" "$REVIEWER" "npx vitest run --coverage src/foo.test.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "npm test -- src/foo.test.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "npx jest --findRelatedTests src/foo.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "node tests/quiz-test.js"
expect "$EXIT_ALLOW" "$REVIEWER" "npx eslint . && npx tsc --noEmit"
expect "$EXIT_ALLOW" "$REVIEWER" "git diff --stat develop...HEAD"
expect "$EXIT_ALLOW" "$REVIEWER" "grep -rn 'npm test' docs/"
expect "$EXIT_ALLOW" "$REVIEWER" "bun test src/a.test.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "node --test test/a.test.js"
expect "$EXIT_ALLOW" "$REVIEWER" "pytest tests/test_a.py"
expect "$EXIT_ALLOW" "$REVIEWER" "npx vitest run -t 'adds two' src/a.test.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "CI=1 npx jest --reporter dot src/a.test.ts"

echo "reviewer: allowed (W-905 read-only / scoped, per segment)"
expect "$EXIT_ALLOW" "$REVIEWER" "cat e2e/run.mjs"
expect "$EXIT_ALLOW" "$REVIEWER" "ls e2e/"
expect "$EXIT_ALLOW" "$REVIEWER" "node --check e2e/run.mjs"
expect "$EXIT_ALLOW" "$REVIEWER" "git diff -- e2e/run.mjs"
expect "$EXIT_ALLOW" "$REVIEWER" "head -50 tests/run-all.sh"
expect "$EXIT_ALLOW" "$REVIEWER" "grep -n playwright package.json"
expect "$EXIT_ALLOW" "$REVIEWER" "npm test -- -t foo src/a.test.ts"
expect "$EXIT_ALLOW" "$REVIEWER" "npm test -- --run src/a.test.ts"
expect "$EXIT_BLOCK" "$REVIEWER" "cat e2e/run.mjs && node e2e/run.mjs"
expect "$EXIT_BLOCK" "$REVIEWER" "FOO=1 bash e2e/smoke.sh"

echo "other agents / main: never blocked"
expect "$EXIT_ALLOW" "" "npm test"
expect "$EXIT_ALLOW" "ai-dev-team:quality-assurance" "bash tests/run-all.sh"
expect "$EXIT_ALLOW" "ai-dev-team:frontend-developer" "npx playwright test"

echo "bypass"
OUT_CODE=0
payload "$REVIEWER" "npm test" | CLAUDE_HOOK_BYPASS_REVIEWER_TEST_SCOPE=1 bash "$HOOK" >/dev/null 2>&1 || OUT_CODE=$?
if [[ "$OUT_CODE" == "$EXIT_ALLOW" ]]; then
    echo "  ✓ bypass env allows"; PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ✗ bypass env allows (got $OUT_CODE)"; FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo
echo "passed: $PASS_COUNT  failed: $FAIL_COUNT"
[[ "$FAIL_COUNT" -eq 0 ]]
