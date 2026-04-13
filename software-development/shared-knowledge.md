# Shared Knowledge Log

> 跨 Agent、跨 Session 嘅共享知識庫。
> 任何 agent 發現 common knowledge 時，必須按格式記錄於此。
> 每個 session 開始前必須閱讀此檔案。

---

## 使用指引

### 何時記錄
- 發現項目特有技術規律或約定
- 發現常見錯誤模式或陷阱
- 發現跨模組嘅共用邏輯
- 發現第三方庫嘅重要限制或 workaround
- 發現環境或部署嘅特殊注意事項
- 發現業務邏輯中容易誤解嘅規則

### 記錄格式

```markdown
## [SK-XXX] [標題]

**日期**：YYYY-MM-DD HH:MM
**來源 Agent**：[agent 名稱]
**類別**：技術規律 / 錯誤模式 / 業務規則 / 環境注意 / 其他
**適用 Agent**：全部 / [指定 agent]
**有效期至**：YYYY-MM-DD / 永久（技術升級或問題解決後請更新）

**內容**：
[詳細描述]

**適用場景**：
[哪些任務需要注意]

**參考**：
[相關檔案或連結]

---
```

### 更新過時條目
如發現條目內容有誤或過時，在條目頂部加入：

```markdown
> ⚠️ 已更新：YYYY-MM-DD HH:MM，原因：[說明]
```

如條目完全失效，加入：

```markdown
> ❌ 已過期：YYYY-MM-DD HH:MM，原因：[說明]（保留作歷史參考，請勿跟從）
```

---

## 定期 Review 規則

**每個 session 開始時**：
- 閱讀所有條目，留意 `有效期至` 欄位
- 發現過期條目，立即標記 `❌ 已過期` 並說明原因

**每月一次**（或項目有重大升級時）：
- PM 或 Architect 主導 review 所有條目
- 確認仍然有效嘅條目，更新 `有效期至` 日期
- 標記失效條目

**觸發即時 review 嘅情況**：
- 更新第三方庫主版本
- 更換框架或 ORM
- 數據庫升級
- 任何 agent 發現某條目描述嘅問題已不存在

---

## 知識條目

## [SK-001] GAS Spreadsheet：Runtime 分類字串無法從 sheet 恢復，須 infer on readback

**日期**：2026-04-04
**來源 Agent**：Backend Developer + Architect
**類別**：技術規律
**適用 Agent**：全部
**有效期至**：永久

**內容**：
喺 GAS spreadsheet-bound 項目，`adjustmentType` 呢類 runtime enum 字串無對應欄位存入 spreadsheet。當腳本 clear + rewrite 所有 row 時（generate 步驟），必須從可觀察嘅數據欄位 infer 返分類：
- `otHours` 非空 → `ADJUSTMENT_TYPE.OT`
- `adjustment` 非空 且 `otHours` 為空 → `ADJUSTMENT_TYPE.SPECIAL`（具體類型不可知）
- 兩者皆空 → `null`（正常月份）

呢個模式首次於 `UK_Salary_Summary/_readExistingRows` 實現（AU-007 + RV-004）。

**適用場景**：
所有 GAS 項目中，generate 步驟需要 clear + rewrite sheet，而業務邏輯依賴 runtime 分類嘅場合。新增分類時必須同步更新 infer 邏輯。

**參考**：
- `UK_Salary_Summary/reports/salary-summary-generate.js` → `_readExistingRows`
- `UK_Salary_Summary/core/init.js` → `ADJUSTMENT_TYPE`

---

## [SK-002] Jest 測試基礎設施：utils 模組路徑依賴 `Constants.js`（非 `Base.js`）

**日期**：2026-04-04
**來源 Agent**：Backend Developer（fix/RV-013）
**類別**：錯誤模式
**適用 Agent**：全部（尤其 Developer、QA）
**有效期至**：永久（直至 utils 下次重構）

**內容**：
`UK_Expenses_Summary/tests/__mocks__/gas-globals.js` 從 `utils/spreadsheet/Constants.js` 載入 `COLOR` 同 `ICON` 全局量。2026-03-29 utils 重構時，原 `Base.js` 已改名為 `Constants.js`，但 mock 文件嘅引用未同步更新，導致所有測試 suite 喺 setup 階段 crash（`ENOENT: Base.js`），0 個測試可執行。

修正路徑（RV-013）：
```js
// gas-globals.js — 正確引用
_loadAsCJS(path.join(UTILS_ROOT, 'spreadsheet/Constants.js'), ['COLOR', 'ICON'])
```

**適用場景**：
- 新增或修改任何 GAS 項目嘅 Jest 測試基礎設施時
- 任何 GAS 項目引入 Jest 測試時，`gas-globals.js` 嘅 utils 路徑須與當前 `utils/spreadsheet/` 實際文件名對齊
- utils 再次重構（改名、拆分）後，必須同步檢查所有引用此路徑嘅 mock 文件

**參考**：
- `UK_Expenses_Summary/tests/__mocks__/gas-globals.js:102` — 已修正（RV-013）
- `Travel_Summary/tests/__mocks__/gas-globals.js:51` — ✅ 已修正，確認引用 `Constants.js`（2026-04-06 refactor session 驗證）
- `utils/spreadsheet/constants.js`（全小寫，`COLOR`、`ICON` 定義位置）

---

## [SK-003] GAS：`SpreadsheetApp.getUi()` 只可在 UI context 調用

**日期**：2026-04-12
**來源 Agent**：Architect（來自 session insight report）
**類別**：錯誤模式
**適用 Agent**：全部（尤其 Developer、Code Reviewer）
**有效期至**：永久

**內容**：
`SpreadsheetApp.getUi()` 只可從 UI context 調用（即 `onOpen` trigger、menu callback、sidebar 等）。
從以下位置調用會導致 runtime error：
- Custom functions（`=myFunction()` 喺 cell 中）
- Time-driven triggers
- API 調用（clasp run / Apps Script API）

**適用場景**：
- 新增或修改 menu、sidebar、dialog 等 UI 元素時，必須確保係在 `onOpen` 或 UI callback 中初始化
- Code Review 時留意有冇 `getUi()` 調用喺非 UI context

**正確做法**：
```js
// ✅ 正確：喺 onOpen trigger 中
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Tools')
    .addItem('Run', 'myFunction')
    .addToUi();
}

// ❌ 錯誤：喺 custom function 或 time trigger 中
function myTimeTrigger() {
  SpreadsheetApp.getUi().alert('message'); // 會 crash
}
```

**參考**：
- Session insight report：此 GAS-specific gotcha 曾造成 runtime error

---
