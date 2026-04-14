---
name: sw-tool-inventory
description: Per-agent tool permissions, error modes, and boundaries. Load when invoking an agent to verify it has the tools it needs, or when an agent is about to perform a side-effectful operation (git, deploy, db).
---

# Skill：Tool Inventory

> **Harness 原則：tool 係 tool，role 係 role。**
> Agent 角色定義行為，tool 提供能力。每個 agent 嘅 tool 權限明確列出，避免職責蔓延。

---

## 通用權限（所有 agent）

| Tool | 用途 | 備注 |
|------|------|------|
| Read | 讀取檔案 | 無限制 |
| Glob | 搵檔案 | 無限制 |
| Grep | 搜代碼 | 無限制 |
| Edit | 改檔案 | 限 agent 負責範圍 |
| Write | 寫檔案 | 限 agent 負責範圍 |

---

## Agent × Tool 矩陣

| Agent | Bash | Git 操作 | DB 操作 | Deploy | Agent tool (invoke subagent) |
|-------|:----:|:-------:|:------:|:------:|:----------------------------:|
| Main agent | ✅ | ✅ **全權** | ⚠️ 需確認 | ⚠️ 需確認 | ✅ |
| Project Manager | ❌ | ❌ | ❌ | ❌ | ❌ |
| Architect | ⚠️ 唯讀（`git log`、`grep`） | ❌ | ❌ | ❌ | ❌ |
| Frontend Developer | ✅ 限 test / build / lint | ❌ | ❌ | ❌ | ❌ |
| Backend Developer | ✅ 限 test / build / lint / migration dry-run | ❌ | ⚠️ dry-run only | ❌ | ❌ |
| Code Reviewer | ✅ 限 lint / type / test / coverage（hard gates） | ❌ | ❌ | ❌ | ❌ |
| Quality Assurance | ✅ 限 test suite / security scan / k6 / EXPLAIN | ❌ | ⚠️ 唯讀 | ❌ | ❌ |
| DevOps Engineer | ✅ 限 CI/CD pipeline | ❌ | ⚠️ migration 執行 | ✅ | ❌ |
| Engineering Manager | ⚠️ 唯讀（audit） | ❌ | ❌ | ❌ | ❌ |

**圖例**：
- ✅ 完全允許
- ⚠️ 條件允許（需滿足前置條件）
- ❌ 禁止

---

## 關鍵規則

### 1. Git 操作統一由 Main Agent 執行

**所有 subagent 禁止執行** `git merge`、`git branch -d`、`git push`、`git reset`、`git checkout`（例外：subagent 可 `git status` / `git diff` / `git log` 只做唯讀觀察）。

原因：
- Git 係 side effect，Harness 原則要求 side effect 集中管理
- Subagent 如果執行 git 失敗，錯誤處理分散，難以 audit
- Main agent 根據 `handoff-receipt` 統一路由，邏輯集中

### 2. Deploy 統一由 DevOps Engineer 執行

即使 main agent 有權，實際 `/deploy` 必須 invoke DevOps agent。原因：pipeline / rollback 邏輯集中一處。

### 3. DB 寫操作需授權

Production DB 嘅寫操作（migration、seed、manual update）必須：
- 有 migration 檔案（唔直接 SQL）
- DevOps 執行，Backend Developer 只 dry-run
- Main agent 事前向用戶確認

### 4. Subagent 禁止 invoke 另一個 subagent

Claude Code 架構上 subagent 無法 spawn subagent。任何跨 agent 協作必須透過 `handoff-receipt` → main agent → 下一個 Agent tool call。

---

## Error Mode 處理

| Tool 失敗情況 | 處理方式 |
|-------------|---------|
| Git merge conflict | Main agent 停止路由，輸出 conflict 檔案，invoke 對應 Developer |
| Lint / type check fail | Reviewer 填 `hard_gates.lint=fail`，status=fail，main agent 不 merge |
| Test fail | 同上 |
| Deploy smoke test fail | DevOps 立即 rollback，receipt `next_action=rollback` |
| Migration fail | DevOps 立即執行 down migration，唔部署新代碼 |
| Subagent 輸出無 receipt | Main agent 視為 fail，唔執行下一步，invoke 同一 agent 要求補交 receipt |
| Subagent 輸出 receipt 格式錯 | 同上 |

---

## Permission 升級流程

如 agent 需要超出本表嘅權限（例：Backend Developer 需要直接寫 prod DB）：

1. Agent 在 receipt `blockers` 欄位列明所需權限
2. Main agent 停止路由，向用戶明確請求授權
3. 授權後改為 main agent 親自執行該操作，唔擴大 agent 權限
4. 紀錄於 session log
