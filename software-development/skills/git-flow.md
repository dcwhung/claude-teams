# Skill：Git Flow

> Branch 管理、Commit 規範、PR 流程。
> 適用於所有開發工作流程。

---

## Branch 策略

### 主要 Branch

| Branch | 用途 | 直接 Push | 部署環境 |
|--------|------|-----------|----------|
| `main` | 生產代碼，已發布版本 | ❌ 禁止 | Production |
| `develop` | 開發整合，所有任務嘅出發點 | ❌ 禁止 | Staging |

**核心規則**：
- 所有工作 branch 必須 checkout 自 `develop`
- **例外：`hotfix/` branch checkout 自 `main`**，修復後 merge to `main`，再 back-merge to `develop`
- QA 通過後，`develop` → `main`，同時升版本
- 禁止直接由工作 branch merge 入 `main`（hotfix 除外）

---

## Branch 命名規範

### 結構

```
[類型]/[前後端或模組]/[TICKET_NUMBER]_[具體描述]
```

**類型（必填）**：

| 類型 | 用途 | Checkout 自 |
|------|------|------------|
| `feature` | 新功能開發 | `develop` |
| `fix` | Bug 修復（對應 ticket） | `develop` |
| `hotfix` | 生產緊急修復 | `main` |
| `refactor` | 重構（唔加新功能，唔修 bug） | `develop` |
| `chore` | 維護性工作（依賴更新、配置改動） | `develop` |
| `docs` | 文件更新 | `develop` |
| `test` | 補充測試 | `develop` |

**前後端 / 模組層（建議填寫，多模組或前後端分離項目必填）**：
- `frontend` / `backend`：明確前後端改動
- 或功能模組名稱（`user-authentication`、`payment` 等）

**Ticket Number（有 ticket 時必填）**：
- 格式：`[PROJECT_ALIAS]-[4位數字]`，例如 `CUI-0001`
- 來自 `.tickets/` 資料夾對應嘅 ticket 檔案
- 用 underscore `_` 連接後面嘅描述
- `chore` / `docs` 等維護性改動可省略

**具體描述（必填）**：
- 英文小寫，`snake_case`
- 3–5 個字，簡短清楚

---

### Branch 命名例子

```bash
# 緊急修復（checkout 自 main）
hotfix/CUI-0099_payment_service_down
hotfix/CUI-0100_auth_token_bypass

# Bug 修復（對應 ticket，前後端分開）
fix/frontend/CUI-0001_button_display_issue
fix/backend/CUI-0001_api_connection_error

# Bug 修復（子 ticket）
fix/frontend/CUI-0002_login_form_validation
fix/backend/CUI-0003_token_expiry_handling

# 新功能（有 ticket，前後端）
feature/frontend/CUI-0015_user_profile_avatar
feature/backend/CUI-0015_profile_upload_api

# 新功能（按模組命名，有 ticket）
feature/user-authentication/CUI-0020_login_flow
feature/payment/CUI-0021_stripe_webhook_handler
feature/dashboard/CUI-0022_monthly_summary_chart

# 重構（有 ticket）
refactor/backend/CUI-0031_payment_service_decompose

# 維護性工作（無 ticket）
chore/dependencies/update-axios-v2
chore/config/add-staging-env

# 文件（無 ticket）
docs/api/payment-endpoints
docs/setup/local-development-guide
```

---

### Branch 操作流程

```bash
# 1. 確保 develop 係最新
git checkout develop
git pull origin develop

# 2. 建立 branch（checkout 自 develop，帶 ticket number）
git checkout -b fix/frontend/CUI-0001_button_display_issue

# 3. 日常開發，定期同步 develop（避免大量 conflict）
git fetch origin
git rebase origin/develop

# 4. 完成後推送
git push -u origin fix/frontend/CUI-0001_button_display_issue

# 5. 建立 PR → develop
# 6. Code Review 通過（≥90 分）→ merge to develop → 執行 /test（staging）

# === QA 全部通過後 ===
# 7. develop → main（升版本）
git checkout main
git merge --no-ff develop -m "chore: release v1.2.0"
git tag v1.2.0
git push origin main --tags
```

---

## Commit Message 規範（Conventional Commits）

### 格式

```
無 ticket：  [類型]: [描述]
有 ticket：  [類型]: [TICKET-ID] | [描述]

[可選 body — 說明原因或破壞性改動]
```

> ⚠️ `|` 分隔符**只在有 ticket number 時使用**，無 ticket 時直接 `[類型]: [描述]`。
> ⚠️ 每個 sub-project 都有獨立 git repo，**唔使用 scope**（即唔寫 `feat(ModuleName):`）。
>    有 ticket 時 ticket ID 本身已包含 project context（如 `PRJ-001`）。

### 範例

```
✅ feat: add user login API
✅ fix: PRJ-003 | replace is1stElement with isFirstElement boolean
✅ chore: merge develop into main
✅ docs: add inline comments across payment module

❌ feat(PaymentModule): add stripe webhook   ← 唔用 scope
❌ chore: | merge develop into main          ← 無 ticket 唔用 |
❌ refactor: | migrate to unified utils      ← 無 ticket 唔用 |
```

### 類型

| 類型 | 用途 | 例子 |
|------|------|------|
| `feat` | 新功能 | `feat: add user login API` |
| `fix` | Bug 修復 / 代碼改善 / 生產 hotfix（`hotfix:` 唔係合法類型） | `fix: RV-TS-001 | sheets.map() → forEach()` |
| `refactor` | 重構 | `refactor: migrate to unified utils namespace` |
| `test` | 新增或修正測試 | `test: add UserService unit tests` |
| `chore` | 維護性工作 | `chore: update axios to 2.0.0` |
| `docs` | 文件更新 | `docs: add inline comments to render functions` |
| `style` | 格式改動（不影響邏輯） | `style: run prettier formatting` |
| `perf` | 性能優化 | `perf: add index to user query` |
| `ci` | CI/CD 配置 | `ci: add staging auto-deploy flow` |

### 描述規則

```
✅ 中文或英文均可，視項目統一
✅ 動詞開頭，描述做咗乜
✅ 唔超過 72 字元
✅ 唔加句號
✅ 有 ticket 先加 TICKET-ID | 前綴，無 ticket 直接描述

❌ feat: 改了一些東西
❌ fix: bug fix
❌ update files
❌ chore: | some work without a ticket
```

### Breaking Change（有需要時加 body）

```
feat: 新增 JWT refresh token 機制

原有 access token 冇 refresh 機制，用戶需要頻繁重新登入。
此改動新增 refresh token endpoint，access token 有效期縮短至 15 分鐘。

BREAKING CHANGE: /api/auth/login response 新增 refreshToken 欄位
```

---

## 每個 Commit 只做一件事

```bash
# ✅ 正確：細粒度 commit
git commit -m "feat: 新增 User entity 及 migration"
git commit -m "feat: 實現 UserRepository CRUD 方法"
git commit -m "feat: 新增 UserService 業務邏輯"
git commit -m "feat: 新增 POST /api/users endpoint"
git commit -m "test: 新增 UserService 單元測試"

# ❌ 錯誤：一次 commit 塞晒所有改動
git commit -m "feat: 完成用戶功能"
```

---

## PR 規範

### PR 標題

同 Commit Message 格式一致：
```
feat: 新增用戶認證功能
fix: 修正付款重複扣款問題
```

### PR 目標 Branch

```
工作 branch → develop    （日常開發）
develop     → main       （QA 通過後升版本，需要 release note）
```

### PR 描述模板

```markdown
## 改動說明

[描述做咗乜，為何要做]

## 改動類型

- [ ] feat：新功能
- [ ] fix：Bug 修復
- [ ] refactor：重構
- [ ] chore：維護性工作

## 測試

- [ ] 已新增對應測試
- [ ] 所有測試通過
- [ ] 已手動測試以下場景：
  - [場景 1]
  - [場景 2]

## Code Review

- [ ] 自我 review 完成
- [ ] 符合 ESLint / Prettier 規範
- [ ] 無 magic number / magic string
- [ ] 函數長度符合規範
- [ ] 無循環依賴

## 相關連結

- Spec：[連結]
- Issue：[連結]
```

### PR 合併條件（merge to develop）

```
□ Code Review 評分 ≥ 90 分
□ 無 🔴 Critical 問題
□ 所有 CI 檢查通過
□ 至少一位 reviewer 批准
```

### Release 條件（develop merge to main）

```
□ QA 測試報告無 🔴 Critical 問題
□ 所有 E2E 測試通過
□ Staging 環境驗證完成
□ Release note 已準備
□ DevOps 確認部署計劃及回滾方案
```

---

## 版本號規範（Semantic Versioning）

```
v[MAJOR].[MINOR].[PATCH]

MAJOR → Breaking change（唔向後兼容）
MINOR → 新功能（向後兼容）
PATCH → Bug fix（向後兼容）

例子：
v1.0.0 → v1.0.1  （bug fix）
v1.0.1 → v1.1.0  （新功能）
v1.1.0 → v2.0.0  （breaking change）
```

---

## 常用 Git 操作

```bash
# 建立新 branch（從 develop）
git checkout develop && git pull origin develop
git checkout -b feature/user-authentication/login-flow

# 提交（逐塊 review）
git add -p
git commit -m "feat: 新增登入 API endpoint"

# 同步最新 develop（rebase 保持 history 線性）
git fetch origin
git rebase origin/develop

# 推送
git push -u origin feature/user-authentication/login-flow

# 修改最後一個 commit message
git commit --amend

# 合併多個 commit（squash，PR 前整理 history）
git rebase -i HEAD~3
```

---

## 禁止行為

```
❌ 直接 push 到 main 或 develop
❌ Force push 到 main 或 develop
❌ 由工作 branch 直接 merge 入 main（必須經 develop）
❌ Commit 未通過測試嘅代碼
❌ Commit .env 或含 secret 嘅檔案
❌ 一個 commit 包含多個無關改動
❌ Commit message 用 "fix bug"、"update"、"misc" 等無意義描述
❌ Branch 名唔包含模組名（多模組項目）
```

---

## Branch 建立強制 Pre-Flight Checklist

> **所有 `/feature`、`/refactor`、`/fix`、`/hotfix` 必須嚴格按順序執行以下步驟，任何一步失敗即停止，提示用戶處理後再繼續。禁止跳過或靜默忽略。**

```
□ Step 1：確認當前 branch
    git rev-parse --abbrev-ref HEAD
    - /feature、/refactor、/fix → 必須 === "develop"
    - /hotfix               → 必須 === "main"
    ❌ 不符合 → 停止。輸出：「⛔ 當前 branch 為 [X]，請先執行 git checkout [develop/main]」

□ Step 2：確認 working tree 乾淨
    git status --porcelain
    - 輸出必須為空
    ❌ 非空 → 停止。輸出：「⛔ 有未 commit 改動，請先 commit 或 stash 後再執行」

□ Step 3：確認 task identifier 唯一（One-Task-One-Branch 鐵律）
    - 每個 task identifier（Review Item ID / QA Ticket / 功能描述）對應一條且只得一條 branch
    - 執行：git branch --list "*<identifier>*"
    ❌ 若已有同 identifier 嘅 branch → 停止。
       輸出：「⛔ 已存在 branch [X]，請 checkout 現有 branch 繼續，或確認是否需要新 identifier」

□ Step 4：同步 source branch
    git pull origin <source>   # source = develop（feature/fix/refactor）或 main（hotfix）

□ Step 5：按本檔案命名規範建立 branch
    git checkout -b <type>/<scope>/[identifier_]<description>

□ Step 6：確認後輸出
    「✅ 已建立 branch: <name>，正式進入開發」
```

### One-Task-One-Branch 鐵律

> ⛔ 同一條 branch **禁止**處理多於一個 Review Item ID / QA Ticket。
>
> 若 `/fix W-003 W-004 S-007` 傳入多個 ID，Developer 必須**順序**處理：
> 為第一個 ID 完成 Pre-Flight → TDD → /review → merge，再為下一個 ID 重新執行 Pre-Flight 開新 branch。
>
> **禁止任何形式嘅「一條 branch 打包多個 fix」。**

---

## Post-Review Handoff Protocol

> **呢個 section 係 `/review` 完成後嘅唯一真相來源。**
> Reviewer 完成評分後，**禁止**等用戶指令，必須立即按下表執行對應動作。
> **禁用「通知」、「提醒」、「建議用戶執行」等被動詞；所有 handoff 必須透過 Agent tool 實際 invoke 下一個 agent。**

### 標準流程（/feature、/fix、/refactor）

| Review 結果 | Reviewer 強制動作 |
|------------|------------------|
| ✅ ≥ 90 分，且無 🔴 Critical | 1. 立即執行：`git checkout develop && git merge --no-ff [branch] -m "chore: merge [branch] into develop" && git branch -d [branch]`<br>2. 立即透過 **Agent tool** 呼叫 quality-assurance agent：<br>&nbsp;&nbsp;&nbsp;`subagent_type: quality-assurance`<br>&nbsp;&nbsp;&nbsp;`prompt: "執行 /test 驗證 develop branch，改動範圍：[branch 改動摘要]"`<br>3. ⛔ 禁止問用戶「要唔要叫 QA」 |
| ⚠️ 75–89 分（有 Warning） | 1. ⛔ 唔 merge<br>2. 列出所有 🟡 W-NNN items<br>3. 立即透過 **Agent tool** 呼叫對應 Developer agent：<br>&nbsp;&nbsp;&nbsp;`subagent_type: frontend-developer 或 backend-developer`<br>&nbsp;&nbsp;&nbsp;`prompt: "喺現有 branch [name] 修正以下 Warning 後重新執行 /review：W-XXX [描述]、W-YYY [描述]"`<br>4. ⛔ 禁止問用戶「要唔要叫 developer 修」 |
| ❌ < 75 分 或有 🔴 Critical | 1. ⛔ 唔 merge<br>2. 列出所有 🔴 C-NNN items 及主要 🟡 W-NNN<br>3. 立即透過 **Agent tool** 呼叫對應 Developer agent（同上格式），要求修正所有 Critical<br>4. 明確輸出：「⛔ 禁止 merge，直至 Critical 問題全部清除」 |

### Hotfix 特殊流程（/hotfix，門檻 75 分）

| Review 結果 | Reviewer 強制動作 |
|------------|------------------|
| ✅ ≥ 75 分，且無 🔴 Critical | 1. 立即執行：`git checkout main && git merge --no-ff [hotfix-branch] -m "fix: [TICKET] \| merge hotfix into main" && git branch -d [hotfix-branch]`<br>2. 立即透過 **Agent tool** 呼叫 devops-engineer：<br>&nbsp;&nbsp;&nbsp;`prompt: "立即執行 /deploy，target=production，原因：hotfix [TICKET]"`<br>3. 立即透過 **Agent tool** 呼叫 quality-assurance agent：<br>&nbsp;&nbsp;&nbsp;`prompt: "執行 smoke test 確認 hotfix [TICKET] 修復有效，完成後執行 back-merge：git checkout develop && git merge --no-ff main -m 'chore: sync hotfix [TICKET] back to develop'"`<br>4. ⛔ 禁止問用戶確認 |
| ❌ < 75 分 或有 🔴 Critical | 同標準流程 Critical 處理，叫 Developer 修正後重新 /review |

---

## Post-QA Release Protocol

> **呢個 section 係 `/test` 完成後嘅唯一真相來源。**
> QA Agent 完成測試後，**禁止**等用戶確認，必須立即按下表執行。

| QA 結果 | QA Agent 強制動作 |
|--------|------------------|
| ✅ 通過（無 🔴 Critical） | 1. 立即執行：`git checkout main && git merge --no-ff develop -m "chore: merge develop into main"`<br>2. 立即透過 **Agent tool** 呼叫 devops-engineer：<br>&nbsp;&nbsp;&nbsp;`prompt: "執行 /deploy，target=production"`<br>3. ⛔ 禁止問用戶「要唔要 release」 |
| ❌ 失敗（有 🔴 Critical） | 1. 建立 QA ticket（CUI-XXXX），記錄失敗原因及重現步驟<br>2. 立即透過 **Agent tool** 呼叫對應 Developer agent：<br>&nbsp;&nbsp;&nbsp;`prompt: "執行 /fix CUI-XXXX"`<br>3. ⛔ 禁止 merge develop → main |

> ⚠️ Hotfix 後嘅 back-merge to develop 由 QA smoke test 階段觸發（見 Post-Review Handoff Protocol → Hotfix 特殊流程），**不**經過此 Post-QA Release Protocol。
