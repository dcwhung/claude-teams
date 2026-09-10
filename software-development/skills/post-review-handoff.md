---
name: sw-post-review-handoff
description: Defines how main agent routes work between subagents after /review, /test, /deploy, /hotfix. Load this whenever a subagent (code-reviewer, quality-assurance, devops-engineer) returns a HANDOFF_RECEIPT, when an agent finishes its own work and needs to emit one, or when there's any uncertainty about what to do next after a review, test, or deploy. This is the Single Source of Truth for all handoff logic — if in doubt, load it.
---

# Skill：Handoff Protocol（唯一真相來源）

> **此檔案係所有 Agent handoff 嘅 Single Source of Truth。**
> 任何其他檔案禁止重複定義 handoff 規則，必須 reference 本檔案。

---

## 架構原則（Harness）

```
Subagent 只做「判斷 + 結構化 receipt」，唔做 git 操作。
Main agent 係唯一執行 git + 唯一 invoke 下一個 agent 嘅角色。
```

**點解咁設計**：

- Subagent 有 single responsibility（review 就 review，test 就 test），side effect 統一由 main agent 執行
- Git 失敗時由 main agent 處理 error recovery，唔會令 subagent context 變垃圾
- 路由邏輯集中一處，易於 audit 同更新

---

## HANDOFF_RECEIPT 格式（強制）

所有 subagent 完成工作後必須在回應最末段輸出以下 block，**唔可以缺欄，唔可以加 prose**：

````
```handoff-receipt
protocol: 1 | 2 | 3 | 4
status: pass | warn | fail
score: XX/100 | n/a
hard_gates:
  lint: pass | fail | n/a
  type_check: pass | fail | n/a
  tests: pass | fail | n/a
  coverage: "XX%" | n/a
next_action: merge_develop | merge_main | back_merge | invoke_qa | invoke_developer | invoke_devops | rollback | end
next_agent: quality-assurance | frontend-developer | backend-developer | devops-engineer | null
branch: "<current branch name>"
context: "one-line summary for next agent"
blockers:
  - "issue 1 (omit this key if none)"
```
````

> ⚠️ **格式強制要求**：必須使用 `` ```handoff-receipt `` fenced code block。禁止使用 `---` YAML delimiter 或任何其他格式——hook 係 grep `` ```handoff-receipt `` 嚟偵測，格式錯誤 = receipt 不存在。

**`next_action` 固定 enum（禁止自創值）**：

| 值 | 適用情況 |
|----|---------|
| `merge_develop` | Protocol 1 pass：merge feature branch → develop |
| `merge_main` | Protocol 2 pass：merge develop → main |
| `back_merge` | Hotfix back-merge：merge main → develop |
| `invoke_qa` | （保留，Protocol 3 Step 3 使用） |
| `invoke_developer` | 任何 fail/warn 需要 developer 修正 |
| `invoke_devops` | Protocol 2 pass 後，main agent merge 完再 invoke devops |
| `rollback` | Protocol 4 deploy fail |
| `end` | 流程正常結束 |

> ⛔ 任何不在以上 enum 嘅 `next_action`（如 `fix_and_rereview`）→ main agent 必須視為格式錯誤，按 `status=fail` 處理，唔可照單全收。

**其他規則**：

- `status=fail` 或任何 `hard_gates.*=fail` → `next_action` 禁止為 merge/invoke_qa/invoke_devops，必須係 `invoke_developer` / `rollback` / `end`
- 任何 🔴 Critical 存在 → 自動 `status=fail`，無論 score
- Main agent 讀取 receipt 後**必須按 `next_action` 執行**，唔可以自行判斷跳步

---

## Main Agent 讀取 Receipt 流程（強制）

```
0. 驗證 receipt 格式：
   - 必須係 ```handoff-receipt fenced block（唔係 --- YAML）
   - next_action 必須係 fixed enum 值
   - 任何格式錯誤 → 視為 status=fail，invoke 上一個 subagent 重新輸出
1. 解析 handoff-receipt block
2. 驗證 hard_gates：任何 fail → 強制走 fail 分支，忽略 score
2a. 驗證 status 同 next_action 一致性：
    若兩者衝突（如 status=warn + next_action=merge_develop）→ 以 status 為準，忽略 next_action
    status 對應正確 next_action：
      pass  → merge_develop / merge_main / back_merge（視 protocol）
      warn  → invoke_developer
      fail  → invoke_developer / rollback（視 protocol）
3. 執行 git 操作（見下方 Protocol 映射表）
   ↳ 失敗：停止，輸出錯誤，唔 invoke 下一個 agent
4. 按 next_action 透過 Agent tool invoke 下一個 agent
   ↳ next_agent 欄位只係參考，以 Protocol 定義為準（見下方 note）
   ↳ prompt 必須包含 receipt.context + receipt.branch + receipt.blockers
5. 禁止問用戶「要唔要繼續」
```

> ⚠️ **Receipt 驗證：status vs next_action 衝突**
> LLM 有可能輸出內部不一致嘅 receipt（高分 warn + `next_action=merge_develop`）。
> **唯一處理原則：以 `status` 為準，`next_action` 只係參考，衝突時忽略 `next_action`。**
> 例：`status=warn` + `next_action=merge_develop` → 按 `warn` 走，invoke developer subagent。

> ⚠️ **Receipt 驗證：next_agent 欄位不可靠**
> LLM 有可能輸出錯誤嘅 `next_agent` 值（如 Protocol 2 pass 後輸出 `next_agent: null`，應為 `devops-engineer`）。
> **唯一處理原則：以各 Protocol 定義嘅 next agent 為準，唔盲從 receipt 嘅 `next_agent` 欄位。**
> 例：Protocol 2 `status=pass` → 必定 invoke `devops-engineer`，即使 receipt 寫 `next_agent: null`。

> ⛔ **Main agent 核心邊界（Harness 原則）**：
> Main agent 只做 3 件事：**解析 receipt → 執行 git → 透過 Agent tool invoke subagent**。
> **禁止自己修改任何項目代碼、配置檔案、或執行任何 fix**。
> 收到 `status=fail` receipt 時，main agent 唯一動作係 invoke developer subagent，唔係自己修正問題。

---

## UI Visual Confirmation Gate（前端 UI 改動強制插入步驟）

> **適用條件**：developer subagent 完成任何涉及視覺輸出嘅前端改動後（JSX 結構、CSS/Tailwind class、layout、新組件）。
> **插入位置**：Protocol 1 — 開始 invoke Code Reviewer **之前**。
> **Design Origin 分流**：問法同對比物按 Design Origin 類型決定（見下方各分支）。

### Step V-1：啟動 dev server

```
□ 到對應 frontend 目錄：pnpm dev &
□ 等 server 就緒（port 輸出後），記下實際 port
□ 用 mcp__plugin_playwright_playwright__browser_navigate 訪問 localhost:<port>
□ 用 mcp__plugin_playwright_playwright__browser_take_screenshot 截圖
```

### Step V-2：按 Design Origin 分流確認

**origin = mockup:**
```
□ 同時展示：
    left：mockup 截圖（讀 _mockups_/<path> 對應 section）
    right：當前 UI 截圖
□ 問用戶：「Mockup @ <path> vs 當前 UI — 視覺一致嗎？Y / N / 列出 delta」
□ 用戶確認 Y → 繼續
□ 用戶列出 delta → invoke developer 修正，完成後重回 Step V-1
```

**origin = baseline:**
```
□ 展示 before / after 截圖（before 從 git stash 或 archive 取）
□ 問用戶：「Baseline vs 改後 — 視覺變化只係 spec 預期嗰啲嗎？Y / N / 列出 unexpected delta」
□ 用戶確認 Y → 繼續
□ 有 unexpected delta → invoke developer 修正
```

**origin = proposal:**
```
□ 展示：spec 入面嘅 Design Proposal 描述 + 當前 UI 截圖
□ 問用戶：「Proposal vs 實作 — 符合 design intent？Y / N」
□ 用戶確認 Y：
    ⚠️ QA 必須截 final screenshot 入 .proj-docs/design-baselines/<feature>-<date>.png
    ⚠️ 更新 spec 將 origin 升級成 baseline:（下次同一 component 用 baseline origin）
□ 用戶 N → invoke developer 修正
```

**origin = library:**
```
□ 展示：library 官方 demo（讀 docs / copy URL）+ 當前 UI 截圖
□ 問用戶：「跟 library 默認樣？有無無謂 override？Y / N」
```

**origin = none-required:**
```
□ 展示 git diff --stat（改咗幾個 file）
□ 問用戶：「實質視覺變化 = 0？確認後 skip 視覺 check。Y / N」
□ 若 N（即有視覺變化）→ Developer 必須補 Design Origin（唔可以 none-required）
```

### Step V-3：結束 dev server

```
□ pkill -f "vite" 2>/dev/null
□ 進入 Protocol 1 invoke Code Reviewer
```

### 例外（唔需要 Visual Confirmation Gate）

```
⬜ 純 TypeScript 工具函數改動（無 .tsx 組件改動）
⬜ 純測試檔案改動
⬜ 配置、常數、類型定義改動（唔影響視覺輸出）
⬜ Backend-only 改動
⬜ Developer 標注 UI_VISUAL_CONFIRMATION_REQUIRED: false
```

> ⛔ **禁止跳過此 gate**：main agent 唔可以以「tests 全過」或「reviewer 會核」為由省略視覺確認步驟。

---

## Protocol 1：Post-Review（`/feature`、`/fix`、`/refactor`）

### Reviewer Subagent

只輸出 review 報告 + receipt，**唔執行 git**。

```
判斷規則：
  hard_gates 全 pass + score ≥ 90 + 無 Critical → status=pass, next_action=merge_develop
  score 75–89（有 Warning）→ status=warn, next_action=invoke_developer
  score < 75 或有 Critical → status=fail, next_action=invoke_developer
```

### Main Agent 動作表

| receipt | Git 操作（main agent 執行） | 下一步 |
|---------|---------------------------|-------|
| `pass / merge_develop` | `git checkout develop && git merge --no-ff <branch> -m "..." && git branch -d <branch>` | **必須** Agent tool invoke `quality-assurance`，prompt 含 `context`。禁止直接結束。 |
| `warn / invoke_developer` | 無 | Agent tool invoke `frontend-developer` 或 `backend-developer`，prompt：「喺 `<branch>` 修正 Warning 後重新 /review：`<blockers>`」 |
| `fail / invoke_developer` | 無 | 同上，修正 Critical/hard gate fail。**Main agent 禁止自己修正代碼。** |

---

## Protocol 2：Post-QA Release（`/test`）

### QA Subagent

只輸出 QA 報告 + receipt，**唔執行 git**。

```
判斷規則：
  hard_gates 全 pass + 無 🔴 Critical → status=pass, next_action=merge_main
  有 🔴 Critical → status=fail, next_action=invoke_developer（並建立 CUI ticket）
```

### Main Agent 動作表

| receipt | Git 操作 | 下一步 |
|---------|---------|-------|
| `pass / merge_main` | `git checkout main && git merge --no-ff develop -m "..."` | Agent tool invoke `devops-engineer`：「執行 /deploy --env=production」 |
| `fail / invoke_developer` | 無 | Agent tool invoke 對應 Developer：「執行 /fix <CUI-XXXX>」 |

---

## Protocol 3：Hotfix（`/hotfix`，門檻 75）

### Reviewer Subagent（hotfix mode）

```
score ≥ 75 且無 Critical + hard_gates 全 pass → status=pass, next_action=merge_main
否則 → status=fail, next_action=invoke_developer
```

### Main Agent 依序動作（唔可跳步）

```
Step 1 (pass): git checkout main && git merge --no-ff <hotfix-branch>
Step 2: Agent tool invoke devops-engineer：「立即 /deploy --env=production，原因 hotfix <TICKET>」
Step 3: DevOps receipt pass 後，Agent tool invoke quality-assurance：
        「Smoke test hotfix <TICKET>。通過後執行 back-merge：
         git checkout develop && git merge --no-ff main -m '...'」
Step 4: QA receipt pass 後，提示用戶：「開新對話執行 /start ai-dev-team --task=postmortem」
```

> Back-merge conflict 處理見 `commands/hotfix.md`。

---

## Protocol 4：Post-Deploy（`/deploy`）

### DevOps Subagent

部署後執行 smoke test 同監察指標，輸出 receipt：

```
Smoke test pass + 指標正常 → status=pass, next_action=end
部署失敗或指標異常 → status=fail, next_action=rollback
```

### Main Agent 動作表

| receipt | 動作 |
|---------|------|
| `pass / end` | 輸出最終摘要，結束 |
| `fail / rollback` | 執行回滾（見 `skills/ci-cd.md`），然後 Agent tool invoke Developer 處理根源 |

---

## 核心禁令

```
⛔ Subagent 禁令：
  - 禁止執行 git merge / branch delete / push
  - 禁止輸出「請確認是否繼續」等被動語句
  - 禁止省略 handoff-receipt block
  - 禁止用 --- YAML delimiter 代替 ```handoff-receipt fenced block
  - 禁止 receipt 內加 prose 或 free-form 欄位
  - 禁止使用 next_action enum 以外的值（如 fix_and_rereview）

⛔ Main Agent 禁令：
  - 禁止收到 fail receipt 後照樣 merge / invoke 下一個 agent
  - 禁止問用戶「要唔要繼續」
  - 禁止自行跳過 Protocol 步驟
  - 禁止對 receipt 做 fuzzy 解讀（缺欄就當 fail，無效 next_action 就當 fail）
  - 禁止自己修改任何項目代碼或配置（收到 fail → 只 invoke developer subagent）
  - 禁止 Protocol 1 merge 後直接結束（必須 invoke QA）
```

---

## Edge Case：Requirements Conflict

當 Reviewer 返回 `status=fail` / `status=warn`，但 Critical / Warning 與現有需求存在明顯衝突時：

**Main agent 唯一動作**：按 receipt 執行，invoke Developer subagent
**禁止動作**：問用戶「是否需要修改需求」——呢個係 Developer + PM 嘅職責，唔係 main agent 嘅判斷範疇

Developer subagent 收到任務後：
1. 分析 Critical / Warning 描述
2. 若確認係需求定義問題（唔係實現問題），Developer 喺自己嘅 context 內升級至 PM
3. PM 釐清後，Developer 修正實現或建議需求變更
4. 完成後執行 `/review` → 輸出新 receipt 交回 main agent

> 核心原則：Main agent 係 harness，只路由，唔判斷業務邏輯。任何需求 vs 技術嘅決策都喺 subagent level 解決。

---

## 驗證 Checklist

Subagent 完成前自我檢查：

```
□ 我係 subagent — 我冇執行 git 操作？
□ 我最末段有完整 handoff-receipt block？
□ hard_gates 每個欄位都有填（唔適用就 n/a）？
□ status 同 next_action 一致（fail 唔會配 merge）？
```

Main agent 收到 receipt 後：

```
□ receipt 係 ```handoff-receipt fenced block（唔係 --- YAML）？
□ next_action 係 fixed enum 值（唔係自創）？
□ receipt 格式完整？（缺欄 → 視為 fail，唔執行下一步）
□ hard_gates 有冇 fail？（有 → 強制 fail 分支）
□ status 同 next_action 有冇衝突？（有 → 以 status 為準，見「Receipt 驗證」note）
□ next_agent 欄位有冇錯誤/缺失？（有 → 以 Protocol 定義為準，見「Receipt 驗證」note）
□ 我有冇自己修改代碼或配置？（禁止）
□ 我執行咗 git 操作（如適用）？
□ 我透過 Agent tool 實際 invoke 下一個 agent（唔係輸出文字叫用戶做）？
□ Protocol 1 pass 後有冇 invoke QA？（禁止直接結束）
```

---

## Quick Reference

| Command | Subagent 輸出 | Main agent 做 |
|---------|-------------|-------------|
| `/feature`、`/fix`、`/refactor` | Developer → /review → Reviewer receipt | Protocol 1 |
| `/test` | QA receipt | Protocol 2 |
| `/hotfix` | Reviewer receipt (hotfix mode) | Protocol 3（3 步依序）|
| `/deploy` | DevOps receipt | Protocol 4 |
