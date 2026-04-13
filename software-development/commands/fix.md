# 指令：/fix

## 用途

開新 branch，以 TDD 方式修復 Bug，確保修復唔會引入新問題，完成後觸發 code review。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視 bug 位置）
**Code Reviewer**（修復完成後自動執行 `/review`）

---

## Fix 前提條件

```
□ Bug 可重現，根源已初步定位
□ 目前在 develop branch（fix branch 必須從 develop 建立）
□ 有 ticket 對應（如來自 QA 或 code review）
```

> ⚠️ **嚴禁從 main 建立 fix branch。** main 只接受來自 develop 嘅 merge。

---

## Git Flow 規則

完全遵從 `skills/git-flow.md`。Branch 建立前必須通過該檔案定義嘅「Branch 建立強制 Pre-Flight Checklist」（含 One-Task-One-Branch 鐵律）。Review / QA 後嘅 handoff 由 Reviewer / QA Agent 按對應 Protocol 主動執行。

---

## 執行流程

```
1.  讀取 shared-knowledge.md（全局 + 項目）
2.  理解 bug 描述，確認可重現步驟
3.  輸出執行計劃，等待確認
4.  執行 `skills/git-flow.md` → Branch 建立強制 Pre-Flight Checklist（source=develop），
    檢查通過後建立：fix/[scope]/[identifier]_[description]
5.  🔴 先寫一個能重現 bug 嘅失敗測試
    ⚠️ 若涉及複雜業務規則（計算邏輯、日期邏輯、狀態機等）：
    先枚舉所有 edge cases（零值、邊界值、null、異常輸入、並發操作、跨境條件），
    確保測試覆蓋全部情況，再進入修復。詳見 `skills/autonomous-loop.md`
6.  定位 bug 根源（Root Cause Analysis）
7.  🟢 修復 bug，令測試通過
8.  🔵 Refactor（如有需要，範圍必須最小化）
9.  使用 Agent tool 啟動自主測試循環（Autonomous Loop），直至全綠：
    a. 執行完整測試套件（npm test）
    b. 如有失敗：讀取失敗輸出，定位根源，修正代碼
    c. 重複直至所有測試通過，毋須問用戶
    d. 完成後輸出修改摘要及每個失敗嘅根源分析
    → 詳見 `skills/autonomous-loop.md`
10. Commit（Conventional Commits 格式）
11. 透過 Agent tool 呼叫 code-reviewer agent 執行 /review（Code Reviewer 獨立 review）
12. Reviewer 返回後，按 `skills/post-review-handoff.md` → 標準流程 執行 handoff
13. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Branch 命名

```bash
# 有 ticket（必須加 ticket number）
fix/frontend/[TICKET_NUMBER]_[簡短描述]
fix/backend/[TICKET_NUMBER]_[簡短描述]

# 例子：
fix/frontend/CUI-0001_button_display_issue
fix/backend/CUI-0001_api_connection_error
fix/frontend/CUI-0002_login_form_validation
fix/backend/CUI-0003_token_expiry_handling
```

**規則**：
- 有 QA ticket 嘅 bug fix 必須帶 ticket number
- 前後端問題分開開 branch（對應各自子 ticket）
- 描述用 `snake_case`，3–5 個字
- ⚠️ **每個 ticket 必須獨立開一條 branch**，詳見 `skills/git-flow.md` → One-Task-One-Branch 鐵律

---

## TDD Fix 循環

### 🔴 Red — 先寫重現 bug 嘅測試

**呢步係關鍵**：測試必須：
- 重現 bug 描述嘅問題
- 喺修復前執行時失敗
- 喺修復後執行時通過

```
例子：
it('should not create duplicate payment when request sent twice')
it('should return 401 when token expired, not 500')
it('should parse dd/MM/yyyy date format correctly')
```

### 根源分析（Root Cause Analysis）

修復前必須輸出：

```
## Root Cause Analysis

**Bug 描述**：[用戶報告嘅問題]
**可重現步驟**：[步驟列表]
**根源**：[真正嘅原因，唔係表面現象]
**影響範圍**：[有冇其他地方受影響]
**修復方案**：[計劃點樣修復]
**回歸風險**：[修復可能影響嘅其他功能]
```

### 🟢 Green — 最少改動修復

```
- 只改修復 bug 所需嘅最少代碼
- 唔趁機做無關嘅重構
- 通過後執行完整測試套件
```

### 🔵 Refactor — 如有需要

```
- 如 bug 係由設計問題引起，可以小範圍重構
- 範圍必須明確，唔好無限擴大
- 確保所有測試仍然通過
```

---

## Commit 格式

每個 review item fix 使用其全局唯一 Review Item ID（`C-NNN`、`W-NNN`、`S-NNN`），確保 commit 可追溯至具體 review 觀察：

```
fix: [REVIEW_ITEM_ID] | [問題描述]

例子：
fix: W-003 | 修正 token 過期後返回 500 而非 401
fix: C-001 | 防止重複付款請求建立重複記錄
fix: S-007 | 提取 ANNUAL_SECTION_TITLES 為 module-level 常數
```

**無 review item 的一般 bug fix：**
```
fix: [問題描述]

例子：
fix: 修正 dd/MM/yyyy 日期格式解析錯誤
```

---

## 完成標準

```
□ Bug 重現測試通過
□ 完整測試套件無回歸問題
□ Root Cause Analysis 已記錄
□ ESLint / Prettier 無錯誤
□ Code Review 評分 ≥ 90 分
□ 無 🔴 Critical 問題
□ 透過 Agent tool 觸發 /review，後續 handoff 由 Reviewer/QA 自動執行
□ 如 bug 係常見陷阱，已記錄入 shared-knowledge.md
```

---

## 使用方式

```
# Review Item ID（全局唯一，跨 review 不重用）
/fix W-003                                 ← 修復指定 Warning
/fix C-001                                 ← 修復指定 Critical
/fix S-007                                 ← 修復指定 Suggestion
/fix W-003 W-004 S-007                     ← 各自獨立 branch + 獨立 commit，順序執行

# QA Ticket（ticket management 系統）
/fix CUI-0001                              ← 按 ticket number 修復
/fix CUI-0001 --frontend                   ← 指定前端部分
/fix CUI-0001 --backend                    ← 指定後端部分
```

> **Review Item ID vs QA Ticket**：兩套系統並行。Review Item ID（C/W/S-NNN）來自 Code Review 報告；QA Ticket（CUI-XXXX）來自 QA 測試報告。詳見 `skills/ticket-management.md`。
