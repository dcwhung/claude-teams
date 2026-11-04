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
#                                                                (vs worktree: staged + untracked too)
# Paths: repo-relative; `./` and `//` are normalized, absolute or `..` paths are rejected.
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
readonly DOUBLE_SLASH="//"
readonly DEFAULT_IGNORE_FILE=".proj-docs/qa/ledger-ignore"
# Docs never need QA (T0); a doc that IS in a chain (e.g. its frozen plan) is still tracked.
readonly DEFAULT_IGNORE_PATTERNS=('*.md' '.proj-docs/*' '.tickets/*' 'docs/*' '.claude/*' '.gitignore' '*/.gitignore' '.git-blame-ignore-revs' 'LICENSE*' 'licenses/*')

LEDGER="${QA_LEDGER:-$DEFAULT_LEDGER}"
IGNORE_FILE="${QA_LEDGER_IGNORE:-$DEFAULT_IGNORE_FILE}"

usage() {
    sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
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

validate_field() { # label value → die if the value would break the TSV row
    [[ "$2" == *$'\t'* || "$2" == *$'\n'* ]] && die_usage "$1 contains tab/newline: $2"
    return 0
}

normalize_path() { # path → repo-relative form git prints; die on absolute / `..`
    local p="$1"
    validate_field "path" "$p"
    while [[ "$p" == *"$DOUBLE_SLASH"* ]]; do p="${p//$DOUBLE_SLASH//}"; done
    while [[ "$p" == ./* ]]; do p="${p#./}"; done
    [[ "$p" == /* ]] && die_usage "absolute path not allowed (use repo-relative): $1"
    [[ "/$p/" == */../* ]] && die_usage "path must not contain '..': $1"
    [[ -z "$p" || "$p" == "." ]] && die_usage "empty path: $1"
    printf '%s\n' "$p"
}

normalized_files() { # must_exist(0|1) file... → unique normalized paths, in input order
    local must_exist="$1" file norm seen=""
    shift
    for file in "$@"; do
        norm="$(normalize_path "$file")" || exit "$EXIT_USAGE"
        [[ "$must_exist" == "1" && ! -f "$norm" ]] && die_usage "file not found: $file"
        grep -qxF -- "$norm" <<<"$seen" && continue
        seen+="$norm"$'\n'
        printf '%s\n' "$norm"
    done
}

# ── freeze ───────────────────────────────────────────────────────────────
cmd_freeze() {
    [[ $# -ge 4 ]] || die_usage "freeze needs <chain_id> <stage> <report> <file...>"
    local chain="$1" stage="$2" report="$3"
    shift 3
    [[ " $VALID_STAGES " == *" $stage "* ]] || die_usage "invalid stage '$stage' (use $VALID_STAGES)"
    validate_field "chain_id" "$chain"
    validate_field "report" "$report"
    local files file tmp commit now count
    files="$(normalized_files 1 "$@")" || exit "$EXIT_USAGE"

    ensure_ledger
    tmp="$(mktemp)"
    commit="$(current_commit)"
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    # Idempotent: drop previous rows for this chain+stage, then append fresh ones.
    awk -F'\t' -v c="$chain" -v s="$stage" '!($1 == c && $2 == s)' "$LEDGER" >"$tmp"
    while IFS= read -r file; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$chain" "$stage" "$file" "$(hash_file "$file")" "$commit" "$now" "$report" >>"$tmp"
    done <<<"$files"
    mv "$tmp" "$LEDGER"
    count="$(grep -c '' <<<"$files")"
    echo "FROZEN	$chain	$stage	$count file(s) @$commit"
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
changed_files_since() { # git ref → changed paths (committed + staged + unstaged + untracked)
    git rev-parse --verify --quiet "$1" >/dev/null || die_usage "unknown git ref: $1"
    # `<ref>` vs worktree covers committed + staged + unstaged; --no-renames keeps the old
    # path of a rename so its frozen row shows up as deleted → REVERIFY (W-902).
    { git diff --name-only --no-renames "$1"; git ls-files --others --exclude-standard; } | sort -u
}

ignore_patterns() { # default doc patterns + project ignore file (one glob per line, # comments)
    printf '%s\n' "${DEFAULT_IGNORE_PATTERNS[@]}"
    [[ -f "$IGNORE_FILE" ]] && grep -v '^[[:space:]]*#' "$IGNORE_FILE" | grep -v '^[[:space:]]*$'
    return 0
}

is_ignored() { # path patterns → 0 if any glob matches (`*` also matches `/`)
    local pattern
    while IFS= read -r pattern; do
        # shellcheck disable=SC2053  # intentional glob match
        [[ -n "$pattern" && "$1" == $pattern ]] && return 0
    done <<<"$2"
    return 1
}

stale_chains_for() { # ledger rows for one path → chain ids whose frozen hash no longer matches
    local chain stage path sha _rest
    while IFS=$'\t' read -r chain stage path sha _rest; do
        [[ "$(row_state "$path" "$sha")" != "ok" ]] && echo "$chain"
    done <<<"$1"
}

impact_changed_paths() { # impact args → normalized, unique changed paths
    if [[ "$1" == "--since" ]]; then
        [[ $# -eq 2 ]] || die_usage "impact --since needs exactly one <ref>"
        changed_files_since "$2"
        return
    fi
    local changed
    changed="$(normalized_files 0 "$@")" || exit "$EXIT_USAGE"
    sort -u <<<"$changed"
}

report_chains() { # chains reverify → REVERIFY / SKIP lines; returns 1 if any REVERIFY
    local chain result="$EXIT_OK"
    while IFS= read -r chain; do
        [[ -z "$chain" ]] && continue
        if grep -qxF -- "$chain" <<<"$2"; then
            echo "REVERIFY	$chain"
            result="$EXIT_STALE"
        else
            echo "SKIP	$chain	(frozen, untouched)"
        fi
    done <<<"$1"
    return "$result"
}

cmd_impact() {
    [[ $# -ge 1 ]] || die_usage "impact needs <file...> or --since <ref>"
    local changed rows chains reverify="" result="$EXIT_OK" file ignored_count=0 patterns hit_rows
    changed="$(impact_changed_paths "$@")" || exit "$EXIT_USAGE"
    rows="$(ledger_rows)"
    chains="$(cut -f1 <<<"$rows" | grep -v '^$' | sort -u)"
    patterns="$(ignore_patterns)"
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        hit_rows="$(awk -F'\t' -v p="$file" '$3 == p' <<<"$rows")"
        if [[ -n "$hit_rows" ]]; then
            # Changed since <ref> but already re-frozen at the current hash → nothing to do.
            reverify+="$(stale_chains_for "$hit_rows")"$'\n'
        elif is_ignored "$file" "$patterns"; then
            ignored_count=$((ignored_count + 1))
        else
            echo "UNCOVERED	$file	(not in any frozen chain → needs S1)"
            result="$EXIT_STALE"
        fi
    done <<<"$changed"
    [[ "$ignored_count" -gt 0 ]] && echo "IGNORED	$ignored_count	(docs / ledger-ignore patterns)"
    report_chains "$chains" "$reverify" || result="$EXIT_STALE"
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
