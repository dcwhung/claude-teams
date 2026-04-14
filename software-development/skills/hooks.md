---
name: sw-hooks
description: Claude Code hook configurations that auto-run on tool lifecycle (PostEdit lint, post-merge test, handoff-receipt enforcement). Load when setting up a new project or adding a quality gate.
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
            "command": "FILE=\"${CLAUDE_TOOL_INPUT_FILE_PATH:-}\"; [[ \"$FILE\" == *.js ]] && node --check \"$FILE\" 2>&1 | head -5 || true"
          }
        ]
      }
    ]
  }
}
```

> 語法錯誤即時顯示於 Claude 嘅 tool result，Claude 立即修正，唔需要用戶介入。

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
            "command": "echo \"${CLAUDE_TOOL_INPUT_COMMAND:-}\" | grep -q 'git merge' && npm test 2>&1 | tail -30 || true"
          }
        ]
      }
    ]
  }
}
```

> 偵測到 merge 後自動執行 `npm test`，輸出最後 30 行供 Claude 判斷是否有 regression。

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
            "command": "FILE=\"${CLAUDE_TOOL_INPUT_FILE_PATH:-}\"; [[ \"$FILE\" == *.js ]] && node --check \"$FILE\" 2>&1 | head -5 || true"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"${CLAUDE_TOOL_INPUT_COMMAND:-}\" | grep -q 'git merge' && npm test 2>&1 | tail -30 || true"
          }
        ]
      }
    ]
  }
}
```

### Hook 3：Handoff Receipt Enforcement（Harness 強制）

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
- `skills/autonomous-loop.md`：配合 hooks 使用嘅自主循環模式
