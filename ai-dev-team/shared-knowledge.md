# Shared Knowledge Log

> 跨 Agent、跨 Session 嘅共享知識庫。
> 任何 agent 發現 common knowledge 時，必須按格式記錄於此。
> 每個 session 開始前必須閱讀此檔案。

---

## 使用指引

### 何時記錄
- 發現項目特有技術規律或約定
- 發現常見錯誤模式或陷阱
- 發現跨模組嘅共用邏輯
- 發現第三方庫嘅重要限制或 workaround
- 發現環境或部署嘅特殊注意事項
- 發現業務邏輯中容易誤解嘅規則

### 記錄格式

```markdown
## [SK-XXX] [標題]

**日期**：YYYY-MM-DD HH:MM
**來源 Agent**：[agent 名稱]
**類別**：技術規律 / 錯誤模式 / 業務規則 / 環境注意 / 平台限制 / 其他
**適用 Agent**：全部 / [指定 agent]
**有效期至**：YYYY-MM-DD / 永久（技術升級或問題解決後請更新）

**內容**：
[詳細描述]

**適用場景**：
[哪些任務需要注意]

**參考**：
[相關檔案或連結]

---
```

### 更新過時條目
如發現條目內容有誤或過時，在條目頂部加入：

```markdown
> ⚠️ 已更新：YYYY-MM-DD HH:MM，原因：[說明]
```

如條目完全失效，加入：

```markdown
> ❌ 已過期：YYYY-MM-DD HH:MM，原因：[說明]（保留作歷史參考，請勿跟從）
```

---

## 定期 Review 規則

**每個 session 開始時**：
- 閱讀所有條目，留意 `有效期至` 欄位
- 發現過期條目，立即標記 `❌ 已過期` 並說明原因

**每月一次**（或項目有重大升級時）：
- PM 或 Architect 主導 review 所有條目
- 確認仍然有效嘅條目，更新 `有效期至` 日期
- 標記失效條目

**觸發即時 review 嘅情況**：
- 更新第三方庫主版本
- 更換框架或 ORM
- 數據庫升級
- 任何 agent 發現某條目描述嘅問題已不存在

---

## 知識條目

> 此區域存放跨 agent、跨 session 嘅共享知識。
> 項目特有嘅技術規律應記錄於對應項目嘅 `CLAUDE.md` 或項目級 shared-knowledge，唔應存入此檔案。

---

## [SK-012] Rate limit（429）中斷 subagent 後：worktree + branch 完整保留，用 SendMessage 續返原 agent

**日期**：2026-09-11 15:40
**來源 Agent**：Main Agent（uno-games parallel-dispatch Round 1 / Round 2）
**類別**：平台限制 / 恢復流程
**適用 Agent**：Main Agent（任何用 Agent tool + `isolation: worktree` 跑 lane 嘅 session）
**有效期至**：永久

**內容**：
Session usage limit 觸發時，所有 background subagent 同時收到 429 並以 `status=failed` 結束，但：
- `.claude/worktrees/agent-<id>/` 同佢 checkout 咗嘅 task branch **唔會被清**（Agent tool 只自動清「無改動」worktree）
- Subagent 嘅 transcript 保留，`SendMessage({to: '<agentId>'})` 可以帶住完整 context 續返（實測：Lane A 由 Red spec commit + 未 commit 嘅 Green 改動位置繼續，零重覆工作）

**恢復流程（main agent）**：
```
□ git worktree list + git branch --list → 對每個 failed lane 判斷：
    有 commit / 有未 commit 改動 → SendMessage 續原 agent（prompt 講明 worktree path、branch、已有 commit、未 commit 檔案）
    branch 同 develop tip 一樣（零進度）→ git worktree remove --force + git branch -D，全新 Agent call
□ 同一 response 發晒全部 SendMessage + Agent call，保持並行
□ Compact Protection block 要列出每個 lane 嘅 branch + 最後 commit，reset 後先可以做上面判斷
```

**禁止**：
- 唔檢查就全部重新 dispatch（會撞 One-Task-One-Branch pre-flight，且浪費已完成嘅 Red spec）
- 用 `git worktree prune` 一刀切（會連有進度嘅 worktree 都清走）

**參考**：uno-games session 2026-09-10 / 09-11：兩次 429，第一次 5 lane 全部重來（只 Lane A 有進度 → resume），第二次 3 agent（2 個 resume + 1 個重開）。

---

## [SK-011] branch-policy hook 對 compound Bash command 按「當前 branch」判斷，`checkout -b X && git commit` 會被誤 block

**日期**：2026-09-11 00:30
**來源 Agent**：Main Agent（uno-games）
**類別**：平台限制 / hook 行為
**適用 Agent**：Main Agent、所有 developer subagent
**有效期至**：直至 hook 改為解析 command 內嘅 `checkout` 為止

**內容**：
`hooks/branch-policy.sh` 喺 PreToolUse 讀 `git rev-parse --abbrev-ref HEAD`（執行**前**嘅 branch）再 grep command string 有冇 `git commit`。所以喺 `develop` 上發一條 `git checkout -b chore/x develop && ... && git commit ...` 會被 block（exit 2），即使 commit 實際會落喺 `chore/x`。

**正確做法**：
- 拆兩個 Bash call：第一個只 `git checkout -b <branch>`，第二個先做改動 + commit
- 或 subagent 喺 worktree 內用 `git checkout -b <branch> develop`（worktree 初始 branch 係 `worktree-agent-*`，唔係 protected，所以唔會撞）

**相關**：merge 入 protected branch 用 `git merge --no-ff <branch> -m "..."` 唔會被 block（command 無 `git commit` 字串），呢個係 main agent sync 嘅正常路徑。

---

## [SK-010] 由 protected branch untrack 檔案（`git rm --cached`）後 merge 會將檔案從 working tree 刪走

**日期**：2026-09-11 00:35
**來源 Agent**：Main Agent（uno-games，跟 sw-git-flow `.gitignore` baseline untrack `CLAUDE.md` / `.claude/` / `.proj-docs/`）
**類別**：錯誤模式 / git 行為
**適用 Agent**：Main Agent（任何執行 git-flow 初始化嘅 agent）
**有效期至**：永久

**內容**：
Observed sequence：
1. `develop` 上 `CLAUDE.md` 係 tracked
2. `git checkout -b chore/gitignore` → `git rm -r --cached CLAUDE.md .claude .proj-docs` + 加 `.gitignore` → commit（檔案仍喺 disk ✅）
3. `git checkout develop`：develop 仍 track 呢啲檔案，git 由 develop tree 還原（仍喺 disk）
4. `git merge --no-ff chore/gitignore`：merge 帶入「刪除 tracked 檔案」嘅 diff → git **從 working tree 刪走** `CLAUDE.md`、`.claude/settings.json`、成個 `.proj-docs/`

`--cached` 只保護 step 2 嗰次操作，唔保護之後嘅 merge。

**恢復**：`git restore --source=<有檔案嘅 commit> --worktree -- <paths>`（唔 stage；之後 `git status --ignored` 應顯示 `!!`）。

**正確流程**：untrack 前先 `cp -r` 備份到 repo 外，或 merge 後即刻由 `main` / 舊 commit restore；`.proj-docs/` 入面嘅 audit / review / QA 報告係唯一副本，冇備份就會永久丟失（今次因為 `main` 上仲有 PR #2 嘅版本先救得返）。

**第二次發生（2026-09-11 15:35，同一 session）**：untrack 只喺 `develop` 做咗，`main` 仍 track 住。Release `git checkout main && git merge --no-ff develop` 再次刪走 `CLAUDE.md`、`.claude/settings.json`、`.proj-docs/audits/*`、`diagrams/*`、`index.md`（連帶 W-030 對 CLAUDE.md 嘅本地改動、reviewer / QA append 入 index.md 嘅條目）。**規則：untrack 之後，每個仍 track 住呢啲檔案嘅 long-lived branch（`main`）第一次收到 merge 都會刪；merge 完必須即刻 `git restore --source=<舊 commit> --worktree` 並重做本地改動。** 更穩妥係喺 `.gitignore` chore 同一日 release 到 `main`，或者先備份成個 `.proj-docs/` + `CLAUDE.md` 到 repo 外。

**後果要同用戶講清楚**：untrack `CLAUDE.md` + `.claude/settings.json` 之後，(a) subagent worktree 唔會有 `CLAUDE.md`（要喺 prompt 指定主 checkout 絕對路徑），(b) cloud session 唔會自動裝 plugin（`.claude/settings.json` 唔入 repo）。

---

## [SK-009] Cloud session 唔會自動裝 project 聲明嘅 plugin——唯一可靠解法係 environment setup script

**日期**：2026-09-11 00:20
**來源 Agent**：Main Agent（claude-teams `/fix` session）
**類別**：平台限制
**適用 Agent**：全部（尤其 DevOps / 任何維護 plugin marketplace 嘅 agent）
**有效期至**：永久（v2.1.195 起嘅 documented behavior，非 bug；若官方統一兩頁矛盾文檔再覆核）

**內容**：

**先講清楚文檔狀態：兩頁官方文檔互相矛盾，以 `discover-plugins` 為權威。** 部分文檔（含本條目上一版所依據嘅段落）令人以為 project `.claude/settings.json` 嘅 `extraKnownMarketplaces` + `enabledPlugins` 會喺 session start 自動裝 plugin；但 `discover-plugins` → *Configure team marketplaces* 明確講相反：

> "As of Claude Code v2.1.195, adding the marketplace doesn't install plugins that come from an external source, on any path that loads plugins. A plugin that only the project's `.claude/settings.json` enables, and that comes from an external source such as a GitHub repository or npm package, doesn't load until the team member installs it. Until then, Claude Code reports the plugin as not installed and shows the `claude plugin install` command to run."

即係話：本條目觀察到嘅行為**唔係 bug、唔係 cloud 專屬缺陷**，而係 v2.1.195 起嘅 documented intended behavior——external source（GitHub repo / npm）嘅 plugin 只由 project settings 啟用時，喺**任何**載入 plugin 嘅路徑都唔會自動裝，要等使用者自己 install。我哋當初當成「文檔寫明會自動裝但實測唔成立」，其實係讀錯咗權威文檔。症狀係 `/ai-dev-team:start` 回 `Unknown command`。

2026-09-10 至 09-11 喺 Python-Project-Run365Days 逐項排除（全部實測）：
- Repo 由 private 轉 public、開全新 session → **仍然失敗**。private 唔係原因；文檔亦明講 cloud session 可存取「連接嘅 GitHub 帳戶睇到嘅任何 repo」。
- 喺 cloud session 內手動跑 `claude plugin marketplace add` + `claude plugin install` → **成功**（HTTPS clone 正常）。即網絡、認證、marketplace 可達性全部冇問題。
- 但 session 中途安裝**當時唔會令 slash command 生效**。官方口徑（`discover-plugins` → *Install plugins*）：「The `claude plugin install` shell command doesn't run in a session, so Claude Code loads the plugins it installs the next time you start Claude Code, or when you run `/reload-plugins` in a session that's already open.」即係要下次啟動、或者喺當前 session 跑 `/reload-plugins`。我哋當時冇試 `/reload-plugins`，所以以下關於 `/reload-plugins` 嘅內容係**引文檔、未實測**：
    - 需要 Claude Code v2.1.260+；可喺無 interactive terminal 嘅 session 用（desktop app、Agent SDK、`-p` 非互動模式）。
    - ⚠️ 「The command runs only when you type it directly into the session… When you send it over a remote connection instead, such as Remote Control or a relayed chat message, the command declines without reloading anything.」——**本次 session 正正中咗呢個限制**：我哋用 `SendMessage` 將指令送入 cloud session，屬 relayed message，即使當時打 `/reload-plugins` 都會被拒、唔會 reload。
    - Reload **唔會** connect / disconnect plugin MCP server。
    - 另外，session 內嗰次安裝唔會帶入下一個 session（見下面 environment caching）。
- claude.ai 帳戶層加 marketplace + plugin（synced plugins，Customize → Plugins → Add → Add marketplace，再喺 Discover 撳 Add）→ 加得成功，但開全新 session **仍然失敗**。
- 加 environment **setup script** → **成功**。Team folder 解析為 `/root/.claude/plugins/cache/claude-teams/ai-dev-team/1.0.3`，即係 marketplace 安裝生效，唔係 synced 路徑。

**因果強度：setup script 已驗證係 sufficient，未驗證係 necessary。** 加 setup script 同時改變兩樣嘢：
1. 真正加入 `claude plugin marketplace add` + `claude plugin install` 命令；
2. **強制重建 environment cache snapshot**——按官方 caching 文檔，setup script 一改就係重建 trigger。

即係「加 setup script」同「換新 snapshot」兩個變數綁埋一齊，無法分離。連帶後果：上面「private 唔係原因」同「claude.ai synced plugin 無效」兩項結論，全部係喺**同一個舊 snapshot** 下觀察到嘅（所有所謂「全新 session」都由該舊 snapshot 開機），所以嚴格只成立於該舊 snapshot，唔可以當成普遍結論。

**Discriminating test（未做）**：將 setup script 改成一個 no-op（例如 `echo noop`）——只觸發 cache 重建、唔安裝任何 plugin——再開全新 session。若仍然失敗 → 安裝命令係真因；若突然成功 → 舊 snapshot 本身係污染源。

**適用場景**：
為任何 project 設定 cloud session 使用 ai-dev-team（或任何自有 plugin）時。

**正確處理**：
- 喺 cloud environment 加 setup script（claude.ai/code 訊息輸入框上面嗰行嘅環境 chip → 齒輪；**Settings 入面冇呢個位，亦冇直接 URL**）：

```bash
claude plugin marketplace add <owner>/<repo>
claude plugin install <plugin>@<marketplace>
```

- Setup script 喺 Claude Code 啟動**之前**執行，寫落磁碟嘅嘢會入環境快取，所以 plugin 喺 command 註冊嗰刻已經存在。
- 改 setup script 亦會迫環境快取重建；`resume` 一個現有 session 永遠唔會重跑 setup script，所以驗證必須開**全新** session。
- ⚠️ **版本 staleness（cloud 會靜默用舊 plugin 版本）**：按 `#environment-caching`，setup script 只喺第一次 session 跑，跑完影快照，之後**新** session 直接 skip setup script step；只有 (a) 改 setup script、(b) 改 allowed network hosts、(c) 快照約七日過期，三者之一才會重建。**「push 新 plugin 版本上 marketplace」唔係重建 trigger**，所以 cloud session 會繼續用快照內嗰個舊版本，而且完全冇錯誤提示。要拿到新版本：手動改一下 setup script（任何改動即可，例如加/改一行註釋）強制重建，或者等快照過期（約七日）。本機唔受影響（`claude plugin update ai-dev-team` 即時生效）。
- Project `.claude/settings.json` 嘅聲明可以保留（本機有效），但**唔可以當佢喺 cloud 會生效**。
- 診斷：cloud 冇 `/plugin` command，睇唔到 Errors tab；只可展開「Initialized session」面板，入面 `Run setup script` 一行亦係加 setup script 嘅入口。
- Marketplace repo 是否必須 public **未驗證**——今次修好時 repo 已經係 public。

**參考**：
- https://code.claude.com/docs/en/discover-plugins#configure-team-marketplaces（權威：external-source plugin 唔會自動裝）
- https://code.claude.com/docs/en/discover-plugins#install-plugins（安裝何時生效）
- https://code.claude.com/docs/en/discover-plugins#apply-plugin-changes-without-restarting（`/reload-plugins` 同其限制）
- https://code.claude.com/docs/en/cloud-environments#setup-scripts
- https://code.claude.com/docs/en/cloud-environments#environment-caching
- https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup
- https://code.claude.com/docs/en/plugins-reference#synced-plugins

---

## [SK-008] `detect-plan-mode` UserPromptSubmit hook 會被 background subagent 通知誤觸發

**日期**：2026-09-10 23:28（原 uno-games session 發現，carry-over 時補記）
**來源 Agent**：Main Agent（uno-games `/audit` session）
**類別**：平台限制 / 錯誤模式
**適用 Agent**：Main Agent（所有用 Agent tool 跑 background subagent 嘅 session）
**有效期至**：直至 hook 加入 notification 過濾為止

**內容**：
`hooks/detect-plan-mode.sh`（UserPromptSubmit）用關鍵字（plan / design / 架構 / 設計 / grill me）判斷用戶想 plan。但 background subagent 完成時嘅 `<task-notification>` 同樣經 UserPromptSubmit 流入，內容係 Architect / Reviewer 嘅報告，必然含「架構」「設計」字眼 → hook 每次都要求 main agent 「VERY FIRST action MUST be EnterPlanMode」。

實際觀察（uno-games `/audit`，2026-09-10）：兩個 subagent 各返一次 notification，hook 兩次都 fire。用戶已 confirm `/audit` plan，而 plan mode 係 read-only，會阻止寫 `.proj-docs/` 報告。

**適用場景**：
Main agent 用 Agent tool 跑 background subagent、收到 task-notification 時。

**正確處理**：
- Notification 頂部有 `[SYSTEM NOTIFICATION - NOT USER INPUT]` 標記 → 唔係用戶 prompt，hook 訊號視為 false positive。
- Main agent **唔進入 plan mode**，繼續當前已確認嘅 workflow，並喺回覆入面一句話向用戶交代點解忽略 hook。
- 只有真正嘅用戶訊息含關鍵字先跟 hook。

**修正方向（待做）**：
`detect-plan-mode.sh` 讀 stdin JSON 嘅 prompt 時，若含 `[SYSTEM NOTIFICATION - NOT USER INPUT]` 或 `<task-notification>` 即 `exit 0`。

**參考**：
- `hooks/detect-plan-mode.sh`、`hooks/hooks.json`
- SK-003（hook 經 stdin JSON）、SK-007（hook 只有 exit 2 係硬 block；呢個 hook 係 exit 0 + 文字指令，所以 main agent 可判斷後忽略）

---

## [SK-007] PreToolUse Hook `permissionDecision: ask` 無效——唯一可靠 block 係 `exit 2`

**日期**：2026-05-02 01:00
**來源 Agent**：Main Agent（project-boundary.sh 修復 session，2026-05-02 00:52）
**類別**：技術規律 / Claude Code 架構行為
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為，除非官方加入 permissionDecision 支持）

**核心發現**：

PreToolUse hook 透過 stdout 輸出 `{"hookSpecificOutput":{"permissionDecision":"ask",...}}` + exit 0，**Claude Code 不響應呢個 JSON 字段，直接放行操作**。

呢個行為係 Claude Code 架構層面嘅限制，唔係 hook 腳本邏輯錯誤。

**可靠的 block 方式**：

```bash
# ✅ 唯一可靠：exit 2 硬 block
echo "BLOCKED: [reason]" >&2
exit 2

# ❌ 無效：permissionDecision: ask（+ exit 0）
echo '{"hookSpecificOutput":{"permissionDecision":"ask","message":"..."}}'
exit 0
```

**含義**：

Hook 系統唔支持「軟性詢問用戶」模式。設計 hook 時只有兩種選擇：
1. **放行**：exit 0
2. **硬 block**：exit 2（Claude Code 停止操作，顯示 stderr 訊息）

**已實施**：

`project-boundary.sh` 已由 `permissionDecision: ask` + exit 0 改為 exit 2 硬 block（2026-05-02 00:47），並加入 `CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1` bypass 選項。

**適用場景**：

- 設計任何 PreToolUse hook 時，唔好嘗試用 `permissionDecision` 做「軟性」攔截
- 如需阻止操作，直接用 exit 2；如唔需阻止，用 exit 0
- 需要「詢問用戶」效果時，喺 hook 錯誤訊息內提示用戶手動設置 bypass 變數

**參考**：

- `~/.claude/hooks/project-boundary.sh`（已實施 exit 2 block）
- Session log：`2026-05-02_00-52_team.md` §備注（SK-007 建議）

---

## [SK-006] `~/.claude/` 寫入嘅「editing its own settings」hardcoded guard

**日期**：2026-05-01 23:55
**來源 Agent**：Main Agent（今次 session 兩次失敗 + Option D workaround 驗證）
**類別**：技術規律 / Claude Code 架構行為
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為，除非官方移除 guard）

**核心發現**：

Claude Code 對 `~/.claude/` 路徑下嘅寫入操作（至少包括 dot-file，例如 `.active-team`）有 **hardcoded permission guard**，獨立於普通 sensitive-file 判定。觸發時 prompt 提供三個選項：

```
Do you want to overwrite .active-team?
  1. Yes
  2. Yes, and allow Claude to edit its own settings for this session
  3. No
```

**Option 2 嘅文字「allow Claude to edit its own settings」係 dead giveaway** — Claude Code 將呢類路徑歸類為「Claude 嘅 settings」，獨立於普通 file write，並且：

- ❌ `permissions.allow` 加 `Write(/Users/.../.active-team)` exact-match rule 都 override 唔到（已驗證 — fresh session 仍彈）
- ❌ `permissions.additionalDirectories` 加 `~/.claude` 都 override 唔到
- ❌ Write tool 嘅 sandbox 豁免唔包含呢類 path

**已驗證無效嘅嘗試（請勿重複）**：

| 嘗試 | 結果 |
|------|------|
| 喺 `~/.claude/settings.json` 加 `Write(/Users/donald91103/.claude/.active-team)` 入 allow list | ❌ 仲彈 prompt（fresh session 都試過） |
| 依賴 `additionalDirectories` 包含 `/Users/donald91103/.claude` | ❌ 仲彈 prompt |
| 用 Write tool（avoid Bash） | ❌ 仲彈 prompt（Bash 撞另一條 sensitive-file 規則，但 Write 都唔 bypass guard） |

**Workaround（已實施於 `commands/start.md` step 3）**：

**Skip-Write-If-Unchanged pattern** — 如內容唔變就唔好調用 Write tool：

```
3a. Read 目標 file
3b. 比較內容 vs 目標值
    ✅ 一致 → 完全跳過 Write，輸出「已係最新（skipped）」
    ⚠️ 唔一致 / file 不存在 → Write（首次/切 team 會彈一次 prompt，accept 一次解決）
```

**設計意圖**：

- 99% 情況（同一機 re-invoke 同一 team / 內容無變）→ **完全唔彈 prompt**
- 1% 情況（首次安裝 / 切 team / 內容真係變）→ 彈一次，acceptable one-time cost

**適用場景**：

- 任何 command 設計需要持久化少量 state 入 `~/.claude/` 嘅情境
- 設計新 slash command 時，避免「永遠 Write」嘅 pattern，改用 skip-write-if-unchanged 或搬出 `~/.claude/`
- 設計 hook / persistent flag 時優先考慮 read-then-compare-then-conditional-write

**禁止行為**：

- ❌ 用 Bash redirect 寫 `~/.claude/` 內 dot-file（撞另一條 sensitive-file guard，永遠彈）
- ❌ 喺 settings.json 加 `Write(...)` allow rule 嚟「修」呢個 prompt — 已驗證無效，只係 cosmetic clutter
- ❌ 假設「下次 session restart 後就好」— guard 係 hardcoded，唔受 session restart 影響

**參考**：

- `~/.claude/commands/start.md` step 3（skip-write-if-unchanged 邏輯實施）
- 觸發此知識嘅 session：2026-05-01_23:30 起連續兩次失敗 → Option D workaround
- 上次 session log 嘅 SK-006 草稿（已被今次驗證結果取代）

---

## [SK-006] 設計原則 — UI Logic 必須先問 utils/service 層有冇

**日期**：2026-05-07 00:45
**來源 Agent**：Main Agent
**類別**：業務規則 / 設計原則
**適用 Agent**：全部（尤其 frontend-developer, code-reviewer）
**有效期至**：永久

**內容**：
新增 UI component logic 前，必須先問：「呢個 grouping / ordering / transformation / computation 係咪已經喺 utils 或 service layer 存在？」

Data 嘅 grouping、ordering、prefix stripping、label formatting 等屬 **domain logic**，應住喺 `utils/` 或 `services/`，唔係 component。

**實際案例（Life-Moments-Suite）**：
`UpcomingMilestonesCard` 最初直接喺 component 內用 `entryMap` 手動做 entryId grouping + kind ordering + prefix stripping，結果：
- 邏輯重複（`mergeSameDay` 在 `utils/milestones.ts` 已實現相同邏輯）
- 輸出唔一致（component 用 `rawMilestones` 排序，`MilestoneTimeline` 用 `allMilestones`）
- Bug：label 順序錯誤（`#48 months | #4 years` 而非 `#4 years | #48 months`）

正確做法：component 接收已由 utils 處理好嘅 `Milestone[]`，直接讀 `subLabelsZh/En`。

**適用場景**：
- 喺 UI component 寫任何超過 2 行嘅 data transformation 前
- Code review 見到 component 內有 sorting / grouping / string manipulation 時，問：「呢個邏輯係咪應該喺 utils 度？」
- 設計新 component interface 時，優先問 upstream 可否提供已處理好嘅 data，而唔係由 component 自己處理 raw data

**參考**：
- `the_moments/frontend/src/utils/milestones.ts` — `mergeSameDay()`, `finalizeMilestone()`, `stripSharedPrefix()`
- `the_moments/frontend/src/components/milestone/upcoming-milestones-card/UpcomingMilestonesCard.tsx`
- CUI-0014 / CUI-0015 session (2026-05-07)

---

## [SK-005] Workflow Bypass — `/start` 無 task 時 main agent 跳過 /feature 流程

**日期**：2026-05-01 13:08
**來源 Agent**：Main Agent（自我覆盤）
**類別**：錯誤模式 / 流程缺陷
**適用 Agent**：Main Agent（所有開 ai-dev-team session 嘅 main agent）
**有效期至**：永久（已加入四層守衛 A/B/C/D 至 2026-05-01）

**內容**：

實際 session 觀察到嘅 failure mode：

1. 用戶用 `/start ai-dev-team`（無 `--task` argument），只 load `team.md` + digest
2. 用戶後續訊息「跟進 X 加個 Y feature」— 含 feature 關鍵字但 main agent 冇識別
3. Main agent 直接做嘢，**完全跳過 `/feature` workflow**：
   - 喺 `main` branch 上開始改代碼（冇開 feature/* branch）
   - 改完冇 invoke code-reviewer subagent
   - Reviewer LGTM 後冇自動接 QA → DevOps，反而問用戶「要唔要 merge?」
   - QA pass 後冇自動接 DevOps deploy
4. Compact 觸發後，workflow 規則完全消失，重啟後 main agent 仍是「直接做嘢」模式

**根本原因**：

| 層級 | 缺失 |
|---|---|
| 入口 | `/start` 無 task 時冇關鍵字識別機制 |
| 行為 | `agent-protocols.md` 無「接到改動任務前 self-check workflow 載入」嘅規則 |
| 系統 | 冇 PreToolUse hook 攔截「直接 commit 入 main / develop」 |
| 持續 | Compact instruction 冇要求保留 workflow state |

**修正（已實施 2026-05-01）**：

四層守衛：

- **A（入口）**：`commands/start.md` 加「Task Type Enforcement」+「關鍵字 → Task 對照表」。Main agent 必須喺第一個回應內識別關鍵字、載入對應 command、由 step 1 開始執行。
- **B（行為）**：`agent-protocols.md` §9 Workflow Self-Check — 接到任何改動訊號前，必須通過 4 項 checklist；任何一項 NO 立即停手。
- **C（系統）**：`~/.claude/hooks/branch-policy.sh` PreToolUse hook — 阻擋直接 commit 入 main/develop、force push、reset --hard 等操作。繞行需明確 bypass。
- **D（持續）**：`agent-protocols.md` §10 Compact Protection — compaction 時必須在 summary 頂部保留 `Active Workflow State` block。`~/.claude/CLAUDE.md` 同 `global-rules.digest.md` 都有 pointer。

**適用場景**：

- 任何 main agent 接到代碼修改任務嘅情境
- Compact 之後重啟 — 必須讀 `Active Workflow State` 再行動
- 一個 session 內連續做多個 task — 每個 task 邊界都要 reset 同 re-confirm

**禁止行為**：

- 「呢個改動好細，唔開 branch」→ 違規
- 「用戶 confirm 咗 plan，我直接做」→ 違規（plan ≠ workflow 啟動）
- 「上一個 task 啱啱完，呢個延續做」→ 違規（每個 task 獨立 self-check）
- Main agent 自己改代碼回應 reviewer 提出嘅問題 → 違規（必須 invoke developer subagent）

**參考**：

- `commands/start.md` § Task Type Enforcement
- `skills/sw-agent-protocols/SKILL.md` §9（Workflow Self-Check）+ §10（Compact Protection）
- `~/.claude/hooks/branch-policy.sh`
- `~/.claude/CLAUDE.md` § Compact Protection
- 觸發此知識嘅 session：UK_Salary_Summary v1.3.0 + P0 bonus % feature flow

---

## [SK-004] Coverage 數字唔等於 TDD 執行

**日期**：2026-04-18
**來源 Agent**：Engineering Manager（HF-001 Post-mortem）
**類別**：錯誤模式
**適用 Agent**：Code Reviewer、Developer
**有效期至**：永久（直至 global-rules.md 正式納入為止）

**內容**：
測試覆蓋率 ≥ 80% 係 hard gate，但 **coverage 數字唔能證明 TDD 流程有執行**。開發者可以先寫實現、後補測試，照樣通過 coverage 門檻。HF-001 根本原因正是如此：錯誤邏輯在無失敗測試保護下合入代碼庫。

**Code Reviewer 必須額外驗證**：
- PR 中有失敗測試（Red）先於實現代碼的 commit 紀錄
- 若無明確紀錄，應要求開發者說明 TDD 執行過程
- 數學/計算邏輯必須覆蓋：正正、正負、負負、零值、浮點邊界

**試行規則位置**：`agents/code-reviewer.md` → TDD 執行驗證 section（試行 2 個 sprint 後評估推至 `global-rules.md`）

**適用場景**：
- 所有涉及數值計算、條件邏輯、狀態轉換嘅 PR
- 任何新功能/修復嘅 code review

**參考**：
- `.proj-docs/audits/2026-04-18_HF-001_postmortem_em.md`

---

## [SK-003] Claude Code Hooks 透過 stdin 傳入 JSON，唔係環境變數

**日期**：2026-04-16 23:00
**來源 Agent**：Main Agent（Hooks 實際觸發驗證 session）
**類別**：技術規律
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為）

**內容**：
Claude Code hooks 唔使用 `$CLAUDE_TOOL_INPUT_*` 環境變數。Tool input 係透過 **stdin 以 JSON 格式**傳入 hook 進程。

stdin JSON 結構：
```json
{
  "session_id": "...",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "tool_response": { ... },
  "tool_use_id": "...",
  "cwd": "...",
  "permission_mode": "..."
}
```

環境變數只有三個：`CLAUDE_CODE_ENTRYPOINT`、`CLAUDE_PROJECT_DIR`、`PWD`。

**正確讀取方式**（用 `jq` 直接讀 stdin）：
```bash
# ✅ 正確
file=$(jq -r '.tool_input.file_path // empty')
cmd=$(jq -r '.tool_input.command // empty')

# ❌ 錯誤：環境變數不存在，永遠是空
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# ❌ 錯誤：echo "$var" 會損毀長 JSON（含特殊字符時）
raw=$(cat); echo "$raw" | jq ...
```

**Hook 輸出可見性**：
- Hook 以 exit 0 退出時，輸出只顯示給用戶終端（Claude 看不到）
- Claude Code TUI 佔用終端時，hook 輸出不可見
- 驗證 hook 是否觸發：用 `>> /tmp/hook.log` 寫入 log 檔再讀取

**適用場景**：
- 編寫任何 PostToolUse hook 命令時
- 調試 hook 唔觸發嘅問題時

**參考**：
- `skills/sw-hooks/SKILL.md`（已更新示例）
- 項目 `.claude/settings.local.json`（已驗證配置）

---

## [SK-002] Hooks 只在對應項目目錄啟動嘅 Session 生效

**日期**：2026-04-16 22:00
**來源 Agent**：Main Agent（P1-B hooks 驗證 session）
**類別**：環境注意
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為）

**內容**：
項目級 hooks（`.claude/settings.local.json` 或 `.claude/settings.json`）只喺 Claude Code session 從**該項目目錄**啟動時才載入同觸發。如果 session 嘅 working directory 係其他位置，hook 唔會自動執行。

驗證方式：
- Hook 命令本身邏輯正確（手動執行有效）
- 但 `PostToolUse` hook 唔喺 tool result 出現
- 原因：session 嘅 primary working directory 唔係項目根目錄

**適用場景**：
- 為項目配置 hooks 後，必須用 `claude` CLI 喺**項目根目錄**開啟 session 先能驗證
- 跨目錄 session（如從 team config 目錄操作項目代碼）無法觸發項目級 hooks

**參考**：
- `skills/sw-hooks/SKILL.md`

---

## [SK-001] §9 Step Execution Integrity — Subagent Checkpoint 壓縮行為

**日期**：2026-04-16 21:30
**來源 Agent**：Main Agent（P0 驗證 session）
**類別**：錯誤模式
**適用 Agent**：全部
**有效期至**：永久（直至 hook 層防護上線或規則更新）

**內容**：
§9 Step Execution Integrity 規則（`skills/sw-agent-protocols/SKILL.md`）成功防止 Ghost Referencing，但 subagent 有另一個系統性傾向：執行完所有步驟後，一次性輸出 summary table，而唔係每步完成後即時輸出 `✅ 步驟 [N] 完成：[可驗證結果]`。
- Steps 9–10（最後幾步）有明確 checkpoint 輸出
- Steps 1–8 被壓縮成一張 summary table

呢個行為唔係 Ghost Referencing（工作確實有執行），而係「延遲 checkpoint 輸出」pattern。規則層防護唔足以強制逐步輸出，需要 hook 層補強。

**適用場景**：
- 審查 subagent 返回結果時，summary table 係合格但非理想輸出
- 設計 hook 層防護時，目標係偵測缺失中間 checkpoint，唔單止最終結果
- 評估 P1 hooks.md 配置優先順序

**參考**：
- `skills/sw-agent-protocols/SKILL.md` §9 Step Execution Integrity
- `global-rules.md` Agent 行為準則

---
