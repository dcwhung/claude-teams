# 指令：/session-log

## 用途

記錄今次 session 完成嘅工作、重要決定、待注意事項及下次任務，按權威 template 生成 log 檔案，供下次 session 參考。

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
8. 按 templates/session-log.md 生成 log 檔案
9. 儲存至指定位置
```

---

## 儲存位置

```
項目專屬 log（包括跨子項目工作）：
[project-root]/.claude/session-logs/YYYY-MM-DD_HH-MM.md

全局 team log（只限冇 project working directory 嘅 session）：
{active-team-folder}/session-logs/YYYY-MM-DD_HH-MM.md
```

> `project-root` 係當前工作目錄所屬嘅頂層項目資料夾（如 `GoogleAppScript/`），唔係 `~/.claude/`。

## Log 輸出格式

權威格式來源：

```
templates/session-log.md
```

> `/session-log` 負責收集內容並填入 template；如需修改欄位、章節次序或 header，應只更新 template，避免 command 文件同 template 漂移。

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
