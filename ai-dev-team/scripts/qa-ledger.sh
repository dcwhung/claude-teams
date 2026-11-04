#!/usr/bin/env bash
# qa-ledger.sh — Verification Ledger (SHA-256 freeze) for ai-dev-team QA.
#
# Records which files a verified chain covered and their SHA-256 at the time
# of verification, so later QA runs only re-verify what actually changed.
# SSoT for the rules: skills/sw-validation-gate/SKILL.md
#
# Usage:
#   qa-ledger.sh freeze <chain_id> <stage> <report> <file...>   record / replace
#   qa-ledger.sh status [chain_id]                               FROZEN / STALE / MISSING
#   qa-ledger.sh impact <file...>                                REVERIFY / SKIP / UNCOVERED
#   qa-ledger.sh impact --since <git-ref>                        same, from git diff
#
# Stages: S1 (功能鏈驗收) / S2 (整合性驗收) / S3 (全面檢查驗收)
# Ledger: $QA_LEDGER, default .proj-docs/qa/verification-ledger.tsv (run from repo root)
# Exit:   0 = all frozen / nothing to re-verify, 1 = stale / re-verify needed, 2 = usage error

set -uo pipefail

readonly EXIT_OK=0
readonly EXIT_STALE=1
readonly EXIT_USAGE=2
readonly DEFAULT_LEDGER=".proj-docs/qa/verification-ledger.tsv"
readonly VALID_STAGES="S1 S2 S3"
readonly LEDGER_HEADER=$'#chain_id\tstage\tpath\tsha256\tverified_commit\tverified_at\treport'
readonly NO_COMMIT="-"

LEDGER="${QA_LEDGER:-$DEFAULT_LEDGER}"

usage() {
    sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit "$EXIT_USAGE"
}

die_usage() { echo "qa-ledger: $1" >&2; exit "$EXIT_USAGE"; }

hash_file() { # prints sha256 of $1
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        die_usage "neither sha256sum nor shasum found"
    fi
}

current_commit() {
    git rev-parse --short HEAD 2>/dev/null || echo "$NO_COMMIT"
}

ensure_ledger() {
    [[ -f "$LEDGER" ]] && return
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || true
    echo "$LEDGER_HEADER" >"$LEDGER"
}

ledger_rows() { # data rows only (no header / comments)
    [[ -f "$LEDGER" ]] || return 0
    grep -v '^#' "$LEDGER" | grep -v '^$' || true
}

validate_path() {
    [[ "$1" == *$'\t'* || "$1" == *$'\n'* ]] && die_usage "path contains tab/newline: $1"
    [[ -f "$1" ]] || die_usage "file not found: $1"
}

# ── freeze ───────────────────────────────────────────────────────────────
cmd_freeze() {
    [[ $# -ge 4 ]] || die_usage "freeze needs <chain_id> <stage> <report> <file...>"
    local chain="$1" stage="$2" report="$3"
    shift 3
    [[ " $VALID_STAGES " == *" $stage "* ]] || die_usage "invalid stage '$stage' (use $VALID_STAGES)"
    local file
    for file in "$@"; do validate_path "$file"; done

    ensure_ledger
    local tmp commit now
    tmp="$(mktemp)"
    commit="$(current_commit)"
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    # Idempotent: drop previous rows for this chain+stage, then append fresh ones.
    awk -F'\t' -v c="$chain" -v s="$stage" '!($1 == c && $2 == s)' "$LEDGER" >"$tmp"
    for file in "$@"; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$chain" "$stage" "$file" "$(hash_file "$file")" "$commit" "$now" "$report" >>"$tmp"
    done
    mv "$tmp" "$LEDGER"
    echo "FROZEN	$chain	$stage	$# file(s) @$commit"
    return "$EXIT_OK"
}

# ── status ───────────────────────────────────────────────────────────────
row_state() { # path sha → prints "ok" / "changed" / "deleted"
    [[ -f "$1" ]] || { echo "deleted"; return; }
    [[ "$(hash_file "$1")" == "$2" ]] && echo "ok" || echo "changed"
}

cmd_status() {
    local filter="${1:-}" rows
    rows="$(ledger_rows)"
    if [[ -n "$filter" ]]; then
        rows="$(awk -F'\t' -v c="$filter" '$1 == c' <<<"$rows")"
        if [[ -z "$rows" ]]; then
            echo "MISSING	$filter	(never verified)"
            return "$EXIT_STALE"
        fi
    fi
    if [[ -z "$rows" ]]; then
        echo "no frozen chains in $LEDGER"
        return "$EXIT_OK"
    fi

    local result="$EXIT_OK" group chain stage path sha commit _rest state stale_in_group group_commit
    while IFS= read -r group; do
        stale_in_group=0
        group_commit="$NO_COMMIT"
        while IFS=$'\t' read -r chain stage path sha commit _rest; do
            group_commit="$commit" # keep a copy: the final failed `read` clears $commit
            state="$(row_state "$path" "$sha")"
            if [[ "$state" != "ok" ]]; then
                echo "STALE	$chain	$stage	$path	$state"
                stale_in_group=1
            fi
        done < <(awk -F'\t' -v g="$group" '($1 "\t" $2) == g' <<<"$rows")
        if [[ "$stale_in_group" -eq 1 ]]; then
            result="$EXIT_STALE"
        else
            echo "FROZEN	$group	@$group_commit"
        fi
    done < <(cut -f1,2 <<<"$rows" | sort -u)
    return "$result"
}

# ── impact ───────────────────────────────────────────────────────────────
changed_files_since() { # git ref → changed paths (committed + working tree)
    git rev-parse --verify --quiet "$1" >/dev/null || die_usage "unknown git ref: $1"
    { git diff --name-only "$1" HEAD; git diff --name-only; } | sort -u
}

cmd_impact() {
    [[ $# -ge 1 ]] || die_usage "impact needs <file...> or --since <ref>"
    local changed
    if [[ "$1" == "--since" ]]; then
        [[ $# -eq 2 ]] || die_usage "impact --since needs exactly one <ref>"
        changed="$(changed_files_since "$2")"
    else
        changed="$(printf '%s\n' "$@" | sort -u)"
    fi

    local rows chains reverify="" result="$EXIT_OK" file chain
    rows="$(ledger_rows)"
    chains="$(cut -f1 <<<"$rows" | grep -v '^$' | sort -u)"
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local hit
        hit="$(awk -F'\t' -v p="$file" '$3 == p {print $1}' <<<"$rows" | sort -u)"
        if [[ -z "$hit" ]]; then
            echo "UNCOVERED	$file	(not in any frozen chain → needs S1)"
            result="$EXIT_STALE"
        else
            reverify+="$hit"$'\n'
        fi
    done <<<"$changed"

    while IFS= read -r chain; do
        [[ -z "$chain" ]] && continue
        if grep -qxF -- "$chain" <<<"$reverify"; then
            echo "REVERIFY	$chain"
            result="$EXIT_STALE"
        else
            echo "SKIP	$chain	(frozen, untouched)"
        fi
    done <<<"$chains"
    return "$result"
}

main() {
    [[ $# -ge 1 ]] || usage
    local sub="$1"
    shift
    case "$sub" in
        freeze) cmd_freeze "$@" ;;
        status) cmd_status "$@" ;;
        impact) cmd_impact "$@" ;;
        -h | --help) usage ;;
        *) die_usage "unknown subcommand '$sub'" ;;
    esac
}

main "$@"
