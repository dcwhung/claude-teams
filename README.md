# claude-teams

Claude Code plugin marketplace for Donald's AI teams.

| Plugin | What it is |
|--------|------------|
| `ai-dev-team` | Virtual software house: 8 role agents, `/feature` `/fix` `/refactor` `/hotfix` `/review` `/test` `/deploy` workflow commands, TDD / git-flow / coding-style skills, branch-policy hooks. |

## Use in a project (Local **and** Cloud sessions)

Add to the project's `.claude/settings.json` (committed):

```json
{
  "extraKnownMarketplaces": {
    "claude-teams": {
      "source": { "source": "github", "repo": "dcwhung/claude-teams" }
    }
  },
  "enabledPlugins": {
    "ai-dev-team@claude-teams": true
  }
}
```

Cloud sessions do **not** install this plugin from a project's `.claude/settings.json` alone — a plugin from an external source such as this GitHub repo has to be installed explicitly — so add the two `claude plugin` commands to the cloud environment's setup script instead (see [SK-009](ai-dev-team/shared-knowledge.md)). Note that the environment snapshot caches that install: pushing a new plugin version is **not** a rebuild trigger, so cloud sessions keep silently using the cached version until you edit the setup script or the snapshot expires (~7 days). Locally, accept the install prompt on first launch (or run `claude plugin install ai-dev-team@claude-teams`).

## Layout

```
.claude-plugin/marketplace.json   ← marketplace manifest (this repo)
ai-dev-team/                      ← the plugin
  .claude-plugin/plugin.json
  agents/      commands/      skills/      hooks/      scripts/
  rules/       templates/     team.md      shared-knowledge.md
```

## QA verification ledger (v1.1.0+)

QA no longer re-verifies what has already passed and has not changed. Each verified feature chain is frozen by SHA-256 in the project's `.proj-docs/qa/verification-ledger.tsv`:

```bash
bash ai-dev-team/scripts/qa-ledger.sh impact --since develop    # REVERIFY / SKIP / UNCOVERED
bash ai-dev-team/scripts/qa-ledger.sh freeze <chain> S1 <report> <plan> <files...>
bash ai-dev-team/scripts/qa-ledger.sh status
```

Acceptance runs in three stages: S1 功能鏈驗收 (after a feature), S2 整合性驗收 (UAT), and S3 全面檢查驗收 (pre-release, automated full suite once per SHA). A finding blocks only if it is backed by all three tiers of evidence: L1 (an AC or SSoT), L2 (reproducible output), and L3 (inference that agrees with both). The rules live in `skills/sw-validation-gate/SKILL.md`. Tests: `bash ai-dev-team/scripts/qa-ledger.test.sh`.

## Developing

- Edit files under `ai-dev-team/`; test locally with `claude --plugin-dir ./ai-dev-team`.
- Bump `version` in `ai-dev-team/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, then push. Cloud picks up the new version on the next session; locally run `claude plugin update ai-dev-team`.
