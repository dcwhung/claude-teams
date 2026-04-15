# 指令：/audit

## 用途

對現有 codebase 進行全面審計，輸出架構分析報告。適用於接手舊項目、重建評估、或定期架構回顧。

## 負責 Agent

**Architect**（主導）+ Code Reviewer（協助識別代碼層問題）

---

## 引用規範（SSoT）

- Plan Before Do 確認規則（main vs subagent）→ `skills/agent-protocols.md` §2

本檔案只定義 `/audit` 獨有嘅執行流程同報告格式。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 輸出執行計劃
   - Main agent（直接同用戶對話）：等用戶確認
   - Subagent（由 main agent invoke）：立即執行，唔等確認（見 agent-protocols.md §2）
3. 掃描整個 codebase 目錄結構
4. 分析 tech stack（package.json、requirements.txt、composer.json 等）
5. 分析架構層次（目錄結構、模組職責、依賴關係）
6. 分析 API 結構（routes、endpoints、controllers）
7. 分析數據庫結構（schema、migrations、models）
8. 識別問題（Critical / Warning / Observation）
9. 評估技術債
10. 輸出完整報告
11. 將報告儲存至 `.proj-docs/audits/YYYY-MM-DD_HH-MM_audit_[描述].md`
12. 更新 `.proj-docs/index.md`（加入新文件條目，更新「最後更新」日期）
13. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 輸出報告格式

```markdown
# 架構審計報告

**日期**：YYYY-MM-DD HH:MM
**項目**：[項目名稱]
**審計員**：Architect Agent
**審計範圍**：[完整 codebase / 指定模組]

---

## 項目概覽

- **類型**：Web App / API / CLI / Mobile / ...
- **狀態**：Active / Legacy / Abandoned / Incomplete
- **估計代碼規模**：[檔案數 / 行數]
- **最後活躍**：[最近 commit 日期（如可得）]

---

## Tech Stack

| 層級 | 技術 | 版本 | 備注 |
|------|------|------|------|
| Frontend | | | |
| Backend | | | |
| Database | | | |
| Cache | | | |
| Queue | | | |
| Infra / DevOps | | | |
| 測試框架 | | | |

---

## 目錄結構

[列出主要目錄結構，說明各資料夾職責]

---

## 架構分析

### 整體架構模式
[描述架構模式：MVC / Clean Architecture / Microservices 等]

### 模組職責
[各主要模組嘅職責及邊界是否清晰]

### 依賴關係
[模組間依賴關係，有冇循環依賴]

---

## API 結構

| Method | Endpoint | 說明 | 認證 |
|--------|----------|------|------|
| | | | |

---

## 數據庫結構

### 主要 Tables / Collections
| 名稱 | 用途 | 主要欄位 |
|------|------|----------|
| | | |

### 關係圖（文字描述）
[描述主要 table 之間嘅關係]

---

## 發現問題

### 🔴 Critical（架構級問題，必須處理）

#### [AU-001] [問題標題]
- **位置**：[檔案 / 模組]
- **描述**：[問題詳情]
- **影響**：[對系統嘅影響]
- **建議**：[解決方向]

### 🟡 Warning（設計問題，建議處理）

#### [AU-002] [問題標題]
- **位置**：...
- **描述**：...
- **影響**：...
- **建議**：...

### 🟢 Observation（可改善點）

- [觀察 + 建議]

---

## 技術債評估

| 類別 | 程度 | 描述 | 預計處理成本 |
|------|------|------|-------------|
| 代碼質量 | 高/中/低 | | |
| 測試覆蓋 | 高/中/低 | | |
| 文件完整性 | 高/中/低 | | |
| 安全性 | 高/中/低 | | |
| 性能 | 高/中/低 | | |
| 依賴更新 | 高/中/低 | | |

---

## 建議方向

### 方案 A：修復現有系統
- **適用情況**：[描述]
- **預計工作量**：[估計]
- **優點**：...
- **缺點**：...

### 方案 B：重建
- **適用情況**：[描述]
- **預計工作量**：[估計]
- **優點**：...
- **缺點**：...

### 推薦
[推薦方案及理由]

---

## 下一步建議

| 優先級 | 行動 | 負責 Agent | 預計工作量 |
|--------|------|-----------|-----------|
| P0 | | | |
| P1 | | | |
| P2 | | | |
```

---

## 使用方式

```
/audit
/audit --scope=src/api        ← 只審計指定目錄
/audit --focus=security       ← 聚焦安全配置審計（見下方）
/audit --focus=performance    ← 聚焦性能問題
```

---

## 安全配置審計（`/audit --focus=security`）

> 接手 Rescue / Legacy project 必須執行，新項目上線前亦建議執行一次。

### HTTP Security Headers

```
□ Content-Security-Policy（CSP）已設定
□ Strict-Transport-Security（HSTS）已啟用
□ X-Frame-Options: DENY 或 SAMEORIGIN
□ X-Content-Type-Options: nosniff
□ Referrer-Policy 已設定
□ Permissions-Policy 已設定
□ 冇洩露 Server / X-Powered-By 版本資訊
```

### CORS 配置

```
□ Access-Control-Allow-Origin 唔係 *（生產環境）
□ 已明確列出允許嘅 origin whitelist
□ Access-Control-Allow-Credentials 唔係同 * 一起使用
□ CORS preflight 有正確 cache 設定
```

### 端點暴露

```
□ 無開放 /debug、/phpinfo、/admin 等敏感端點
□ 無開放未使用嘅 HTTP methods
□ Health check endpoint 唔暴露系統細節（版本、DB 連線等）
□ Error response 唔包含 stack trace 或系統路徑
```

### 依賴庫安全

```
□ 執行依賴漏洞掃描：
  npm audit --audit-level=high
  pip-audit
  composer audit
□ 無 Critical / High CVE 未修復
□ 無超過 2 年未更新嘅主要依賴
```

### SSL / TLS

```
□ 只支持 TLS 1.2 及以上（禁止 TLS 1.0、1.1）
□ 證書有效期 > 30 天
□ 無使用自簽證書（生產環境）
```

### Rate Limiting

```
□ 登入 / 註冊等認證端點有 rate limiting
□ 公開 API 有 rate limiting
□ Rate limit 超出時返回 429，唔係 500
```

### 安全審計報告附錄格式

```markdown
## 安全配置審計結果

| 類別 | 項目 | 狀態 | 風險 | 建議 |
|------|------|------|------|------|
| HTTP Headers | CSP | ❌ 缺失 | 🔴 | 加入 CSP header |
| CORS | Allow-Origin | ⚠️ 過寬 | 🟡 | 改為 whitelist |
| 端點 | /debug 開放 | ❌ 發現 | 🔴 | 立即關閉 |
| 依賴庫 | lodash CVE | ❌ 發現 | 🔴 | 升級至 4.17.21 |
| TLS | TLS 1.0 啟用 | ❌ | 🔴 | 禁用 TLS 1.0/1.1 |
| Rate Limiting | 登入端點 | ❌ 缺失 | 🔴 | 加入 rate limiting |
```
