# 指令：/deploy

## 用途

觸發 CI/CD 部署流程，確保所有前置條件達標，輸出部署記錄。

## 負責 Agent

**DevOps Engineer**（主導）

---

## 引用規範（SSoT）

- Pipeline 各階段、環境變數管理、回滾流程 → `skills/ci-cd.md`
- 部署記錄格式 → `agents/devops-engineer.md`
- 部署完成後 handoff（smoke test、回滾判斷）→ `skills/post-review-handoff.md` → Protocol 4
- develop → main merge 規則 → `skills/git-flow.md`

本檔案只定義 `/deploy` 獨有嘅前置條件、migration 規範、回滾表述。

---

## 前置條件（必須全部達標）

```
□ Code Review 評分 ≥ 90，無 🔴 Critical
□ QA 測試報告無 🔴 Critical
□ Unit + Integration + E2E 測試通過
□ ESLint / TypeScript 無錯誤
□ Build 成功
□ Security scan 無 Critical 漏洞
□ 環境變數 / Secrets 已正確配置
□ develop → main merge 已由 main agent 按 QA receipt 完成（見 post-review-handoff.md → Protocol 2）
□ Production 部署已獲授權
```

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 確認前置條件達標
3. 確認有冇 pending migration，評估影響
4. 輸出執行計劃（含 migration 策略 + 回滾方案），等待確認
5. 執行 Pipeline（見 ci-cd.md → Pipeline 標準架構）
   ↳ 含 Lint → Tests → Build → Security Scan → Migration → Deploy → Smoke Test
6. Post-deploy 監察 5–10 分鐘指標
7. 按 post-review-handoff.md → Protocol 4 執行 handoff（成功 / 失敗）
8. 輸出部署記錄（格式見 devops-engineer.md）
9. 如有 common knowledge 記錄入 shared-knowledge.md
```

---

## Database Migration 規範

### 執行時機

```
Migration 必須在新代碼部署之前（pre-deploy）：
  舊代碼 running → 執行 migration → 部署新代碼 → 新代碼 running

原因：新代碼依賴新 schema，代碼先上線 → 即時出錯
```

### 前置確認

```
□ Migration 已在 Staging 成功執行並驗證
□ Migration 向後兼容（舊代碼仍可運行）
□ 估算執行時間（大表可能需要 maintenance window）
□ 有 down migration
□ 備份生產數據庫（大型 migration 必須）
```

### 不兼容 Migration（Breaking Schema Change）

若 migration 會令舊代碼無法運行，**必須分兩個 deploy**：

```
Deploy 1：向後兼容過渡
  - 新增欄位（nullable 或有預設值）
  - 新舊欄位並存，代碼雙寫

Deploy 2：清理舊結構
  - 確認流量已用新欄位
  - 移除舊欄位 + 雙寫邏輯

例子：重命名 user_name → display_name
  Deploy 1：新增 display_name，保留 user_name，雙寫
  Deploy 2：移除 user_name，移除雙寫
```

### 失敗處理

```
Migration 失敗 → 立即停止 → 不部署新代碼 → 執行 down migration → 通知團隊

輸出：失敗 migration 檔名、錯誤訊息、已執行/未執行步驟、回滾指令
```

---

## 環境說明

| 環境 | 觸發條件 | 需要授權 |
|------|----------|----------|
| Staging | merge to staging branch | 否 |
| Production | merge to main / tag release | **是** |

---

## 回滾方案（部署前必須確認）

```
## 回滾方案
**觸發條件**：[何時需要回滾]
**回滾步驟**：[具體步驟]
**回滾驗證**：[如何確認]
**預計回滾時間**：[估計]
```

> 實際回滾指令模板見 `skills/ci-cd.md` → 回滾流程。

---

## 使用方式

```
/deploy --env=staging       ← 部署至 Staging
/deploy --env=production    ← 部署至 Production（需授權）
/deploy --dry-run           ← 只輸出計劃
/deploy --rollback          ← 執行回滾
```
