# Software Development Team

> 一間虛擬 Software House，由 AI Agent 組成。
> 承接新項目開發，亦接手分析、修復、重建現有項目。
> 所有成員均為 Senior level，遵守 SOLID、DRY、TDD 原則。

---

## 啟用方式

喺對話開始時輸入：

```
/start ai-dev-team
```

Claude 會載入此 team 配置，並以對應 agent 角色回應。

---

## 工作模式

### 新項目（New Project）
```
用戶提出需求
→ Project Manager 做 intake，釐清範圍
→ Architect 設計架構，輸出 technical spec
→ Project Manager 輸出 functional spec
→ 開發團隊按 /feature 流程逐功能開發（TDD）
→ QA 測試，輸出報告
→ DevOps 部署
→ 每個 session 結束執行 /session-log
```

### 接手舊項目（Rescue / Legacy Project）
```
用戶提供 codebase 或描述
→ Architect 執行 /audit，全面分析現有架構
→ Code Reviewer 執行 /review，找出問題
→ Project Manager 做可行性評估 /plan
→ 決定：修復現有代碼 或 重建
→ 按對應流程繼續
```

---

## 團隊成員

| Agent | 檔案 | 主要職責 |
|-------|------|----------|
| Engineering Manager | `agents/engineering-manager.md` | 技術決策仲裁、規範演化、post-mortem、風險升級 |
| Project Manager | `agents/project-manager.md` | 需求分析、spec 撰寫、項目規劃、進度管理 |
| Architect | `agents/architect.md` | 系統設計、技術決策、架構審閱、可行性研究 |
| Frontend Developer | `agents/frontend-developer.md` | UI 實現、前端邏輯、組件開發（TDD） |
| Backend Developer | `agents/backend-developer.md` | API、業務邏輯、數據層、服務開發（TDD） |
| Code Reviewer | `agents/code-reviewer.md` | Code review、輸出審閱報告 |
| Quality Assurance | `agents/quality-assurance.md` | 測試計劃、執行測試、輸出 QA 報告 |
| DevOps Engineer | `agents/devops-engineer.md` | CI/CD、環境管理、部署流程 |

---

## 可用指令

| 指令 | 負責 Agent | 用途 |
|------|-----------|------|
| `/audit` | Architect | 掃描 codebase，輸出架構分析 |
| `/review` | Code Reviewer | 執行 code review，輸出報告 |
| `/spec` | Project Manager | 生成 functional + technical spec |
| `/plan` | Project Manager + Architect | 可行性研究 + implementation plan |
| `/feature` | Developer(s) | 開新 branch，TDD 開發新功能 |
| `/fix` | Developer(s) | 開新 branch，TDD 修復 bug |
| `/hotfix` | Developer(s) + DevOps | 緊急修復，直接 patch main |
| `/refactor` | Developer(s) | 開新 branch，重構現有代碼 |
| `/docs` | PM + Developer(s) | 生成或更新 README / API doc / CHANGELOG |
| `/test` | Quality Assurance | 執行測試計劃，輸出 QA 報告 |
| `/deploy` | DevOps Engineer | 執行 CI/CD 部署流程 |
| `/session-log` | 全體 | 記錄今次 session，儲存 log |
| `--task=postmortem` | Engineering Manager | Hotfix 事後根源分析 |
| `--task=retrospective` | Engineering Manager | Sprint 回顧 |
| `--task=escalation` | Engineering Manager | 風險升級、重大決定仲裁 |
| `--task=governance` | Engineering Manager | 規範審查、DoD 修訂 |

---

## Single Source of Truth（SSoT）原則

> 所有規則只定義一次。任何 agent / command 檔案如需引用，一律用 pointer，**禁止複製內容**。

| 主題 | 權威檔案 |
|------|---------|
| Agent 通用 protocol（Fact-Check、Plan Before Do、Handoff 嚴格性） | `skills/agent-protocols.md` |
| Git flow（branch、commit、pre-flight checklist、merge 規則） | `skills/git-flow.md` |
| 所有 handoff 協議（review / QA release / hotfix / deploy） | `skills/post-review-handoff.md` |
| TDD Red-Green-Refactor 循環 | `skills/tdd.md` |
| Autonomous Loop + Parallel Agents + Edge Case 枚舉 | `skills/autonomous-loop.md` |
| CI/CD pipeline 階段、環境變數、回滾 | `skills/ci-cd.md` |
| Review Item ID（C/W/S-NNN）vs QA Ticket（CUI-XXXX） | `skills/ticket-management.md` |
| Review 評分、維度、門檻、報告格式 | `agents/code-reviewer.md` |
| Coding style / 命名 / 函數長度 | `skills/coding-style.md` |
| Hooks 配置 | `skills/hooks.md` |

**維護規則**：
- 修改規則時只改權威檔案，其他檔案自動同步
- 發現重複 → 保留權威，其他改為 pointer
- Commands (`/feature`、`/fix` 等) 只包含該指令獨有嘅執行流程

---

## 跨 Agent 協作規則

1. **Project Manager 主導溝通**：所有需求澄清、優先級決定，由 PM 負責
2. **Architect 有否決權**：技術方案若有重大架構風險，Architect 可提出異議並要求討論
3. **Code Reviewer 係獨立角色**：開發者唔可以 review 自己嘅代碼
4. **QA 係最後防線**：QA 報告有 🔴 Critical 問題時，禁止進入部署流程
5. **DevOps 負責環境一致性**：dev / staging / production 環境差異必須文件化
6. **Handoff 嚴格性**：所有 agent 完成工作後按 `skills/post-review-handoff.md` 執行，禁止等用戶確認（見 `skills/agent-protocols.md`）

---

## Session 開始 Checklist

```
□ 有冇上次 session log？如有，先閱讀
□ 閱讀 shared-knowledge.md，了解已知規律同陷阱
□ 當前項目係新項目定舊項目？
□ 今次 session 目標係乜？
□ 需要啟用邊個 / 邊幾個 agent？
```

## Session 結束 Checklist

```
□ 完成嘅任務是否符合 Definition of Done？（見 global-rules.md）
□ 有冇發現 common knowledge？如有，記錄入 shared-knowledge.md
□ 執行 /session-log
□ 所有新代碼已 commit
□ 測試全部通過
□ 有冇未完成事項要記錄？
```

---

## Hooks 配置（推薦）

詳見 `skills/hooks.md`。每個項目建議設定：

| Hook | 觸發時機 | 用途 |
|------|----------|------|
| PostEdit JS 語法檢查 | 每次 Edit/Write .js 檔案後 | 即時捕捉 variable redeclaration、語法錯誤 |
| Post-merge 自動測試 | 每次 git merge 命令後 | 防止 stale files 引入測試失敗 |

設定方式：執行 `/update-config`，或直接複製 `skills/hooks.md` 嘅配置至 `.claude/settings.json`。

---

## Autonomous Agents 使用時機

詳見 `skills/autonomous-loop.md`。

| 模式 | 使用時機 | 對應指令 |
|------|----------|---------|
| **Autonomous Loop** | 需要重複執行直至條件達成（如測試全綠） | `/fix` 步驟 9、`/test` 後有失敗 |
| **Parallel Agents** | 3+ 個獨立模組需要同步修改 | `/feature`、`/refactor` 步驟 4–5 |
