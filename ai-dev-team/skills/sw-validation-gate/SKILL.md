---
name: sw-validation-gate
description: SSoT for QA scope and finding validity — Verification Ledger (SHA-256 freeze, already-verified + unchanged = never re-verified), three acceptance stages (S1 功能鏈驗收 / S2 整合性驗收 / S3 全面檢查驗收), frozen test plans, and the Three-Tier Convergent Validation Gate (L1 SSoT / L2 reproducible evidence / L3 AI inference) that decides whether a finding may block. Load before ANY /test or /review, before writing a test plan, before raising a finding, or when QA feels slow, repetitive, or keeps finding "problems".
---

# Skill：Validation Gate（驗收凍結 + 三階段驗收 + 三層收斂驗證）

> **核心原則**：已通過、SHA-256 冇變嘅嘢唔再驗。驗收範圍由「改咗乜」決定，唔係由「可以驗乜」決定。
> 一個「問題」要經 L1 / L2 / L3 三層交叉印證、同源收斂，先有資格 block。

> **觸發原因（2026-11-04）**：903-player 同 life-in-uk-test 嘅記錄顯示：
> - QA 每次都跑 full suite：life-in-uk 72/72 份 QA 都跑，連純改註解都要 958 s
> - 同一個 SHA 由 Reviewer、QA、CI 各跑一次
> - QA 自己加碼：e2e ×2/×4/×5、swapped build、加 CPU 負載
> - 🟢 Low 問題佔大多數，但都觸發 re-review（35/93、16/43）

---

## 1. Verification Ledger（SHA-256 凍結）

### 檔案

| 檔案 | 用途 | Git |
|------|------|-----|
| `.proj-docs/qa/verification-ledger.tsv` | 每條已驗證鏈嘅檔案 + SHA-256 | ✅ 必須 tracked（唔可以入 `.gitignore`，見 SK-016） |
| `.proj-docs/qa/plans/<chain_id>.md` | Frozen test plan（見 §3） | ✅ tracked |
| `.proj-docs/qa/known-issues.md` | 已知失敗登記（KI-NNN） | ✅ tracked |

### 工具：`${CLAUDE_PLUGIN_ROOT}/scripts/qa-ledger.sh`（喺 repo root 執行）

```bash
# 開工第一步：邊啲要驗、邊啲可以跳
bash "${CLAUDE_PLUGIN_ROOT}/scripts/qa-ledger.sh" impact --since <base-ref>   # 例：develop、上次 release tag
# → REVERIFY <chain>   要重驗
# → SKIP <chain>       已凍結、冇改 → 報告引用 ledger 行，唔可以再跑
# → UNCOVERED <path>   未屬任何鏈 → 要開新鏈行 S1

# 驗收 pass 之後凍結（同一個 chain + stage 重跑會覆蓋，冪等）
bash "${CLAUDE_PLUGIN_ROOT}/scripts/qa-ledger.sh" freeze <chain_id> <S1|S2|S3> <report-path> <plan-file> <scope-files...>

# 檢查：FROZEN / STALE（列出改咗嘅 path）/ MISSING
bash "${CLAUDE_PLUGIN_ROOT}/scripts/qa-ledger.sh" status [chain_id]
```

> `CLAUDE_PLUGIN_ROOT` 冇 set 嘅話，用 SessionStart hook 印出嚟嘅 plugin 路徑。
> Exit code：0 = 全部 frozen，1 = 有要重驗，2 = 用法錯誤。

### 凍結規則

```
✅ freeze 嘅檔案清單 = frozen plan 檔 + plan 入面列明嘅 scope 檔（實作 + test）
✅ 只有喺該階段 pass 之後先 freeze；fail 唔 freeze
✅ SKIP 嘅鏈：報告寫一行「SKIP <chain> frozen @<commit>」，唔讀佢嘅 code，唔跑佢嘅 test
❌ 以「保險起見」重驗 SKIP 嘅鏈
❌ 改咗 plan 檔但唔重新 freeze（plan hash 變咗 = 鏈係 STALE）
```

---

## 2. 三階段驗收（Stage）

| 階段 | 觸發 | 範圍 | 自動化測試 | 手動 / PWA | 結束 |
|------|------|------|-----------|-----------|------|
| **S1 功能鏈驗收** | 單一功能 Reviewer pass 後（`/test` 預設） | 只限 frozen plan 嘅 scope | 只跑 plan 列明嘅 unit test 同對應呢條鏈嘅 e2e spec | PWA gate 只喺 scope 改到 `sw.js`、更新邏輯、build config 或 manifest 先做 | `freeze <chain> S1` |
| **S2 整合性驗收** | UAT（`/test --stage=integration`） | `impact` 列出嘅 REVERIFY 同新鏈，加埋佢哋之間嘅跨功能 user journey | 只跑涉及上述鏈嘅 e2e journey | 只做 REVERIFY 鏈 | `freeze <journey> S2` |
| **S3 全面檢查驗收** | 發佈前（`/test --stage=release`） | 整個 release | **Automated full suite 每個 release SHA 跑一次**；CI 喺同一個 SHA 已經綠 → 引用 CI run，唔重跑 | 手動、探索式、PWA vN→vN+1 只做上次 release 之後 STALE 嘅鏈；PWA gate 每次 release 做一次 | `freeze release-<version> S3` |

> S3 包含 S1：如果 `impact` 仲有 REVERIFY / UNCOVERED 鏈（例如 fix 完即刻 release），S3 會順手按嗰啲鏈嘅 plan 做 S1 並 freeze，唔使先跑一次 `/test` 再跑一次 `/test --stage=release`。
> MAJOR release 都係行 S3：automated full suite 照跑，先知會用戶（Hard Rule #7）；已凍結嘅鏈唔再做手動重驗。

### 改動分級（決定使唔使入 QA）

| 級別 | 例子 | 處理 |
|------|------|------|
| **T0** | 只改 docs、註解、純格式（AST 無變，見 SK-017） | 唔入 QA；Reviewer 用 light review + lint 就 pass；ledger 唔使改 |
| **T1** | PATCH、單一模組 | S1 |
| **T2** | MINOR、新功能、跨模組 | S1，然後喺 UAT 行 S2 |
| **T3** | MAJOR、改 `sw.js` / build / manifest / 更新邏輯 / test setup | S1 加 PWA gate；release 時行 S3 |

---

## 3. Frozen Test Plan（防過厚、防範圍擴散）

每條鏈喺第一次行 S1 時寫一次 plan：`.proj-docs/qa/plans/<chain_id>.md`，上限 40 行。

```markdown
# Test Plan — <chain_id>
- Chain: <一句描述功能鏈>
- AC: AC-1 <…> / AC-2 <…>            ← L1 基準來源（spec / ticket / mockup）
- Scope files:                          ← 實作檔 + test 檔 + 直接 import 佢嘅檔（只計 1-hop）
  - src/…
- Commands:                             ← 只列呢條鏈要跑嘅指令
  - npx vitest run <files>
  - node e2e/<spec>.mjs
- PWA gate: yes | no（原因）
- Out of scope: <相鄰但唔驗嘅功能>
```

```
✅ 之後重驗同一條鏈 → 沿用同一份 plan，唔重寫
✅ Scope 只可以喺兩種情況擴大：(a) `impact` 指出 scope 檔改咗；(b) 一個三層收斂嘅 finding 需要
✅ 相鄰範圍只計 1-hop 直接 import，唔計 transitive
❌ 一份 plan 覆蓋成個 app
❌ Plan 入面寫「regression：跑 full suite」（full suite 只屬 S3）
```

### 防「過度完整」禁令（S1 / S2）

```
❌ 已 pass 嘅 test 為「double check」再跑
❌ Flaky 重跑多過 1 次 → 第 2 次都 fail 就登記 KI 或開 ticket，唔好再重跑
❌ 加 CPU 負載重跑、swapped build、mutation 測試、手動 PWA 矩陣（只限 S3 而且 PWA 鏈係 STALE）
❌ 為咗「完整」補寫 edge case → 只有 S1 而且屬高風險邏輯（計算 / state machine / business logic）先補，上限 3 個
❌ 重新分析已登記嘅 known issue → 報告寫「KI-NNN（known）」一行就夠
```

---

## 4. Validation Gate — 三層收斂驗證（Three-Tier Convergent Validation）

> 越強嘅 AI 越識搵「問題」。呢個 gate 決定一個 finding 有冇資格 block。
> L1–L3 按 **證據權威度** 分層。

| 層 | 定義 | 合法引證 |
|----|------|---------|
| **L1 一手基準** | 用戶原始需求 / SSoT | AC ID、spec 章節、ticket、mockup 路徑、`package.json` version、Hard Rule 編號、`file:line` |
| **L2 可重現證據** | 實際執行得出嘅證據 | 指令 + 輸出節錄（≤ 10 行）、failing test 名、log、截圖路徑；而且要重現到 |
| **L3 模型推論** | AI 推導出嚟嘅根本原因同影響 | 根本原因分析；必須同 L1、L2 指向**同一症狀、同一位置** |

### 判定表

| L1 | L2 | L3 對齊 | 結果 | Block? | Ticket? | Re-review? |
|----|----|---------|------|--------|---------|------------|
| ✅ | ✅ | ✅ | 🔴 Critical（違反核心 AC / 安全 / 數據）或 🟡 Major | ✅ | ✅ | ✅ |
| ❌ 冇違反任何 AC / SSoT | ✅ | — | 🟢 Minor（偏好 / 改善建議） | ❌ | ❌，入 backlog | ❌ |
| ✅ | ❌ 重現唔到 | — | Observation | ❌ | ❌ | ❌ |
| ❌ | ❌ | — | 唔寫入報告 | ❌ | ❌ | ❌ |

```
✅ 每個 🔴 / 🟡 finding 必須逐行列出 L1 / L2 / L3 引證；缺任何一層 → 自動降級
✅ 🟢 Minor 同 Observation：每條一行，唔寫分析段落
✅ Reviewer 同 QA 共用呢個 gate
❌ 用「可能」「理論上」「最佳實踐」作 L1（佢哋係 L3）
❌ 用「我讀 code 覺得會 fail」作 L2（嗰個係 L3；L2 要實際跑過）
❌ 🟢 / Observation 觸發 status=warn / fail
```

---

## 5. 報告上限

| 報告 | 上限 | 必須有 | 禁止 |
|------|------|--------|------|
| QA（S1 / S2） | 60 行 | Stage、ledger 摘要（SKIP N / REVERIFY M / UNCOVERED K）、跑過嘅指令 + 結果、finding（附 L1/L2/L3）、receipt | 抄 review 內容；Hard Gates 全 pass 都逐項列（只寫一行「all pass」）；嵌入截圖 |
| QA（S3） | 100 行 | 同上，加 full suite 結果（或 CI run 連結 + SHA）同 PWA gate 結果 | 同上 |
| Review | 120 行 | 評分、三層收斂嘅 finding、receipt | 🟢 寫成段落 |

截圖存 scratchpad 或者 `.gitignore` 咗嘅路徑；只有 design baseline 先 commit 入 `.proj-docs/design-baselines/`。

---

## 6. Known Issues（`.proj-docs/qa/known-issues.md`）

```markdown
| KI | Test / 症狀 | 原因 | 狀態 | 首次記錄 |
|----|------------|------|------|---------|
| KI-001 | desktop-study-test fail @ cloud | 環境（無 GPU） | open | 2026-10-30 |
```

QA 遇到已登記嘅 KI → 唔計 fail，報告寫一行引用 KI。新出現嘅環境失敗 → 新增一個 KI，唔使開 CUI ticket。

---

## 7. Cross-link

- 測試執行範圍（Developer / Reviewer）→ `skills/sw-tdd/SKILL.md` §測試執行範圍
- Receipt 格式（`stage` 欄）→ `skills/sw-post-review-handoff/SKILL.md`
- Cloud 環境 Playwright 版本唔夾 → `shared-knowledge.md` SK-023
