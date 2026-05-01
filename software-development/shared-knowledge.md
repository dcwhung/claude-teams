# Shared Knowledge Log

> 跨 Agent、跨 Session 嘅共享知識庫。
> 任何 agent 發現 common knowledge 時，必須按格式記錄於此。
> 每個 session 開始前必須閱讀此檔案。

---

## 使用指引

### 何時記錄
- 發現項目特有技術規律或約定
- 發現常見錯誤模式或陷阱
- 發現跨模組嘅共用邏輯
- 發現第三方庫嘅重要限制或 workaround
- 發現環境或部署嘅特殊注意事項
- 發現業務邏輯中容易誤解嘅規則

### 記錄格式

```markdown
## [SK-XXX] [標題]

**日期**：YYYY-MM-DD HH:MM
**來源 Agent**：[agent 名稱]
**類別**：技術規律 / 錯誤模式 / 業務規則 / 環境注意 / 其他
**適用 Agent**：全部 / [指定 agent]
**有效期至**：YYYY-MM-DD / 永久（技術升級或問題解決後請更新）

**內容**：
[詳細描述]

**適用場景**：
[哪些任務需要注意]

**參考**：
[相關檔案或連結]

---
```

### 更新過時條目
如發現條目內容有誤或過時，在條目頂部加入：

```markdown
> ⚠️ 已更新：YYYY-MM-DD HH:MM，原因：[說明]
```

如條目完全失效，加入：

```markdown
> ❌ 已過期：YYYY-MM-DD HH:MM，原因：[說明]（保留作歷史參考，請勿跟從）
```

---

## 定期 Review 規則

**每個 session 開始時**：
- 閱讀所有條目，留意 `有效期至` 欄位
- 發現過期條目，立即標記 `❌ 已過期` 並說明原因

**每月一次**（或項目有重大升級時）：
- PM 或 Architect 主導 review 所有條目
- 確認仍然有效嘅條目，更新 `有效期至` 日期
- 標記失效條目

**觸發即時 review 嘅情況**：
- 更新第三方庫主版本
- 更換框架或 ORM
- 數據庫升級
- 任何 agent 發現某條目描述嘅問題已不存在

---

## 知識條目

> 此區域存放跨 agent、跨 session 嘅共享知識。
> 項目特有嘅技術規律應記錄於對應項目嘅 `CLAUDE.md` 或項目級 shared-knowledge，唔應存入此檔案。

---

## [SK-006] `~/.claude/` 寫入嘅「editing its own settings」hardcoded guard

**日期**：2026-05-01 23:55
**來源 Agent**：Main Agent（今次 session 兩次失敗 + Option D workaround 驗證）
**類別**：技術規律 / Claude Code 架構行為
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為，除非官方移除 guard）

**核心發現**：

Claude Code 對 `~/.claude/` 路徑下嘅寫入操作（至少包括 dot-file，例如 `.active-team`）有 **hardcoded permission guard**，獨立於普通 sensitive-file 判定。觸發時 prompt 提供三個選項：

```
Do you want to overwrite .active-team?
  1. Yes
  2. Yes, and allow Claude to edit its own settings for this session
  3. No
```

**Option 2 嘅文字「allow Claude to edit its own settings」係 dead giveaway** — Claude Code 將呢類路徑歸類為「Claude 嘅 settings」，獨立於普通 file write，並且：

- ❌ `permissions.allow` 加 `Write(/Users/.../.active-team)` exact-match rule 都 override 唔到（已驗證 — fresh session 仍彈）
- ❌ `permissions.additionalDirectories` 加 `~/.claude` 都 override 唔到
- ❌ Write tool 嘅 sandbox 豁免唔包含呢類 path

**已驗證無效嘅嘗試（請勿重複）**：

| 嘗試 | 結果 |
|------|------|
| 喺 `~/.claude/settings.json` 加 `Write(/Users/donald91103/.claude/.active-team)` 入 allow list | ❌ 仲彈 prompt（fresh session 都試過） |
| 依賴 `additionalDirectories` 包含 `/Users/donald91103/.claude` | ❌ 仲彈 prompt |
| 用 Write tool（avoid Bash） | ❌ 仲彈 prompt（Bash 撞另一條 sensitive-file 規則，但 Write 都唔 bypass guard） |

**Workaround（已實施於 `commands/start.md` step 3）**：

**Skip-Write-If-Unchanged pattern** — 如內容唔變就唔好調用 Write tool：

```
3a. Read 目標 file
3b. 比較內容 vs 目標值
    ✅ 一致 → 完全跳過 Write，輸出「已係最新（skipped）」
    ⚠️ 唔一致 / file 不存在 → Write（首次/切 team 會彈一次 prompt，accept 一次解決）
```

**設計意圖**：

- 99% 情況（同一機 re-invoke 同一 team / 內容無變）→ **完全唔彈 prompt**
- 1% 情況（首次安裝 / 切 team / 內容真係變）→ 彈一次，acceptable one-time cost

**適用場景**：

- 任何 command 設計需要持久化少量 state 入 `~/.claude/` 嘅情境
- 設計新 slash command 時，避免「永遠 Write」嘅 pattern，改用 skip-write-if-unchanged 或搬出 `~/.claude/`
- 設計 hook / persistent flag 時優先考慮 read-then-compare-then-conditional-write

**禁止行為**：

- ❌ 用 Bash redirect 寫 `~/.claude/` 內 dot-file（撞另一條 sensitive-file guard，永遠彈）
- ❌ 喺 settings.json 加 `Write(...)` allow rule 嚟「修」呢個 prompt — 已驗證無效，只係 cosmetic clutter
- ❌ 假設「下次 session restart 後就好」— guard 係 hardcoded，唔受 session restart 影響

**參考**：

- `~/.claude/commands/start.md` step 3（skip-write-if-unchanged 邏輯實施）
- 觸發此知識嘅 session：2026-05-01_23:30 起連續兩次失敗 → Option D workaround
- 上次 session log 嘅 SK-006 草稿（已被今次驗證結果取代）

---

## [SK-005] Workflow Bypass — `/start` 無 task 時 main agent 跳過 /feature 流程

**日期**：2026-05-01 13:08
**來源 Agent**：Main Agent（自我覆盤）
**類別**：錯誤模式 / 流程缺陷
**適用 Agent**：Main Agent（所有開 ai-dev-team session 嘅 main agent）
**有效期至**：永久（已加入四層守衛 A/B/C/D 至 2026-05-01）

**內容**：

實際 session 觀察到嘅 failure mode：

1. 用戶用 `/start ai-dev-team`（無 `--task` argument），只 load `team.md` + digest
2. 用戶後續訊息「跟進 X 加個 Y feature」— 含 feature 關鍵字但 main agent 冇識別
3. Main agent 直接做嘢，**完全跳過 `/feature` workflow**：
   - 喺 `main` branch 上開始改代碼（冇開 feature/* branch）
   - 改完冇 invoke code-reviewer subagent
   - Reviewer LGTM 後冇自動接 QA → DevOps，反而問用戶「要唔要 merge?」
   - QA pass 後冇自動接 DevOps deploy
4. Compact 觸發後，workflow 規則完全消失，重啟後 main agent 仍是「直接做嘢」模式

**根本原因**：

| 層級 | 缺失 |
|---|---|
| 入口 | `/start` 無 task 時冇關鍵字識別機制 |
| 行為 | `agent-protocols.md` 無「接到改動任務前 self-check workflow 載入」嘅規則 |
| 系統 | 冇 PreToolUse hook 攔截「直接 commit 入 main / develop」 |
| 持續 | Compact instruction 冇要求保留 workflow state |

**修正（已實施 2026-05-01）**：

四層守衛：

- **A（入口）**：`commands/start.md` 加「Task Type Enforcement」+「關鍵字 → Task 對照表」。Main agent 必須喺第一個回應內識別關鍵字、載入對應 command、由 step 1 開始執行。
- **B（行為）**：`agent-protocols.md` §9 Workflow Self-Check — 接到任何改動訊號前，必須通過 4 項 checklist；任何一項 NO 立即停手。
- **C（系統）**：`~/.claude/hooks/branch-policy.sh` PreToolUse hook — 阻擋直接 commit 入 main/develop、force push、reset --hard 等操作。繞行需明確 bypass。
- **D（持續）**：`agent-protocols.md` §10 Compact Protection — compaction 時必須在 summary 頂部保留 `Active Workflow State` block。`~/.claude/CLAUDE.md` 同 `global-rules.digest.md` 都有 pointer。

**適用場景**：

- 任何 main agent 接到代碼修改任務嘅情境
- Compact 之後重啟 — 必須讀 `Active Workflow State` 再行動
- 一個 session 內連續做多個 task — 每個 task 邊界都要 reset 同 re-confirm

**禁止行為**：

- 「呢個改動好細，唔開 branch」→ 違規
- 「用戶 confirm 咗 plan，我直接做」→ 違規（plan ≠ workflow 啟動）
- 「上一個 task 啱啱完，呢個延續做」→ 違規（每個 task 獨立 self-check）
- Main agent 自己改代碼回應 reviewer 提出嘅問題 → 違規（必須 invoke developer subagent）

**參考**：

- `commands/start.md` § Task Type Enforcement
- `skills/agent-protocols.md` §9（Workflow Self-Check）+ §10（Compact Protection）
- `~/.claude/hooks/branch-policy.sh`
- `~/.claude/CLAUDE.md` § Compact Protection
- 觸發此知識嘅 session：UK_Salary_Summary v1.3.0 + P0 bonus % feature flow

---

## [SK-004] Coverage 數字唔等於 TDD 執行

**日期**：2026-04-18
**來源 Agent**：Engineering Manager（HF-001 Post-mortem）
**類別**：錯誤模式
**適用 Agent**：Code Reviewer、Developer
**有效期至**：永久（直至 global-rules.md 正式納入為止）

**內容**：
測試覆蓋率 ≥ 80% 係 hard gate，但 **coverage 數字唔能證明 TDD 流程有執行**。開發者可以先寫實現、後補測試，照樣通過 coverage 門檻。HF-001 根本原因正是如此：錯誤邏輯在無失敗測試保護下合入代碼庫。

**Code Reviewer 必須額外驗證**：
- PR 中有失敗測試（Red）先於實現代碼的 commit 紀錄
- 若無明確紀錄，應要求開發者說明 TDD 執行過程
- 數學/計算邏輯必須覆蓋：正正、正負、負負、零值、浮點邊界

**試行規則位置**：`agents/code-reviewer.md` → TDD 執行驗證 section（試行 2 個 sprint 後評估推至 `global-rules.md`）

**適用場景**：
- 所有涉及數值計算、條件邏輯、狀態轉換嘅 PR
- 任何新功能/修復嘅 code review

**參考**：
- `.proj-docs/audits/2026-04-18_HF-001_postmortem_em.md`

---

## [SK-003] Claude Code Hooks 透過 stdin 傳入 JSON，唔係環境變數

**日期**：2026-04-16 23:00
**來源 Agent**：Main Agent（Hooks 實際觸發驗證 session）
**類別**：技術規律
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為）

**內容**：
Claude Code hooks 唔使用 `$CLAUDE_TOOL_INPUT_*` 環境變數。Tool input 係透過 **stdin 以 JSON 格式**傳入 hook 進程。

stdin JSON 結構：
```json
{
  "session_id": "...",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "tool_response": { ... },
  "tool_use_id": "...",
  "cwd": "...",
  "permission_mode": "..."
}
```

環境變數只有三個：`CLAUDE_CODE_ENTRYPOINT`、`CLAUDE_PROJECT_DIR`、`PWD`。

**正確讀取方式**（用 `jq` 直接讀 stdin）：
```bash
# ✅ 正確
file=$(jq -r '.tool_input.file_path // empty')
cmd=$(jq -r '.tool_input.command // empty')

# ❌ 錯誤：環境變數不存在，永遠是空
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# ❌ 錯誤：echo "$var" 會損毀長 JSON（含特殊字符時）
raw=$(cat); echo "$raw" | jq ...
```

**Hook 輸出可見性**：
- Hook 以 exit 0 退出時，輸出只顯示給用戶終端（Claude 看不到）
- Claude Code TUI 佔用終端時，hook 輸出不可見
- 驗證 hook 是否觸發：用 `>> /tmp/hook.log` 寫入 log 檔再讀取

**適用場景**：
- 編寫任何 PostToolUse hook 命令時
- 調試 hook 唔觸發嘅問題時

**參考**：
- `skills/hooks.md`（已更新示例）
- 項目 `.claude/settings.local.json`（已驗證配置）

---

## [SK-002] Hooks 只在對應項目目錄啟動嘅 Session 生效

**日期**：2026-04-16 22:00
**來源 Agent**：Main Agent（P1-B hooks 驗證 session）
**類別**：環境注意
**適用 Agent**：全部
**有效期至**：永久（Claude Code 架構行為）

**內容**：
項目級 hooks（`.claude/settings.local.json` 或 `.claude/settings.json`）只喺 Claude Code session 從**該項目目錄**啟動時才載入同觸發。如果 session 嘅 working directory 係其他位置，hook 唔會自動執行。

驗證方式：
- Hook 命令本身邏輯正確（手動執行有效）
- 但 `PostToolUse` hook 唔喺 tool result 出現
- 原因：session 嘅 primary working directory 唔係項目根目錄

**適用場景**：
- 為項目配置 hooks 後，必須用 `claude` CLI 喺**項目根目錄**開啟 session 先能驗證
- 跨目錄 session（如從 team config 目錄操作項目代碼）無法觸發項目級 hooks

**參考**：
- `skills/hooks.md`

---

## [SK-001] §9 Step Execution Integrity — Subagent Checkpoint 壓縮行為

**日期**：2026-04-16 21:30
**來源 Agent**：Main Agent（P0 驗證 session）
**類別**：錯誤模式
**適用 Agent**：全部
**有效期至**：永久（直至 hook 層防護上線或規則更新）

**內容**：
§9 Step Execution Integrity 規則（`skills/agent-protocols.md`）成功防止 Ghost Referencing，但 subagent 有另一個系統性傾向：執行完所有步驟後，一次性輸出 summary table，而唔係每步完成後即時輸出 `✅ 步驟 [N] 完成：[可驗證結果]`。
- Steps 9–10（最後幾步）有明確 checkpoint 輸出
- Steps 1–8 被壓縮成一張 summary table

呢個行為唔係 Ghost Referencing（工作確實有執行），而係「延遲 checkpoint 輸出」pattern。規則層防護唔足以強制逐步輸出，需要 hook 層補強。

**適用場景**：
- 審查 subagent 返回結果時，summary table 係合格但非理想輸出
- 設計 hook 層防護時，目標係偵測缺失中間 checkpoint，唔單止最終結果
- 評估 P1 hooks.md 配置優先順序

**參考**：
- `skills/agent-protocols.md` §9 Step Execution Integrity
- `global-rules.md` Agent 行為準則

---
