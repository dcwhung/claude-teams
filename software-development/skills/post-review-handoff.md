---
name: sw-post-review-handoff
description: Defines how main agent routes work between subagents after /review, /test, /deploy, /hotfix. Load this when a subagent (code-reviewer, quality-assurance, devops-engineer) returns a HANDOFF_RECEIPT, or when an agent finishes its own work and needs to emit one.
---

# Skill：Handoff Protocol（唯一真相來源）

> **此檔案係所有 Agent handoff 嘅 Single Source of Truth。**
> 任何其他檔案禁止重複定義 handoff 規則，必須 reference 本檔案。

---

## 架構原則（Harness）

```
Subagent 只做「判斷 + 結構化 receipt」，唔做 git 操作。
Main agent 係唯一執行 git + 唯一 invoke 下一個 agent 嘅角色。
```

**點解咁設計**：

- Subagent 有 single responsibility（review 就 review，test 就 test），side effect 統一由 main agent 執行
- Git 失敗時由 main agent 處理 error recovery，唔會令 subagent context 變垃圾
- 路由邏輯集中一處，易於 audit 同更新

---

## HANDOFF_RECEIPT 格式（強制）

所有 subagent 完成工作後必須在回應最末段輸出以下 block，**唔可以缺欄，唔可以加 prose**：

````
```handoff-receipt
protocol: 1 | 2 | 3 | 4
status: pass | warn | fail
score: XX/100 | n/a
hard_gates:
  lint: pass | fail | n/a
  type_check: pass | fail | n/a
  tests: pass | fail | n/a
  coverage: "XX%" | n/a
next_action: merge_develop | merge_main | back_merge | invoke_qa | invoke_developer | invoke_devops | rollback | end
next_agent: quality-assurance | frontend-developer | backend-developer | devops-engineer | null
branch: "<current branch name>"
context: "one-line summary for next agent"
blockers:
  - "issue 1 (omit this key if none)"
```
````

**規則**：

- `status=fail` 或任何 `hard_gates.*=fail` → `next_action` 禁止為 merge/invoke_qa/invoke_devops，必須係 invoke_developer / rollback / end
- 任何 🔴 Critical 存在 → 自動 `status=fail`，無論 score
- Main agent 讀取 receipt 後**必須按 `next_action` 執行**，唔可以自行判斷跳步

---

## Main Agent 讀取 Receipt 流程（強制）

```
1. 解析 handoff-receipt block
2. 驗證 hard_gates：任何 fail → 強制走 fail 分支，忽略 score
3. 執行 git 操作（見下方 Protocol 映射表）
   ↳ 失敗：停止，輸出錯誤，唔 invoke 下一個 agent
4. 按 next_action + next_agent 透過 Agent tool invoke
   ↳ prompt 必須包含 receipt.context + receipt.branch + receipt.blockers
5. 禁止問用戶「要唔要繼續」
```

---

## Protocol 1：Post-Review（`/feature`、`/fix`、`/refactor`）

### Reviewer Subagent

只輸出 review 報告 + receipt，**唔執行 git**。

```
判斷規則：
  hard_gates 全 pass + score ≥ 90 + 無 Critical → status=pass, next_action=merge_develop
  score 75–89（有 Warning）→ status=warn, next_action=invoke_developer
  score < 75 或有 Critical → status=fail, next_action=invoke_developer
```

### Main Agent 動作表

| receipt | Git 操作（main agent 執行） | 下一步 |
|---------|---------------------------|-------|
| `pass / merge_develop` | `git checkout develop && git merge --no-ff <branch> -m "..." && git branch -d <branch>` | Agent tool invoke `quality-assurance`，prompt 含 `context` |
| `warn / invoke_developer` | 無 | Agent tool invoke `frontend-developer` 或 `backend-developer`，prompt：「喺 `<branch>` 修正 Warning 後重新 /review：`<blockers>`」 |
| `fail / invoke_developer` | 無 | 同上，修正 Critical |

---

## Protocol 2：Post-QA Release（`/test`）

### QA Subagent

只輸出 QA 報告 + receipt，**唔執行 git**。

```
判斷規則：
  hard_gates 全 pass + 無 🔴 Critical → status=pass, next_action=merge_main
  有 🔴 Critical → status=fail, next_action=invoke_developer（並建立 CUI ticket）
```

### Main Agent 動作表

| receipt | Git 操作 | 下一步 |
|---------|---------|-------|
| `pass / merge_main` | `git checkout main && git merge --no-ff develop -m "..."` | Agent tool invoke `devops-engineer`：「執行 /deploy --env=production」 |
| `fail / invoke_developer` | 無 | Agent tool invoke 對應 Developer：「執行 /fix <CUI-XXXX>」 |

---

## Protocol 3：Hotfix（`/hotfix`，門檻 75）

### Reviewer Subagent（hotfix mode）

```
score ≥ 75 且無 Critical + hard_gates 全 pass → status=pass, next_action=merge_main
否則 → status=fail, next_action=invoke_developer
```

### Main Agent 依序動作（唔可跳步）

```
Step 1 (pass): git checkout main && git merge --no-ff <hotfix-branch>
Step 2: Agent tool invoke devops-engineer：「立即 /deploy --env=production，原因 hotfix <TICKET>」
Step 3: DevOps receipt pass 後，Agent tool invoke quality-assurance：
        「Smoke test hotfix <TICKET>。通過後執行 back-merge：
         git checkout develop && git merge --no-ff main -m '...'」
Step 4: QA receipt pass 後，提示用戶：「開新對話執行 /start ai-dev-team --task=postmortem」
```

> Back-merge conflict 處理見 `commands/hotfix.md`。

---

## Protocol 4：Post-Deploy（`/deploy`）

### DevOps Subagent

部署後執行 smoke test 同監察指標，輸出 receipt：

```
Smoke test pass + 指標正常 → status=pass, next_action=end
部署失敗或指標異常 → status=fail, next_action=rollback
```

### Main Agent 動作表

| receipt | 動作 |
|---------|------|
| `pass / end` | 輸出最終摘要，結束 |
| `fail / rollback` | 執行回滾（見 `skills/ci-cd.md`），然後 Agent tool invoke Developer 處理根源 |

---

## 核心禁令

```
⛔ Subagent 禁令：
  - 禁止執行 git merge / branch delete / push
  - 禁止輸出「請確認是否繼續」等被動語句
  - 禁止省略 handoff-receipt block
  - 禁止 receipt 內加 prose 或 free-form 欄位

⛔ Main Agent 禁令：
  - 禁止收到 fail receipt 後照樣 merge / invoke 下一個 agent
  - 禁止問用戶「要唔要繼續」
  - 禁止自行跳過 Protocol 步驟
  - 禁止對 receipt 做 fuzzy 解讀（缺欄就當 fail）
```

---

## 驗證 Checklist

Subagent 完成前自我檢查：

```
□ 我係 subagent — 我冇執行 git 操作？
□ 我最末段有完整 handoff-receipt block？
□ hard_gates 每個欄位都有填（唔適用就 n/a）？
□ status 同 next_action 一致（fail 唔會配 merge）？
```

Main agent 收到 receipt 後：

```
□ receipt 格式完整？（缺欄 → 視為 fail，唔執行下一步）
□ hard_gates 有冇 fail？（有 → 強制 fail 分支）
□ 我執行咗 git 操作（如適用）？
□ 我透過 Agent tool 實際 invoke 下一個 agent（唔係輸出文字叫用戶做）？
```

---

## Quick Reference

| Command | Subagent 輸出 | Main agent 做 |
|---------|-------------|-------------|
| `/feature`、`/fix`、`/refactor` | Developer → /review → Reviewer receipt | Protocol 1 |
| `/test` | QA receipt | Protocol 2 |
| `/hotfix` | Reviewer receipt (hotfix mode) | Protocol 3（3 步依序）|
| `/deploy` | DevOps receipt | Protocol 4 |
