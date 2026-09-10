---
description: 開 feature/ branch，TDD 開發新功能，完成後自動 handoff review
argument-hint: [feature description]
---

# 指令：/feature

## 用途

開新 branch，以 TDD（Red-Green-Refactor）方式開發新功能，完成後透過 Agent tool invoke code review。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視功能範圍）
**Code Reviewer**（由 Developer 完成後透過 Agent tool invoke `/review`）

---

## 引用規範（SSoT）

- Branch 命名、Pre-Flight Checklist、Commit 格式 → `skills/sw-git-flow/SKILL.md`
- TDD Red-Green-Refactor 循環 → `skills/sw-tdd/SKILL.md`
- Edge Case 枚舉 + Parallel Agents → `skills/sw-autonomous-loop/SKILL.md`
- Review 完成後 handoff → `skills/sw-post-review-handoff/SKILL.md` → Protocol 1

本檔案只定義 `/feature` 獨有嘅執行流程，上述規範禁止重複。

---

## 執行流程

```
0. Design Origin Check（所有 UI / 涉及 *.tsx|css|jsx 嘅任務強制執行）
   ✅ 確認 spec 有 `## Design Source` section 且 Origin 已填（5 種之一）
   ✅ Branch description 第一行寫：Design Origin: <origin>: <詳情>
   ✅ 按 Origin 類型做準備：
        mockup    → 完整讀 mockup file 先動 code（tokens.css + component CSS + HTML）
        baseline  → 開 dev server 截現有 UI screenshot 做 reference
        proposal  → 確認 reviewer design sign-off 已 record；ship 後截 baseline screenshot
        library   → 讀 library doc + 試裝 minimal example 對齊 props
        none-required → 自我審：今次 diff 真係零視覺變化？如有任何 className / 新 layout 即 stop
   ❌ Origin 缺 / spec 未 sign-off → 停低，return /spec（唔可繼續）
   ❌ 純 backend / logic 改動 → 標 none-required + Why 一句說明，跳過此 check

1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及 plan（確認功能需求及驗收標準）
3. 輸出執行計劃，等待確認（見 agent-protocols.md）
4. 執行 git-flow.md → Branch Pre-Flight Checklist（source=develop）
   → 建立：feature/[scope]/[identifier]_[description]
   ⚡ 若功能橫跨 3+ 個獨立模組：使用 Agent tool 並行派發
     （見 autonomous-loop.md → Parallel Agents）
5. 逐個功能點執行 TDD 循環（見 tdd.md）：
   ⚠️ 若涉及複雜業務規則（計算邏輯、日期邏輯、狀態機等）：
   先枚舉所有 edge cases（見 autonomous-loop.md）
6. 完成所有功能點後，執行完整測試套件確認全綠
7. Commit（Conventional Commits，見 git-flow.md）
8. 透過 Agent tool 呼叫 code-reviewer agent 執行 /review
9. Reviewer 返回後，main agent 按 **`skills/sw-post-review-handoff/SKILL.md` → Protocol 1** 執行 handoff：
   - 驗證 receipt 格式（fenced block）+ next_action 係合法 enum
   - `pass` → ① git merge develop → ② invoke QA → ③ QA pass 後 git merge main → ④ invoke devops → ⑤ devops pass 才結束
   - `fail/warn` → invoke developer 修正（main agent 禁止自己改代碼）
   > ⛔ 禁止在 QA pass 後、git merge main 前 invoke devops。
   > ⛔ 只有收到 DevOps receipt `status=pass, next_action=end` 後才可結束整條鏈。

10. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 完成標準

```
□ 所有功能點測試通過
□ 測試覆蓋率達標（核心邏輯 ≥ 80%）
□ ESLint / Prettier 無錯誤
□ TypeScript 無類型錯誤
□ Code Review 評分 ≥ 90 分，無 🔴 Critical
□ Commit history 清晰
□ 透過 Agent tool invoke /review，後續 handoff 由 Reviewer receipt + main agent 執行
```

---

## 使用方式

```
/feature user-authentication         ← 開發用戶認證功能
/feature payment-webhook --backend   ← 指定只用 backend developer
/feature export-csv --frontend       ← 指定只用 frontend developer
```
