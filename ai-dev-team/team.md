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
| `/session-close` | 全體 | 記錄今次 session log 並自動關閉 session |
| `--task=postmortem` | Engineering Manager | Hotfix 事後根源分析 |
| `--task=retrospective` | Engineering Manager | Sprint 回顧 |
| `--task=escalation` | Engineering Manager | 風險升級、重大決定仲裁 |
| `--task=governance` | Engineering Manager | 規範審查、DoD 修訂 |

---

## Single Source of Truth（SSoT）原則

> 所有規則只定義一次。任何 agent / command 檔案如需引用，一律用 pointer，**禁止複製內容**。

| 主題 | 權威檔案 |
|------|---------|
| Agent 通用 protocol（Fact-Check、Plan、Context Budget、On-demand loading） | `skills/sw-agent-protocols/SKILL.md` |
| Handoff 協議 + `handoff-receipt` 格式 | `skills/sw-post-review-handoff/SKILL.md` |
| Tool × Agent 權限矩陣、Git/Deploy 歸屬 | `skills/sw-tool-inventory/SKILL.md` |
| Git flow（branch、commit、pre-flight、merge 規則） | `skills/sw-git-flow/SKILL.md` |
| TDD Red-Green-Refactor 循環 | `skills/sw-tdd/SKILL.md` |
| Autonomous Loop + Parallel Agents（低層機制）+ Edge Case 枚舉 | `skills/sw-autonomous-loop/SKILL.md` |
| Multi-task Parallel Dispatch（決策層：conflict matrix、lane clustering、batch review/QA/release） | `skills/sw-parallel-dispatch/SKILL.md` |
| CI/CD pipeline 階段、環境變數、回滾 | `skills/sw-ci-cd/SKILL.md` |
| Review Item ID（C/W/S-NNN）vs QA Ticket（CUI-XXXX） | `skills/sw-ticket-management/SKILL.md` |
| Review hard gates、評分維度、門檻 | `agents/code-reviewer.md` |
| Coding style / 命名 / 函數長度 | `skills/sw-coding-style/SKILL.md` |
| Hooks 配置（含 handoff-receipt enforcement） | `skills/sw-hooks/SKILL.md` |

**原生 Skill 機制**：

- 所有 `skills/*.md` 檔案頭部有 YAML frontmatter（`name: sw-*` + `description`），符合 Claude Code Skill 格式
- 所有 skill 以 `skills/<name>/SKILL.md` 形式打包喺 `ai-dev-team` plugin 內，Claude Code（Local 同 Cloud session）可透過原生 Skill tool lazy load（名稱帶 namespace：`ai-dev-team:sw-<name>`）
- Agent 唔應 inline skill 內容；任務需要時透過 **Skill tool** 或 Read `skills/<name>.md` 載入（見 `agent-protocols.md` §6 Context Budget）
- 更新 skill 檔案後 push 上 marketplace repo，cloud session 要靠 environment setup script 安裝，唔可靠 project settings 自動裝（見 SK-009）；Local 模式用 `claude plugin update ai-dev-team`
- ⚠️ **Cloud 版本 staleness**：environment 快照一旦影好，之後新 session 會 skip setup script，而「push 新版本」唔係快照重建 trigger → cloud 會靜默沿用快照內嘅舊 plugin 版本。要生效需手動改一下 setup script 強制重建，或等快照約七日過期（見 SK-009）

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
6. **Handoff 嚴格性**：所有 agent 完成工作後按 `skills/sw-post-review-handoff/SKILL.md` 執行，禁止等用戶確認（見 `skills/sw-agent-protocols/SKILL.md`）

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

詳見 `skills/sw-hooks/SKILL.md`。每個項目建議設定：

| Hook | 觸發時機 | 用途 |
|------|----------|------|
| PostEdit JS 語法檢查 | 每次 Edit/Write .js 檔案後 | 即時捕捉 variable redeclaration、語法錯誤 |
| Post-merge 自動測試 | 每次 git merge 命令後 | 防止 stale files 引入測試失敗 |

設定方式：執行 `/update-config`，或直接複製 `skills/sw-hooks/SKILL.md` 嘅配置至 `.claude/settings.json`。

---

## Autonomous Agents 使用時機

詳見 `skills/sw-autonomous-loop/SKILL.md`。

| 模式 | 使用時機 | 對應指令 |
|------|----------|---------|
| **Autonomous Loop** | 需要重複執行直至條件達成（如測試全綠） | `/fix` 步驟 9、`/test` 後有失敗 |
| **Parallel Agents** | 3+ 個獨立模組需要同步修改 | `/feature`、`/refactor` 步驟 4–5 |
