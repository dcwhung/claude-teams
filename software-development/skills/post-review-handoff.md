# Skill：Post-Review Handoff

> **單一真相來源**。所有 command（`/fix`、`/feature`、`/refactor`、`/hotfix`）在
> code-reviewer subagent 返回後，main agent 必須嚴格按此檔案執行 handoff。
>
> ⚠️ **架構限制**：subagent 無法呼叫其他 agent。
> Reviewer subagent 負責執行 git 操作（merge / branch delete）；
> **main agent 負責監察 Reviewer 結果並 invoke 下一個 agent。**

---

## 標準流程（`/fix`、`/feature`、`/refactor`）

```
Reviewer 返回後，main agent 立即執行：

1. 讀取 Reviewer 返回的評分及 git 操作結果

2. 按評分路由：

   ✅ ≥ 90 分，且無 🔴 Critical，且 merge 已完成
   → 立即透過 Agent tool 呼叫 QA agent：
       subagent_type: quality-assurance
       prompt: "執行 /test 驗證 develop branch，改動範圍：[branch 改動摘要]"

   ⚠️ 75–89 分（有 Warning），或 merge 未完成
   → 立即透過 Agent tool 呼叫對應 Developer agent，要求修正後重新 /review

   ❌ < 75 分 或有 🔴 Critical
   → 立即透過 Agent tool 呼叫對應 Developer agent，要求修正所有 Critical
   → 輸出：「⛔ 禁止 merge，直至 Critical 問題全部清除」

3. QA agent 返回後，按 Post-QA Release Protocol 跟進（同樣由 main agent 執行）
```

> ⛔ **main agent 禁令**：
> - 禁止 Reviewer 返回後直接輸出「完成」而不 invoke 下一個 agent
> - 禁止問用戶「要唔要叫 QA」、「需要繼續嗎」

---

## Hotfix 特殊流程（`/hotfix`，門檻 75 分）

```
Reviewer 返回後，main agent 立即執行：

1. 讀取 Reviewer 返回的評分及 git 操作結果

2. 按評分路由：

   ✅ ≥ 75 分，且無 🔴 Critical，且 merge to main 已完成
   → 依序透過 Agent tool invoke：

     a. DevOps agent（立即部署）：
        subagent_type: devops-engineer
        prompt: "立即執行 /deploy，target=production，原因：hotfix [TICKET]"

     b. QA agent（smoke test + back-merge）：
        subagent_type: quality-assurance
        prompt: "執行 smoke test 確認 hotfix [TICKET] 修復有效，
                 完成後執行 back-merge：
                 git checkout develop && git merge --no-ff main
                 -m 'chore: sync hotfix [TICKET] back to develop'"

   ❌ < 75 分 或有 🔴 Critical
   → 立即透過 Agent tool 呼叫對應 Developer agent，要求修正後重新 /review
   → 輸出：「⛔ 禁止 merge，直至 Critical 問題全部清除」
```

> ⛔ **main agent 禁令**：
> - 禁止 Reviewer 返回後直接輸出「完成」而不 invoke DevOps + QA
> - DevOps 與 QA 必須**依序** invoke（QA 需在部署後執行 smoke test）
