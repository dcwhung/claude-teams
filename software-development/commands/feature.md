# 指令：/feature

## 用途

開新 branch，以 TDD（Red-Green-Refactor）方式開發新功能，完成後觸發 code review。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視功能範圍）
**Code Reviewer**（功能完成後自動執行 `/review`）

---

## 引用規範（SSoT）

- Branch 命名、Pre-Flight Checklist、Commit 格式 → `skills/git-flow.md`
- TDD Red-Green-Refactor 循環 → `skills/tdd.md`
- Edge Case 枚舉 + Parallel Agents → `skills/autonomous-loop.md`
- Review 完成後 handoff → `skills/post-review-handoff.md` → Protocol 1

本檔案只定義 `/feature` 獨有嘅執行流程，上述規範禁止重複。

---

## 執行流程

```
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
9. Reviewer 返回後，main agent 按 post-review-handoff.md → Protocol 1 執行 handoff
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
□ 透過 Agent tool 觸發 /review，後續 handoff 由 Reviewer + main agent 自動執行
```

---

## 使用方式

```
/feature user-authentication         ← 開發用戶認證功能
/feature payment-webhook --backend   ← 指定只用 backend developer
/feature export-csv --frontend       ← 指定只用 frontend developer
```
