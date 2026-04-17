# 指令：/session-close

## 用途

記錄今次 session 完成嘅工作、重要決定、待注意事項及下次任務，儲存 log 後關閉當前 session。

## 負責 Agent

**全體**（由最後活躍嘅 agent 或 PM 整合執行）

---

## 執行流程

```
1.  執行 date '+%Y-%m-%d %H:%M' 取得本機當前時間（用於 log header 及文件名）
2.  回顧今次 session 嘅完整對話
3.  整理完成事項
4.  整理重要決定及原因
5.  識別待注意事項及未完成工作
6.  制定下次 session 建議任務
7.  確認有冇 common knowledge 需要補充入 shared-knowledge.md
8.  生成 log 檔案，儲存至指定位置
9.  輸出 Session Closed Banner（見下方格式）
10. 執行 Bash：`kill -2 $PPID` 發送 SIGINT，自動關閉 session
```

---

## 儲存位置

```
全局 team log：
{active-team-folder}/session-logs/YYYY-MM-DD_HH-MM.md

項目專屬 log（如有 project working directory）：
[project-root]/.claude/session-logs/YYYY-MM-DD_HH-MM.md
```

---

## Log 輸出格式

```markdown
# Session Log

**日期**：YYYY-MM-DD HH:MM
**時間**：HH:MM
**項目**：[項目名稱 / 全局]
**參與 Agent**：[列出今次用到嘅 agents]
**Session 目標**：[今次 session 開始時嘅目標]

---

## 完成事項

- [具體完成嘅工作，要清楚到下次可以繼續]

---

## 重要決定

| 決定 | 原因 | 影響 |
|------|------|------|
| | | |

---

## 代碼改動摘要

| 檔案 | 改動類型 | 描述 |
|------|----------|------|
| | feat/fix/refactor/chore | |

---

## 待注意事項

- ⚠️ [重要注意事項]
- 🔧 [技術細節需要留意]
- ❓ [未解決問題或待確認事項]

---

## 未完成工作

| 任務 | 狀態 | 阻礙原因 | 下次繼續方式 |
|------|------|----------|-------------|
| | | | |

---

## 下次 Session 建議任務

按優先順序排列：

1. **[P0] [任務描述]**
   - 背景：[為何要做]
   - 建議方式：[點樣開始]

---

## Shared Knowledge 更新

- [SK-XXX] [標題]（新增 / 更新）

---

## 備注

[其他值得記錄嘅觀察、想法或提醒]
```

---

## Session Closed Banner

Log 儲存完成後輸出：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Session log 已儲存
📁 [log 檔案路徑]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Session closing...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 使用方式

```
/session-close               ← 儲存 log 並自動關閉 session（kill -2 $PPID）
/session-close --preview     ← 預覽 log，唔儲存，唔關閉
```
