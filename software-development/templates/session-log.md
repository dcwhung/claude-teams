# Template：Session Log

> 每次 session 結束前由 `/session-log` 指令自動填寫並儲存。
> 儲存位置：`~/projects/[project]/.claude/session-logs/YYYY-MM-DD_HH-MM.md`

---

# Session Log

**日期**：YYYY-MM-DD HH:MM
**項目**：[項目名稱 / 全局]
**參與 Agent**：[例如：Project Manager, Architect, Backend Developer]
**Session 目標**：[今次 session 開始時嘅目標，一句話]
**目標達成**：✅ 完全達成 / ⚠️ 部分達成 / ❌ 未達成

---

## 完成事項

> 具體到下次 session 可以直接繼續，唔需要重新了解背景

- [x] [具體完成嘅工作，包括：改動咗邊個檔案、決定咗乜、輸出咗乜文件]
- [x] ...

---

## 重要決定

| 決定 | 原因 | 影響範圍 |
|------|------|----------|
| [做咗乜決定] | [點解咁決定] | [影響哪些功能 / 模組] |

---

## 代碼改動摘要

| 檔案 / 模組 | 改動類型 | 描述 |
|------------|----------|------|
| | feat / fix / refactor / chore | |

**Branch 狀態**：
- 當前 branch：`[branch name]`
- 最後 commit：`[commit hash 或描述]`
- 未 commit 改動：有 / 無

---

## 待注意事項

> 下次 session 開始前必須了解嘅資訊

- ⚠️ [重要注意事項，例如：某個 API 有 breaking change]
- 🔧 [技術細節，例如：DB migration 未執行]
- ❓ [待確認事項，例如：用戶未確認某設計決定]

---

## 未完成工作

| 任務 | 狀態 | 阻礙原因 | 下次繼續方式 |
|------|------|----------|-------------|
| | 進行中 / 待開始 | [context timeout / 待確認 / 其他] | [從哪步繼續] |

---

## 下次 Session 建議任務

> 按優先順序，下次開始時可以直接執行

**1. [P0] [任務名稱]**
- 背景：[為何要做]
- 建議起點：[從哪個指令或步驟開始]
- 預計工作量：[估計]

**2. [P1] [任務名稱]**
- 背景：...
- 建議起點：...

**3. [P2（可選）] [任務名稱]**
- 背景：...

---

## Shared Knowledge 更新

> 今次 session 新增或更新嘅知識條目

| 編號 | 標題 | 類別 | 動作 |
|------|------|------|------|
| SK-001 | [標題] | 技術規律 | 新增 |

*無更新：填「無」*

---

## 備注

[其他值得記錄嘅觀察、想法、或提醒]

---

## 下次 Session 開始指引

```
讀取上次 session log：
~/projects/[project-name]/.claude/session-logs/YYYY-MM-DD_HH-MM.md

然後輸入：
/start ai-dev-team
繼續 [項目名稱] 項目，上次做到 [任務名稱]，今次繼續 [下一步]。
```
