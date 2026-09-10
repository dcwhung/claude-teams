---
description: 開 fix/ branch，TDD 修復 bug
argument-hint: [bug description | CUI-XXXX]
---

# 指令：/fix

## 用途

開新 branch，以 TDD 方式修復 Bug，確保修復唔會引入新問題，完成後透過 Agent tool invoke code review。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視 bug 位置）
**Code Reviewer**（由 Developer 完成後透過 Agent tool invoke `/review`）

---

## 引用規範（SSoT）

- Branch 命名（含 One-Task-One-Branch 鐵律）、Pre-Flight Checklist、Commit 格式 → `skills/sw-git-flow/SKILL.md`
- TDD Red-Green-Refactor 循環 → `skills/sw-tdd/SKILL.md`
- Autonomous Loop + Edge Case 枚舉 → `skills/sw-autonomous-loop/SKILL.md`
- Review Item ID（C/W/S-NNN）vs QA Ticket（CUI-XXXX）→ `skills/sw-ticket-management/SKILL.md`
- Review 完成後 handoff → `skills/sw-post-review-handoff/SKILL.md` → Protocol 1

本檔案只定義 `/fix` 獨有嘅執行流程，上述規範禁止重複。

---

## Fix 前提條件

```
□ Bug 可重現，根源已初步定位
□ 目前在 develop branch（fix branch 必須從 develop 建立）
□ 有 ticket 對應（如來自 QA 或 code review）
```

> ⚠️ **嚴禁從 main 建立 fix branch。** main 只接受來自 develop 嘅 merge。
> 緊急情況使用 `/hotfix`，唯一合法從 main 開 branch 嘅指令。

---

## 執行流程

```
1.  讀取 shared-knowledge.md（全局 + 項目）
2.  理解 bug 描述，確認可重現步驟
3.  輸出執行計劃
    - Main agent（直接同用戶對話）：等用戶確認
    - Subagent（由 main agent invoke）：立即執行，唔等確認（見 agent-protocols.md §2）
4.  執行 git-flow.md → Branch Pre-Flight Checklist（source=develop）
    → 建立：fix/[scope]/[identifier]_[description]
    ⚠️ One-Task-One-Branch 鐵律：每個 identifier 獨立 branch
5.  🔴 先寫一個能重現 bug 嘅失敗測試
    ⚠️ 複雜業務規則：先枚舉所有 edge cases（見 autonomous-loop.md）
6.  輸出 Root Cause Analysis（見下方格式）
7.  🟢 最少改動修復 bug
8.  🔵 Refactor（範圍必須最小化）
9.  使用 Agent tool 啟動 Autonomous Loop 直至測試全綠（見 autonomous-loop.md）
10. Commit（每個 review item 一個 commit，見 git-flow.md）
11. 透過 Agent tool 呼叫 code-reviewer agent 執行 /review
12. Reviewer 返回後，main agent 按 **`skills/sw-post-review-handoff/SKILL.md` → Protocol 1** 執行 handoff：
    - 驗證 receipt 格式（fenced block）+ next_action 係合法 enum
    - `pass` → ① git merge develop → ② invoke QA → ③ QA pass 後 git merge main → ④ invoke devops → ⑤ devops pass 才結束
    - `fail/warn` → invoke developer 修正（main agent 禁止自己改代碼）
13. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Root Cause Analysis 格式

修復前必須輸出：

```
## Root Cause Analysis

**Bug 描述**：[用戶報告嘅問題]
**可重現步驟**：[步驟列表]
**根源**：[真正嘅原因，唔係表面現象]
**影響範圍**：[有冇其他地方受影響]
**修復方案**：[計劃點樣修復]
**回歸風險**：[修復可能影響嘅其他功能]
```

---

## 完成標準

```
□ Bug 重現測試通過
□ 完整測試套件無回歸問題
□ Root Cause Analysis 已記錄
□ ESLint / Prettier 無錯誤
□ Code Review 評分 ≥ 90 分，無 🔴 Critical
□ 透過 Agent tool invoke /review，後續 handoff 由 Reviewer receipt + main agent 執行
□ 如 bug 係常見陷阱，已記錄入 shared-knowledge.md
```

---

## 使用方式

```
# Review Item ID（全局唯一，跨 review 不重用）
/fix W-003                                 ← 修復指定 Warning
/fix C-001                                 ← 修復指定 Critical
/fix S-007                                 ← 修復指定 Suggestion
/fix W-003 W-004 S-007                     ← 各自獨立 branch + 獨立 commit，順序執行

# QA Ticket
/fix CUI-0001                              ← 按 ticket number 修復
/fix CUI-0001 --frontend                   ← 指定前端部分
/fix CUI-0001 --backend                    ← 指定後端部分
```
