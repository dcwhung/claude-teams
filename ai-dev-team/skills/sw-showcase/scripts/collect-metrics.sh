#!/usr/bin/env bash
# collect-metrics.sh — 由 git history + repo 檔案收集 showcase 開發數字，輸出 JSON（stdout）
#
# 用法：collect-metrics.sh [repo-dir]   （預設：當前目錄）
#
# 數字來源（SSoT，見 SKILL.md §開發數字）：
#   active_days / date range → git log --all 嘅 author date（distinct 日子）
#   commits                  → git log --all
#   merged_prs               → distinct "Merge pull request #N"
#   ai_sessions              → distinct claude.ai/code/session_* URL（commit trailer）
#   version                  → package.json → APP_VERSION 常數 → 最新 tag
#   tests                    → 測試檔數 + it(/test( 數 + assert( 數
#   tokens                   → .claude/usage/*.json（usage-logger hook）+ .proj-docs/showcase/manual-metrics.json
#
# 淺 clone 會令數字偏細 → 自動嘗試 unshallow；失敗就喺 JSON 標 shallow: true。

set -uo pipefail

REPO_DIR="${1:-.}"
cd "$REPO_DIR" || { echo "repo dir not found: $REPO_DIR" >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo: $REPO_DIR" >&2; exit 1; }

TEST_FILE_REGEX='(\.(test|spec)\.[cm]?[jt]sx?$|[-_]test\.(js|ts|py)$|(^|/)test_[^/]+\.py$)'
EXCLUDE_DIRS_REGEX='(^|/)(node_modules|dist|build|\.git|vendor)/'
USAGE_DIR='.claude/usage'
MANUAL_METRICS_FILE='.proj-docs/showcase/manual-metrics.json'

if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
  git fetch --unshallow --quiet >/dev/null 2>&1 || true
fi
IS_SHALLOW=$(git rev-parse --is-shallow-repository)

COMMIT_DATES=$(git log --all --format=%ad --date=short)
FIRST_DATE=$(printf '%s\n' "$COMMIT_DATES" | sort | head -1)
LAST_DATE=$(printf '%s\n' "$COMMIT_DATES" | sort | tail -1)
ACTIVE_DAYS=$(printf '%s\n' "$COMMIT_DATES" | sort -u | grep -c .)
COMMITS=$(git rev-list --all --count)
MERGED_PRS=$(git log --all --format=%s | grep -oE '^Merge pull request #[0-9]+' | sort -u | grep -c . || true)
AI_SESSIONS=$(git log --all --format=%B | grep -oE 'claude\.ai/code/session_[A-Za-z0-9]+' | sort -u | grep -c . || true)
TAGS=$(git tag | grep -c . || true)

detect_version() {
  if [[ -f package.json ]]; then
    jq -r '.version // empty' package.json && return
  fi
  local const_hit
  const_hit=$(grep -rhoE "APP_VERSION\s*=\s*['\"][0-9]+\.[0-9]+\.[0-9]+['\"]" --include='*.js' --include='*.ts' . 2>/dev/null \
    | grep -v node_modules | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  if [[ -n "$const_hit" ]]; then echo "$const_hit"; return; fi
  git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//'
}
VERSION=$(detect_version)

TEST_FILES=$(git ls-files | grep -Ev "$EXCLUDE_DIRS_REGEX" | grep -E "$TEST_FILE_REGEX" || true)
TEST_FILE_COUNT=$(printf '%s\n' "$TEST_FILES" | grep -c . || true)
count_in_tests() {
  [[ -z "$TEST_FILES" ]] && { echo 0; return; }
  printf '%s\n' "$TEST_FILES" | tr '\n' '\0' | xargs -0 grep -ohE "$1" 2>/dev/null | grep -c . || true
}
TEST_CASES=$(count_in_tests '\b(it|test)(\.each\([^)]*\))?\(')
ASSERTIONS=$(count_in_tests '\b(assert|ok)\(|\bexpect\(')

sum_usage() {
  local total=0
  if compgen -G "$USAGE_DIR/*.json" >/dev/null; then
    total=$(jq -s '[.[].total_tokens // 0] | add' "$USAGE_DIR"/*.json)
  fi
  echo "$total"
}
LOGGED_TOKENS=$(sum_usage)
MANUAL_TOKENS=null
if [[ -f "$MANUAL_METRICS_FILE" ]]; then
  MANUAL_TOKENS=$(jq '.tokens // null' "$MANUAL_METRICS_FILE")
fi

jq -n \
  --arg repo "$(basename "$(git rev-parse --show-toplevel)")" \
  --arg remote "$(git remote get-url origin 2>/dev/null | sed -E 's|//[^/@]*@|//|' || true)" \
  --arg first "$FIRST_DATE" --arg last "$LAST_DATE" \
  --argjson activeDays "$ACTIVE_DAYS" --argjson commits "$COMMITS" \
  --argjson prs "$MERGED_PRS" --argjson sessions "$AI_SESSIONS" --argjson tags "$TAGS" \
  --arg version "$VERSION" \
  --argjson testFiles "$TEST_FILE_COUNT" --argjson testCases "$TEST_CASES" --argjson assertions "$ASSERTIONS" \
  --argjson loggedTokens "$LOGGED_TOKENS" --argjson manualTokens "$MANUAL_TOKENS" \
  --argjson shallow "$IS_SHALLOW" \
  '{
    repo: $repo, remote: $remote, version: $version,
    first_commit: $first, last_commit: $last, active_days: $activeDays,
    commits: $commits, merged_prs: $prs, ai_sessions: $sessions, tags: $tags,
    tests: { files: $testFiles, cases: $testCases, assertions: $assertions },
    tokens: { logged: $loggedTokens, manual: $manualTokens,
              display: (if $manualTokens != null then $manualTokens elif $loggedTokens > 0 then $loggedTokens else null end) },
    shallow: $shallow
  }'
