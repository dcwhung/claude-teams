# 指令：/feature

## 用途

開新 branch，以 TDD（Red-Green-Refactor）方式開發新功能，完成後觸發 code review。

---

## Git Flow 規則

完全遵從 `skills/git-flow.md`。Branch 建立前必須通過該檔案定義嘅「Branch 建立強制 Pre-Flight Checklist」。Review / QA 後嘅 handoff 由 Reviewer / QA Agent 按「Post-Review Handoff Protocol」及「Post-QA Release Protocol」主動執行，Developer 無須介入。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視功能範圍）
**Code Reviewer**（功能完成後自動執行 `/review`）

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及 plan（確認功能需求及驗收標準）
3. 輸出執行計劃，等待確認
4. 執行 `skills/git-flow.md` → Branch 建立強制 Pre-Flight Checklist（source=develop），
   檢查通過後建立：feature/[scope]/[identifier]_[description]
   ⚡ 若功能橫跨 3+ 個獨立模組：使用 Agent tool 為每個模組派生子 Agent 並行開發
      各子 Agent 有明確唔重疊嘅檔案範圍；完成後執行整合測試
      詳見 `skills/autonomous-loop.md`
5. 逐個功能點執行 TDD 循環：
   ⚠️ 若涉及複雜業務規則（計算邏輯、日期邏輯、狀態機等）：
   先枚舉所有 edge cases（零值、邊界值、null、異常輸入、並發操作），再寫測試。
   詳見 `skills/autonomous-loop.md`
   🔴 Red    → 寫失敗測試
   🟢 Green  → 最少代碼通過測試
   🔵 Refactor → 重構，保持測試全綠
6. 完成所有功能點後，執行完整測試套件，確認全綠
7. Commit（Conventional Commits 格式）
8. 透過 Agent tool 呼叫 code-reviewer agent 執行 /review（Code Reviewer 獨立 review）
9. Reviewer 返回後，按 `skills/post-review-handoff.md` → 標準流程 執行 handoff
10. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Branch 命名

```bash
# 有 ticket（新功能，前後端分開或按模組）
feature/frontend/CUI-0015_user_profile_avatar
feature/backend/CUI-0015_profile_upload_api
feature/user-authentication/CUI-0020_login_flow
feature/payment/CUI-0021_stripe_webhook_handler
feature/dashboard/CUI-0022_monthly_summary_chart

# 無 ticket（主動開發，唔常見）
feature/user-authentication/login_flow
feature/payment/stripe_webhook
```

**規則**：
- 有 ticket 時必須帶 ticket number
- 前後端分離項目用 `frontend` / `backend` 層
- 模組型項目用模組名稱層（`user-authentication`、`payment` 等）
- 描述用 `snake_case`，3–5 個字

---

## TDD 循環執行標準

每個功能點必須按以下順序執行，**禁止跳步**：

### 🔴 Red — 寫失敗測試
```
- 測試必須描述預期行為，唔係實現細節
- 命名：it('should [預期結果] when [條件]')
- 確認測試執行後真係失敗（唔係錯誤，係失敗）
- 一次只寫一個測試
```

### 🟢 Green — 最少代碼通過測試
```
- 只寫令測試通過所需嘅最少代碼
- 唔追求完美，唔提前優化
- 通過後立即進入 Refactor
```

### 🔵 Refactor — 重構
```
- 消除重複代碼（DRY）
- 改善命名
- 抽取共用邏輯
- 確保測試仍然全綠
- 確保符合 SOLID 原則
```

---

## Commit 格式

```
feat: [功能描述]                          ← 無 ticket
feat: [TICKET_NUMBER] | [功能描述]        ← 有 ticket（常見情況）

例子（無 ticket）：
feat: 新增用戶登入 API

例子（有 ticket）：
feat: CUI-0015 | 新增用戶頭像上傳功能
feat: CUI-0020 | 實現 JWT refresh token 機制
feat: CUI-0021 | 新增付款 webhook 處理
```

每個有意義嘅完整功能點 commit 一次，唔好積累大量改動後一次 commit。

---

## 完成標準

```
□ 所有功能點測試通過
□ 測試覆蓋率達標（核心邏輯 ≥ 80%）
□ ESLint / Prettier 無錯誤
□ TypeScript 無類型錯誤
□ Code Review 評分 ≥ 90 分
□ 無 🔴 Critical 問題
□ Commit history 清晰
□ 透過 Agent tool 觸發 /review，後續 handoff 由 Reviewer/QA 自動執行
```

---

## 使用方式

```
/feature user-authentication         ← 開發用戶認證功能
/feature payment-webhook --backend   ← 指定只用 backend developer
/feature export-csv --frontend       ← 指定只用 frontend developer
```
