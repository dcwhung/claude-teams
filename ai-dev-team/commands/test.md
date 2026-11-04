---
description: QA 按階段驗收（S1 功能鏈 / S2 整合 / S3 發佈前），已凍結冇改嘅唔再驗，輸出精簡 QA 報告
argument-hint: [--stage=chain|integration|release] [chain_id | CUI-XXXX]
---

# 指令：/test

## 用途

按改動範圍做驗收：**已通過、SHA-256 冇變嘅功能鏈唔再驗**。每個 finding 要經三層收斂 Validation Gate，先可以 block。

## 負責 Agent

**Quality Assurance**（主導）

---

## 引用規範（SSoT）

- 階段、ledger、frozen plan、L1/L2/L3 gate、報告上限 → `skills/sw-validation-gate/SKILL.md`
- QA 行為、Hard Gates 表、報告模板 → `agents/quality-assurance.md`
- Ticket（CUI-XXXX）→ `skills/sw-ticket-management/SKILL.md`（有 ticket 要開先讀）
- Handoff → `skills/sw-post-review-handoff/SKILL.md` → Protocol 2

本檔案只定義 `/test` 嘅參數同 performance 規範。

---

## 執行流程

```
1. 讀 sw-validation-gate + project CLAUDE.md + known-issues.md（如有）
2. 分級 T0–T3；T0 → 直接 pass，唔跑 test
3. qa-ledger.sh impact --since <base> → 決定 REVERIFY / SKIP / UNCOVERED
4. 沿用或新寫 frozen plan（只限 REVERIFY / UNCOVERED 鏈）
5. 按 plan 執行，每條指令一次（flaky 最多重跑 1 次）
6. Finding 過 Validation Gate → 定級
7. Pass 嘅鏈 freeze → 輸出報告 + handoff-receipt（Protocol 2）
```

> Subagent 輸出計劃之後**直接執行**，唔使等確認。
> `<base>` 預設：S1 = feature branch 嘅 merge-base；S2 = 上次 S2 嘅 commit；S3 = 上一個 release tag。

---

## 使用方式

| 指令 | 階段 | 範圍 |
|------|------|------|
| `/test` | S1（預設） | Reviewer pass 嗰條功能鏈 |
| `/test <chain_id>` / `/test CUI-XXXX` | S1 | 指定嘅鏈或 ticket |
| `/test --stage=integration` | S2 | UAT：REVERIFY 鏈 + 跨功能 journey |
| `/test --stage=release` | S3 | 發佈前：full suite 一次 + STALE 鏈手動驗 + PWA gate |
| `/test --design` | — | 只輸出 frozen plan，唔執行 |
| `/test --status` | — | 只跑 `qa-ledger.sh status`，列出 FROZEN / STALE |

---

## Performance Testing（有條件先做）

> 只適用於有 **backend API** 嘅 project。純前端 PWA 冇 API 改動就跳過，報告寫「n/a」。

### 必須執行嘅情況

```
□ 新增大數據量 API（列表、搜尋、報表）
□ 新增 DB 查詢（要 EXPLAIN 確認有用 index）
□ 新增外部 API 調用（要有 timeout）
□ 修改現有高頻 API / 有 N+1 query 風險
```

### Response Time 基準（project CLAUDE.md 可以覆蓋）

| API 類型 | P95 |
|----------|-----|
| 一般讀取 | < 300ms |
| 列表查詢 / 寫入 | < 500ms |
| 複雜報表 | < 5s |

判定（亦要過 Validation Gate：L1 = 基準表，L2 = k6 / 實測輸出）：
- 🔴 P95 超過基準 2 倍，或失敗率 > 1%
- 🟡 P95 超過基準
- 🟢 可以優化但未超標 → backlog

---

## 阻止 Release 條件

見 `agents/quality-assurance.md` §阻止部署條件。
