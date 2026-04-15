# 指令：/session-log

## 用途

記錄今次 session 完成嘅工作、重要決定、待注意事項及下次任務，儲存為 log 檔案，供下次 session 參考。

## 負責 Agent

**全體**（由最後活躍嘅 agent 或 PM 整合執行）

---

## 執行流程

```
1. 執行 date '+%Y-%m-%d %H:%M' 取得本機當前時間（用於 log header 及文件名，見 agent-protocols.md §8）
2. 回顧今次 session 嘅完整對話
3. 整理完成事項
4. 整理重要決定及原因
5. 識別待注意事項及未完成工作
6. 制定下次 session 建議任務
7. 確認有冇 common knowledge 需要補充入 shared-knowledge.md
8. 生成 log 檔案，儲存至指定位置
```

---

## 儲存位置

```
項目專屬 log（包括跨子項目工作）：
[project-root]/.claude/session-logs/YYYY-MM-DD_HH-MM.md
```

> `project-root` 係當前工作目錄所屬嘅頂層項目資料夾（如 `GoogleAppScript/`），唔係 `~/.claude/`。

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
- [包括：檔案改動、決定、輸出文件等]

---

## 重要決定

| 決定 | 原因 | 影響 |
|------|------|------|
| [做咗乜決定] | [點解] | [影響哪些部分] |

---

## 代碼改動摘要

| 檔案 | 改動類型 | 描述 |
|------|----------|------|
| | feat/fix/refactor/chore | |

---

## 待注意事項

> 呢度記錄嘅係下次 session 開始前必須了解嘅資訊

- ⚠️ [重要注意事項]
- 🔧 [技術細節需要留意]
- ❓ [未解決問題或待確認事項]

---

## 未完成工作

| 任務 | 狀態 | 阻礙原因 | 下次繼續方式 |
|------|------|----------|-------------|
| | 進行中 / 待開始 | | |

---

## 下次 Session 建議任務

按優先順序排列：

1. **[P0] [任務描述]**
   - 背景：[為何要做]
   - 建議方式：[點樣開始]

2. **[P1] [任務描述]**
   - 背景：...
   - 建議方式：...

3. **[P2] [可選] [任務描述]**
   - 背景：...

---

## Shared Knowledge 更新

> 今次 session 新增或更新嘅 shared knowledge 條目

- [SK-XXX] [標題]（[新增 / 更新]）
- 無

---

## 備注

[其他值得記錄嘅觀察、想法或提醒]
```

---

## 使用方式

```
/session-log                 ← 生成並儲存當前 session log
/session-log --project=myapp ← 指定項目名稱
/session-log --preview       ← 預覽 log，唔儲存
```

---

## 下次 Session 開始方式

下次 session 開始時，輸入：

```
讀取上次 session log：~/projects/[project-name]/.claude/session-logs/YYYY-MM-DD_HH-MM.md
```

Claude 會自動讀取並摘要，然後建議從哪裡繼續。
