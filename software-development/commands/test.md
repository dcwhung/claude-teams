# 指令：/test

## 用途

制定並執行測試計劃，涵蓋 Unit、Integration、E2E 三個層次，輸出完整 QA 測試報告。

## 負責 Agent

**Quality Assurance**（主導）

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及功能描述，了解驗收標準
3. 輸出執行計劃，等待確認
4. 設計測試案例（Happy path / Error path / Edge case）
5. 執行 Unit Tests
6. 執行 Integration Tests
7. 執行 E2E Tests（如適用）
8. 執行安全測試（關鍵功能）
9. 執行回歸測試（如有改動影響範圍）
10. 整理結果，輸出 QA 測試報告
11. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 測試案例設計框架

每個功能點必須覆蓋：

```
✅ Happy Path     ← 正常輸入，預期成功結果
❌ Error Path     ← 無效輸入、系統錯誤嘅處理
🔲 Edge Case      ← 空值、null、極端數值、超長字串、特殊字元
🔒 Security Case  ← 未授權訪問、invalid token、injection、IDOR
🔄 Idempotency    ← 重複操作唔應造成數據異常
⚡ Performance    ← 關鍵 API 必須符合 response time 基準
```

命名格式：
```
it('should [預期結果] when [條件]')

例子：
it('should return user profile when valid token provided')
it('should return 401 when token is expired')
it('should return 400 when email format is invalid')
it('should not create duplicate record when request sent twice')
it('should respond within 500ms when fetching user list')
```

---

## Performance Testing 規範

### Response Time 基準（預設，可由 project CLAUDE.md 覆蓋）

| API 類型 | P50 | P95 | P99 |
|----------|-----|-----|-----|
| 一般讀取 | < 100ms | < 300ms | < 500ms |
| 列表查詢（有分頁） | < 200ms | < 500ms | < 1s |
| 寫入操作 | < 200ms | < 500ms | < 1s |
| 複雜報表 / 匯出 | < 2s | < 5s | < 10s |

### 測試工具

```
輕量 load test：k6 / Artillery
API benchmark：autocannon（Node.js）/ wrk
DB query analysis：EXPLAIN ANALYZE（PostgreSQL）/ EXPLAIN（MySQL）
前端性能：Lighthouse CI / Web Vitals
```

### 必須執行 Performance Test 嘅情況

```
□ 新增涉及大數據量嘅 API（列表、搜尋、報表）
□ 新增數據庫查詢（必須 EXPLAIN 確認有用 index）
□ 新增外部 API 調用（必須有 timeout 設定）
□ 修改現有高頻 API
□ 任何 N+1 query 風險改動
```

### 基本 Load Test 範例（k6）

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 50,           // 50 個並發用戶
  duration: '30s',   // 持續 30 秒
  thresholds: {
    http_req_duration: ['p(95)<500'],  // P95 < 500ms
    http_req_failed: ['rate<0.01'],    // 失敗率 < 1%
  },
};

export default function () {
  const res = http.get('http://staging/api/v1/users');
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

### Performance 問題判定

```
🔴 Critical：P95 超過基準 2 倍以上，或失敗率 > 1%
🟡 Warning：P95 超過基準，或有明顯 N+1 query
🟢 Observation：可優化但未超標
```

---

## 阻止部署條件

以下情況 QA 必須阻止進入部署流程，並通知 DevOps：

```
🚫 任何 🔴 Critical 測試失敗
🚫 核心業務流程測試失敗
🚫 安全測試失敗
🚫 數據一致性測試失敗
```

---

## 輸出報告格式

（完整格式定義於 `global-rules.md` → QA 測試報告格式）

報告包含：
1. 報告頭部（日期、範圍、環境、總結）
2. 測試覆蓋概覽表
3. 失敗測試詳情（可重現步驟、根源分析、建議修正）
4. 問題修正優先順序表
5. 測試建議（下一步）

---

## QA 完成後 Handoff

所有 handoff 規則**完全定義於** `skills/git-flow.md` → Post-QA Release Protocol。QA Agent 完成測試後，**禁止等用戶確認**，必須立即按該 protocol 執行：

- ✅ **通過**（無 🔴 Critical）→ 立即執行 develop→main merge，透過 Agent tool invoke devops-engineer 執行 /deploy
- ❌ **失敗**（有 🔴 Critical）→ 立即建立 QA ticket，透過 Agent tool invoke 對應 Developer 執行 /fix

> ⛔ 禁止輸出「要唔要 release」、「請確認是否 merge」等問句。

---

## 使用方式

```
/test                          ← 執行當前功能嘅完整測試計劃
/test --unit-only              ← 只執行 unit tests
/test --e2e-only               ← 只執行 E2E tests
/test --performance            ← 執行 performance tests（load test + DB query analysis）
/test --regression             ← 執行回歸測試
/test --scope=src/payment      ← 只測試指定模組
/test --design                 ← 只輸出測試計劃，唔執行
```
