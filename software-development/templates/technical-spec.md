# Template：Technical Spec

> 由 Architect Agent 主導撰寫，配合 Project Manager。
> 描述「點做」，必須基於已 Approved 嘅 Functional Spec。
> 開發團隊嘅執行依據。

---

# Technical Spec：[功能 / 項目名稱]

**版本**：v1.0
**日期**：YYYY-MM-DD HH:MM
**作者**：Architect Agent
**關聯 Functional Spec**：[版本 + 日期]
**審閱者**：[用戶 / 相關人員]
**狀態**：🔵 Draft / 🟡 In Review / ✅ Approved

---

## 修訂記錄

| 版本 | 日期 | 改動描述 | 作者 |
|------|------|----------|------|
| v1.0 | YYYY-MM-DD HH:MM | 初稿 | Architect Agent |

---

## 架構概覽

[文字描述整體技術架構，包括各層次職責及邊界]

### 架構圖（文字描述）

```
[Frontend]
  React SPA
    ↓ HTTP / WebSocket
[API Gateway / BFF]
  Express / Fastify
    ↓
[Service Layer]
  UserService | PaymentService | ...
    ↓
[Repository Layer]
  UserRepository | PaymentRepository | ...
    ↓
[Database]
  PostgreSQL        Redis（Cache）
```

---

## Tech Stack

| 層級 | 技術 | 版本 | 選擇原因 |
|------|------|------|----------|
| Frontend | | | |
| 狀態管理 | | | |
| Backend | | | |
| ORM | | | |
| 主數據庫 | | | |
| Cache | | | |
| 認證 | | | |
| 測試（前端） | | | |
| 測試（後端） | | | |
| CI/CD | | | |
| 部署平台 | | | |

---

## API 設計

### 認證方式

[描述認證機制，例如 JWT Bearer Token]

```
Authorization: Bearer <access_token>
```

### 統一 Response 格式

```json
// 成功
{
  "success": true,
  "data": { },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}

// 失敗
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "人類可讀嘅錯誤描述"
  }
}
```

### Endpoints

#### [API-001] [功能描述]

- **Method**：`POST`
- **Path**：`/api/v1/[resource]`
- **認證**：Required / Optional / None
- **描述**：[此 endpoint 做乜]

**Request Headers**：
```
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body**：
```json
{
  "field1": "string",
  "field2": 123
}
```

**Validation Rules**：
| 欄位 | 類型 | 必填 | 規則 |
|------|------|------|------|
| field1 | string | ✅ | min: 1, max: 255 |
| field2 | number | ❌ | min: 0 |

**Response（200 / 201）**：
```json
{
  "success": true,
  "data": { }
}
```

**Error Cases**：
| Status | Code | 觸發條件 |
|--------|------|----------|
| 400 | VALIDATION_ERROR | 輸入驗證失敗 |
| 401 | UNAUTHORIZED | Token 缺失或過期 |
| 403 | FORBIDDEN | 無權限 |
| 404 | NOT_FOUND | 資源不存在 |
| 409 | CONFLICT | 重複建立 |
| 500 | INTERNAL_ERROR | 服務器錯誤 |

---

## 數據庫設計

### Tables / Collections

#### `[table_name]`

| 欄位 | 類型 | 約束 | 描述 | 預設值 |
|------|------|------|------|--------|
| `id` | `uuid` | PK, NOT NULL | 主鍵 | `gen_random_uuid()` |
| `created_at` | `timestamptz` | NOT NULL | 建立時間 | `now()` |
| `updated_at` | `timestamptz` | NOT NULL | 更新時間 | `now()` |

#### 關係

```
users (1) ──< (N) posts
posts (1) ──< (N) comments
```

#### 索引設計

```sql
-- 說明建立原因
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

---

## 安全設計

### 認證 & 授權
- Access Token：JWT，有效期 15 分鐘
- Refresh Token：httpOnly cookie，有效期 7 天
- 授權方式：[RBAC / ABAC / 其他]

### 輸入驗證
- 所有 API 輸入使用 Zod / Joi 做 schema validation
- SQL 操作全部使用 parameterized queries
- 禁止字串拼接 SQL

### 敏感資料
- 密碼：bcrypt，cost factor 12
- 敏感欄位不出現喺 log
- API response 不返回密碼等敏感欄位

---

## 性能考量

### 預期負載
[描述預期用戶數、請求量等]

### 潛在瓶頸
[識別可能嘅性能瓶頸]

### 緩存策略
| 數據 | 緩存位置 | TTL | 失效策略 |
|------|----------|-----|----------|
| | Redis / Memory | | |

### 數據庫優化
[索引策略、查詢優化、分頁方式]

---

## 錯誤處理策略

```
業務邏輯錯誤    → 返回對應 4xx，附 error code
外部服務失敗    → Retry（最多 3 次，exponential backoff）
數據庫錯誤      → 500，記錄 log，唔暴露細節
未預期錯誤      → 500，記錄完整 stack trace
```

---

## 部署架構

### 環境

| 環境 | 用途 | 部署方式 |
|------|------|----------|
| Development | 本地開發 | docker-compose |
| Staging | QA 測試 | 自動（CI/CD） |
| Production | 正式服務 | 自動 + 人工確認 |

### 環境變數清單

```bash
# 必填
DATABASE_URL=
JWT_SECRET=
JWT_REFRESH_SECRET=

# 可選（有預設值）
APP_PORT=3000
LOG_LEVEL=info
```

---

## 技術風險

| 編號 | 風險描述 | 可能性 | 影響 | 應對方案 |
|------|----------|--------|------|----------|
| TR-001 | | 高/中/低 | 高/中/低 | |

---

## 實現注意事項

[開發時需要特別留意嘅技術細節、陷阱、或已知限制]

---

## 附錄

### 相關文件
- Functional Spec：[連結]
- API 文件（Postman / OpenAPI）：[連結]
- 數據庫 ERD：[連結]
