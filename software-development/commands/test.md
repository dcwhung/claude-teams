# 指令：/test

## 用途

制定並執行測試計劃，涵蓋 Unit、Integration、E2E 三個層次，輸出完整 QA 測試報告。

## 負責 Agent

**Quality Assurance**（主導）

---

## 引用規範（SSoT）

- QA 報告格式、Definition of Done → `global-rules.md`
- Ticket 建立流程（CUI-XXXX）→ `skills/ticket-management.md`
- QA 完成後 handoff（release / reject）→ `skills/post-review-handoff.md` → Protocol 2

本檔案只定義 `/test` 獨有嘅測試設計框架同 performance 規範。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及功能描述，確認驗收標準
3. 輸出執行計劃，等待確認
4. 設計測試案例（Happy / Error / Edge / Security / Idempotency / Performance）
5. 依序執行 Unit → Integration → E2E → Security → Regression
6. 輸出 QA 測試報告
7. 按 post-review-handoff.md → Protocol 2 執行 handoff
8. 如有 common knowledge 記錄入 shared-knowledge.md
```

---

## 測試案例設計框架

```
✅ Happy Path     ← 正常輸入，預期成功
❌ Error Path     ← 無效輸入、系統錯誤
🔲 Edge Case      ← 空值、null、極端值、特殊字元
🔒 Security Case  ← 未授權、invalid token、injection、IDOR
🔄 Idempotency    ← 重複操作唔應造成數據異常
⚡ Performance    ← 關鍵 API 符合 response time 基準
```

命名：`it('should [預期結果] when [條件]')`

---

## Performance Testing

### Response Time 基準（可由 project CLAUDE.md 覆蓋）

| API 類型 | P50 | P95 | P99 |
|----------|-----|-----|-----|
| 一般讀取 | < 100ms | < 300ms | < 500ms |
| 列表查詢 | < 200ms | < 500ms | < 1s |
| 寫入操作 | < 200ms | < 500ms | < 1s |
| 複雜報表 | < 2s | < 5s | < 10s |

### 必須執行 Performance Test 嘅情況

```
□ 新增涉大數據量 API（列表、搜尋、報表）
□ 新增 DB 查詢（必須 EXPLAIN 確認用 index）
□ 新增外部 API 調用（必須有 timeout）
□ 修改現有高頻 API
□ 任何 N+1 query 風險改動
```

### k6 範例

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 50, duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('http://staging/api/v1/users');
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

### 判定

```
🔴 Critical：P95 超基準 2 倍，或失敗率 > 1%
🟡 Warning：P95 超基準，或明顯 N+1 query
🟢 Observation：可優化但未超標
```

---

## 阻止 Release 條件

以下情況 QA 必須 reject（見 post-review-handoff.md → Protocol 2）：

```
🚫 任何 🔴 Critical 測試失敗
🚫 核心業務流程測試失敗
🚫 安全測試失敗
🚫 數據一致性測試失敗
```

---

## 使用方式

```
/test                       ← 完整測試計劃
/test --unit-only           ← 只執行 unit
/test --e2e-only            ← 只執行 E2E
/test --performance         ← 執行 performance
/test --regression          ← 回歸測試
/test --scope=src/payment   ← 只測指定模組
/test --design              ← 只輸出計劃，唔執行
```
