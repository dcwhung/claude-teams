# 指令：/docs

## 用途

生成或更新項目文件，包括 README、API 文件（OpenAPI）、CHANGELOG。
確保文件同代碼同步，避免文件落後於實現。

## 負責 Agent

**Project Manager**（README、CHANGELOG）
**Backend Developer**（API 文件 / OpenAPI spec）
**Frontend Developer**（組件文件）
**Architect**（架構文件）

---

## 引用規範（SSoT）

- Plan Before Do 確認規則（main vs subagent）→ `skills/agent-protocols.md` §2

本檔案只定義 `/docs` 獨有嘅執行流程、README / OpenAPI / CHANGELOG 格式同文件同步規則。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 確認文件類型（見 --type 選項）
3. 輸出執行計劃
   - Main agent（直接同用戶對話）：等用戶確認
   - Subagent（由 main agent invoke）：立即執行，唔等確認（見 agent-protocols.md §2）
4. 讀取現有代碼 / spec，生成或更新文件
5. 輸出文件
6. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## README 規範

每個項目必須有 README，包含以下章節（按順序）：

```markdown
# [項目名稱]

[一段話描述項目係乜、解決乜問題]

## 快速開始

\`\`\`bash
# 1. Clone
git clone [repo URL]

# 2. 安裝依賴
npm install

# 3. 設定環境變數
cp .env.example .env.local
# 填寫 .env.local 必填欄位

# 4. 執行 migration（如有）
npm run migration:run

# 5. 啟動開發環境
npm run dev
\`\`\`

## 環境需求

| 工具 | 最低版本 |
|------|----------|
| Node.js | 20.x |
| npm | 10.x |
| Docker | 24.x |

## 項目結構

\`\`\`
src/
  api/          ← API routes
  services/     ← 業務邏輯
  repositories/ ← 數據訪問
  utils/        ← 工具函數
\`\`\`

## 可用指令

| 指令 | 用途 |
|------|------|
| \`npm run dev\` | 啟動開發環境 |
| \`npm run build\` | 生產 build |
| \`npm run test\` | 執行全套測試 |
| \`npm run lint\` | 執行 lint |

## 環境說明

見 `docs/environments.md`

## 貢獻指引

見 `CONTRIBUTING.md`（如有）
```

---

## API 文件規範（OpenAPI）

後端新增或修改 API 後，必須同步更新 OpenAPI spec：

```yaml
# 位置：docs/api/openapi.yaml 或 openapi.json

openapi: 3.1.0
info:
  title: [項目名稱] API
  version: 1.0.0
  description: [API 描述]

paths:
  /api/v1/users:
    get:
      summary: 取得用戶列表
      tags: [Users]
      security:
        - bearerAuth: []
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserListResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
```

**必填欄位**：
- 所有 endpoint 有 `summary`
- 所有 request body 有 schema 定義
- 所有 response 有 schema（至少 200 同常見錯誤碼）
- 需要認證嘅 endpoint 標明 `security`

---

## CHANGELOG 規範

遵從 [Keep a Changelog](https://keepachangelog.com) 格式：

```markdown
# Changelog

## [Unreleased]

## [1.2.0] - YYYY-MM-DD

### Added
- 新增用戶頭像上傳功能（CUI-0015）
- 新增 /api/v2/users endpoint（向後兼容）

### Changed
- 付款流程優化，減少步驟

### Fixed
- 修復 token 過期後返回 500 問題（CUI-0001）
- 修復 Safari 日期格式解析錯誤（CUI-0004）

### Deprecated
- /api/v1/profile 將於 v1.4.0 移除，請改用 /api/v2/users/:id

### Security
- 修復 CORS 過寬配置問題

## [1.1.0] - YYYY-MM-DD
...
```

**生成方式**：從 git log 同 ticket 記錄自動整理，按 `Added / Changed / Fixed / Deprecated / Security` 分類。

---

## 文件同步規則

以下情況必須執行 `/docs` 更新：

```
□ 新增或修改 API endpoint → 更新 OpenAPI spec
□ 新增環境變數 → 更新 .env.example 及 README
□ 改變啟動步驟 → 更新 README「快速開始」
□ 每次 release → 更新 CHANGELOG
□ 新增主要功能 → 更新 README「項目結構」（如有改變）
```

---

## 使用方式

```
/docs                        ← 審查現有文件，列出過時或缺失部分
/docs --type=readme          ← 生成或更新 README
/docs --type=api             ← 生成或更新 OpenAPI spec
/docs --type=changelog       ← 生成本次 release 嘅 CHANGELOG 條目
/docs --type=all             ← 更新所有文件
```
