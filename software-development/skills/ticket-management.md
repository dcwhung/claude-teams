# Skill：Ticket Management

> QA 測試發現問題後，必須建立 ticket。
> 適用於 QA Agent（建立）、Frontend / Backend Developer（執行）、Project Manager（管理）。

---

## 兩套 ID 系統總覽

本項目同時使用兩套獨立嘅問題追蹤系統，**唔可混用**：

| 系統 | ID 格式 | 來源 | 負責人 |
|------|---------|------|--------|
| **Review Item ID** | `C-NNN` / `W-NNN` / `S-NNN` | Code Review 報告 | Code Reviewer |
| **QA Ticket** | `[ALIAS]-NNNN`（如 `CUI-0001`） | QA 測試報告 | QA Agent |

### Review Item ID 系統

Code Review 發現嘅問題使用 `C-NNN`（Critical）、`W-NNN`（Warning）、`S-NNN`（Suggestion）格式。

**關鍵規則：全局唯一，跨 review 遞增**

```
❌ 錯誤：每次 review 從 C-001、W-001、S-001 重新開始
✅ 正確：延續上次最高序號，各類型獨立計數
```

**序號維護規則**：
- 賦號前掃描 `.proj-docs/reviews/` 所有報告，找出各類型最高序號
- 下一個 ID = 最高序號 + 1（C、W、S 各自獨立）
- 即使係同一問題延續至下一個 review，亦賦予新 ID

**commit 格式**：
```
fix: W-007 | 提取常數至 module-level
fix: C-002 | 修正 null reference 問題
```

### QA Ticket 系統

（詳見下方「Ticket 編號格式」至「Ticket 操作流程」各節）

---

## Ticket 編號格式

```
[PROJECT_ALIAS]-[4位數字序號]

例子：
CUI-0001
CUI-0042
CUI-0200
```

**PROJECT_ALIAS** 定義於 `~/projects/[project]/CLAUDE.md`：
```markdown
## Project Info
- Alias: CUI
```

序號從 `0001` 開始，每張新 ticket 遞增，**不重用、不跳號**。
當前最新序號從 `.tickets/` 資料夾現有 ticket 檔案取得。

---

## Ticket 資料夾結構

```
~/projects/[project]/
└── .tickets/
    ├── pending/           ← 待處理
    │   ├── 0001-0200/     ← 每 200 張一個子資料夾
    │   │   ├── CUI-0001.md
    │   │   └── CUI-0042.md
    │   └── 0201-0400/
    │       └── CUI-0201.md
    ├── in-progress/       ← 處理中
    │   └── 0001-0200/
    │       └── CUI-0003.md
    ├── completed/         ← 已完成
    │   └── 0001-0200/
    │       └── CUI-0002.md
    └── on-hold/           ← 暫緩
        └── 0001-0200/
            └── CUI-0010.md
```

### 子資料夾命名規則

```
序號範圍：[起始]-[結束]，每 200 張一組

0001-0200   ← ticket 0001 至 0200
0201-0400   ← ticket 0201 至 0400
0401-0600   ← 如此類推
```

**如何判斷放入哪個子資料夾：**

```
ticket 序號 → ceil(序號 / 200) × 200
例：CUI-0001 → ceil(1/200)=1 → 第一組 → 0001-0200/
例：CUI-0199 → ceil(199/200)=1 → 第一組 → 0001-0200/
例：CUI-0200 → ceil(200/200)=1 → 第一組 → 0001-0200/
例：CUI-0201 → ceil(201/200)=2 → 第二組 → 0201-0400/
```

---

## Ticket 狀態流轉

```
建立 → pending
開始處理 → in-progress（移動檔案至對應資料夾）
完成並通過驗證 → completed
暫時擱置 → on-hold

狀態改變 = 移動 .md 檔案至對應子資料夾 + 更新檔案內「狀態歷史」
```

**每次狀態改變必須同時做兩件事：**
1. 移動 `.md` 檔案至對應狀態資料夾
2. 在 ticket 檔案底部「狀態歷史」區塊加入一條記錄

---

## Ticket 格式

```markdown
# [TICKET_NUMBER] [標題]

**狀態**：pending / in-progress / completed / on-hold
**類型**：bug / task / improvement
**優先級**：🔴 Critical / 🟡 High / 🟢 Low
**來源**：QA Report [日期] / Code Review / Manual
**建立日期**：YYYY-MM-DD HH:MM
**建立人**：QA Agent / Code Reviewer Agent
**負責人**：Frontend Developer / Backend Developer / 待分配
**關聯 QA Report**：[QA report 檔案路徑或日期]
**Code Review 報告**：[.proj-docs/reviews/YYYY-MM-DD_HH-MM_review_CUI-XXXX.md / 待完成]

---

## 問題描述

[清楚描述問題係乜，喺什麼情況下發生]

## 重現步驟

1. [步驟 1]
2. [步驟 2]
3. [步驟 3]

## 預期結果

[應該發生乜]

## 實際結果

[實際發生咗乜]

## 環境

- **測試環境**：dev / staging / production
- **瀏覽器 / 平台**：[如適用]
- **相關版本**：[commit hash 或版本號]

## 影響範圍

- **受影響功能**：[列出受影響嘅功能或模組]
- **受影響用戶**：[所有用戶 / 特定角色 / 特定情況]

## 截圖 / 錯誤訊息

```
[貼上錯誤訊息或描述截圖內容]
```

## 子 Tickets（如有拆分）

| Ticket | 類型 | 負責人 | 狀態 |
|--------|------|--------|------|
| CUI-0002 | Frontend | Frontend Developer | pending |
| CUI-0003 | Backend | Backend Developer | pending |

## 解決方案（完成後填寫）

[描述點樣修復，改動咗乜]

## 驗證方式

[QA 如何驗證已修復]

## 完成日期

[YYYY-MM-DD HH:MM]

---

## 狀態歷史

| 日期 | 舊狀態 | 新狀態 | 負責人 | 原因 |
|------|--------|--------|--------|------|
| YYYY-MM-DD HH:MM | — | pending | QA Agent | 建立 ticket |
| YYYY-MM-DD HH:MM | pending | in-progress | Backend Developer | 開始處理 |
| YYYY-MM-DD HH:MM | in-progress | on-hold | Project Manager | 等待第三方 API 確認 |
| YYYY-MM-DD HH:MM | on-hold | in-progress | Backend Developer | 第三方已確認，繼續處理 |
| YYYY-MM-DD HH:MM | in-progress | completed | QA Agent | 驗證通過 |
```

---

## 拆分 Ticket 規則

當 QA report 問題涉及前後端，必須拆分：

```
主 Ticket（CUI-0001）
  ├── 子 Ticket Frontend（CUI-0002）
  └── 子 Ticket Backend（CUI-0003）
```

**拆分條件：**
- 問題同時涉及 UI 及 API
- Frontend 同 Backend 改動互相獨立，可以平行進行
- 其中一方工作量明顯大，需要獨立追蹤

**拆分後：**
- 主 ticket 記錄整體問題及子 ticket 列表，狀態設為 `in-progress`
- 子 ticket 各自追蹤進度
- 所有子 ticket `completed` 後，主 ticket 才可標記 `completed`

---

## Branch 命名

> Branch 命名規則（含 `[類型]/[scope]/[identifier]_[描述]` 格式、scope 定義、One-Task-One-Branch 鐵律）**完全定義於** `skills/git-flow.md`。
> 本檔案只補充：當 ticket 橫跨前後端時，以主 ticket 拆分嘅子 ticket（frontend / backend）分別開 branch，identifier 使用各自子 ticket 號。

---

## Ticket 操作流程

### QA 建立 Ticket

```
1. 執行完 /test，發現問題
2. 取得當前最新 ticket 序號（掃描 .tickets/ 所有子資料夾）
3. 建立新 ticket 檔案，填寫所有欄位
4. 在「狀態歷史」加入第一條記錄：
   | YYYY-MM-DD HH:MM | — | pending | QA Agent | 建立 ticket |
5. 判斷是否需要拆分（涉及前後端）
6. 如需拆分，建立子 tickets（各自有獨立狀態歷史）
7. 將 ticket 放入 .tickets/pending/[對應序號範圍]/
8. 在 QA report 加入 ticket 編號
```

### Developer 認領 Ticket

```
1. 從 .tickets/pending/ 取得 ticket
2. 更新 ticket 檔案：
   - 頭部「狀態」欄位改為 in-progress
   - 頭部「負責人」填寫自己
   - 「狀態歷史」加入一條記錄：
     | YYYY-MM-DD HH:MM | pending | in-progress | [Developer] | 開始處理 |
3. 移動 ticket 檔案至 .tickets/in-progress/[對應序號範圍]/
4. 按 ticket number 建立 branch
5. 開發完成後，提 PR 並在 PR 描述加入 ticket number
```

### Ticket 暫緩（on-hold）

```
1. 更新 ticket 檔案：
   - 頭部「狀態」欄位改為 on-hold
   - 「狀態歷史」加入一條記錄，原因必須填寫：
     | YYYY-MM-DD HH:MM | in-progress | on-hold | [Agent] | [具體原因，例如：等待第三方 API 確認] |
2. 移動 ticket 檔案至 .tickets/on-hold/[對應序號範圍]/
```

### Ticket 完成

```
1. PR merge 後，QA 驗證修復
2. 驗證通過後，更新 ticket 檔案：
   - 頭部「狀態」改為 completed
   - 填寫「解決方案」及「完成日期」
   - 「狀態歷史」加入最後一條記錄：
     | YYYY-MM-DD HH:MM | in-progress | completed | QA Agent | 驗證通過 |
3. 移動至 .tickets/completed/[對應序號範圍]/
4. 如係子 ticket，檢查主 ticket 所有子項是否全部 completed
5. 所有子 ticket completed → 主 ticket 亦更新為 completed
```

---

## 初始化項目 Ticket 資料夾

新項目開始時執行：

```bash
mkdir -p .tickets/pending/0001-0200
mkdir -p .tickets/in-progress/0001-0200
mkdir -p .tickets/completed/0001-0200
mkdir -p .tickets/on-hold/0001-0200
```
