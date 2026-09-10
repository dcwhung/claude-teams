---
description: 啟動 ai-dev-team session（載入 team.md + 規則，按 --task 只載入需要嘅 agent / skill）
argument-hint: [--task=feature|fix|review|...] [--ticket=CUI-XXXX]
---

# Start AI Team

Activate the ai-dev-team with optional task scope to minimise token usage. Works identically in Local and Cloud sessions — everything lives under `${CLAUDE_PLUGIN_ROOT}` (the SessionStart hook prints the resolved path).

## Usage

```
/ai-dev-team:start
/ai-dev-team:start --task=fix --ticket=CUI-0001
/ai-dev-team:start --task=review --ticket=CUI-0001
/ai-dev-team:start --task=audit
/ai-dev-team:start --task=spec
/ai-dev-team:start --task=deploy
```

## Task → Files to Load

| --task | Agents to load | Skills / Commands to load |
|--------|---------------|--------------------------|
| (none) | team.md only | global-rules.digest.md |
| audit | architect.md, code-reviewer.md | audit.md, coding-style.md |
| spec | project-manager.md, architect.md | spec.md, functional-spec.md, technical-spec.md |
| plan | project-manager.md, architect.md | plan.md |
| feature | frontend-developer.md or backend-developer.md | feature.md, tdd.md, git-flow.md, coding-style.md |
| fix | frontend-developer.md or backend-developer.md | fix.md, tdd.md, ticket-management.md |
| review | code-reviewer.md | review.md, coding-style.md |
| test | quality-assurance.md | test.md, ticket-management.md |
| deploy | devops-engineer.md | deploy.md, ci-cd.md |
| hotfix | frontend-developer.md or backend-developer.md, devops-engineer.md | hotfix.md, git-flow.md |
| refactor | frontend-developer.md or backend-developer.md | refactor.md, tdd.md, coding-style.md |
| docs | project-manager.md | docs.md |
| postmortem | engineering-manager.md | hotfix.md |
| retrospective | engineering-manager.md | plan.md |
| escalation | engineering-manager.md, project-manager.md | — |
| governance | engineering-manager.md | — |

## Instructions

1. Parse optional `--task` / `--ticket` flags from `$ARGUMENTS`.

2. Team folder = `${CLAUDE_PLUGIN_ROOT}` (this plugin's root; the SessionStart hook prints the absolute path as "Team loaded from:"). No `.active-team` file is used — the plugin is the team.

3. Skill files are native plugin skills: prefer the **Skill tool** (namespaced: `ai-dev-team:sw-tdd`, `ai-dev-team:sw-git-flow`, ...) over `Read`. The table above lists them by short name (`tdd.md` = skill `sw-tdd`, `coding-style.md` = `sw-coding-style`, etc.). Agents are native subagents (`ai-dev-team:frontend-developer` etc.) — invoke them with the Agent tool instead of reading their `.md` into context.

4. Load files based on task scope:
   - **Always load**: project `CLAUDE.md` (if exists in cwd), `${CLAUDE_PLUGIN_ROOT}/rules/global-rules.digest.md`（SessionStart hook 已注入，唔使再 Read）
   - **Always load**: `team.md` for agent roster overview (not full agent files unless scoped)
   - **Load only** the agent files listed for the `--task`
   - **Load only** the command / skill files listed for the `--task`
   - If `--task` not provided: load digest only, then ask user what they want to do
   - If `--ticket` provided: read `.tickets/` for that ticket number and its status

5. Check `.proj-docs/index.md`:
   - Read the `**最後更新**` date at the top
   - Only read full index if updated since last session, or if `--task` is `spec` / `plan` / `audit`
   - Otherwise: skip to save tokens

6. Read `{team-folder}/shared-knowledge.md`:
   - Skip entries marked `❌ 已過期`
   - Only load entries relevant to the current `--task`

7. Confirm activation with a concise summary:
   - Team + task scope loaded
   - Agent(s) active
   - Files loaded (list)
   - Ticket context (if any)
   - index.md last updated date
   - Then ask: **今次 session 嘅目標係乜？**

---

## Task Type Enforcement（強制流程）

> 此節適用於整個 session — 唔止 `/start` 命令本身，而係 **main agent 喺 session 內任何時刻**接到新任務時都必須遵守。

### 1. 開 session 時：必須確認 task type

```
若 /start 冇 --task argument:
  □ 載入 team.md + global-rules.digest 後
  □ 唔可以直接做嘢，必須等用戶答 "今次 session 嘅目標係乜？"
  □ 收到答覆後，按下面「關鍵字 → task」對照表自動識別
  □ 識別後，先 Read 對應 task 嘅 commands/skills 檔案，再開始執行
  □ 識別有歧義時，明確問用戶：「呢個係 /feature 定 /fix?」
```

### 2. Session 進行中：每個新任務都要重新確認

```
觸發點（任何一個）：
  ✅ DevOps subagent 返回 receipt status=pass, next_action=end
  ✅ Hotfix Protocol Step 4 完成（postmortem 提示後）
  ✅ /test / /audit / /review 流程結束
  ✅ 用戶話題明顯切換（新功能、新 bug、新 ticket）

動作：
  □ Main agent 唔可假設「下一個任務同上一個係同類」
  □ 每接到新訊號（用戶訊息含關鍵字），重新識別 task type
  □ 載入唔同類型嘅 task 時，先卸載上一個 command（清晰告知用戶）
  □ 唔可以喺一條 chain 入面 mix 兩個 task type（例：feature 中途轉 hotfix）
```

### 3. 關鍵字 → Task 對照表（強制識別）

| 關鍵字（用戶訊息含其中之一） | 自動識別為 | 載入 |
|------|------|------|
| 跟進 / 繼續做 / 接住做 / 完成 | **歧義 — 必須再問**：「呢個係延續緊舊功能（/feature）、修 bug（/fix）、定 refactor？」 | — |
| 新功能 / 加 / 新增 / 加入 / implement / 開發 | `/feature` | `feature.md`, `tdd.md`, `git-flow.md`, `coding-style.md` |
| 修 / fix / 修復 / bug / error / 唔 work / 報錯 / 壞咗 | `/fix` | `fix.md`, `tdd.md`, `ticket-management.md` |
| 重構 / refactor / 重新整理 / 清理代碼 / 拆檔 | `/refactor` | `refactor.md`, `tdd.md`, `coding-style.md` |
| 改 / 修改 / 調整 / update | **歧義 — 必須再問**：「呢個係新行為（/feature）定修錯誤行為（/fix）？」 | — |
| review / 審 / 睇下 OK 唔 OK | `/review` | `review.md`, `coding-style.md` |
| 測試 / test / QA / 跑 test | `/test` | `test.md`, `ticket-management.md` |
| 部署 / deploy / push / 上線 / 出 prod | `/deploy` | `deploy.md`, `ci-cd.md` |
| 緊急 / hotfix / urgent / production down / 立即 | `/hotfix` | `hotfix.md`, `git-flow.md` |
| audit / 體檢 / 評估 codebase / 全面分析 | `/audit` | `audit.md`, `coding-style.md` |
| spec / 規格 / 需求文件 / requirements | `/spec` | `spec.md`, `functional-spec.md`, `technical-spec.md` |
| plan / 計劃 / implementation plan / 可行性 | `/plan` | `plan.md` |
| docs / README / API doc / changelog | `/docs` | `docs.md` |

> ⛔ **禁止行為**：用戶訊息含上表關鍵字但 main agent 直接做嘢、唔載入對應 command、唔開 feature/fix branch — 一律視為違反 workflow。

### 4. 強制執行 Checklist

每接到新任務訊號時，main agent 必須喺第一個回應內：

```
□ 識別 task type（引述用戶嘅關鍵字）
□ **檢查 task 數量**（見 §5 Multi-Task Detection — N ≥ 2 必須先載 parallel-dispatch.md）
□ 列出將載入嘅 command + skills
□ 執行 Read 載入對應檔案
□ 按該 command 嘅 step 1 開始執行（唔可跳到 step 5）
```

範例：

```
用戶：「跟進 UK_Salary_Summary 加個 bonus % 顯示」

Main agent：
  ✅ 識別關鍵字「加」「bonus % 顯示」→ /feature
  ✅ Task 數 = 1，唔需 parallel-dispatch
  ✅ 載入：feature.md, tdd.md, git-flow.md, coding-style.md
  ✅ [Read 對應檔案]
  → 進入 /feature step 1：讀取 shared-knowledge.md
```

### 5. Multi-Task Detection（並行調度入口）

> **強制規則**：用戶喺一個 message 列出 N ≥ 2 個獨立 task 時，main agent 唔可一個一個 serial 做。
> 必須先載入 skill `sw-parallel-dispatch`，跑 Conflict Analysis，clustered 成 lane，再 dispatch。

#### 觸發訊號（任何一個）

| 訊號 | 例子 |
|------|------|
| 用戶用 numbered list 列 task | `1. fix X<br>2. fix Y<br>3. fix Z` |
| 逗號 / 頓號分隔多 task | `修 X、改 Y、加 Z` |
| `/fix CUI-A CUI-B` 多 ticket 一齊傳 | `/fix W-003 W-004 S-007` |
| 用戶明確要求並行 | 「呢幾個一齊做」/「parallel」/「唔好一個一個」 |
| 多個 ticket 同時送來 | 「呢 3 張 ticket 一次處理」 |

#### 動作（main agent 強制）

```
□ Step 1：偵測 task 數量 N
    N = 1 → 走標準 single-task flow（fix.md / feature.md / refactor.md）
    N ≥ 2 → 載入 sw-parallel-dispatch（Skill tool 或 Read）

□ Step 2：載 parallel-dispatch.md 後，按其 Step 1（Conflict Analysis）逐對分析
    輸出 conflict matrix table

□ Step 3：按 parallel-dispatch.md Step 2 cluster 成 lane

□ Step 4：輸出 Parallel Dispatch Plan，等用戶 confirm
    （格式 + Lane Plan table 見 parallel-dispatch.md）

□ Step 5：Confirm 後按 parallel-dispatch.md Step 4 同 response 多 Agent call dispatch

□ Step 6：Sync → Batch Review → Batch QA → Batch Release（全部跟 parallel-dispatch.md）
```

#### 例外（強制 serial，唔可 parallel）

```
⛔ Hotfix（即使 N ≥ 2，hotfix.md / Protocol 3 強制 serial）
⛔ 同一 ticket 嘅多個 sub-step（仍係單一 task，非多 task）
⛔ 一條 review 提出嘅多個 review item，但 reviewer 標明咗順序依賴
```

範例：

```
用戶：「UK_Salary_Summary 三個跟進：
       1. Checksum total formula 改 AVERAGE
       2. Take Home 內容置右
       3. 數字加千位逗號」

Main agent：
  ✅ 偵測：3 個 task（numbered list） → N ≥ 2 觸發 parallel-dispatch
  ✅ 識別 task type：3 個都係 /fix（含「改」「置右」「加」隱含 bug 修正）
  ⚠️ 「改」歧義 → 用戶 confirm 為 /fix
  ✅ 載入：fix.md, tdd.md, ticket-management.md, parallel-dispatch.md
  ✅ 執行 parallel-dispatch.md Step 1：Conflict Analysis
     | Pair | 類型 | 理由 |
     | T1↔T2 | Independent | generate.js vs style.js |
     | T1↔T3 | Hard conflict | 同改 _writeTotalsRow |
     | T2↔T3 | Independent | style.js vs formatter.js |
  ✅ Lane: A=[T2], B=[T1→T3 serial]
  → 輸出 plan，等 confirm，dispatch
```
