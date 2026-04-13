# [項目名稱] — Project Configuration

> 此檔案放置於 `~/projects/[project-name]/CLAUDE.md`。
> 覆蓋 `~/.claude/` 全局設定，優先級最高。
> 使用前刪除所有 `[...]` 佔位符及說明注釋。

---

## 版本記錄

| 版本 | 日期 | 更新人 | 改動描述 |
|------|------|--------|----------|
| v1.0 | YYYY-MM-DD HH:MM | [Agent / 用戶] | 初始建立 |

**當前版本**：v1.0
**最後更新**：YYYY-MM-DD HH:MM

---

## 啟用 Team

```
/start ai-dev-team
```

---

## Project Info

| 項目 | 內容 |
|------|------|
| **名稱** | [項目名稱，例如：Customer Portal] |
| **Alias** | [票據前綴，例如：CUI（用於 ticket 編號 CUI-0001）] |
| **類型** | [新項目 / 接手項目 / Rescue 項目 / 重建項目] |
| **狀態** | [Active / In Development / Maintenance] |
| **建立日期** | YYYY-MM-DD HH:MM |

---

## Tech Stack

> 此處定義覆蓋 agent 預設技術能力。

| 層級 | 技術 | 版本 | 備注 |
|------|------|------|------|
| Frontend | [React / Vue / Next.js / 其他] | [版本] | |
| 語言 | [TypeScript / JavaScript] | [版本] | |
| 狀態管理 | [Zustand / Redux / Pinia / 其他] | [版本] | |
| Backend | [Node.js / Python / PHP / 其他] | [版本] | |
| 框架 | [Express / FastAPI / Laravel / 其他] | [版本] | |
| 數據庫 | [PostgreSQL / MySQL / MongoDB / 其他] | [版本] | |
| Cache | [Redis / Memcached / 無] | [版本] | |
| ORM | [Prisma / TypeORM / SQLAlchemy / 其他] | [版本] | |
| 測試（前端） | [Vitest / Jest / 其他] | [版本] | |
| 測試（後端） | [Jest / Pytest / PHPUnit / 其他] | [版本] | |
| CI/CD | [GitHub Actions / GitLab CI / 其他] | | |
| 部署平台 | [Vercel / AWS / Railway / 其他] | | |

---

## 環境資訊

| 環境 | URL / 位置 | 備注 |
|------|-----------|------|
| Development | `http://localhost:[port]` | |
| Staging | [URL] | |
| Production | [URL] | |

---

## Active Agents

> 此項目主要用到嘅 agents（唔需要列出冇用到嘅）

- [x] Project Manager
- [x] Architect
- [x] Frontend Developer
- [x] Backend Developer
- [x] Code Reviewer
- [x] Quality Assurance
- [x] DevOps Engineer

---

## Constraints（限制條件）

> 必須明確列出，所有 agent 嚴格遵守。

### 唔可以改動
```
- [例如：users 表 schema 唔可以改，有 legacy 系統依賴]
- [例如：/api/v1/ 所有 endpoint 必須保持向後兼容]
- [如無限制，填「無」]
```

### 技術限制
```
- [例如：只可以用 MySQL，唔可以換數據庫]
- [例如：唔可以引入需要付費的第三方服務]
- [如無限制，填「無」]
```

### 安全要求
```
- [例如：所有 API 必須有 rate limiting]
- [例如：用戶數據唔可以存喺第三方服務]
- [如無特殊要求，填「遵從 global-rules.md 安全規範」]
```

---

## 項目特有規範

> 覆蓋或補充 global-rules.md 嘅規範，只寫同全局規範不同嘅地方。

### Coding Style 補充
```
- [例如：component 最大行數改為 80 行（視覺組件較複雜）]
- [例如：唔用 Tailwind，用 CSS Modules]
- [如無補充，刪除此節]
```

### Git 補充
```
- [例如：commit message 必須用英文]
- [例如：所有 PR 必須兩人 review]
- [如無補充，刪除此節]
```

### 命名補充
```
- [例如：Interface 統一加 I 前綴（IUserRepository）]
- [例如：API endpoint 用英文，唔用縮寫]
- [如無補充，刪除此節]
```

---

## 外部依賴 & 整合

| 服務 | 用途 | 文件 / 備注 |
|------|------|------------|
| [例如：Stripe] | [付款處理] | [API 文件連結] |
| [例如：SendGrid] | [郵件發送] | [API 文件連結] |

---

## 重要文件連結

| 文件 | 位置 |
|------|------|
| Functional Spec | [連結或路徑] |
| Technical Spec | [連結或路徑] |
| API 文件 | [連結或路徑] |
| 設計稿 | [連結或路徑] |
| Staging 環境 | [連結] |

---

## Session Log 位置

```
~/projects/[project-name]/.claude/session-logs/
```

## Shared Knowledge 位置

```
~/projects/[project-name]/.claude/shared-knowledge.md
```

---

## 備注

[任何其他需要所有 agent 知道嘅重要資訊]
