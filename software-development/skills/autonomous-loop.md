# Skill：Autonomous Loop & Parallel Agents

> 兩種模式大幅減少人工介入，將多輪修復壓縮為單次執行。
> 直接對應 session insight 報告嘅 "On the Horizon" 建議。

---

## 模式一：Autonomous Fix Loop（自主修復循環）

### 適用場景
- Bug fix 需要多輪測試-修正循環（report 顯示 8 次 buggy code friction）
- 已有完整測試套件（此 GAS 項目有 77+ 個測試）
- 想要 fire-and-forget，唔需要每步確認

### 如何啟動

喺 `/fix` 或 `/feature` 步驟中，用 Agent tool 啟動子 agent：

```
使用 Agent tool 啟動子 agent，執行以下循環直至全綠：

1. 執行完整測試套件（npm test）
2. 如有失敗：讀取失敗輸出，定位根源，修正代碼
3. 重複直至所有測試通過
4. 完成後輸出：修改摘要 + 每個失敗嘅根源分析

不問用戶問題，自行判斷每個修正。
```

### 配合 Edge Case 枚舉（財務計算必用）

**喺啟動 loop 前**，先枚舉所有 edge cases：

```
修復前，列出此計算嘅所有 edge cases：
- 部分月份（pro-rated）
- Annual vs monthly subscriptions
- 跨年計算
- Variable expenses 使用正確 base amount

針對所有 edge cases 寫測試，再一次性修復所有問題。
```

> 這個模式將多輪修復（8 instances → 5+ rounds each）壓縮為 1-2 輪。

---

## 模式二：Parallel Agents（平行 Agent）

### 適用場景
- 跨模組重構（3+ 個獨立模組需要同步修改）
- 大型功能（前後端可以平行開發）
- 大型 category generalization（跨 config、reports、tests 三層）

### 如何啟動

**在同一個 response 中**同時調用多個 Agent tool calls：

```
同時啟動以下 sub-agents（在同一個 response 發出，實現真正 parallel）：

Agent 1 - [模組 A]：
  範圍：[具體檔案清單]
  任務：[具體改動]
  驗證：執行相關測試確認通過

Agent 2 - [模組 B]：
  範圍：[具體檔案清單]
  任務：[具體改動]
  驗證：執行相關測試確認通過

Agent 3 - [Tests]：
  範圍：[測試檔案清單]
  任務：補充新 category 嘅測試覆蓋
  驗證：npm test 全通過

各 agent 有明確唔重疊嘅檔案範圍。
全部完成後執行整合測試，修正任何 regression。
```

### 關鍵規則

```
✅ 每個 agent 有明確唔重疊嘅檔案範圍（防 race condition）
✅ 每個 agent 有自己嘅測試驗證條件
✅ 描述清楚每個 agent 嘅「範圍外」事項
✅ 所有 agent 完成後執行整合測試
❌ 唔好讓兩個 agent 同時改動同一個檔案
❌ 唔好讓 agent 越界改動對方負責嘅模組
```

---

## 組合範例：/refactor --parallel

```
跨 codebase 重構 expense category 處理（同時啟動 3 個 agents）：

Agent 1 - Config Layer：
  範圍：config/mapping.js, config/categories.js
  任務：更新 category type definitions，統一命名規範
  驗證：node --check 語法通過，unit tests 通過

Agent 2 - Reports Layer：
  範圍：reports/monthly-summary.js, reports/annual-summary.js
  任務：更新 report generator 使用新 generalized categories
  驗證：report 相關 tests 通過

Agent 3 - Test Layer：
  範圍：tests/
  任務：更新測試以覆蓋新 categories，補充缺失 edge cases
  驗證：npm test 全通過

三個 agents 同時執行，完成後匯報各自改動摘要。
主 agent 執行 npm test，修正任何整合問題。
```

---

## 與 Hooks 組合（最佳效果）

`skills/hooks.md` + Autonomous Loop 組合：

```
Hooks 即時偵測錯誤  →  Autonomous Loop 自動修正  →  無需人工介入
```

- Hook 偵測 JS 語法錯誤 → Agent 立即修正，不等用戶
- Hook 觸發 merge 後測試 → Agent 自主修復 regression
- 大幅減少「edit → 發現問題 → 用戶介入 → 修正」嘅往返

---

## 何時使用哪個模式

| 情況 | 推薦模式 |
|------|----------|
| 單一模組 bug，需要多輪修正 | Autonomous Loop |
| 財務計算邏輯修復 | Autonomous Loop + Edge Case 枚舉 |
| 跨 3+ 個獨立模組嘅改動 | Parallel Agents |
| 前後端同步開發新功能 | Parallel Agents |
| Merge 後測試失敗需要修正 | Autonomous Loop |
| 大型 category generalization | Parallel Agents |
