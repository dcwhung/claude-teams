#!/usr/bin/env bash
# SessionStart hook (ai-dev-team plugin)
#
# Cloud sessions never read ~/.claude/CLAUDE.md or ~/.claude/global-rules.md,
# so the plugin injects the always-on rules itself: hard rules + global-rules
# digest + where the full team files live. Local sessions get the same text,
# which keeps Local and Cloud behaviour identical.
#
# Bypass: CLAUDE_HOOK_BYPASS_SESSION_START=1

set -uo pipefail

if [[ "${CLAUDE_HOOK_BYPASS_SESSION_START:-0}" == "1" ]]; then
  exit 0
fi

# stdin carries the hook JSON; drain it so the pipe never blocks.
cat >/dev/null 2>&1 || true

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

cat <<HDR
[ai-dev-team plugin] Team loaded from: ${ROOT}
- Team roster / SSoT map: ${ROOT}/team.md
- Full global rules:      ${ROOT}/rules/global-rules.md
- Shared knowledge (SK-*): ${ROOT}/shared-knowledge.md
- Start a scoped session:  /ai-dev-team:start [--task=feature|fix|review|...]
Agents are native subagents (ai-dev-team:code-reviewer etc.). Skills load via the Skill tool (sw-tdd, sw-git-flow, ...).

HDR
cat "${ROOT}/rules/hard-rules.md"
echo
cat "${ROOT}/rules/global-rules.digest.md"
exit 0
