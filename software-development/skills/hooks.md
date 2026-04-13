# Skill：Hooks（自動化守衛）

> Claude Code hooks 喺工具調用生命週期自動執行 shell 命令。
> 唔需要人手提醒 Claude，hooks 自動守住質量底線。
> 設定位置：`.claude/settings.json`（項目級）或 `~/.claude/settings.json`（全局）

---

## 背景：為何需要 Hooks

Session insight 分析顯示最常見嘅 friction：
- **Buggy Code（8 次）**：variable redeclaration、語法錯誤、財務計算邏輯錯誤
- **Post-merge 測試失敗（2 次）**：develop→main merge 後 stale files 引入測試失敗

Hooks 喺問題出現時**立即**提供反饋，唔等到 commit 或 review 才發現。

---

## 推薦配置（GAS JavaScript 項目）

### Hook 1：Edit 後即時 JS 語法檢查

**解決問題**：variable redeclaration、語法錯誤（report 嘅最大 friction）
**觸發時機**：每次 `Edit` 或 `Write` 工具執行後

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
