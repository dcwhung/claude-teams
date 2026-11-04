#!/usr/bin/env bash
# Tests for qa-ledger.sh — run: bash ai-dev-team/scripts/qa-ledger.test.sh
# Plain bash, no framework. Each test runs in its own temp project dir.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/qa-ledger.sh"
readonly SCRIPT
readonly EXIT_OK=0
readonly EXIT_STALE=1
readonly EXIT_USAGE=2

PASS_COUNT=0
FAIL_COUNT=0

fail() { echo "  ✗ $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
pass() { echo "  ✓ $1"; PASS_COUNT=$((PASS_COUNT + 1)); }

assert_exit() { # expected actual label
    if [[ "$1" == "$2" ]]; then pass "$3"; else fail "$3 (expected exit $1, got $2)"; fi
}
assert_contains() { # haystack needle label
    if grep -qF -- "$2" <<<"$1"; then pass "$3"; else fail "$3 (missing: $2)"; echo "$1" | sed 's/^/      | /'; fi
}
assert_not_contains() { # haystack needle label
    if grep -qF -- "$2" <<<"$1"; then fail "$3 (unexpected: $2)"; else pass "$3"; fi
}

new_project() { # creates a temp project with two source files, cds into it
    PROJECT_DIR="$(mktemp -d)"
    cd "$PROJECT_DIR" || exit 1
    mkdir -p src
    echo "export const a = 1;" >src/a.ts
    echo "export const b = 2;" >src/b.ts
    echo "export const c = 3;" >src/c.ts
    export QA_LEDGER="$PROJECT_DIR/ledger.tsv"
}

cleanup() { cd / && rm -rf "$PROJECT_DIR"; }

run() { OUT="$(bash "$SCRIPT" "$@" 2>&1)"; CODE=$?; }

# ── usage ────────────────────────────────────────────────────────────────
test_usage_errors() {
    echo "usage errors"
    new_project
    run
    assert_exit "$EXIT_USAGE" "$CODE" "no subcommand → exit 2"
    run bogus
    assert_exit "$EXIT_USAGE" "$CODE" "unknown subcommand → exit 2"
    run freeze chain-a S1
    assert_exit "$EXIT_USAGE" "$CODE" "freeze without report/files → exit 2"
    run freeze chain-a S9 report.md src/a.ts
    assert_exit "$EXIT_USAGE" "$CODE" "invalid stage → exit 2"
    run freeze chain-a S1 report.md src/missing.ts
    assert_exit "$EXIT_USAGE" "$CODE" "freeze non-existent file → exit 2"
    cleanup
}

# ── freeze ───────────────────────────────────────────────────────────────
test_freeze_writes_rows() {
    echo "freeze writes one row per file"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts src/b.ts
    assert_exit "$EXIT_OK" "$CODE" "freeze → exit 0"
    local rows
    rows="$(grep -c $'^chain-a\tS1\t' "$QA_LEDGER")"
    [[ "$rows" == "2" ]] && pass "2 rows written" || fail "2 rows written (got $rows)"
    local expected_hash
    expected_hash="$(sha256sum src/a.ts | awk '{print $1}')"
    assert_contains "$(cat "$QA_LEDGER")" "$expected_hash" "row stores sha256 of file"
    cleanup
}

test_freeze_is_idempotent() {
    echo "freeze is idempotent per chain+stage"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts src/b.ts
    run freeze chain-a S1 qa/r2.md src/a.ts
    local rows
    rows="$(grep -c $'^chain-a\tS1\t' "$QA_LEDGER")"
    [[ "$rows" == "1" ]] && pass "re-freeze replaces old rows" || fail "re-freeze replaces old rows (got $rows)"
    run freeze chain-a S2 qa/r3.md src/b.ts
    rows="$(grep -c $'^chain-a\t' "$QA_LEDGER")"
    [[ "$rows" == "2" ]] && pass "other stage of same chain kept" || fail "other stage kept (got $rows)"
    cleanup
}

# ── status ───────────────────────────────────────────────────────────────
test_status_frozen() {
    echo "status reports FROZEN when nothing changed"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    run status
    assert_exit "$EXIT_OK" "$CODE" "all frozen → exit 0"
    assert_contains "$OUT" "FROZEN" "prints FROZEN"
    assert_contains "$OUT" "chain-a" "names the chain"
    assert_contains "$OUT" $'S1\t@-' "shows verified commit (- outside git)"
    cleanup
}

test_status_stale_on_change() {
    echo "status reports STALE when a frozen file changes"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    run freeze chain-b S1 qa/r2.md src/b.ts
    echo "// edit" >>src/a.ts
    run status
    assert_exit "$EXIT_STALE" "$CODE" "stale → exit 1"
    assert_contains "$OUT" $'STALE\tchain-a\tS1\tsrc/a.ts\tchanged' "chain-a stale with path"
    assert_contains "$OUT" $'FROZEN\tchain-b' "chain-b still frozen"
    cleanup
}

test_status_stale_on_delete() {
    echo "status reports deleted files"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    rm src/a.ts
    run status
    assert_exit "$EXIT_STALE" "$CODE" "deleted → exit 1"
    assert_contains "$OUT" "deleted" "marks deleted"
    cleanup
}

test_status_missing_chain() {
    echo "status <chain> reports MISSING for unknown chain"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    run status chain-zzz
    assert_exit "$EXIT_STALE" "$CODE" "missing → exit 1"
    assert_contains "$OUT" $'MISSING\tchain-zzz' "prints MISSING"
    run status chain-a
    assert_exit "$EXIT_OK" "$CODE" "filter by chain works"
    cleanup
}

test_status_empty_ledger() {
    echo "status on empty / absent ledger"
    new_project
    run status
    assert_exit "$EXIT_OK" "$CODE" "no ledger → exit 0 (nothing frozen yet)"
    assert_contains "$OUT" "no frozen chains" "explains empty ledger"
    cleanup
}

# ── impact ───────────────────────────────────────────────────────────────
test_impact_files() {
    echo "impact lists REVERIFY / SKIP / UNCOVERED"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    run freeze chain-b S1 qa/r2.md src/b.ts
    echo "// edit" >>src/a.ts
    run impact src/a.ts src/c.ts
    assert_exit "$EXIT_STALE" "$CODE" "something to re-verify → exit 1"
    assert_contains "$OUT" $'REVERIFY\tchain-a' "chain-a needs re-verify"
    assert_contains "$OUT" $'SKIP\tchain-b' "chain-b skipped"
    assert_contains "$OUT" $'UNCOVERED\tsrc/c.ts' "uncovered file reported"
    assert_not_contains "$OUT" $'REVERIFY\tchain-b' "chain-b not re-verified"
    cleanup
}

test_impact_nothing_touched() {
    echo "impact with untouched chains → all SKIP"
    new_project
    run freeze chain-a S1 qa/r1.md src/a.ts
    run impact src/c.ts
    assert_contains "$OUT" $'SKIP\tchain-a' "chain-a skipped"
    assert_exit "$EXIT_STALE" "$CODE" "uncovered file still → exit 1"
    run impact
    assert_exit "$EXIT_USAGE" "$CODE" "impact without files → exit 2"
    cleanup
}

test_impact_since_git_ref() {
    echo "impact --since <ref> reads git diff"
    new_project
    git init -q . && git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -qm init
    run freeze chain-a S1 qa/r1.md src/a.ts
    run freeze chain-b S1 qa/r2.md src/b.ts
    echo "// edit" >>src/b.ts
    git -c user.email=t@t -c user.name=t commit -qam edit
    run impact --since HEAD~1
    assert_contains "$OUT" $'REVERIFY\tchain-b' "chain-b from git diff"
    assert_contains "$OUT" $'SKIP\tchain-a' "chain-a skipped"
    cleanup
}

test_impact_changed_but_refrozen() {
    echo "impact: file changed since ref but frozen at current hash → SKIP"
    new_project
    echo "// edit" >>src/a.ts
    run freeze chain-a S1 qa/r1.md src/a.ts
    run impact src/a.ts
    assert_exit "$EXIT_OK" "$CODE" "already verified at current hash → exit 0"
    assert_contains "$OUT" $'SKIP\tchain-a' "chain-a skipped"
    assert_not_contains "$OUT" "REVERIFY" "no re-verify"
    cleanup
}

test_impact_ignores_docs() {
    echo "impact: docs are ignored by default, not UNCOVERED"
    new_project
    mkdir -p .proj-docs/qa .tickets docs
    run freeze chain-a S1 qa/r1.md src/a.ts
    run impact README.md .proj-docs/qa/report.md .tickets/CUI-1.md docs/guide.md .proj-docs/qa/shot.png
    assert_exit "$EXIT_OK" "$CODE" "docs only → exit 0"
    assert_not_contains "$OUT" "UNCOVERED" "no UNCOVERED for docs"
    assert_contains "$OUT" "IGNORED	5" "reports ignored count"
    cleanup
}

test_impact_frozen_doc_still_tracked() {
    echo "impact: a doc that is part of a chain (plan file) is still tracked"
    new_project
    mkdir -p .proj-docs/qa/plans
    echo "# plan" >.proj-docs/qa/plans/chain-a.md
    run freeze chain-a S1 qa/r1.md .proj-docs/qa/plans/chain-a.md src/a.ts
    echo "- more scope" >>.proj-docs/qa/plans/chain-a.md
    run impact .proj-docs/qa/plans/chain-a.md
    assert_contains "$OUT" $'REVERIFY\tchain-a' "edited plan → chain re-verify"
    cleanup
}

test_impact_ignore_file() {
    echo "impact: project ignore file adds patterns"
    new_project
    mkdir -p .proj-docs/qa tools
    printf '# comment\ntools/*\n' >.proj-docs/qa/ledger-ignore
    echo "x" >tools/gen.js
    run impact tools/gen.js
    assert_exit "$EXIT_OK" "$CODE" "ignored by project pattern → exit 0"
    assert_not_contains "$OUT" "UNCOVERED" "tools/gen.js ignored"
    cleanup
}

# ── hash fallback ────────────────────────────────────────────────────────
test_shasum_fallback() {
    echo "falls back to shasum -a 256 when sha256sum is absent"
    new_project
    local bin="$PROJECT_DIR/bin" tool
    mkdir -p "$bin"
    for tool in awk cat date dirname git grep mktemp mv rm sort tr cut uniq head wc printf sed bash env; do
        [[ -x "$(command -v "$tool")" ]] && ln -s "$(command -v "$tool")" "$bin/$tool"
    done
    ln -s "$(command -v shasum)" "$bin/shasum"
    OUT="$(PATH="$bin" "$bin/bash" "$SCRIPT" freeze chain-a S1 qa/r1.md src/a.ts 2>&1)"
    CODE=$?
    assert_exit "$EXIT_OK" "$CODE" "freeze works with shasum only"
    local expected_hash
    expected_hash="$(sha256sum src/a.ts | awk '{print $1}')"
    assert_contains "$(cat "$QA_LEDGER")" "$expected_hash" "same hash as sha256sum"
    cleanup
}

main() {
    test_usage_errors
    test_freeze_writes_rows
    test_freeze_is_idempotent
    test_status_frozen
    test_status_stale_on_change
    test_status_stale_on_delete
    test_status_missing_chain
    test_status_empty_ledger
    test_impact_files
    test_impact_nothing_touched
    test_impact_since_git_ref
    test_impact_changed_but_refrozen
    test_impact_ignores_docs
    test_impact_frozen_doc_still_tracked
    test_impact_ignore_file
    test_shasum_fallback
    echo
    echo "passed: $PASS_COUNT  failed: $FAIL_COUNT"
    [[ "$FAIL_COUNT" -eq 0 ]]
}

main
