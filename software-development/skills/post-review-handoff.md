# Skill：Handoff Protocol（唯一真相來源）

> **此檔案係所有 Agent handoff 嘅唯一真相來源（Single Source of Truth）。**
> 所有 command（`/feature`、`/fix`、`/refactor`、`/hotfix`、`/review`、`/test`、`/deploy`）
> 在 subagent 返回後，main agent 必須嚴格按此檔案執行 handoff。
>
> 任何其他檔案（`git-flow.md`、`code-reviewer.md`、`quality-assurance.md`、commands）
> 禁止重複定義 handoff 規則，必須 reference 本檔案。

---

## 架構前提

```
Subagent（code-reviewer / qa / devops 等）無法呼叫其他 agent。
→ Subagent 執行自己嘅職責（review / test / deploy）+ 負責執行對應 git 操作
→ Main agent 監察 subagent 返回結果，立即 invoke 下一個 agent
```

---

## 核心禁令（所有 agent 通用）

```
⛔ Subagent 禁令：
  - 禁止輸出「通知用戶」、「建議用戶執行」、「請確認是否繼續」等被動語句
  - 禁止在報告結尾問「需要繼續嗎？」、「要唔要叫 QA？」
  - 完成工作後必須在輸出中明確標註：評分 / 結果 / git 操作結果

⛔ Main agent 禁令：
  - 禁止 subagent 返回後直接輸出「完成」而不 invoke 下一個 agent
  - 禁止問用戶「要唔要繼續」、「要唔要 merge」、「要唔要 release」
  - 禁止跳過對應 handoff 步驟（例如跳過 QA 直接 deploy）
```

---

## Protocol 1：Post-Review Handoff（標準流程）

適用於 `/feature`、`/fix`、`/refactor`。

### Reviewer Subagent 必須執行

Review 完成後，code-reviewer subagent 在輸出報告前/後必須執行：

```
✅ 評分 ≥ 90 分，且無 🔴 Critical
  → 立即執行 git merge：
    git checkout develop
    git merge --no-ff [branch] -m "chore: merge [branch] into develop"
    git branch -d [branch]
  → 報告末尾輸出：
    「✅ Review 通過，評分 XX/100。已執行 merge to develop + 刪除 branch [name]。
      請 main agent 按 post-review-handoff.md invoke QA。」

⚠️ 75–89 分（有 Warning），或 ❌ < 75 分 或有 🔴 Critical
  → ⛔ 禁止 merge
  → 報告末尾輸出：
    「⚠️ Review 未通過，評分 XX/100。未執行 merge。
      請 main agent 按 post-review-handoff.md invoke Developer 修正。」
```

### Main Agent 必須執行

Reviewer subagent 返回後，main agent 立即按評分路由：

| Reviewer 返回 | Main Agent 動作 |
|--------------|----------------|
| ✅ ≥ 90 分，merge 已完成 | 立即透過 **Agent tool** invoke：<br>`subagent_type: quality-assurance`<br>`prompt: "執行 /test 驗證 develop branch，改動範圍：[branch 改動摘要]。完成後按 post-review-handoff.md Protocol 2 處理。"` |
| ⚠️ 75–89 分 | 立即透過 **Agent tool** invoke 對應 Developer：<br>`subagent_type: frontend-developer 或 backend-developer`<br>`prompt: "喺現有 branch [name] 修正以下 Warning 後重新執行 /review：W-XXX [描述]、W-YYY [描述]"` |
| ❌ < 75 分 或有 🔴 Critical | 立即透過 **Agent tool** invoke 對應 Developer：<br>`prompt: "喺現有 branch [name] 修正以下 Critical 後重新執行 /review：C-XXX [描述]"`<br>輸出：「⛔ 禁止 merge，直至 Critical 問題全部清除」 |

---

## Protocol 2：Post-QA Release（/test 後）

適用於 QA agent 完成 `/test` 之後。

### QA Subagent 必須執行

| QA 結果 | QA Subagent 動作 |
|--------|-----------------|
| ✅ 通過（無 🔴 Critical） | 1. 立即執行：`git checkout main && git merge --no-ff develop -m "chore: merge develop into main"`<br>2. 報告末尾輸出：「✅ QA 通過，已執行 develop → main merge。請 main agent 按 post-review-handoff.md invoke DevOps。」 |
| ❌ 失敗（有 🔴 Critical） | 1. 建立 QA ticket（見 `skills/ticket-management.md`）<br>2. ⛔ 禁止 merge<br>3. 報告末尾輸出：「❌ QA 失敗，已建立 ticket [CUI-XXXX]。請 main agent invoke Developer 執行 /fix。」 |

### Main Agent 必須執行

| QA 返回 | Main Agent 動作 |
|--------|----------------|
| ✅ 通過，merge 完成 | 立即透過 **Agent tool** invoke：<br>`subagent_type: devops-engineer`<br>`prompt: "執行 /deploy --env=production，改動範圍：[摘要]"` |
| ❌ 失敗 | 立即透過 **Agent tool** invoke 對應 Developer：<br>`prompt: "執行 /fix [CUI-XXXX]"` |

> ⚠️ Hotfix 後嘅 back-merge 唔經此 Protocol，由 Protocol 3 處理。

---

## Protocol 3：Hotfix Handoff（/hotfix 特殊流程，門檻 75 分）

適用於 `/hotfix`。唯一合法由 `main` 建立 branch 嘅情況。

### Reviewer Subagent 必須執行

```
✅ 評分 ≥ 75 分，且無 🔴 Critical
  → 立即執行 git merge to main：
    git checkout main
    git merge --no-ff [hotfix-branch] -m "fix: [TICKET] | merge hotfix into main"
    git branch -d [hotfix-branch]
  → 報告末尾輸出：
    「✅ Hotfix review 通過，評分 XX/100。已執行 merge to main。
      請 main agent 按 post-review-handoff.md Protocol 3 依序 invoke DevOps + QA。」

❌ < 75 分 或有 🔴 Critical
  → ⛔ 禁止 merge
  → 同 Protocol 1 Critical 處理
```

### Main Agent 必須執行（依序，唔可跳步）

Reviewer subagent 返回後：

```
Step 1: 立即透過 Agent tool invoke DevOps（立即部署）：
  subagent_type: devops-engineer
  prompt: "立即執行 /deploy --env=production，原因：hotfix [TICKET]"

Step 2: DevOps 返回後，立即透過 Agent tool invoke QA（smoke test + back-merge）：
  subagent_type: quality-assurance
  prompt: "執行 smoke test 確認 hotfix [TICKET] 修復有效。
           通過後執行 back-merge：
           git checkout develop
           git merge --no-ff main -m 'chore: sync hotfix [TICKET] back to develop'"

Step 3: QA 返回後，提示用戶：
  「⚠️ Hotfix 已完成，請開新對話執行 /start ai-dev-team --task=postmortem 進行根源分析」
```

---

## Protocol 4：Post-Deploy（/deploy 後）

適用於 DevOps agent 完成 `/deploy` 之後。

### DevOps Subagent 必須執行

```
✅ 部署成功
  → 執行 smoke test 確認關鍵 endpoint 正常
  → 監察 5–10 分鐘部署後指標
  → 報告末尾輸出部署記錄 + 「✅ Deploy 完成」

❌ 部署失敗
  → 立即執行回滾（見 skills/ci-cd.md）
  → 報告末尾輸出：「❌ Deploy 失敗，已執行回滾。請 main agent invoke Developer 處理根源。」
```

### Main Agent 必須執行

| DevOps 返回 | Main Agent 動作 |
|------------|----------------|
| ✅ 部署成功 | 輸出最終結果摘要，結束流程 |
| ❌ 部署失敗且已回滾 | 立即透過 Agent tool invoke 對應 Developer 處理根源 |

---

## 驗證 Checklist（每次 handoff 前自我檢查）

```
□ 我係 subagent 還是 main agent？
□ 我需要執行嘅 Protocol 係邊個（1/2/3/4）？
□ 我係咪已經執行咗該 Protocol 要求嘅 git 操作（如有）？
□ 我係咪已經透過 Agent tool 實際 invoke 下一個 agent（main agent 必須）？
□ 我有冇問用戶「要唔要繼續」？（❌ 禁止）
□ 我有冇跳過任何 Protocol 步驟？（❌ 禁止）
```

---

## Quick Reference

| Command | Subagent 完成後 | Main agent 動作 |
|---------|---------------|----------------|
| `/review`（標準） | Reviewer 執行 merge to develop | Invoke QA |
| `/review`（hotfix） | Reviewer 執行 merge to main | Invoke DevOps → QA |
| `/test` | QA 執行 merge to main | Invoke DevOps |
| `/deploy` | DevOps 執行 deploy + smoke test | 結束或 invoke fix |
| `/fix`, `/feature`, `/refactor` | Developer 完成 → invoke Reviewer | 按 Protocol 1 |
| `/hotfix` | Developer 完成 → invoke Reviewer | 按 Protocol 3 |
