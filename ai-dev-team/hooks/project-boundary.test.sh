#!/usr/bin/env bash
# Tests for project-boundary.sh — run: bash ai-dev-team/hooks/project-boundary.test.sh
# Plain bash, no framework. HOME / TMPDIR / CLAUDE_CONFIG_DIR point at a temp sandbox.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/project-boundary.sh"
readonly HOOK
readonly EXIT_ALLOW=0
readonly EXIT_BLOCK=2

PASS_COUNT=0
FAIL_COUNT=0

SANDBOX="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$SANDBOX"' EXIT
readonly PROJECT="$SANDBOX/project"
readonly TMP_ROOT="$SANDBOX/tmp"
readonly CONFIG_DIR="$SANDBOX/config"
readonly SCRATCHPAD="$TMP_ROOT/claude-0/-home-user/session-1/scratchpad"
readonly FAKE_BIN="$SANDBOX/fake-bin"
mkdir -p "$PROJECT" "$SANDBOX/home" "$CONFIG_DIR/plans" "$SCRATCHPAD" "$FAKE_BIN"
# Simulates macOS BSD realpath, which has no -m and fails on missing paths.
printf '#!/bin/sh\nexit 1\n' >"$FAKE_BIN/realpath"
chmod +x "$FAKE_BIN/realpath"

payload() { # file_path
    jq -cn --arg f "$1" --arg d "$PROJECT" '{tool_name:"Write",cwd:$d,tool_input:{file_path:$f}}'
}

run_hook() { # path_prefix file_path → exit code
    payload "$2" | PATH="$1$PATH" HOME="$SANDBOX/home" TMPDIR="$TMP_ROOT" \
        CLAUDE_CONFIG_DIR="$CONFIG_DIR" CLAUDE_HOOK_BYPASS_BRANCH_POLICY=0 \
        bash "$HOOK" >/dev/null 2>&1
}

expect() { # expected_exit label file_path [path_prefix]
    local code
    run_hook "${4:-}" "$3"
    code=$?
    if [[ "$code" == "$1" ]]; then
        echo "  ✓ [$1] $2"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ [$1 expected, got $code] $2 :: $3"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo "allowed"
expect "$EXIT_ALLOW" "project file" "$PROJECT/src/a.ts"
expect "$EXIT_ALLOW" "relative project file" "src/a.ts"
expect "$EXIT_ALLOW" "plans dir" "$CONFIG_DIR/plans/plan.md"
expect "$EXIT_ALLOW" "session scratchpad" "$SCRATCHPAD/shot.png"

echo "blocked"
expect "$EXIT_BLOCK" "/etc/x" "/etc/x"
expect "$EXIT_BLOCK" "/tmp/other/scratchpad/x" "/tmp/other/scratchpad/x"
expect "$EXIT_BLOCK" "scratchpad without project/session levels (S-901)" "$TMP_ROOT/claude-0/scratchpad/x"

echo "blocked: .. escape (real realpath)"
expect "$EXIT_BLOCK" "project/../other" "$PROJECT/../other/x"
expect "$EXIT_BLOCK" "scratchpad/../../x" "$SCRATCHPAD/../../x"

echo "blocked: .. escape (realpath unavailable, W-906)"
expect "$EXIT_BLOCK" "project/../other" "$PROJECT/../other/x" "$FAKE_BIN:"
expect "$EXIT_BLOCK" "scratchpad/../../x" "$SCRATCHPAD/../../x" "$FAKE_BIN:"
expect "$EXIT_BLOCK" "relative ../x" "../other/x" "$FAKE_BIN:"
expect "$EXIT_BLOCK" "trailing /.." "$PROJECT/src/.." "$FAKE_BIN:"
expect "$EXIT_ALLOW" "project file still allowed" "$PROJECT/src/a.ts" "$FAKE_BIN:"
expect "$EXIT_ALLOW" "scratchpad still allowed" "$SCRATCHPAD/shot.png" "$FAKE_BIN:"

echo
echo "passed: $PASS_COUNT  failed: $FAIL_COUNT"
[[ "$FAIL_COUNT" -eq 0 ]]
