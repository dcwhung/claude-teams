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

Review 報告輸出後，**唔係交差**。

**Reviewer 職責**：執行 git 操作（merge / branch delete），在報告末尾標明評分及 git 結果。
**Main agent 職責**：監察 Reviewer 返回結果，按 `skills/post-review-handoff.md` 立即 invoke 下一個 agent。

> ⛔ **Reviewer 禁令**：
> - 禁用「通知」、「提醒」、「建議用戶執行」等被動語句
> - 禁止輸出「請確認是否繼續」、「要唔要叫 developer fix」、「需要叫 QA 嗎」等問句

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
