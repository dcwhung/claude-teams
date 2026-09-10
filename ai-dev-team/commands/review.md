---
description: Code Reviewer 執行 code review，輸出評分報告
argument-hint: [branch|PR|path]
---

# 指令：/review

## 用途

對指定代碼、檔案或 PR 進行全面 code review，輸出評分報告及修訂代碼。

## 負責 Agent

**Code Reviewer**（獨立執行，不可 review 自己寫嘅代碼）

---

## 引用規範（SSoT）

- Review 維度、評分、報告格式、Review Item ID 賦予規則 → `agents/code-reviewer.md`
- Review Item ID vs QA Ticket 系統 → `skills/sw-ticket-management/SKILL.md`
- Review 完成後 handoff → `skills/sw-post-review-handoff/SKILL.md` → Protocol 1

本檔案只定義 `/review` 獨有嘅執行步驟。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 掃描 .proj-docs/reviews/ 現有報告，提取 C/W/S 各類型最高序號
   （全局唯一 Review Item ID 賦予規則見 code-reviewer.md）
3. 輸出執行計劃，等待確認
4. 完整閱讀目標代碼
5. 逐項執行 Review 檢查清單（見 code-reviewer.md）
6. 計算評分，整理問題清單（🔴 → 🟡 → 🟢）
7. 每個問題賦予全局唯一 ID（從步驟 2 最高序號 +1 開始）
8. 每個問題提供 ≥2 個解決方案及 trade-off
9. 輸出完整修訂代碼（附 inline comment）
10. 儲存至 `.proj-docs/reviews/YYYY-MM-DD_HH-MM_review_[描述].md`
11. 更新 `.proj-docs/index.md`
12. 按 post-review-handoff.md → Protocol 1 執行 git 操作及 handoff 標記
13. 如有 common knowledge 記錄入 shared-knowledge.md
```

---

## 合格門檻（簡要）

```
≥ 90 分 ✅ 合格
75–89 分 ⚠️ 需修 Warning 後 re-review
< 75 分 ❌ 不合格
任何 🔴 Critical 存在 → 一律不合格
```

> 完整定義見 `agents/code-reviewer.md`。

---

## 使用方式

```
/review                          ← review 當前對話中嘅代碼
/review src/services/payment.ts  ← review 指定檔案
/review --pr=42                  ← review 指定 PR
```
