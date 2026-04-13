# 指令：/review

## 用途

對指定代碼、檔案或 PR 進行全面 code review，輸出評分報告及修訂代碼。

## 負責 Agent

**Code Reviewer**（獨立執行，不可 review 自己寫嘅代碼）

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 掃描 .proj-docs/reviews/ 所有現有報告，提取 C/W/S 各類型目前最高序號
   （用於後續賦予全局唯一 Review Item ID，見 code-reviewer.md）
3. 輸出執行計劃，等待確認
4. 完整閱讀目標代碼
5. 逐項執行 Review 檢查清單（參考 code-reviewer.md）
6. 計算評分（0–100，各維度獨立評分）
7. 整理問題清單（🔴 → 🟡 → 🟢），為每個問題賦予全局唯一 ID（從步驟 2 確認嘅最高序號 +1 開始）
8. 為每個問題提供 ≥2 個解決方案及 trade-off
9. 排列修正優先順序
10. 輸出完整修訂代碼（附 inline comment）
11. 將報告儲存至 `.proj-docs/reviews/YYYY-MM-DD_HH-MM_review_[描述].md`
12. 更新 `.proj-docs/index.md`（加入新文件條目，更新「最後更新」日期）
13. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 合格門檻

```
≥ 90 分  ✅ 合格 — 可以合併
75–89 分  ⚠️  需修正 Warning 後重新 review
< 75 分   ❌ 不合格 — 必須修正所有 Critical 及主要 Warning

任何 🔴 Critical 問題存在 → 無論總分，一律不合格
```

---

## Review 完成後必須執行嘅 Handoff

Review 報告輸出後，**唔係交差**。Code Reviewer 必須按分數執行以下動作：

### ✅ ≥ 90 分（合格）

```
1. 執行 merge（Reviewer 負責，唔係等 Developer）：
   git checkout develop
   git merge --no-ff [feature/refactor-branch] -m "chore: merge [branch] into develop"
   git branch -d [feature/refactor-branch]

2. 明確通知用戶：
   「✅ Review 通過（XX/100）。已 merge [branch] → develop，branch 已刪除。
     移交 QA Agent 執行 /test 驗證 develop。」

3. 執行 /test（QA Agent 接手）
```

> ⚠️ Reviewer 唔可以等用戶叫先 merge。Review 通過即執行。

### ⚠️ 75–89 分（需修正）

```
1. 列出所有 🟡 Warning items（附 ID）
2. 明確通知 Developer Agent：
   「⚠️ Review 未通過（XX/100）。請修正以下 Warning 後重新提交：
     W-XXX：[描述]
     W-XXX：[描述]
   修正完成後再次執行 /review。」
3. 唔執行 merge，等待 Developer 修正後重新 review
```

### ❌ < 75 分 或有 🔴 Critical（不合格）

```
1. 列出所有 🔴 Critical items（附 ID）及主要 Warning
2. 明確通知 Developer Agent：
   「❌ Review 不合格（XX/100）。以下問題必須修正：
     C-XXX：[描述]（Critical）
   修正完成後再次執行 /review。」
3. 明確阻止 merge：「⛔ 禁止 merge，直至 Critical 問題全部修正。」
```

---

## 輸出報告格式

（完整格式定義於 `global-rules.md` → Code Review 報告格式）

報告包含：
1. 報告頭部（日期、審閱者、目標、總評）
2. 評分結果表（6 個維度）
3. 問題清單（🔴 → 🟡 → 🟢）
4. ✅ 做得好嘅地方
5. 修正優先順序表
6. 修訂後完整代碼

---

## 使用方式

```
/review                          ← review 當前對話中嘅代碼
/review src/services/payment.ts  ← review 指定檔案
/review --pr=42                  ← review 指定 PR（需提供 diff）
/review --focus=security         ← 聚焦安全問題
```
