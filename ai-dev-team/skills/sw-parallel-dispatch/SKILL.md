---
name: sw-parallel-dispatch
description: Multi-task parallel dispatcher — main agent runs Conflict Analysis (AI judgment), clusters tasks into lanes, dispatches developer subagents in isolated worktrees, batches review/QA/release at end. Load when user provides 2+ tasks in one message (numbered list, comma-separated, sequential bullets) — main agent MUST run this protocol BEFORE starting any /fix /feature /refactor work. Also load when user explicitly says "do these in parallel", "唔好一個一個做", "可以同時做嘅就同時做", or asks for time savings on multi-task workloads. The Single Source of Truth for parallel dispatch decisions.
---

# Skill：Parallel Dispatch（多任務平行調度）

> **此檔案係多任務平行調度嘅 Single Source of Truth。**
> 適用於 `/fix`、`/feature`、`/refactor` 任何 N ≥ 2 嘅情境。
> 與 `skills/sw-autonomous-loop/SKILL.md`「模式二：Parallel Agents」嘅關係：
> - autonomous-loop = 同 response 內多個 Agent call 嘅低層機制
> - parallel-dispatch = main agent 喺 dispatch 前嘅**決策層**（要唔要 parallel、點分 lane、conflict 點處理、結果點 sync）
>
> Subagent 唔讀本檔；只 main agent 讀。

---

## 何時觸發

```
✅ 用戶喺一個 message 列出 ≥ 2 個獨立 task（numbered list / 逗號分隔 / 連續 bullet）
✅ 用戶話「呢幾個一齊做」/「唔好一個一個」/「parallel」
✅ 多個 ticket 同時送來：/fix CUI-0001 CUI-0002 CUI-0003
```

```
❌ 單一 task — 直接行對應 command（fix.md / feature.md / refactor.md）
❌ Hotfix — Protocol 3 強制 serial，禁止 parallel
❌ 一條 task 拆出嘅多個 sub-step（仍係單一 ticket，serial）
```

---

## 核心原則

```
1. Main agent 係唯一 dispatcher — 做決策、做 conflict 分析、merge、invoke 下游 agent
2. Developer subagent 喺隔離 worktree 工作 — 每個 lane 獨立，唔可越界
3. Reviewer / QA / DevOps 一律 batch — 最多 5 個 fix 一齊 review/QA/release
4. 失敗 isolation — 一個 lane fail 唔可 block 其他 lane；main agent 整合後決定整體 status
5. TDD 純度不可妥協 — 每個 lane 嚴格 Red → Green → Refactor，subagent 唔可跳步
```

---

## Step 1：Conflict Analysis（AI judgment）

> **Main agent 用 LLM 判斷 + grep 輔助**，唔係純機械算法。

對每對 task (A, B)，main agent 必須回答：

```
Q1. A 同 B 提到嘅 file 有冇 overlap？
    → grep target file mentions in task description
Q2. 即使 file overlap，係咪同一 function / 同一 symbol？
    → 用 grep 確認 task 描述涉及嘅 function 名係咪共用
Q3. 有冇 sequencing 依賴？（B 用 A 嘅輸出 / B 改 A 嘅新增 helper）
    → LLM read description carefully
Q4. 有冇 shared state / shared symbol rename？
    → grep symbol 名喺 codebase 出現位置
```

依答案分類：

| 分類 | 條件 | 處理 |
|------|------|------|
| **Independent** | 無 file overlap，無 sequencing | ✅ Parallel safe |
| **Soft conflict** | 同 file，但唔同 function / symbol | ✅ Parallel + git auto-merge（罕有 conflict 由 main agent 解）|
| **Hard conflict** | 同 function / 同 symbol / 有 sequencing | ❌ Serial only — 排入同一 lane |
| **不確定** | LLM 判斷有疑問 | ⚠️ 當 hard conflict 處理（保守）|

---

## Step 2：Lane Clustering

```
Tasks  T1, T2, T3, T4, T5
       ↓
Build conflict graph：edge = hard conflict
       ↓
Greedy chromatic colouring：
  Lane A = {T1, T3}      ← 互相無 hard edge → can parallel
  Lane B = {T2 → T4}     ← T2-T4 hard conflict → serial within lane
  Lane C = {T5}          ← 單獨

Lanes 之間 parallel；lane 內部 serial。
```

> Lane 數上限 = 同時 dispatch 嘅 subagent 數，建議 ≤ 5（Anthropic API 並行 + reviewer batch cap）。
> 多過 5 個 lane → split 成兩 round（先做頭 5 個 lane，sync 後再做下 5 個）。

---

## Step 3：輸出 Plan + 等用戶 confirm（main agent only）

格式（強制）：

```
## Parallel Dispatch Plan

### Conflict Analysis
| Pair | 衝突類型 | 理由 |
|------|---------|------|
| T1 ↔ T2 | Independent | 無 file overlap |
| T1 ↔ T3 | Hard conflict | 同改 _funcX |
| T2 ↔ T3 | Independent | 無 file overlap |

### Lane Plan
| Lane | Tasks | 模式 | Worktree |
|------|-------|------|----------|
| A | T1, T2（serial pair） | serial | wt-A |
| B | T3 | single | wt-B |

並行啟動 Lane A + Lane B。預估節省 X%。

### 後段
- Sync：每 lane 完成 commit 後 merge → develop（main agent 順序執行）
- Batch Review：1 reviewer 處理全部 N 個 commit
- Batch QA：1 QA 處理整個 develop
- Release：1 次 develop → main + tag + deploy

確認執行？
```

> **Main agent 必須等用戶 confirm**，subagent 唔受呢條限制（subagent 收到指令直接做）。

---

## Step 4：Parallel Dispatch（同 response 多 Agent call）

```
單一 main-agent response 內，同時發出 N 個 Agent tool call：

Agent 1（Lane A 嘅 dev subagent）：
  isolation: worktree
  subagent_type: general-purpose（或 frontend-developer / backend-developer）
  prompt:
    - Lane scope：[task list, files, branches naming]
    - Pre-flight checklist 自己跑
    - TDD Red → Green → Refactor → Commit
    - 完成後輸出 receipt（lane-level，含 branch name + commit hash + test 結果）
    - 禁止 git merge / push（main agent 做）
    - 禁止越界改 lane 外 file

Agent 2（Lane B 嘅 dev subagent）：
  ...同上

⚠️ 必須喺同一個 message 嘅同一個 response 發出全部 Agent call，
   先可以 LLM runtime 真正並行；分多 message 發 = serial。
```

Per-lane prompt 必須包含：

```
□ Lane scope 完整 file list（防越界）
□ TDD 純度規則（Red 必須先寫測試）
□ Branch naming：fix/<scope>/<TICKET>_<desc>
□ Receipt format（自定 lane-receipt block，含 branch + commit + test count）
□ 禁止 git operations except commit on own branch
□ Worktree cleanup：完成後唔需要主動清，main agent 收齊後決定
```

---

## Step 5：Sync Phase（main agent serial）

收齊全部 lane receipt 後：

```
1. 解析每個 lane receipt：
   - status=pass → branch 入 merge queue
   - status=fail → 記錄入 failed list，唔 block 其他

2. 按 lane 完成順序 merge 入 develop（git 唔可並發 merge）：
   for branch in merge_queue:
     git checkout develop
     git merge --no-ff <branch> -m "..."
     git branch -d <branch>

3. 任何 unexpected merge conflict → main agent 解決（簡單）或 invoke developer subagent（複雜）

4. Worktree cleanup：
   - 有 commit 嘅 worktree → Agent tool 自動保留 path，main agent merge 完可任由系統清
   - 無 commit 嘅 worktree → Agent tool 已自動清

5. 失敗 lane 處理：
   - 若所有 lane 都 fail → 中止，invoke developer subagent 重做
   - 若部分 fail → 成功 lane 照常入 develop，失敗 lane 單獨 follow-up
```

---

## Step 6：Batch Review

```
1 個 reviewer subagent，prompt 包含：
  - 全部 merged commit hash 清單（≤ 5）
  - 每個 fix 嘅 ticket 同 scope
  - Hard gates 一次過跑（npm test 一次涵蓋全部）
  - 報告分 Section 處理每個 fix
  - 出 1 個 handoff receipt 涵蓋整體 status

receipt status 規則：
  全部 fix pass → status=pass
  任何一個 fix warn → status=warn（main agent invoke developer 修錯嗰個）
  任何一個 fix fail → status=fail（main agent invoke developer 修錯嗰個）

⚠️ Cap：1 batch 最多 **5 個 fix**。超過自動分兩批。
```

報告路徑命名：`YYYY-MM-DD_review_<batch-name>_batch.md`

---

## Step 7：Batch QA

```
1 個 QA subagent，prompt 包含：
  - 全部已 merge 嘅 fix 清單
  - 每個 fix 嘅驗證 scenario
  - 一次過跑全 suite + edge case 評估（per fix 一段）
  - 1 個 receipt protocol 2

⚠️ Cap：1 batch 最多 **5 個 fix**（同 review 一致）
```

---

## Step 8：Batch Release

```
QA receipt pass 後：
  1. main agent 開 chore/release/vX.Y.Z_bump_version branch
  2. 改 package.json + commit
  3. merge → develop
  4. merge develop → main with release commit message 列出全部 ticket
  5. tag vX.Y.Z
  6. invoke devops subagent 一次 deploy

Version bump 規則：
  全 PATCH（fix only）→ +0.0.1
  混 feat + fix     → +0.1.0
  Breaking change   → +1.0.0
```

---

## 失敗處理

| 情況 | 處理 |
|------|------|
| 1 個 lane fail，其他 pass | 成功 lane merge develop，失敗 lane invoke developer subagent 喺新 fix branch 修 |
| 全 lane fail | 中止，main agent 集中收 fail receipt，invoke developer 序列修正 |
| Sync phase merge conflict | Main agent 嘗試解；解唔到 invoke developer subagent |
| Reviewer batch fail | 按受影響 fix invoke developer subagent；其他 fix 唔受影響可繼續 |
| QA batch fail | 同上 |
| Deploy fail | Protocol 4 rollback，唔影響 develop（已 merge 嘅 fix 仍喺 develop） |

---

## Caps & Limits

| 項目 | 上限 | 理由 |
|------|------|------|
| 同時 dispatch 嘅 lane 數 | 5 | LLM context cost + reviewer batch cap |
| Batch review 一次處理 fix 數 | 5 | Cognitive load + receipt 結構清晰度 |
| Batch QA 一次處理 fix 數 | 5 | 同上 |
| 單個 lane 嘅 task 數 | 無硬上限（serial）| 但建議 ≤ 3，多就 split 另一 batch |

---

## 禁止行為

```
⛔ Main agent 跳過 Conflict Analysis 直接 dispatch
⛔ 將 hard conflict 嘅 task 放入唔同 lane（會 merge 撞）
⛔ 同一 worktree 跑多個 lane（worktree 隔離係 parallel safety 基礎）
⛔ Subagent 自己 merge / push / branch delete（係 main agent 專責）
⛔ Reviewer / QA per-fix invoke（必須 batch，除非單 fix）
⛔ Hotfix 走 parallel-dispatch（hotfix 永遠 serial、Protocol 3）
⛔ Compaction 後忘記 lane state（compact summary 必須保留 active lane list）
```

---

## Compact Protection

當 parallel-dispatch flow 中段觸發 compaction，summary 必須喺頂部保留：

```markdown
## Active Workflow State

- **Active command**: /fix --parallel | /feature --parallel | /refactor --parallel
- **Source branch**: develop
- **Active lanes**: 
  - Lane A (worktree wt-A): T1 → T2 [serial], status: T1 in-progress
  - Lane B (worktree wt-B): T3, status: complete (commit abc1234)
- **Sync queue**: [Lane B branch ready to merge]
- **Pending batch review**: yes (waiting all lanes)
- **Open blockers**: <list, or none>
```

---

## Quick Reference

```
入口偵測 → Conflict Analysis (AI judgment) → Lane Clustering
       → User Confirm Plan → Parallel Dispatch (1 message, N Agent calls)
       → Sync (serial merge) → Batch Review → Batch QA → Batch Release
```

| 場景 | 用 parallel-dispatch？ | Lane 結構 |
|------|---------------------|----------|
| 1 個 fix | ❌ | n/a |
| 3 個獨立 fix | ✅ | 3 lanes parallel |
| 3 個 fix（其中 2 個改同 file 同 func）| ✅ | 2 lanes（一條 serial 包 2 個）|
| 5 個獨立 feature | ✅ | 5 lanes parallel |
| 6 個獨立 fix | ✅ | 5 + 1 = 兩批 batch |
| Hotfix + 普通 fix | ❌（hotfix 永遠 serial）| n/a |

---

## 與其他 SSoT 嘅關係

- 低層 dispatch 機制：`skills/sw-autonomous-loop/SKILL.md` 模式二（Parallel Agents）
- 單 fix 流程：`commands/fix.md` / `feature.md` / `refactor.md`
- Branch / commit 規範：`skills/sw-git-flow/SKILL.md`
- Reviewer batch 行為：`agents/code-reviewer.md` § Batch Review
- QA batch 行為：`agents/quality-assurance.md` § Batch QA
- Receipt 格式：`skills/sw-post-review-handoff/SKILL.md`
- Compact protection：`skills/sw-agent-protocols/SKILL.md` §10
