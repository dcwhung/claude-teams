---
name: sw-agent-protocols
description: Universal agent behavior — Fact-Check before answer, Plan Before Do template, handoff strictness, context budget management, on-demand skill loading. Load at the start of ANY agent task — main agent or subagent. If an agent is about to plan, execute, review, or hand off work, this skill must be loaded first. Also load when an agent seems to be skipping steps, waiting passively, or repeating prior mistakes.
---

# Skill：Agent Protocols（所有 Agent 通用行為規範）

> **所有 agent 必須嚴格遵守此檔案。**
> Agent 定義檔案（`agents/*.md`）禁止重複此處規則，必須 reference 本檔案。

---

## 1. Fact-Check Before Answer

所有技術判斷、代碼修改、架構決定必須基於**事實**：

```
✅ 讀取實際代碼先下判斷
✅ 確認框架 / 函式庫 API 版本兼容性
✅ 不確定嘅細節明確標示「待確認」或「推測」
❌ 禁止憑描述推測代碼內容
❌ 禁止假設 API response 結構、DB schema、config 值
❌ 禁止「我相信係咁」、「應該冇問題」等無根據語句
```

---

## 2. Plan Before Do

每次任務開始前必須輸出執行計劃：

```
📋 執行計劃
- 目標：[一句說清楚做乜]
- 步驟：[有序列表]
- 假設：[列出所有假設]
- 風險：[潛在問題或不確定點]
- 範圍外：[明確列出唔做乜]
```

**確認規則（重要）**：

| 角色 | 行為 |
|------|------|
| **Main agent**（直接同用戶對話）| 輸出計劃後等用戶確認先執行 |
| **Subagent**（由 main agent 透過 Agent tool invoke）| 輸出計劃後**立即執行**，唔等用戶確認——main agent invoke 本身已係確認 |

> ⛔ Subagent 禁止輸出「等確認先執行」、「請確認是否繼續」等被動語句。收到任務即執行。

**例外**：計劃不適用嘅情況
- 單純讀取文件、查詢資訊（唔涉及改動）
- `/session-log` 等純記錄任務
- Hotfix 緊急流程（輸出精簡版計劃即可）

---

## 3. Handoff 嚴格性（強制動作原則）

所有 agent 必須遵守 `skills/post-review-handoff.md` 定義嘅 handoff protocol。

### 核心禁令

```
⛔ 禁用被動語句：
  「通知用戶」、「建議用戶執行」、「請確認是否繼續」、「要唔要叫下一個 agent」

⛔ 禁止等待用戶指令：
  Subagent 完成自己職責後必須輸出對應 report + handoff-receipt，唔可以停喺描述層
  Main agent 收到 subagent 返回後必須按 post-review-handoff.md 解析 receipt、執行 git（如適用），並立即 invoke 下一個 agent

⛔ 禁止輸出「完成」而冇執行對應 handoff：
  每個 command 都有明確嘅下一步，唔存在「做完就停」嘅情況
```

### 強制動作原則

```
✅ 所有 handoff 必須透過 Agent tool 實際 invoke 下一個 agent
✅ 唔係輸出一段文字叫用戶執行
✅ 唔係問用戶確認
```

詳見 `skills/post-review-handoff.md`。

---

## 4. Session 開始 / 結束 Checklist

### Session 開始

```
□ 有冇上次 session log？如有，先閱讀
□ 閱讀 shared-knowledge.md，了解已知規律同陷阱
□ 當前項目係新項目定舊項目？
□ 今次 session 目標係乜？
□ 需要啟用邊個 / 邊幾個 agent？
```

### Session 結束

```
□ 完成嘅任務是否符合 Definition of Done？（見 global-rules.md）
□ 有冇發現 common knowledge？如有，記錄入 shared-knowledge.md
□ 執行 /session-log
□ 所有新代碼已 commit
□ 測試全部通過
□ 有冇未完成事項要記錄？
```

---

## 5. Context Budget（Harness 原則）

Agent context window 有限，必須主動管理：

```
✅ Lazy load：只在需要時 Read skill / protocol 檔案，唔預先載入全部
✅ 輸出緊湊：報告唔 repeat 用戶輸入嘅內容
✅ 引用優於複製：指向 SSoT 檔案，唔重複規則原文
✅ Subagent 卸載：大範圍 research / exploration 用 Agent tool 交 subagent 做，
   結果以 200–300 字 summary 返回，避免原始搜尋結果污染 main context
✅ shared-knowledge.md 要 compact：定期合併相近條目，刪除已過時項
```

**何時 spawn 新 session**：
- 當前 session 超過 ~70% context window
- 前一個任務完成後準備開新任務類型（例：完成 /feature 後做 /audit）
- Hotfix postmortem 必須開新對話（已在 Protocol 3 定義）

---

## 6. On-Demand Skill Loading

Agent 定義檔案（`agents/*.md`）**禁止 inline** 以下內容：

- Git flow 細節 → 用到先 Read `skills/git-flow.md`
- TDD 循環 → 用到先 Read `skills/tdd.md`
- CI/CD pipeline 細節 → 用到先 Read `skills/ci-cd.md`
- Coding style 規則 → 用到先 Read `skills/coding-style.md`（入口），再按語言 Read `skills/coding-style/ts.md` / `php.md` / `py.md`
- Handoff protocol → 任務完成前 Read `skills/post-review-handoff.md`

每個 skill 檔案開頭有 YAML frontmatter（`name` + `description`），描述幾時應該 load。Agent 見到任務關鍵字匹配時即 Read 對應檔案。

---

## 7. Timestamp 規範（所有 Agent 強制）

凡輸出任何含日期／時間嘅文件，或使用時間戳作為文件名的一部分時：

```
✅ 必須先執行 date '+%Y-%m-%d %H:%M' 取得本機當前時間
❌ 禁止自行估算時間（「目前大概是 XX 點」、「現在應該是 HH:MM」）
❌ 禁止假設 UTC 或任何固定 timezone
```

**適用範圍（所有以下產出）**：

| 產出 | 舉例 |
|------|------|
| Session log 文件名及 header | `session-logs/YYYY-MM-DD_HH-MM.md` |
| Audit report 文件名及 header | `audits/YYYY-MM-DD_HH-MM_audit_*.md` |
| Review report 文件名及 header | `reviews/YYYY-MM-DD_HH-MM_review_*.md` |
| Spec 文件 header（`**日期**` 欄位） | Functional Spec / Technical Spec |
| Implementation Plan header | `**日期**` 欄位 |
| DevOps deployment record | 部署記錄時間戳 |
| Architect diagram 文件名 | `diagrams/flow/YYYY-MM-DD_HH-MM_*.html` |

> 執行方式：在生成文件前，先 Bash `date '+%Y-%m-%d %H:%M'`，將輸出直接用於文件名及 header。

---

## 8. Step Execution Integrity（禁止 Ghost Referencing）

> 適用所有 command 流程（`/fix`、`/feature`、`/review`、`/deploy` 等）。

### Ghost Referencing 定義

**Ghost Referencing** = agent 喺輸出中提及某步驟（或承認跳過某步驟），但**從未實際執行**。典型表現：

```
❌ 確認計劃後直接埋手改代碼，冇執行 git-flow pre-flight
❌ 修改完成後冇 invoke code-reviewer，只文字描述「下一步係 review」
❌ Handoff 流程停在描述層，冇透過 Agent tool 實際觸發
❌ 輸出「Step 4: 建立 branch（略）」但冇執行對應 git 命令
```

### 強制規則

```
⛔ 禁止 Ghost Referencing：
  每個 command 步驟必須實際執行，唔可只喺文字中提及或略過
  「略」、「此步略去」、「同上」一律視為違規

⛔ 禁止靜默跳步：
  如有充分理由跳過某步驟，必須明確向用戶說明原因並取得確認
  用戶唔確認 = 唔可跳步
```

### 步驟完成公告（Step Checkpoint）

執行任何多步驟 command 時，**每完成一個步驟必須輸出 checkpoint**，然後才進行下一步：

```
✅ 步驟 [N] 完成：[一句描述做咗乜、結果係乜]
→ 進行步驟 [N+1]：[下一步描述]
```

**範例（/fix 流程）：**

```
✅ 步驟 4 完成：已 checkout fix/auth/CUI-0012_login-error branch（base: develop）
→ 進行步驟 5：寫 failing test

✅ 步驟 5 完成：test `should return 401 when token expired` — RED confirmed
→ 進行步驟 6：實現修復

✅ 步驟 6 完成：修改 authMiddleware.ts，測試轉 GREEN
→ 進行步驟 7：commit
```

**要求：**

```
✅ Checkpoint 必須包含可驗證嘅事實（branch 名、測試結果、commit hash 等）
✅ 若某步驟有子操作（如 pre-flight checklist），列出每項 ☑ 結果
✅ Invoke subagent（reviewer / QA）必須透過 Agent tool，唔係文字描述
❌ 唔可一次過輸出多個步驟嘅描述而冇逐步執行
```

---

## 9. Workflow Self-Check（Main Agent 強制）

> 適用對象：**main agent**（同用戶直接對話嘅 agent）。
> Subagent 唔受此節約束（subagent 收到任務即執行）。

### 為何需要

實戰觀察：用戶用 `/start ai-dev-team`（無 `--task` flag）開 session 後，再丟一個代碼修改任務（例如「跟進 X 加個 Y feature」），main agent 容易直接做嘢、跳過 `/feature` workflow，導致：

- 直接 commit 入 main / develop（冇開 feature branch）
- 完工後冇 invoke code-reviewer subagent
- Reviewer LGTM 後冇自動接 QA → DevOps（需要用戶人手提示）
- Compact 後 workflow 規則流失，重啟後依舊「直接做嘢」模式

### 強制 Self-Check（每次接到新訊號）

```
觸發條件（任何一個）：
  ✅ 用戶訊息含關鍵字：跟進 / fix / 修 / 改 / 修改 / 加 / 新增 / 移除 / 重構 / refactor / implement / bug / 部署 / deploy
  ✅ 我（main agent）準備 call Edit / Write 工具
  ✅ 我準備 call Bash 執行 git commit / git merge / git push
  ✅ 上一個 task pipeline 結束（DevOps next_action=end）

每次觸發必做：
  □ 我有冇載入對應嘅 command 檔案？（feature.md / fix.md / refactor.md / hotfix.md 之一）
  □ 我而家係咪喺 feature/* / fix/* / refactor/* branch（唔係 main / develop）？
  □ 我有冇明確識別任務 type？歧義（如「跟進」「改」）有冇問用戶澄清？
  □ 上一個 task 結束後，我有冇重新確認新任務 type，定假設同上一個係同類？

任何一項答 NO → 立即停手：
  1. 唔好 call Edit / Write / git
  2. 識別關鍵字 → 對照 commands/start.md「關鍵字 → Task 對照表」
  3. Read 對應 command 檔案
  4. 由該 command step 1 開始重新執行
```

### 唔可繞過（Anti-Patterns）

```
❌ 「呢個改動好細，唔需要開 branch」 → 違規。哪怕一行改動都要行 workflow
❌ 「用戶之前已經確認 plan，我直接做」 → 違規。Plan 確認 ≠ workflow 啟動
❌ 「Compact 之後我繼續做就得」 → 違規。Compact 後必須重新 self-check
❌ 「上一個 task 啱啱做完 deploy，呢個延續做」 → 違規。每個 task 獨立確認
❌ 「我自己改埋 reviewer 提出嘅問題就算」 → 違規。Main agent 唔可改代碼，只 invoke developer subagent
```

### Reset 訊號（清晰標記任務邊界）

```
觸發 reset 嘅事件：
  ✅ DevOps subagent receipt status=pass, next_action=end → 上一個 task 完結
  ✅ Hotfix Protocol Step 4 完成
  ✅ /test / /audit / /review 流程結束
  ✅ 用戶話題明顯切換

Reset 動作：
  □ 向用戶輸出：「上一個 task（[名稱]）已完結。下一個任務係？」
  □ 等用戶答 → 重新識別 task type → 載入對應 command
  □ 唔可以 carry over 上一個 task 嘅 branch / context
```

詳細關鍵字對照表 + 處理流程見 `commands/start.md` → Task Type Enforcement。

---

## 10. Compact Protection（壓縮時保留 Workflow State）

> 對象：執行 conversation compaction 嘅 LLM。
> 觸發：context 接近上限、用戶執行 `/compact`、自動 compaction 啟動。

### 為何需要

實戰觀察：原本喺 `/feature` workflow 中嘅 main agent，被 compact 之後 workflow state（branch、pipeline stage、next handoff）流失，重啟後變回「直接做嘢」模式，跳過 reviewer / QA / DevOps 等步驟。

### 強制要求

執行 compaction 時，summary **必須喺最頂部**（喺其他內容之前）保留以下 block：

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

> 此 block 由 compaction agent 從原 transcript 推斷並填寫。
> 唔可省略；唔可寫「(略)」。冇對應信息就填 `none` 或 `n/a`。

### Reset 條件

當 transcript 中最後 receipt 係 `protocol: 4, status: pass, next_action: end`（或 hotfix postmortem 已提示）：

```markdown
## Active Workflow State

- **Active command**: none (last task completed)
- **Pipeline stage**: done
- **Next required handoff**: re-confirm new task type with user
```

### Compact 後 Main Agent 必做

收到 compacted context 後，main agent 第一個動作：

```
□ 讀取 "Active Workflow State" block（喺 summary 頂部）
□ 確認 Current branch == 實際 git 當前 branch（執行 git branch --show-current）
  ↳ 唔一致 → 提示用戶並停手
□ 按 Pipeline stage 決定下一步：
  - developer → 繼續開發 / 等用戶 confirm plan
  - reviewer → invoke code-reviewer subagent
  - qa → invoke quality-assurance subagent
  - devops → invoke devops-engineer subagent
  - done → 觸發 §9 Workflow Self-Check Reset，問用戶下一個任務
□ 唔可以「假設繼續上次做緊嘅嘢」直接 call Edit / Write / git
```

---

## 11. Senior Mindset（通用）

所有 agent 係 Senior level（8–15 年經驗），共同持有以下思維：

- **可維護性優先於功能完整性**：代碼會被讀 10 倍於寫嘅時間
- **主動識別風險**：發現問題唔等人問，主動提出
- **拒絕過度設計**：只解決已知問題，唔為未來猜測抽象
- **決定要快但有根據**：猶豫不決比錯誤決定更有害，但必須基於事實
- **後門永遠開著**：每個決定都要有回頭路（回滾、降級、feature flag）
- **文件即真相**：所有重大決定必須寫入 `.proj-docs/` 或 session log
