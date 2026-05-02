#!/usr/bin/env bash
# UserPromptSubmit hook: detect planning/design keywords in user prompts and
# inject a system instruction that nudges Claude into plan-mode behavior.
#
# Two priorities (first match wins):
#   1. Slash command  /plan or /feature  → ask user whether to run grill-me first
#   2. Keywords       plan / design / 架構 / 設計 / grill me  → enter plan mode
#
# Bypass: CLAUDE_HOOK_BYPASS_PLAN_MODE=1

set -uo pipefail

if [[ "${CLAUDE_HOOK_BYPASS_PLAN_MODE:-0}" == "1" ]]; then
  exit 0
fi

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[[ -z "$PROMPT" ]] && exit 0

# Lowercase ASCII; Chinese characters pass through unchanged.
PROMPT_LC=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')
# Pad with spaces so word-edge patterns work at start/end of string.
PADDED=" $PROMPT_LC "

# ---------------------------------------------------------------------------
# Priority 1: /plan or /feature → ask about grill-me before executing
# ---------------------------------------------------------------------------
if echo "$PADDED" | grep -qE '[^a-z]/(plan|feature)([^a-z]|$)'; then
  cat <<'EOF'
[detect-plan-mode hook] User invoked /plan or /feature.

BEFORE executing the slash command, your FIRST action MUST be to ask the user
in plain text:

  「執行之前，要唔要我先 run grill-me skill 同你 stress-test 個 plan？(y / n)」

Wait for an explicit y/n. Then:
  - y → invoke the grill-me skill first; only after the grilling concludes,
        proceed with the original /plan or /feature command.
  - n → proceed with the original command directly.

(Bypass: set env CLAUDE_HOOK_BYPASS_PLAN_MODE=1)
EOF
  exit 0
fi

# ---------------------------------------------------------------------------
# Exclusion: meta noun phrases that contain a keyword but aren't planning intent
# (e.g. "plan mode", "design pattern", "design doc", "design system").
# ---------------------------------------------------------------------------
if echo "$PROMPT_LC" | grep -qE 'plan mode|design pattern|design doc|design system|系統設計師|架構師'; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Priority 2: planning keywords → auto-enter plan mode
# ---------------------------------------------------------------------------
matched=0
if echo "$PADDED" | grep -qE '[^a-z](plan|design)([^a-z]|$)'; then
  matched=1
elif echo "$PROMPT_LC" | grep -qF 'grill me'; then
  matched=1
elif echo "$PROMPT" | grep -qE '架構|設計'; then
  matched=1
fi

if [[ "$matched" == "1" ]]; then
  cat <<'EOF'
[detect-plan-mode hook] Prompt contains planning/design keywords
(plan / design / 架構 / 設計 / grill me).

Your VERY FIRST action MUST be to call the EnterPlanMode tool. Do NOT respond
in text, search, or analyze first — enter plan mode immediately, then design
the plan inside that mode.

(Bypass: set env CLAUDE_HOOK_BYPASS_PLAN_MODE=1)
EOF
  exit 0
fi

exit 0
