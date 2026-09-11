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

Cloud sessions do **not** reliably install this plugin from a project's `.claude/settings.json`; add the two `claude plugin` commands to the cloud environment's setup script instead (see [SK-009](ai-dev-team/shared-knowledge.md)). Locally, accept the install prompt on first launch (or run `claude plugin install ai-dev-team@claude-teams`).

## Layout

```
.claude-plugin/marketplace.json   ← marketplace manifest (this repo)
ai-dev-team/                      ← the plugin
  .claude-plugin/plugin.json
  agents/      commands/      skills/      hooks/
  rules/       templates/     team.md      shared-knowledge.md
```

## Developing

- Edit files under `ai-dev-team/`; test locally with `claude --plugin-dir ./ai-dev-team`.
- Bump `version` in `ai-dev-team/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, then push. Cloud picks up the new version on the next session; locally run `claude plugin update ai-dev-team`.
