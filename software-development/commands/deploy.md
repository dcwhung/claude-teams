# 指令：/deploy

## 用途

觸發 CI/CD 部署流程，確保所有前置條件達標，輸出部署記錄。

## 負責 Agent

**DevOps Engineer**（主導）

---

## 前置條件（必須全部達標才可部署）

```
□ Code Review 評分 ≥ 90 分，且無 🔴 Critical 問題
□ QA 測試報告無 🔴 Critical 失敗
□ 所有測試通過（Unit + Integration + E2E）
□ ESLint / TypeScript 無錯誤
□ Build 成功
□ Security scan 無 Critical 漏洞
□ 環境變數 / Secrets 已正確配置
□ Code Reviewer 已執行 develop → main git merge
□ 如部署至 Production，已獲明確授權
```

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 確認前置條件全部達標
3. 確認有冇 pending migration（如有，評估影響）
4. 輸出執行計劃（含 migration 策略 + 回滾方案），等待確認
4a. Pre-merge 驗證：喺 SOURCE branch（develop）執行完整測試套件，全通過先執行 merge
    → 若失敗：終止，唔執行 merge，通知開發者修正
5. 執行 Pipeline：
   Lint & Type Check
   → Unit Tests
   → Integration Tests
   → Build
   → Security Scan
   → Database Migration（如有，見下方規範）
   → Deploy to 目標環境
   → Smoke Test
   → 通知結果
5b. Post-merge 驗證：merge 完成後立即喺 TARGET branch 重新執行完整測試套件
    → 若失敗：優先排查 main 嘅 stale files（`git diff develop...main --name-only`）
    → 確認全綠先繼續部署
6. 監察部署後指標（5–10 分鐘）
7. 輸出部署記錄
8. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Database Migration 規範

### 執行時機

```
Migration 必須在新代碼部署之前執行（pre-deploy）：

  舊代碼 running
      ↓
  執行 migration（schema 更新）
      ↓
  部署新代碼
      ↓
  新代碼 running

原因：新代碼依賴新 schema，若代碼先上線而 schema 未更新 → 即時出錯
```

### Migration 前置確認

```
□ Migration 已在 Staging 成功執行並驗證
□ Migration 係向後兼容（舊代碼仍可正常運行）
□ 估算 migration 執行時間（大表操作可能需要 maintenance window）
□ 確認有 migration rollback script（down migration）
□ 備份生產數據庫（大型 migration 必須）
```

### 不兼容 Migration 處理（Breaking Schema Change）

```
若 migration 導致舊代碼無法運行，必須分兩個 deploy 處理：

Deploy 1：向後兼容過渡
  - 新增欄位（nullable 或有預設值）
  - 新舊欄位並存，代碼同時寫入兩個欄位

Deploy 2：清理舊結構
  - 確認所有流量已使用新欄位
  - 移除舊欄位
  - 移除兩欄並存邏輯

例子：重命名 user_name → display_name
  Deploy 1：新增 display_name，保留 user_name，同時寫入兩欄
  Deploy 2：移除 user_name，移除雙寫邏輯
```

### Migration 失敗處理

```
Migration 失敗 → 立即停止 → 不部署新代碼 → 執行 down migration → 通知團隊

失敗時輸出：
  - 失敗嘅 migration 檔案名
  - 錯誤訊息
  - 已執行 / 未執行嘅步驟
  - 回滾指令
```

### Migration 回滾方案

```
每個 migration 必須有對應 down migration：

# 執行回滾
npm run migration:rollback
python manage.py migrate [app] [previous_migration]
php artisan migrate:rollback

回滾後必須驗證：
  □ 數據庫 schema 已還原
  □ 現有代碼正常運行
  □ 數據無損失
```

---

## 環境說明

| 環境 | 觸發條件 | 需要授權 |
|------|----------|----------|
| Staging | merge to staging branch | 否 |
| Production | merge to main / tag release | **是** |

---

## 回滾方案（必須在部署前確認）

每次部署前必須明確：

```
## 回滾方案

**觸發條件**：[何時需要回滾]
**回滾步驟**：
  1. [具體步驟]
  2. [具體步驟]
**回滾驗證**：[如何確認回滾成功]
**預計回滾時間**：[估計]
```

---

## 輸出格式

（完整格式定義於 `devops-engineer.md` → /deploy 輸出格式）

部署記錄包含：
1. 部署頭部（日期、環境、版本、部署員）
2. Pipeline 各步驟結果
3. 改動摘要
4. 回滾方案
5. 備注

---

## 使用方式

```
/deploy --env=staging       ← 部署至 Staging
/deploy --env=production    ← 部署至 Production（需授權）
/deploy --dry-run           ← 只輸出計劃，唔實際執行
/deploy --rollback          ← 執行回滾
```
