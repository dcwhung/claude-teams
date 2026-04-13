# 指令：/feature

## 用途

開新 branch，以 TDD（Red-Green-Refactor）方式開發新功能，完成後觸發 code review。

---

## Git Flow 規則（強制）

```
✅ 允許：develop → feature branch → develop（merge --no-ff）→ main
❌ 禁止：從 main 建立 feature branch
❌ 禁止：merge main → develop（反向操作）
❌ 禁止：直接 commit 到 develop 或 main
```

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視功能範圍）
**Code Reviewer**（功能完成後自動執行 `/review`）

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及 plan（確認功能需求及驗收標準）
3. 輸出執行計劃，等待確認
4. 確認目前在 develop branch，建立 feature branch（必須從 develop）：
   git checkout develop && git checkout -b feature/[scope]/[description]
   ⚡ 若功能橫跨 3+ 個獨立模組：使用 Agent tool 為每個模組派生子 Agent 並行開發
      各子 Agent 有明確唔重疊嘅檔案範圍；完成後執行整合測試
      詳見 `skills/autonomous-loop.md`
5. 逐個功能點執行 TDD 循環：
   ⚠️ 若涉及財務計算、日期邏輯：先枚舉 edge cases（pro-rated、annual vs monthly、
   partial periods、零值），再寫測試。詳見 `skills/autonomous-loop.md`
   🔴 Red    → 寫失敗測試
   🟢 Green  → 最少代碼通過測試
   🔵 Refactor → 重構，保持測試全綠
6. 完成所有功能點後，執行完整測試套件，確認全綠
7. Commit（Conventional Commits 格式）
8. 明確通知用戶：「功能完成，移交 Code Reviewer 執行 /review」
   → 執行 /review（Code Reviewer 獨立 review）
9. Review 合格（≥90 分）後，Code Reviewer 執行：
   a. git checkout develop
   b. git merge --no-ff [feature-branch] -m "chore: merge [branch] into develop"
   c. git branch -d [feature-branch]
   d. 通知用戶：「已 merge，移交 QA Agent 執行 /test」
10. 執行 /test（QA Agent 喺 develop 驗證功能）
11. QA 通過後，執行 develop → main merge：
    git checkout main && git merge --no-ff develop -m "chore: merge develop into main"
12. 如有發現 common knowledge，記錄入 shared-knowledge.md
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
□ feature branch 已 merge --no-ff 入 develop
□ feature branch 已刪除（本地）
□ QA /test 通過（develop 行為驗證）
```

---

## 使用方式

```
/feature user-authentication         ← 開發用戶認證功能
/feature payment-webhook --backend   ← 指定只用 backend developer
/feature export-csv --frontend       ← 指定只用 frontend developer
```
