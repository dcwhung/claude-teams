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

## 儲存位置（強制分流）

> **規範**：一次 session 入面嘅工作必須按性質分入兩類，**唔可以混入同一 log**。

### 分類標準

| 類別 | 內容定義 | 儲存位置 |
|---|---|---|
| **Project Log** | 改動目標係**項目代碼/配置**：feature 開發、bug fix、refactor、deploy、項目 spec、項目 audit、項目特有知識 | `[project-root]/.claude/session-logs/YYYY-MM-DD_HH-MM.md` |
| **Team Log** | 改動目標係 **ai-dev-team 自身基建**：agent 規範、command 流程、skills、hooks、shared-knowledge（跨項目通用部分）、template、workflow guards | `{active-team-folder}/session-logs/YYYY-MM-DD_HH-MM_team.md` |

> `project-root` 係當前 working directory 所屬嘅頂層項目資料夾。
> `team` 後綴用嚟同同日 project log 區分。

### 分流規則

```
□ 一次 session 內混合做兩類工作 → 必須生成兩份 log
□ Project log 只記項目相關內容（branch、code 改動、PR、deploy 結果）
□ Team log 只記 team infrastructure 改動（哪個 .md / hook / skill 改咗、為何）
□ 兩份 log 互相 cross-reference（filename 引用對方）
□ 純項目工作：只生成 project log
□ 純 team 工作 / 冇項目 working directory：只生成 team log
```

### Cross-Reference 格式

兩份 log 嘅「備注」section 互相指向：

```markdown
> 本次 session 同時包含 [team / project] 工作，相關改動見：
> [filename](relative/path)
```

### 例子

| Session 內容 | 生成檔案 |
|---|---|
| UK_Salary_Summary feature 開發 | 只生成 `UK_Salary_Summary/.claude/session-logs/2026-05-01_HH-MM.md` |
| 修改 agent-protocols.md + 加 hook | 只生成 `{team}/session-logs/2026-05-01_HH-MM_team.md` |
| UK_Salary_Summary feature + 修改 start.md（兩類混合） | 兩份都要生成，互相 cross-reference |

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
