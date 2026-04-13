# 指令：/spec

## 用途

根據需求討論，生成 Functional Spec 及 Technical Spec，作為開發團隊嘅執行依據。

## 負責 Agent

**Project Manager**（Functional Spec）+ **Architect**（Technical Spec）

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取現有 project CLAUDE.md（了解 stack 及 constraints）
3. 輸出執行計劃，等待確認
4. 如需求未釐清，按需求釐清框架提問（一次過）
5. 撰寫 Functional Spec（PM 主導）
6. 等待用戶確認 Functional Spec
7. 撰寫 Technical Spec（Architect 主導）
8. 等待用戶確認 Technical Spec
9. 輸出最終文件（可下載）
10. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## Functional Spec 格式

```markdown
# Functional Spec：[功能 / 項目名稱]

**版本**：v1.0
**日期**：YYYY-MM-DD HH:MM
**作者**：Project Manager Agent
**狀態**：Draft / Review / Approved

---

## 背景及目標

[描述業務背景，為何需要呢個功能 / 項目]

## 目標用戶

| 用戶類型 | 描述 | 主要需求 |
|----------|------|----------|
| | | |

## 用戶故事（User Stories）

### [US-001] [故事標題]
- **身份**：作為 [用戶類型]
- **目標**：我希望 [做某事]
- **原因**：以便 [達到某目標]
- **驗收標準**：
  - [ ] [具體可測試嘅條件]
  - [ ] [具體可測試嘅條件]

## 功能需求

| 優先級 | 需求編號 | 功能描述 | 備注 |
|--------|----------|----------|------|
| P0（必須） | FR-001 | | |
| P1（重要） | FR-002 | | |
| P2（可選） | FR-003 | | |

## 非功能需求

| 類別 | 需求 | 指標 |
|------|------|------|
| 性能 | | |
| 安全 | | |
| 可用性 | | |
| 可維護性 | | |

## 範圍外（Out of Scope）

- [明確列出唔係呢次做嘅嘢]

## 驗收標準

[整體驗收條件，超出個別 US 層面]

## 假設及依賴

- [列出所有假設]
- [列出外部依賴]

## 開放問題

| 問題 | 負責人 | 截止日期 |
|------|--------|----------|
| | | |
```

---

## Technical Spec 格式

```markdown
# Technical Spec：[功能 / 項目名稱]

**版本**：v1.0
**日期**：YYYY-MM-DD HH:MM
**作者**：Architect Agent
**關聯 Functional Spec**：[版本 + 日期]
**狀態**：Draft / Review / Approved

---

## 架構概覽

[文字描述整體技術架構，包括各層次職責]

## Tech Stack

| 層級 | 技術 | 版本 | 選擇原因 |
|------|------|------|----------|
| | | | |

## 系統架構

### 組件圖（文字描述）
[描述各組件及其關係]

### 數據流
[描述主要數據流向]

## API 設計

### [API-001] [Endpoint 名稱]
- **Method**：GET / POST / PUT / PATCH / DELETE
- **Path**：`/api/v1/...`
- **認證**：Required / Optional / None
- **Request Body**：
  ```json
  { }
  ```
- **Response（200）**：
  ```json
  { }
  ```
- **Error Cases**：
  | Status | Code | 描述 |
  |--------|------|------|
  | 400 | VALIDATION_ERROR | |
  | 401 | UNAUTHORIZED | |

## 數據庫設計

### [表名]
| 欄位 | 類型 | 約束 | 描述 |
|------|------|------|------|
| id | uuid | PK | |
| created_at | timestamp | NOT NULL | |

### 索引設計
[列出需要建立嘅索引及原因]

## 安全設計

[認證方式、授權策略、輸入驗證、敏感資料處理]

## 性能考量

[預期負載、瓶頸識別、緩存策略、優化方向]

## 部署架構

[環境設定、基礎設施需求、CI/CD 整合點]

## 技術風險

| 風險 | 可能性 | 影響 | 應對方案 |
|------|--------|------|----------|
| | 高/中/低 | 高/中/低 | |

## 實現注意事項

[開發時需要特別注意嘅技術細節]
```

---

## Change Request（CR）流程

> Spec 一旦 Approved，任何改動必須經 CR 流程，唔可以靜靜雞改。

### 觸發條件
- 用戶提出需求改動
- 開發過程中發現原 spec 有誤或不可行
- 外部依賴變化導致設計需要調整

### CR 執行步驟

```
1. PM 評估改動影響：
   - 影響哪些 User Stories / 功能需求？
   - 影響哪些已完成嘅開發工作？
   - 影響時間線多少？
2. 輸出 CR 影響評估，等待確認
3. 確認後更新 spec 版本號（v1.0 → v1.1）
4. 喺 spec 修訂記錄加入改動描述
5. 通知相關 agent 有 spec 更新
```

### CR 影響評估格式

```markdown
## Change Request 影響評估

**CR 編號**：CR-001
**日期**：YYYY-MM-DD HH:MM
**提出人**：[用戶 / Agent]
**改動描述**：[清楚描述要改乜]

**影響範圍**：
- 受影響 User Stories：[US-001, US-003]
- 受影響功能需求：[FR-002, FR-005]
- 已完成開發受影響：[有 / 無，如有列出]
- 時間線影響：[估計額外工作量]

**建議方案**：[接受 / 拒絕 / 分拆至下一個 iteration]
**理由**：[原因]
```

---

## 使用方式

```
/spec                    ← 根據當前對話需求生成 spec
/spec --functional-only  ← 只生成 functional spec
/spec --technical-only   ← 只生成 technical spec
/spec --update           ← 更新現有 spec（觸發 CR 流程）
/spec --cr               ← 處理 Change Request
```
