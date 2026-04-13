# 指令：/refactor

## 用途

對現有代碼進行重構，改善設計質量、可讀性或性能，**不改變外部行為**。
必須以測試保證行為不變，完成後觸發 code review。

---

## Git Flow 規則（強制）

```
✅ 允許：develop → refactor branch → develop（merge --no-ff）→ main
❌ 禁止：從 main 建立 refactor branch
❌ 禁止：merge main → develop（反向操作）
❌ 禁止：直接 commit 到 develop 或 main
```

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視重構範圍）
**Code Reviewer**（重構完成後自動執行 `/review`）

---

## 重構前提條件

```
□ 現有測試覆蓋率達標（核心邏輯 ≥ 80%）
□ 所有現有測試通過
□ 重構範圍已明確界定
□ 有 ticket 對應（如源自 code review 或 QA 建議）
□ 目前在 develop branch（refactor branch 必須從 develop 建立）
```

> 如測試覆蓋率不足，**必須先補測試再重構**。
> 冇測試保護嘅重構唔係重構，係賭博。
>
> **⚠️ 嚴禁從 main 建立 refactor branch。** main 只接受來自 develop 嘅 merge。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 輸出執行計劃，等待確認
3. 確認目前在 develop branch，所有現有測試通過（作為行為基準）
4. 建立 refactor branch（必須從 develop）：
   git checkout develop && git checkout -b refactor/[scope]/[description]
5. 逐步重構，每個動作後執行測試確認全綠：
   ⚡ 若重構橫跨 3+ 個獨立模組（無共用依賴）：使用 Agent tool 並行派發，每個模組一個子 Agent
      各子 Agent 有明確唔重疊嘅檔案範圍；有共用依賴時改為順序執行
      詳見 `skills/autonomous-loop.md`
   - 抽取函數 / 類別
   - 改善命名
   - 消除重複（DRY）
   - 拆分過長函數
   - 調整分層
6. 完成後執行完整測試套件，確認全綠
7. Commit（Conventional Commits 格式）
8. 明確通知用戶：「重構完成，移交 Code Reviewer 執行 /review」
   → 執行 /review（Code Reviewer 獨立 review，唔可 review 自己嘅代碼）
9. Review 合格（≥ 90 分）後，Code Reviewer 執行以下步驟：
   a. git checkout develop
   b. git merge --no-ff [refactor-branch] -m "chore: merge [branch] into develop"
   c. git branch -d [refactor-branch]
   d. 通知用戶：「已 merge，移交 QA Agent 執行 /test」
10. 執行 /test（QA Agent 驗證 develop branch 行為不變）
11. QA 通過後，執行 develop → main merge：
    git checkout main && git merge --no-ff develop -m "chore: merge develop into main"
12. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Branch 命名

```bash
# 有 ticket
refactor/frontend/CUI-0031_extract_user_hooks
refactor/backend/CUI-0031_payment_service_decompose
refactor/backend/CUI-0045_repository_layer_cleanup

# 無 ticket（主動發現）
refactor/frontend/extract_auth_context
refactor/backend/simplify_order_service
```

---

## 重構原則（必須遵守）

### 小步前進
每次只做**一種**重構動作，完成並確認測試通過後，再進行下一個：

```
✅ 正確：
  步驟 1：抽取 calculateTotal() 為獨立函數 → 測試通過
  步驟 2：改善變數命名 → 測試通過
  步驟 3：消除重複邏輯 → 測試通過

❌ 錯誤：
  一次過改晒所有嘢，測試失敗時唔知係邊步出問題
```

### 行為不變原則
重構前後，系統對外行為必須完全一致：
- API response 格式不變
- 函數輸入輸出不變
- 業務邏輯不變
- 如有行為改動，唔係重構，係功能改動，需另開 `/feature`

### 禁止趁機加功能
重構 branch 唔可以包含新功能或 bug fix，發現 bug 記錄喺 ticket，完成重構後另開 `/fix`。

---

## Commit 格式

```
refactor: [描述做咗乜重構]

例子：
refactor: 拆分 UserService，抽取 AuthService
refactor: 消除 payment module 重複驗證邏輯
refactor: 統一 API error response 格式
```

---

## 完成標準

```
□ 所有既有測試仍然通過（行為不變）
□ 重構後函數長度符合規範（≤ 30 行）
□ 無新增 magic number / magic string
□ ESLint / Prettier 無錯誤
□ Code Review 評分 ≥ 90 分
□ 無 🔴 Critical 問題
□ refactor branch 已 merge --no-ff 入 develop
□ refactor branch 已刪除（本地）
□ QA /test 通過（develop 行為驗證）
□ develop 已 merge → main
```

---

## 使用方式

```
/refactor                                    ← 重構當前討論嘅代碼
/refactor src/services/payment.ts            ← 重構指定檔案
/refactor CUI-0031                           ← 按 ticket number 重構
/refactor src/services/ --backend            ← 指定後端重構
/refactor --plan-only                        ← 只輸出重構計劃，唔執行
```
