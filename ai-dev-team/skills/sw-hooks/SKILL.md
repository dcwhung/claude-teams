---
name: sw-hooks
description: Claude Code hook configurations that auto-run on tool lifecycle (PostEdit lint, post-merge test, handoff-receipt enforcement). Load when setting up a new project, adding a quality gate, or when the user says "automate X", "run Y after every edit", "enforce Z automatically", or "I keep forgetting to run lint". Also load when a recurring mistake (syntax error, missed handoff, broken merge) could be caught by a hook instead of manual reminders.
---

# Skill：Hooks（自動化守衛）

> Claude Code hooks 喺工具調用生命週期自動執行 shell 命令。
> 唔需要人手提醒 Claude，hooks 自動守住質量底線。
> 設定位置：`.claude/settings.json`（項目級）或 `~/.claude/settings.json`（全局）

---

## 背景：為何需要 Hooks

兩類常見 friction，hooks 可以自動攔截：
- **語法 / 靜態錯誤**：variable redeclaration、類型錯誤、lint 違規
- **Post-merge 回歸**：merge 後 stale files 引入測試失敗

Hooks 喺問題出現時**立即**提供反饋，唔等到 commit 或 review 才發現。

---

## 推薦配置

### Hook 1：Edit 後即時語法檢查（以 JS 為例）

**解決問題**：variable redeclaration、語法錯誤
**觸發時機**：每次 `Edit` 或 `Write` 工具執行後
**注意**：以下範例針對 `.js` 檔案，可按項目語言調整（如 TypeScript 用 `tsc --noEmit`，Python 用 `python -m py_compile`）

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "file=$(jq -r '.tool_input.file_path // empty'); [[ \"$file\" == *.js ]] && node --check \"$file\" 2>&1 | head -5 || true"
          }
        ]
      }
    ]
  }
}
```

> Tool input 透過 stdin 以 JSON 傳入，用 `jq` 直接讀取。語法錯誤輸出至用戶終端。

---

### Hook 2：Merge 後自動執行測試套件

**解決問題**：post-merge stale files、測試失敗未被捕捉
**觸發時機**：包含 `git merge` 嘅 Bash 命令執行後

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "cmd=$(jq -r '.tool_input.command // empty'); echo \"$cmd\" | grep -q 'git merge' && npm test 2>&1 | tail -30 || true"
          }
        ]
      }
    ]
  }
}
```

> 偵測到 merge 後自動執行 `npm test`，輸出最後 30 行至用戶終端。

---

## ⚠️ 重要：Tool Input 讀取方式

Claude Code hooks **唔使用** `$CLAUDE_TOOL_INPUT_*` 環境變數。Tool input 透過 **stdin JSON** 傳入：

```bash
# ✅ 正確：jq 直接讀 stdin
file=$(jq -r '.tool_input.file_path // empty')
cmd=$(jq -r '.tool_input.command // empty')

# ❌ 錯誤：環境變數不存在（永遠是空）
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# ❌ 錯誤：echo "$var" 損毀長 JSON
raw=$(cat); echo "$raw" | jq ...
```

stdin JSON 完整結構見 `shared-knowledge.md` → SK-003。

---

## 組合配置（推薦 copy 入 `.claude/settings.json`）

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "file=$(jq -r '.tool_input.file_path // empty'); [[ \"$file\" == *.js ]] && node --check \"$file\" 2>&1 | head -5 || true"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "cmd=$(jq -r '.tool_input.command // empty'); echo \"$cmd\" | grep -q 'git merge' && npm test 2>&1 | tail -30 || true"
          }
        ]
      }
    ]
  }
}
```

### Hook 3：Branch Policy（系統層 workflow 守衛）

**解決問題**：main agent 繞過 `/feature` `/fix` workflow，直接 commit 入 `main` / `develop`
**觸發時機**：每次 Bash tool 即將執行命令前（PreToolUse）
**腳本位置**：`${CLAUDE_PLUGIN_ROOT}/hooks/branch-policy.sh`（由 plugin `hooks/hooks.json` 註冊）

**規則**（block exit code 2）：
- 喺 `main` / `master` / `develop` 上執行 `git commit` → BLOCK
- Force push 至 `main` / `master` / `develop` → BLOCK
- 喺 protected branch 上 `git reset --hard` → BLOCK
- merge 操作（含 `--no-ff`）→ 放行（handoff state 由 main agent 負責）

**繞行方式**（合理情境下）：
- `CLAUDE_HOOK_BYPASS_BRANCH_POLICY=1` 環境變數
- `touch .claude-hotfix-active` 喺 git root（`/hotfix` Step 4 完成後自動移除）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/branch-policy.sh"
          }
        ]
      }
    ]
  }
}
```

> ⚠️ 此 hook 已配置喺 `~/.claude/settings.json`（global）— 影響所有 Claude Code session。
> 設計原則：保守 — 寧願偶爾 block 合理操作（用戶按 bypass）也唔可放任 main agent 繞過 workflow。

---

### Hook 4：Handoff Receipt Enforcement（Harness 強制）

**解決問題**：subagent 忘記輸出 `handoff-receipt` block → main agent 跳步
**觸發時機**：subagent 任務結束（SubagentStop）
**原理**：檢查 subagent 最終輸出有無符合格式嘅 receipt block，缺失即視為 fail 並要求重交。

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "code-reviewer|quality-assurance|devops-engineer",
        "hooks": [
          {
            "type": "command",
            "command": "grep -qE '^```handoff-receipt' \"${CLAUDE_SUBAGENT_OUTPUT_FILE:-/dev/null}\" || echo '⛔ Missing handoff-receipt block — main agent MUST NOT proceed. Re-invoke this agent to emit receipt.'"
          }
        ]
      }
    ]
  }
}
```

> 如 Claude Code 版本唔支援 `SubagentStop` hook，main agent 仍須按 `post-review-handoff.md` → 驗證 Checklist 人工檢查。

---

## 激活方式

```
/update-config
```

描述需要嘅 hook 行為，例如：
- "每次 Edit .js 文件後，自動執行 `node --check` 語法檢查"
- "每次 git merge 後，自動執行 `npm test`"

---

## Hook 輸出原則

- Hook 輸出**直接顯示**喺 Claude 嘅 tool result 中
- Claude 讀取 hook 輸出並決定是否需要修正
- 保持輸出精簡（`head -5`、`tail -30`）避免 context 爆滿
- Hook 命令應以 `|| true` 結尾，防止 hook 本身報錯阻塞流程

---

## 參考資源

- `/update-config` skill：自動配置 hooks 至 settings.json
- `skills/sw-autonomous-loop/SKILL.md`：配合 hooks 使用嘅自主循環模式
