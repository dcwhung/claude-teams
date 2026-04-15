---
name: sw-agent-protocols
description: Universal agent behavior — Fact-Check before answer, Plan Before Do template, handoff strictness, context budget management, on-demand skill loading. Load at the start of any agent task.
---

# Skill：Agent Protocols（所有 Agent 通用行為規範）

> **所有 agent 必須嚴格遵守此檔案。**
> Agent 定義檔案（`agents/*.md`）禁止重複此處規則，必須 reference 本檔案。

---

## 1. Fact-Check Before Answer

所有技術判斷、代碼修改、架構決定必須基於**事實**：

```
✅ 讀取實際代碼先下判斷
✅ 確認框架 / 函式庫 API 版本兼容性
✅ 不確定嘅細節明確標示「待確認」或「推測」
❌ 禁止憑描述推測代碼內容
❌ 禁止假設 API response 結構、DB schema、config 值
❌ 禁止「我相信係咁」、「應該冇問題」等無根據語句
```

---

## 2. Plan Before Do

每次任務開始前必須輸出執行計劃：

```
📋 執行計劃
- 目標：[一句說清楚做乜]
- 步驟：[有序列表]
- 假設：[列出所有假設]
- 風險：[潛在問題或不確定點]
- 範圍外：[明確列出唔做乜]
```

**確認規則（重要）**：

| 角色 | 行為 |
|------|------|
| **Main agent**（直接同用戶對話）| 輸出計劃後等用戶確認先執行 |
| **Subagent**（由 main agent 透過 Agent tool invoke）| 輸出計劃後**立即執行**，唔等用戶確認——main agent invoke 本身已係確認 |

> ⛔ Subagent 禁止輸出「等確認先執行」、「請確認是否繼續」等被動語句。收到任務即執行。

**例外**：計劃不適用嘅情況
- 單純讀取文件、查詢資訊（唔涉及改動）
- `/session-log` 等純記錄任務
- Hotfix 緊急流程（輸出精簡版計劃即可）

---

## 3. Handoff 嚴格性（強制動作原則）

所有 agent 必須遵守 `skills/post-review-handoff.md` 定義嘅 handoff protocol。

### 核心禁令

```
⛔ 禁用被動語句：
  「通知用戶」、「建議用戶執行」、「請確認是否繼續」、「要唔要叫下一個 agent」

⛔ 禁止等待用戶指令：
  Subagent 完成自己職責後必須按 post-review-handoff.md 執行對應 git 操作
  Main agent 收到 subagent 返回後必須立即 invoke 下一個 agent

⛔ 禁止輸出「完成」而冇執行對應 handoff：
  每個 command 都有明確嘅下一步，唔存在「做完就停」嘅情況
```

### 強制動作原則

```
✅ 所有 handoff 必須透過 Agent tool 實際 invoke 下一個 agent
✅ 唔係輸出一段文字叫用戶執行
✅ 唔係問用戶確認
```

詳見 `skills/post-review-handoff.md`。

---

## 4. Session 開始 / 結束 Checklist

### Session 開始

```
□ 有冇上次 session log？如有，先閱讀
□ 閱讀 shared-knowledge.md，了解已知規律同陷阱
□ 當前項目係新項目定舊項目？
□ 今次 session 目標係乜？
□ 需要啟用邊個 / 邊幾個 agent？
```

### Session 結束

```
□ 完成嘅任務是否符合 Definition of Done？（見 global-rules.md）
□ 有冇發現 common knowledge？如有，記錄入 shared-knowledge.md
□ 執行 /session-log
□ 所有新代碼已 commit
□ 測試全部通過
□ 有冇未完成事項要記錄？
```

---

## 5. Context Budget（Harness 原則）

Agent context window 有限，必須主動管理：

```
✅ Lazy load：只在需要時 Read skill / protocol 檔案，唔預先載入全部
✅ 輸出緊湊：報告唔 repeat 用戶輸入嘅內容
✅ 引用優於複製：指向 SSoT 檔案，唔重複規則原文
✅ Subagent 卸載：大範圍 research / exploration 用 Agent tool 交 subagent 做，
   結果以 200–300 字 summary 返回，避免原始搜尋結果污染 main context
✅ shared-knowledge.md 要 compact：定期合併相近條目，刪除已過時項
```

**何時 spawn 新 session**：
- 當前 session 超過 ~70% context window
- 前一個任務完成後準備開新任務類型（例：完成 /feature 後做 /audit）
- Hotfix postmortem 必須開新對話（已在 Protocol 3 定義）

---

## 6. On-Demand Skill Loading

Agent 定義檔案（`agents/*.md`）**禁止 inline** 以下內容：

- Git flow 細節 → 用到先 Read `skills/git-flow.md`
- TDD 循環 → 用到先 Read `skills/tdd.md`
- CI/CD pipeline 細節 → 用到先 Read `skills/ci-cd.md`
- Coding style 規則 → 用到先 Read `skills/coding-style.md`（入口），再按語言 Read `skills/coding-style/ts.md` / `php.md` / `py.md`
- Handoff protocol → 任務完成前 Read `skills/post-review-handoff.md`

每個 skill 檔案開頭有 YAML frontmatter（`name` + `description`），描述幾時應該 load。Agent 見到任務關鍵字匹配時即 Read 對應檔案。

---

## 8. Timestamp 規範（所有 Agent 強制）

凡輸出任何含日期／時間嘅文件，或使用時間戳作為文件名的一部分時：

```
✅ 必須先執行 date '+%Y-%m-%d %H:%M' 取得本機當前時間
❌ 禁止自行估算時間（「目前大概是 XX 點」、「現在應該是 HH:MM」）
❌ 禁止假設 UTC 或任何固定 timezone
```

**適用範圍（所有以下產出）**：

| 產出 | 舉例 |
|------|------|
| Session log 文件名及 header | `session-logs/YYYY-MM-DD_HH-MM.md` |
| Audit report 文件名及 header | `audits/YYYY-MM-DD_HH-MM_audit_*.md` |
| Review report 文件名及 header | `reviews/YYYY-MM-DD_HH-MM_review_*.md` |
| Spec 文件 header（`**日期**` 欄位） | Functional Spec / Technical Spec |
| Implementation Plan header | `**日期**` 欄位 |
| DevOps deployment record | 部署記錄時間戳 |
| Architect diagram 文件名 | `diagrams/flow/YYYY-MM-DD_HH-MM_*.html` |

> 執行方式：在生成文件前，先 Bash `date '+%Y-%m-%d %H:%M'`，將輸出直接用於文件名及 header。

---

## 7. Senior Mindset（通用）

所有 agent 係 Senior level（8–15 年經驗），共同持有以下思維：

- **可維護性優先於功能完整性**：代碼會被讀 10 倍於寫嘅時間
- **主動識別風險**：發現問題唔等人問，主動提出
- **拒絕過度設計**：只解決已知問題，唔為未來猜測抽象
- **決定要快但有根據**：猶豫不決比錯誤決定更有害，但必須基於事實
- **後門永遠開著**：每個決定都要有回頭路（回滾、降級、feature flag）
- **文件即真相**：所有重大決定必須寫入 `.proj-docs/` 或 session log
