# ai-dev-team — Hard Rules（永遠生效，唔可省略）

> 由 plugin SessionStart hook 每次 session 自動注入（Local 同 Cloud 一致）。
> 詳細規則喺 pointer 指向嘅檔案；此處只係 entry-point 提醒。
> 設立原因：observed failure mode — rule 散落 3+ 處，main agent 仍會因 token 壓力或 compaction 跳步。

## 1. Git Workflow — 禁止直接動 protected branch
- ❌ 唔可喺 `main` / `master` / `develop` 直接 commit / Edit / Write
- ❌ 唔可 force push protected branch、唔可 `git reset --hard` protected branch
- ✅ 永遠 checkout `feature/` / `fix/` / `refactor/` branch 先動手
- 機制：`hooks/branch-policy.sh`（PreToolUse 階段：Bash + Edit + Write 三層 hard block，exit 2）
- 詳細：`rules/global-rules.md` §Git 規範、skill `sw-git-flow`

## 2. Auto-Handoff — Agent 之間禁止等用戶確認
- ❌ Reviewer pass 後唔可停低問「要唔要 invoke QA？」
- ✅ 直接 invoke 下一個 agent；只有 fail / merge conflict / explicit blocker 先停
- 詳細：`team.md` §跨 Agent 協作規則 #6 + skill `sw-post-review-handoff`

## 3. Claude Code 平台限制（已踩過嘅坑，唔好再踩）
- Hook input 經 **stdin JSON**，唔係 env var → SK-003
- `~/.claude/` 寫入有 hardcoded「editing own settings」guard，需要 skip-write-if-unchanged workaround → SK-006
- `permissionDecision: "ask"` **唔被 Claude Code 尊重**；硬 block 必須用 `exit 2` → SK-007
- `/clear` 係 UI-layer command，Claude **唔可程序觸發**
- Cloud session **只讀 repo 入面嘅 `.claude/`**；`~/.claude/` 嘅 settings / skills / CLAUDE.md 全部唔會帶過去 → 所以規則由 plugin 注入
- 詳細：`shared-knowledge.md` SK-003 / SK-006 / SK-007

## 4. Design-Source Binding Rule — UI 任務必須綁 mockup / baseline / proposal
- ❌ 任何 `*.tsx`、`*.jsx`、`*.css`、`*.scss` 改動，PR description 冇 `Design Origin:` 行 → Reviewer 必須 reject
- ❌ 用 `none-required` 但 diff 有新 className / layout → reject
- ✅ 五種合法 origin：`mockup:` / `baseline:` / `proposal:` / `library:` / `none-required`（附 Why）
- 觸發原因：2026-05-17 life-travels 前端同 mockup 完全唔符（黑色地球、錯誤字體、文案全錯）
- 詳細：`rules/global-rules.md` §Design-Source Binding Rule、skill `sw-coding-style-css`

## 5. Compact Protection（Conversation Compaction 強制規則）

執行 compaction（用戶觸發 `/compact` 或 context 自動壓縮）時，summary **必須在最頂部** 包含以下 block：

```markdown
## Active Workflow State

- **Active command**: /feature | /fix | /refactor | /hotfix | /test | /audit | none
- **Source branch**: <e.g. develop or main>
- **Current branch**: <e.g. feature/foo/bar>
- **Pipeline stage**: developer | reviewer | qa | devops | done
- **Next required handoff**: <next agent + action, or "user input" / "n/a">
- **Latest receipt**: <protocol N, status pass/warn/fail, or "none yet">
- **Open blockers**: <list, or "none">
```

唔可省略；無對應 info 就填 `none` / `n/a`。詳細規則見 skill `sw-agent-protocols` §10。

> **為何重要**：observed failure mode — main agent 喺 `/feature` workflow 中段被 compact，summary 只記得「業務改動」，workflow state 流失，重啟後直接 commit 入 main / 跳過 reviewer。此規則為 D 層守衛。

## 6. 讀取優先順序
1. Project `CLAUDE.md` — 項目專屬設定，永遠覆蓋全局
2. `team.md` — 團隊定義
3. `rules/global-rules.md` — 全局行為規範（digest 已注入，詳細按需 Read）
