---
description: PM + Architect 可行性研究 + implementation plan
argument-hint: [topic]
---

# 指令：/plan

## 用途

根據 spec 或需求描述，進行可行性評估並制定 Implementation Plan，分解任務、排列優先順序、識別風險。

## 負責 Agent

**Project Manager**（主導）+ **Architect**（技術可行性）

---

## 引用規範（SSoT）

- Plan Before Do 確認規則（main vs subagent）→ `skills/sw-agent-protocols/SKILL.md` §2

本檔案只定義 `/plan` 獨有嘅執行流程、可行性框架同輸出格式。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取現有 spec（如有）及 project CLAUDE.md
3. 輸出執行計劃
   - Main agent（直接同用戶對話）：等用戶確認
   - Subagent（由 main agent invoke）：立即執行，唔等確認（見 agent-protocols.md §2）
4. Architect 進行技術可行性評估
5. PM 制定任務分解及優先順序
6. 識別風險及依賴關係
7. 估算工作量
8. 輸出完整 Implementation Plan
9. 等待用戶確認計劃
10. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 可行性評估框架

Architect 必須從以下維度評估：

```
技術可行性    ← 現有技術棧能否支持？有冇技術限制？
時間可行性    ← 工作量估算係咪合理？
資源可行性    ← 需要哪些技術能力？
風險評估      ← 有冇未知因素或技術盲點？
依賴識別      ← 有冇外部依賴（API、第三方服務）？
```

---

## 輸出格式

```markdown
# Implementation Plan：[功能 / 項目名稱]

**版本**：v1.0
**日期**：YYYY-MM-DD HH:MM
**關聯 Spec**：[版本 + 日期]
**負責人**：Project Manager + Architect Agent

---

## 可行性評估

### 技術可行性
| 項目 | 評估 | 備注 |
|------|------|------|
| 技術棧支持 | ✅ / ⚠️ / ❌ | |
| 第三方依賴 | ✅ / ⚠️ / ❌ | |
| 性能要求 | ✅ / ⚠️ / ❌ | |
| 安全要求 | ✅ / ⚠️ / ❌ | |

**總體可行性**：✅ 可行 / ⚠️ 有條件可行 / ❌ 不可行

**不可行或有條件嘅原因**：[如有，詳細說明]

---

## 階段劃分

### Phase 1：[階段名稱]
- **目標**：[此階段要達成乜]
- **包含功能**：[功能列表]
- **預計工作量**：[估計]
- **完成標準**：[可測試嘅完成條件]

### Phase 2：[階段名稱]
- ...

---

## 任務分解

| 任務編號 | 任務描述 | 類型 | 負責 Agent | Mockup Binding | 預計工作量 | 依賴任務 | 優先級 |
|----------|----------|------|-----------|----------------|-----------|----------|--------|
| T-001 | | feature/fix/chore | | mockup: / baseline: / none-required | | - | P0 |
| T-002 | | | | | | T-001 | P0 |
| T-003 | | | | | | T-001 | P1 |

> ⚠️ **Mockup Binding 欄規則**：
> - UI 任務：必須填 `mockup: <path>` / `baseline: <path>` / `proposal: <spec-section>` / `library: <name@ver>`
> - 後端 / logic 任務：填 `none-required`
> - Binding 空白嘅 UI 任務 → flag 返去 `/spec` 補 Design Source 先可以 plan

**任務類型說明**：
- `feature`：新功能開發
- `fix`：Bug 修復
- `refactor`：重構
- `chore`：環境、配置、依賴
- `test`：測試補充
- `docs`：文件更新

---

## 風險登記

| 風險編號 | 風險描述 | 可能性 | 影響 | 應對方案 | 負責人 |
|----------|----------|--------|------|----------|--------|
| R-001 | | 高/中/低 | 高/中/低 | | |

---

## 依賴關係

### 內部依賴
[任務之間嘅依賴關係]

### 外部依賴
| 依賴項 | 類型 | 狀態 | 影響任務 |
|--------|------|------|----------|
| | API / 服務 / 人員 | 已確認 / 待確認 | |

---

## 工作量估算

| 階段 | 前端 | 後端 | DevOps | QA | 總計 |
|------|------|------|--------|-----|------|
| Phase 1 | | | | | |
| Phase 2 | | | | | |
| **總計** | | | | | |

---

## 建議開始順序

```
Step 1 → [最先做嘅任務，原因]
Step 2 → [第二步，原因]
...
```

---

## 假設及前提

- [列出所有假設，必須在開始前確認]

---

## 開放問題

| 問題 | 影響任務 | 需要誰決定 | 截止日期 |
|------|----------|-----------|----------|
| | | | |
```

---

## Sprint Planning（`/plan --sprint`）

> 當有多個 pending tickets 需要排優先順序時使用。
> PM 主導，幫團隊決定今個 iteration 做乜。

### Sprint Planning 輸出格式

```markdown
## Sprint [N] Planning

**Sprint 期間**：YYYY-MM-DD → YYYY-MM-DD（通常 1–2 週）
**Sprint 目標**：[一句話描述今個 sprint 要達成乜]

### 納入本 Sprint

| Ticket | 標題 | 優先級 | 預計工作量 | 負責人 |
|--------|------|--------|-----------|--------|
| CUI-0001 | | 🔴 | | Frontend Developer |
| CUI-0003 | | 🟡 | | Backend Developer |

**Sprint 總工作量**：[估計]
**緩衝**：[預留 20% 處理突發情況]

### 排除本 Sprint（原因）

| Ticket | 排除原因 | 計劃納入 |
|--------|----------|----------|
| CUI-0005 | 依賴 CUI-0003 未完成 | Sprint N+1 |
| CUI-0008 | 優先級較低 | Sprint N+2 |

### Sprint 風險
- [列出本 sprint 嘅已知風險]
```

### 排優先順序原則

```
P0 🔴  生產 bug、安全漏洞、阻塞其他工作嘅 blocker
P1 🟡  核心功能、有 deadline 嘅需求、依賴鏈上游任務
P2 🟢  改善性功能、技術債、nice-to-have
```

---

## 使用方式

```
/plan                      ← 根據當前 spec 生成計劃
/plan --feasibility-only   ← 只做可行性評估
/plan --rescope            ← 重新評估現有計劃範圍
/plan --sprint             ← Sprint planning，排列 pending tickets 優先順序
```
