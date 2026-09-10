# 全局規範

> 適用於所有 team、所有項目、所有 session。
> Team 層或 Project 層可覆蓋個別規則，但不可完全忽略此文件。

---

## 語言規範

- 預設以**繁體中文（廣東話書面語）**溝通
- 代碼、技術術語、變數命名一律使用英文
- 文件（spec、log、README）視項目要求決定語言

---

## Agent 行為準則（所有 agent 必須遵守）

### Fact-Check Before Answer
- 所有技術判斷必須基於已知事實，不靠估
- 遇到不確定嘅技術細節，明確說明「需要確認」並列出假設
- 唔好為咗流暢輸出而捏造 API、函數名、行為

### Plan Before Do
每次執行任何任務（代碼、review、spec 等）前，**必須先輸出執行計劃**：

```
📋 執行計劃
- 目標：[一句說清楚做乜]
- 步驟：[有序列表]
- 假設：[列出所有假設]
- 風險：[潛在問題或不確定點]
- 範圍外：[明確列出唔做乜]
```

等待確認後才開始執行，除非用戶明確說「直接做」。

### 問清楚先做
- 需求模糊時必須提問，不靠估
- 一次過問清楚所有問題，唔好逐條問

### Step Execution Integrity（禁止 Ghost Referencing）
- **禁止 Ghost Referencing**：每個 command 步驟必須實際執行，唔可只喺文字中提及、略過或假裝執行
- **步驟完成公告**：每完成一個步驟必須輸出 `✅ 步驟 [N] 完成：[可驗證結果]`，然後才進行下一步
- **禁止靜默跳步**：如有充分理由跳過某步驟，必須向用戶說明原因並取得確認
- **Invoke 必須透過 Agent tool**：觸發 reviewer / QA / subagent 必須實際 invoke，唔係文字描述
→ 詳細規則及 checkpoint 格式：`skills/sw-agent-protocols/SKILL.md` §9

### Shared Knowledge（跨 Agent 知識共享）

任何 agent 在工作過程中，若發現以下類型嘅 **common knowledge**，必須記錄入 shared knowledge log，供其他 agent 及下一個 session 參考。

**觸發條件（發現以下情況時必須記錄）：**
- 發現項目特有嘅技術規律或約定（例如：「呢個項目所有 API 都要加 `X-Request-ID` header」）
- 發現常見錯誤模式或陷阱（例如：「呢個 ORM 版本喺 transaction 內唔支持 upsert」）
- 發現跨模組嘅共用邏輯或工具函數
- 發現第三方庫嘅重要限制或 workaround
- 發現環境或部署嘅特殊注意事項
- 發現業務邏輯中容易誤解嘅規則

**記錄格式：**

```markdown
## [SK-001] [標題]

**日期**：YYYY-MM-DD HH:MM
**來源 Agent**：[agent 名稱]
**類別**：技術規律 / 錯誤模式 / 業務規則 / 環境注意 / 其他
**適用 Agent**：全部 / [指定 agent]
**有效期至**：YYYY-MM-DD / 永久

**內容**：
[詳細描述，包括背景、原因、影響範圍]

**適用場景**：
[哪些任務或情況需要注意]

**參考**：
[相關檔案路徑、PR、issue 等]

---
```

**記錄位置：**
- 全局知識（適用所有項目）：`${CLAUDE_PLUGIN_ROOT}/shared-knowledge.md`
- 項目專屬知識：`~/projects/[project-name]/.claude/shared-knowledge.md`

> ⚠️ 項目 shared knowledge **唔可以**放入 `session-logs/`——session log 有 90 天自動清除規則，shared knowledge 係永久性知識。

**全局 vs 項目選擇準則：**
- **全局**：跨項目通用嘅技術規律（如框架 bug workaround、第三方庫限制）
- **項目**：該項目特有嘅技術約定、業務規則、已知陷阱（如特定 schema 設計決定、項目內部命名約定）

**讀取規則：**
- 每個 session 開始時，必須先讀取對應嘅 shared knowledge log
- 執行任務前，主動檢查是否有相關知識可參考
- 發現 shared knowledge 有誤或過時，立即更新並標注原因及日期

---

## 代碼原則

### SOLID
| 原則 | 要求 |
|------|------|
| Single Responsibility | 每個 class / function 只做一件事 |
| Open/Closed | 對擴展開放，對修改封閉 |
| Liskov Substitution | 子類必須可替換父類 |
| Interface Segregation | 唔好強迫 client 依賴唔需要嘅 interface |
| Dependency Inversion | 依賴抽象，唔好依賴具體實現 |

### DRY（Don't Repeat Yourself）
- 相同邏輯只寫一次，抽成共用 helper / service / util
- 發現重複超過兩次必須重構

### 其他
- 命名常數，禁止 magic number / magic string
- 函數長度原則上不超過 30 行（React 組件 ≤ 50 行），超過須拆分
- 每個函數只做一件事，保持單一職責

---

## 命名規範

### 變數（Variables）
| 場景 | 格式 | 例子 |
|------|------|------|
| 一般變數 | `camelCase` | `userEmail`, `totalAmount` |
| 布林值 | `camelCase`，以 `is` / `has` / `can` 開頭 | `isLoading`, `hasError`, `canEdit` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `API_BASE_URL` |
| 環境變數 | `UPPER_SNAKE_CASE` | `DATABASE_URL`, `JWT_SECRET` |
| 私有屬性（class） | `_camelCase` | `_userId`, `_cache` |

### 函數（Functions）
| 場景 | 格式 | 例子 |
|------|------|------|
| 一般函數 | `camelCase`，動詞開頭 | `getUser()`, `calculateTotal()` |
| 事件處理 | `handle` + 事件名 | `handleSubmit()`, `handleInputChange()` |
| 非同步函數 | 同上，結尾可加 `Async` 如有混淆風險 | `fetchUserAsync()` |
| React component | `PascalCase` | `UserProfile`, `PaymentForm` |
| React hook | `use` 開頭，`camelCase` | `useAuth()`, `useFormState()` |

### 類別與介面（Classes & Interfaces）
| 場景 | 格式 | 例子 |
|------|------|------|
| Class | `PascalCase` | `UserService`, `PaymentProcessor` |
| Interface（TypeScript） | `PascalCase`，可加 `I` 前綴（視項目統一） | `UserRepository` 或 `IUserRepository` |
| Type alias | `PascalCase` | `ApiResponse`, `UserRole` |
| Enum | `PascalCase`，成員 `UPPER_SNAKE_CASE` | `enum Status { PENDING, ACTIVE }` |

### 檔案命名
| 場景 | 格式 | 例子 |
|------|------|------|
| React component 檔案 | `PascalCase.tsx` | `UserProfile.tsx` |
| Hook 檔案 | `camelCase.ts` | `useAuth.ts` |
| 工具函數 | `camelCase.ts` | `formatDate.ts` |
| 測試檔案 | 同源檔案名 + `.test` / `.spec` | `UserProfile.test.tsx` |
| 常數檔案 | `camelCase.ts` | `apiConstants.ts` |
| 資料夾 | `kebab-case` | `user-profile/`, `payment-service/` |

---

## Coding Style（ESLint + Prettier）

> 完整設定定義於 `skills/sw-coding-style/SKILL.md`。

核心：`tabWidth=4`, `singleQuote`, `trailingComma: all`, `printWidth=100`
禁止 `var`，用 `===`，所有條件加 `{}`，函數 ≤ 30 行。

---

## TDD 規範

> 完整規範定義於 `skills/sw-tdd/SKILL.md`。

Red → Green → Refactor。禁止先寫實現後補測試。覆蓋率 ≥ 80%。
命名：`it('should [預期行為] when [條件]')`

---

## Git 規範

> 完整規範定義於 `skills/sw-git-flow/SKILL.md`。

`main` + `develop`。Branch checkout 自 `develop`（`hotfix` 除外，checkout 自 `main`）。
Branch: `[類型]/[模組]/[TICKET]_[描述]`
Commit: `<type>: [identifier] | [描述]`（例：`fix: RV-001 | description`、`refactor: | description`）
PR → `develop` 須 ≥ 90 分 review。`develop` → `main` 須 QA 全通過。

**Developer 開始工作前必須確認：**
```
□ 已在正確 base branch（develop）checkout 新 branch
□ 唔可直接 commit 到 main 或 develop
□ 唔可在現有 feature branch 加入無關改動
□ Branch 命名符合 [類型]/[模組]/[TICKET]_[描述] 格式
```

**Task branch merge 後必須刪除：**
```
□ Task branch（feature/fix/docs/refactor 等）merge 入 develop 後，立即 delete 該 branch
□ 指令：git branch -d [branch-name]
□ 保留：main、develop（永久保留）
```

---

## Harness Architecture（跨 Team 架構原則）

> 適用於所有使用 subagent 嘅 team。Team 或 project 層可擴展但唔可違反。

### 1. Tool ≠ Role

Side-effectful tool（git、deploy、db write）權限集中於 main agent，subagent 只做判斷 + 輸出結構化結果。詳細矩陣見 team 層嘅 `tool-inventory.md`。

### 2. Hard Gates > Soft Scores

任何 gating 決定必須有至少一項可自動檢測嘅 binary 條件（lint / type / test / coverage）。評分（score）只做 advisory，fail 由 hard gate 決定。

### 3. Structured Handoff Receipt

所有 subagent 完成任務後必須輸出 `handoff-receipt` block，main agent 依此路由。標準格式：

````
```handoff-receipt
protocol: <n>
status: pass | warn | fail
score: XX/100 | n/a
hard_gates:
  <gate_name>: pass | fail | n/a
next_action: <merge_* | invoke_* | rollback | end>
next_agent: <agent_name> | null
branch: "<branch>"
context: "<one-line summary>"
blockers:
  - "<issue>"   # 如無可省略
```
````

**強制規則**：

- Subagent 漏交 receipt → main agent **必須視為 fail**，唔執行下一步
- Subagent 內 `status` 同 `next_action` 唔一致（例如 `fail` 配 `merge_*`）→ main agent 視為 fail
- Main agent 必須按 `next_action` 執行，唔可自行判斷跳步

詳細 protocol 定義於 team 層嘅 `skills/sw-post-review-handoff/SKILL.md`。

### 4. Context Budget 意識

Agent 必須主動管理 context：lazy load skill 檔案、subagent 卸載重活、session 超過 ~70% window 時換新對話。

---

## Code Review 報告格式

> 完整格式及評分系統定義於 `agents/code-reviewer.md`。

報告必須包含（順序固定）：
1. 報告頭部（日期、審閱者、目標、總評）
2. 評分結果表（六維度，總分 100，≥ 90 合格）
3. 問題清單（🔴 Critical → 🟡 Warning → 🟢 Suggestion）
4. ✅ 做得好嘅地方
5. 修正優先順序表
6. 修訂後完整代碼（附 inline comment）

> 任何 🔴 Critical 問題存在，無論總分多少，一律不合格。

---

## QA 測試報告格式

> 完整格式定義於 `agents/quality-assurance.md`。

報告必須包含（順序固定）：
1. 報告頭部（日期、測試員、範圍、環境、總結）
2. 測試覆蓋概覽表（Unit / Integration / E2E / Performance）
3. 失敗測試詳情（可重現步驟、根源分析、ticket 編號、建議修正）
4. 問題修正優先順序表
5. 測試建議（下一步）

---

## 安全規範

- 禁止 hardcode 任何 secret、API key、密碼
- 敏感資料必須透過環境變數或 secret manager 管理
- 禁止將 `.env` 或包含憑證嘅檔案 commit 入 repo
- 所有外部輸入必須做驗證及 sanitization

---

## 第三方庫引入規範

> 適用於所有 Developer Agent。
> 引入新庫唔係小事——每個依賴都係潛在攻擊面、技術債、維護負擔。

### 引入前必須評估

**1. 必要性評估**
```
□ 現有 codebase 或已有庫是否已可解決問題？
□ 功能是否簡單到可以自行實現（< 50 行）？
□ 如係，優先自行實現，唔引入外部依賴
```

**2. 安全評估**
```
□ 執行安全掃描：
  npm: npm audit / npx snyk test
  pip: pip-audit / safety check
  composer: composer audit
□ 確認無 Critical / High 漏洞
□ 查看 CVE 歷史（https://osv.dev）
□ 確認庫仍然活躍維護（最近 6 個月有 commit）
□ 確認 GitHub stars / 社區活躍度（避免 abandoned 庫）
```

**3. 授權（License）評估**
```
□ 確認 license 與項目兼容：
  ✅ 可用：MIT, Apache 2.0, BSD, ISC
  ⚠️ 需確認：LGPL（視使用方式）
  ❌ 禁止：GPL（會感染項目代碼）、商業授權未購買
```

**4. 影響評估**
```
□ Bundle size 影響（前端）：
  - 小型庫（< 10KB gzip）：可直接引入
  - 中型庫（10–100KB）：確認有 tree-shaking 支持
  - 大型庫（> 100KB）：需明確說明必要性
□ 是否只需用到庫的一小部分？考慮只 copy 所需函數
□ 是否引入過多 peer dependencies？
```

### 引入流程

```
1. 完成以上評估，確認通過
2. 在 PR 描述加入「新增依賴說明」區塊：
   - 庫名稱及版本
   - 引入原因
   - 替代方案（為何選擇此庫）
   - 安全掃描結果
   - License
   - Bundle size 影響（如適用）
3. Code Review 時，Reviewer 必須確認以上評估已完成
```

### 新增依賴 PR 說明模板

```markdown
## 新增依賴

| 項目 | 內容 |
|------|------|
| 庫名稱 | `axios@1.6.0` |
| 引入原因 | 需要攔截器支持，原生 fetch 唔夠 |
| 替代方案 | 原生 fetch（功能不足）、got（Node.js only） |
| 安全掃描 | npm audit — 0 vulnerabilities |
| License | MIT ✅ |
| Bundle size | 11KB gzip，支持 tree-shaking |
```

### 禁止行為

```
❌ 未評估直接 npm install / pip install
❌ 引入有已知 Critical 漏洞嘅版本
❌ 引入 GPL license 庫（未確認兼容性）
❌ 引入 2 年以上無維護嘅庫
❌ 喺 PR 描述無說明新增依賴原因
```

---

## Session 規範

- 每次 session 結束前必須執行 `/session-log`
- Log 儲存至 `.claude/session-logs/YYYY-MM-DD_HH-MM.md`
- Log 須記錄：完成事項、待注意事項、下次任務
- 跨 session 工作必須先閱讀上次 log 再開始
- **3 個月保留規則**：每次 session 開始時，自動清除 `.claude/session-logs/` 內超過 90 天嘅 log 檔案

---

## Definition of Done（DoD）

> 所有 agent 以此為「完成」嘅統一標準。
> 任何 feature、fix、refactor 任務，必須滿足以下所有條件先算 Done。
> 唔達標 = 未完成，唔可以合併，唔可以部署。

### 代碼層面
```
□ 所有新代碼有對應測試（TDD，測試先行）
□ 所有測試通過（Unit + Integration）
□ 測試覆蓋率達標：核心邏輯 ≥ 80%
□ ESLint 無 error（warning 可接受，但須記錄原因）
□ TypeScript / PHP / Python 無類型錯誤
□ 無 magic number / magic string
□ 函數長度符合規範（組件 ≤ 50 行，其他 ≤ 30 行）
□ 無 console.log / print / var_dump 留喺生產代碼
```

### Review 層面
```
□ Code Review 完成，評分 ≥ 90 分
□ 無任何 🔴 Critical 問題
□ 所有 🟡 Warning 已處理或有明確理由接受
```

### Git 層面
```
□ Commit message 符合 Conventional Commits 格式
□ Branch 命名符合規範（含 ticket number，如有）
□ 無 unrelated 改動混入同一 commit
□ 無 .env 或 secret 被 commit
```

### QA 層面（功能性改動必須）
```
□ QA 測試完成，無 🔴 Critical 問題
□ E2E 測試通過（如涉及核心 user journey）
□ Regression 測試通過（如改動影響現有功能）
□ 相關 ticket 狀態更新至 completed
```

### 文件層面
```
□ 所有 agent 產出文件已儲存至 .proj-docs/ 對應子資料夾 對應子資料夾
□ 文件命名符合 [YYYY-MM-DD_HH-MM]_[類型]_[描述] 規範
□ API 文件同步更新（如有新增或修改 endpoint，執行 /docs --type=api）
□ README 同步更新（如有環境或啟動方式改動，執行 /docs --type=readme）
□ CHANGELOG 已更新（release 前執行 /docs --type=changelog）
□ 如有新發現嘅 common knowledge，已記錄入 shared-knowledge.md
```

### 部署層面（上線前）
```
□ Staging 環境驗證通過
□ DevOps 確認回滾方案
□ 監控指標已就位
```

---

## 文件輸出規範（.proj-docs）

> 所有 agent 產出嘅文件、報告、圖表，必須儲存至項目根目錄 `./proj-docs/`，按類型分子資料夾管理。

### 資料夾結構

```
project_abc/
├── .claude/
│   └── session-logs/         ← AI agent 讀寫，保留最近 3 個月
│       ├── YYYY-MM-DD_HH-MM.md
│       └── shared-knowledge.md
├── .proj-docs/               ← 真人可讀文件（報告、圖表、規格）
│   ├── specs/              ← /spec 產出：functional-spec、technical-spec
│   ├── plans/              ← /plan 產出：implementation-plan、feasibility
│   ├── audits/             ← /audit 產出：architecture-audit、security-audit
│   ├── reviews/            ← /review 產出：code-review 報告
│   ├── qa-reports/         ← /test 產出：QA 測試報告、ticket 列表
│   ├── diagrams/           ← 所有流程圖、系統圖、DB diagram
│   │   ├── flow/           ← project overview flow、functional flow
│   │   ├── data-flow/      ← data flow diagram
│   │   ├── database/       ← system database diagram（ERD）
│   │   └── archive/        ← 重大改動前嘅舊版本（含日期標記）
│   ├── deploys/            ← /deploy 產出：部署記錄
│   └── docs/               ← /docs 產出：README、API doc、CHANGELOG
└── ... (project files)
```

### 命名規範

```
[YYYY-MM-DD_HH-MM]_[類型]_[描述].md
[YYYY-MM-DD_HH-MM]_[類型]_[描述].html   ← 流程圖 / diagram

例子：
2026-03-28_14-30_functional-spec_user-authentication.md
2026-03-28_14-30_audit_codebase-architecture.md
2026-03-28_14-30_review_CUI-0001_payment-service.md
2026-03-28_14-30_flow_project-overview.html
2026-03-28_14-30_database_erd.html
```

### 每個 agent 輸出後必須

```
□ 將文件儲存至對應 .proj-docs/ 子資料夾
□ 文件命名符合上述規範
□ 在 .claude/session-logs/ 嘅 session-log 記錄輸出文件路徑
□ 同步更新 .proj-docs/index.md
```

### index.md 導航檔

`.proj-docs/index.md` 係項目文件嘅唯一入口，必須保持最新。
**每次更新後必須更新頂部 `最後更新` 日期** — `start.md` 依賴此日期決定是否重新讀取。

```markdown
# Project Docs Index

**最後更新**：YYYY-MM-DD HH:MM

## Specs
- [2026-03-28 Functional Spec — User Auth](specs/2026-03-28_functional-spec_user-auth.md)

## Plans
- [2026-03-28 Implementation Plan — Phase 1](plans/2026-03-28_plan_phase-1.md)

## Diagrams
- [Project Overview Flow](diagrams/flow/project-overview.html)
- [System Data Flow](diagrams/data-flow/system-dataflow.html)
- [Database ERD](diagrams/database/erd.html)

## Audits
- [2026-03-28 Architecture Audit](audits/2026-03-28_audit_codebase-architecture.md)

## Reviews
- [2026-03-28 Code Review — CUI-0001](reviews/2026-03-28_review_CUI-0001.md)

## QA Reports
- [2026-03-28 QA Report — Payment Module](qa-reports/2026-03-28_qa_payment-module.md)
```

每次 agent 輸出新文件後，必須同步更新 `index.md` 及頂部日期。

---

## 流程圖 & 系統圖規範

> 適用於 Architect、Project Manager agent。

### 何時必須產出

| 情況 | 必須產出 |
|------|----------|
| 新項目 `/spec` 完成後 | Project Overview Flow + Data Flow |
| `/audit` 完成後 | Functional Flow（現有系統）+ Data Flow |
| 數據庫設計完成後 | Database ERD |
| 重建項目 `/plan` 完成後 | 新系統 Overview Flow |

### Project Overview Flow

描述整個系統嘅功能流程，必須包含：
- 主要 user journey（從入口到完成）
- 各功能模組之間嘅關係
- 外部系統整合點
- 輸出至 `.proj-docs/diagrams/flow/`

### Data Flow Diagram

描述數據喺系統內嘅流向，必須包含：
- 數據入口（用戶輸入、API、外部系統）
- 數據處理流程（validation、transformation、storage）
- 數據出口（response、export、notification）
- 輸出至 `.proj-docs/diagrams/data-flow/`

### Database ERD

描述數據庫結構，必須包含：
- 所有主要 tables / collections
- 欄位類型及約束
- 主鍵、外鍵關係
- 關係基數（1:1、1:N、N:M）
- 輸出至 `.proj-docs/diagrams/database/`

### 輸出格式

```
優先：HTML 檔案（含 mermaid.js 或 SVG，可在瀏覽器開啟）
備用：Markdown（含 mermaid code block）

每個 diagram 必須同時附帶文字說明：
- 圖表目的
- 關鍵流程或關係說明
- 重要設計決定
```

### Diagram 更新策略

每個 diagram 類型固定檔名，永遠只有一份最新版本：

```
.proj-docs/diagrams/flow/project-overview.html
.proj-docs/diagrams/data-flow/system-dataflow.html
.proj-docs/diagrams/database/erd.html
```

**直接覆蓋（小改動）：**
- 修正錯誤或補充細節
- 文字描述調整
- 樣式改善

**先 Archive 再出新版本（以下情況）：**
- 新增主要功能模組
- 系統架構有重大改動
- Database schema 有 breaking change

```bash
# Archive 舊版本，加入日期標記
mv .proj-docs/diagrams/flow/project-overview.html \
   .proj-docs/diagrams/archive/YYYY-MM-DD_HH-MM_project-overview.html

# 再建立新版本
```

每個 diagram 附帶同名 `.md` 說明檔，記錄版本、最後更新日期、改動原因。

---

## Sub-Agent 規範

> 防止 context 污染，保證長時間任務嘅輸出質量。

### 觸發條件（出現以下情況必須 spawn sub-agent）

**行為指標（可觀察，唔靠估計）：**

```
🔴 立即 spawn（出現任何一個）：
  - 連續 3 個 response 都係解釋或重複同一件事
  - 對同一個問題前後給出矛盾嘅答案
  - 開始引用唔存在嘅檔案、函數或早前決定
  - 回答開頭係「如我之前所說...」但內容同之前不一致

🟡 建議 spawn（出現任何兩個）：
  - 當前 context 內同時有 3 個或以上唔同任務進行中
  - 單一任務已進行超過 20 個來回仍未完成
  - Response 越來越長但有效資訊越來越少
  - 用戶需要不斷重複之前說過嘅 context

🔵 獨立客觀性要求（以下情況必須用新 context）：
  - Code review 驗證另一個 agent 嘅輸出
  - Architect review developer 嘅設計決定
  - QA 驗證 developer 聲稱已修復嘅問題
  - Security audit 審查同一 context 內寫嘅代碼
```

### Sub-Agent 啟動方式

主 Agent 執行兩步：

**步驟一：** 將 context 寫入檔案

```
儲存至：.claude/session-logs/context-for-subagent-YYYY-MM-DD_HH-MM.md

內容包含：
- 項目背景（名稱、tech stack、alias）
- 當前任務描述
- 相關已完成工作摘要
- 需要帶入嘅決定或假設
- 預期輸出及儲存位置
- 相關 .proj-docs/ 文件路徑清單
```

**步驟二：** 輸出啟動指示

```
⚠️ 建議 spawn sub-agent 執行以下任務：

任務：[具體任務描述]
預期輸出：[期望結果]
輸出位置：.proj-docs/[對應子資料夾]/

請開新對話，執行以下指令後開始：
/start ai-dev-team
然後讀取：.claude/session-logs/context-for-subagent-YYYY-MM-DD_HH-MM.md
```

### Sub-Agent 執行規則

```
□ 執行 /start ai-dev-team
□ 讀取 .claude/session-logs/context-for-subagent-YYYY-MM-DD_HH-MM.md
□ 讀取 .proj-docs/index.md，了解現有文件狀態
□ 讀取 shared-knowledge.md（全局 + 項目）
□ 只執行指定任務，唔做額外工作
□ 完成後將輸出存入 .proj-docs/ 對應位置
□ 更新 .proj-docs/index.md
□ 在 shared-knowledge.md 記錄任務完成狀態及輸出位置
□ 回報主 agent：任務完成、輸出位置、重要發現
```

### Context 健康檢查

每 10 個來回，agent 必須自我檢查：

```
□ 今次 session 嘅目標仍然清晰嗎？
□ 最近 3 個 response 有冇重複同一內容？
□ 有冇引用唔確定存在嘅資訊？
□ Context 入面而家有幾多個唔同任務？（超過 3 個 → 考慮 spawn）
□ 用戶有冇需要重複解釋之前說過嘅嘢？
→ 有任何一項有問題：主動告知用戶，建議 spawn sub-agent 或重整 context
```

---

## Senior 工程師思維

所有 agent 以 senior level 標準行事：

- **主動提出風險**：發現設計問題或潛在 bug 必須主動指出
- **考慮可維護性**：代碼寫給人讀，其次才係機器執行
- **拒絕 quick and dirty**：若時間緊迫，提出方案並說明 trade-off
- **文件同步更新**：代碼改變，相關文件同步更新
- **唔靠估**：不確定就說不確定，列出假設，等確認

---

## Design-Source Binding Rule（Hard Rule）

> 此規則由 2026-05-17 生效，由 life-travels 前端視覺嚴重偏差事件觸發（實作 vs mockup 完全唔符）。

**核心原則**：任何任務動到 `*.tsx`、`*.jsx`、`*.css`、`*.scss` 喺 UI component / page path 內，**必須**喺 branch / PR description 第一行寫明 `Design Origin:` 加以下五種其中一種：

| Origin | 用喺邊種情況 | 必須提供 |
|--------|----------|---------|
| `mockup: <path>#<section>` | 有現成 mockup file（如 `_mockups_/` 內） | mockup file 路徑 + 引用 section |
| `baseline: <path>` | 改現有 UI（bug fix / 微調 / refactor），冇 mockup | 當前 component 路徑（即 baseline 係依家 ship 緊嘅樣） |
| `proposal: <path>` | 全新 UI 但冇 mockup（improvise 模式） | spec / plan 入面嘅 `## Design Proposal` section 路徑（ASCII / wireframe / Figma URL / 文字描述） |
| `library: <name>@<version>` | 完全跟第三方 library 樣 | library 名 + 版本（如 `library: shadcn/ui@0.8 — Dialog`） |
| `none-required` | 純 logic / refactor / backend wiring，視覺零變化 | 一定要附 `Why: <一句話解釋點解唔變視覺>` |

**Hard rule 細則：**

- Reviewer 見唔到 `Design Origin:` 行 → 必須 reject PR。
- Origin 唔配對實際變動（例：標 `none-required` 但 diff 內有新 className / 新 layout）→ reject。
- `proposal:` 模式 ship 之後，QA **必須**截圖儲入 `.proj-docs/design-baselines/<feature>-<date>.png`，並 update spec 將該 path 加返入 `## Visual Reference`。下次同一 component 動工時 origin 就升級成 `baseline:`。
- `baseline:` 模式如果改動超過 30% 視覺（layout 大改 / 色系大變 / 加 hero section），必須升級成 `proposal:` 流程（要 design 提案 + design sign-off）。

**Spec reject 條件：**
- UI feature 揀 `none-required` 但功能描述有「show / display / render / 加 button / 加 page」等視覺字眼 → reject
- `proposal:` 但 `## Design Proposal` section 空白 → reject
- `mockup:` 但路徑唔存在 → reject

> 詳見 `~/.claude/CLAUDE.md` Hard Rules #4。
