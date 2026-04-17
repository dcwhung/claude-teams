---
name: sw-autonomous-loop
description: Self-healing fix loop + parallel subagent dispatch + edge case enumeration. Load when tests are failing and need to iterate until green, when a task spans 3+ independent modules, or when the user says "fix all failing tests", "do this in parallel", "run agents simultaneously", or "I don't want to babysit each step". Also load when a fix loop keeps cycling without converging — edge case enumeration breaks the cycle.
---

# Skill：Autonomous Loop & Parallel Agents

> 兩種模式大幅減少人工介入，將多輪修復壓縮為單次執行。

---

## 模式一：Autonomous Fix Loop（自主修復循環）

### 適用場景
- Bug fix 需要多輪測試-修正循環
- 已有完整測試套件，測試失敗輸出清晰
- 想要 fire-and-forget，唔需要每步確認

### 如何啟動

喺 `/fix` 或 `/feature` 步驟中，用 Agent tool 啟動子 agent：

```
使用 Agent tool 啟動子 agent，執行以下循環直至全綠：

1. 執行完整測試套件（[項目測試指令，如 npm test / pytest / php artisan test]）
2. 如有失敗：讀取失敗輸出，定位根源，修正代碼
3. 重複直至所有測試通過
4. 完成後輸出：修改摘要 + 每個失敗嘅根源分析

不問用戶問題，自行判斷每個修正。
```

### 配合 Edge Case 枚舉（複雜業務邏輯必用）

**喺啟動 loop 前**，若涉及複雜業務規則（計算邏輯、日期邏輯、狀態機等），先枚舉所有 edge cases：

```
修復前，列出此邏輯嘅所有 edge cases：
- 零值 / null / 空集合
- 邊界值（最小值、最大值、臨界點）
- 異常輸入（格式錯誤、類型錯誤）
- 並發或重複操作（idempotency）
- 跨境條件（跨日期、跨狀態、跨層）

針對所有 edge cases 寫測試，再一次性修復所有問題。
```

> 此模式將多輪修復壓縮為 1-2 輪。

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
跨 codebase 重構（同時啟動 3 個 agents）：

Agent 1 - [模組 A]：
  範圍：[具體檔案清單]
  任務：更新 [模組 A] 嘅邏輯及命名規範
  驗證：語法通過，unit tests 通過

Agent 2 - [模組 B]：
  範圍：[具體檔案清單]
  任務：更新 [模組 B] 使用新嘅共用邏輯
  驗證：相關 tests 通過

Agent 3 - Test Layer：
  範圍：[測試檔案清單]
  任務：更新測試以覆蓋新邏輯，補充缺失 edge cases
  驗證：完整測試套件全通過

三個 agents 同時執行，完成後匯報各自改動摘要。
主 agent 執行完整測試套件，修正任何整合問題。
```

---

## 與 Hooks 組合（最佳效果）

`skills/hooks.md` + Autonomous Loop 組合：

```
Hooks 即時偵測錯誤  →  Autonomous Loop 自動修正  →  無需人工介入
```

- Hook 偵測語法錯誤 → Agent 立即修正，不等用戶
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
