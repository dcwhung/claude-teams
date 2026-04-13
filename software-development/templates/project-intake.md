# Template：Project Intake

> 每個新項目或接手舊項目時，PM 必須先完成此表，釐清方向先開始工作。

---

# Project Intake：[項目名稱]

**日期**：YYYY-MM-DD HH:MM
**負責 PM**：Project Manager Agent
**填寫方式**：由 PM 主導提問，用戶回答後填寫

---

## 項目類型

- [ ] 🆕 **新項目**（從零開始）
- [ ] 🔧 **接手現有項目**（繼續未完成功能）
- [ ] 🚑 **Rescue 項目**（修復失敗或問題嚴重嘅項目）
- [ ] 🔄 **重建項目**（以新架構重寫現有系統）

---

## 基本資訊

| 項目 | 內容 |
|------|------|
| 項目名稱 | |
| 業務描述 | |
| 目標用戶 | |
| 核心問題 | [呢個項目解決咩問題] |
| 成功指標 | [點樣衡量成功] |

---

## 現有情況（接手 / Rescue / 重建項目填寫）

### Codebase 狀態
- [ ] 有完整代碼，可以運行
- [ ] 有代碼，但無法運行
- [ ] 有部分代碼
- [ ] 只有舊版本或備份

### 已知問題
[描述已知嘅問題、錯誤或未完成功能]

### 現有文件
- [ ] 有 README
- [ ] 有 API 文件
- [ ] 有 spec 或設計文件
- [ ] 有測試
- [ ] 基本上冇文件

### 前任開發情況
[如有，描述前任開發者留下嘅狀況]

---

## 技術要求

| 項目 | 內容 |
|------|------|
| 前端框架 | [或「待 Architect 決定」] |
| 後端語言 / 框架 | [或「待 Architect 決定」] |
| 數據庫 | [或「待 Architect 決定」] |
| 部署平台 | |
| 有冇現有系統需要整合 | |
| 有冇 API 需要對接 | |

---

## 限制條件（Constraints）

| 類別 | 內容 |
|------|------|
| 技術限制 | [必須用某技術 / 唔可以用某技術] |
| 唔可以改動嘅部分 | [例如：DB schema、現有 API] |
| 安全要求 | |
| 性能要求 | |
| 其他限制 | |

---

## 範圍（Scope）

### 此次包含

- [功能 / 模組 1]
- [功能 / 模組 2]

### 此次**不包含**（Out of Scope）

- [明確列出唔做嘅嘢，避免 scope creep]

---

## 時間線

| 里程碑 | 目標日期 | 備注 |
|--------|----------|------|
| Audit / 需求確認完成 | | |
| Spec 完成 | | |
| 開發完成 | | |
| QA 完成 | | |
| 上線 | | |

---

## 建議工作流程

根據項目類型，建議以下流程：

### 🆕 新項目
```
/spec → /plan → /feature（逐功能）→ /test → /deploy
```

### 🔧 接手現有項目
```
/audit → /plan → /feature 或 /fix → /test → /deploy
```

### 🚑 Rescue 項目
```
/audit → /review（現有代碼）→ /plan（決定修復或重建）
→ 修復：/fix → /test → /deploy
→ 重建：/spec → /plan → /feature → /test → /deploy
```

### 🔄 重建項目
```
/audit（了解現有系統）→ /spec（新系統）→ /plan → /feature → /test → /deploy
```

---

## 開放問題

| 問題 | 重要性 | 需要誰決定 | 截止日期 |
|------|--------|-----------|----------|
| | 高/中/低 | | |

---

## Intake 確認

- [ ] 用戶已確認項目類型及範圍
- [ ] 技術限制已釐清
- [ ] Out of scope 已明確列出
- [ ] 時間線已確認（或標注「待定」）
- [ ] 開放問題已記錄
- [ ] **Project Alias 已定義**（用於 ticket 編號，例如 `CUI`）

**下一步**：[根據項目類型，執行對應嘅第一個指令]

---

## 項目初始化 Checklist

新項目確認 intake 後，執行以下初始化：

```bash
# 1. 建立項目 CLAUDE.md（從模板 copy）
cp ~/.claude/teams/software-development/templates/project-claude.md \
   ~/projects/[project-name]/CLAUDE.md
# 然後填寫所有 [...] 佔位符

# 2. 建立 ticket 資料夾結構
mkdir -p .tickets/pending/0001-0200
mkdir -p .tickets/in-progress/0001-0200
mkdir -p .tickets/completed/0001-0200
mkdir -p .tickets/on-hold/0001-0200

# 3. 建立 .proj-docs 資料夾結構（供真人閱讀）
mkdir -p .proj-docs/specs
mkdir -p .proj-docs/plans
mkdir -p .proj-docs/audits
mkdir -p .proj-docs/reviews
mkdir -p .proj-docs/qa-reports
mkdir -p .proj-docs/diagrams/flow
mkdir -p .proj-docs/diagrams/data-flow
mkdir -p .proj-docs/diagrams/database
mkdir -p .proj-docs/diagrams/archive
mkdir -p .proj-docs/deploys
mkdir -p .proj-docs/docs

# 建立空白 index.md
cat > .proj-docs/index.md << 'EOF'
# Project Docs Index

**最後更新**：YYYY-MM-DD HH:MM

## Specs
## Plans
## Diagrams
## Audits
## Reviews
## QA Reports
## Deploys
## Docs
EOF

# 4. 建立 .claude/session-logs（供 AI agent 讀寫）
mkdir -p .claude/session-logs

# 5. 更新 .gitignore（敏感內部文件唔 commit）
cat >> .gitignore << 'EOF'

# AI team 內部文件
.claude/session-logs/

# 敏感報告（含 audit / security / QA 詳情）
.proj-docs/audits/
.proj-docs/qa-reports/

# 如需 commit diagrams、specs、plans，保留以下；否則可加入：
# .proj-docs/
EOF
```

Project `CLAUDE.md` 模板位置：`~/.claude/teams/software-development/templates/project-claude.md`

必須填寫嘅欄位：
- `Project Info` — 名稱、Alias、類型
- `Tech Stack` — 所有技術及版本
- `Constraints` — 唔可以改動嘅部分
- `Active Agents` — 勾選此項目用到嘅 agents
