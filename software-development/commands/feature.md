# 指令：/feature

## 用途

開新 branch，以 TDD（Red-Green-Refactor）方式開發新功能，完成後觸發 code review。

## 負責 Agent

**Frontend Developer** 及/或 **Backend Developer**（視功能範圍）
**Code Reviewer**（功能完成後自動執行 `/review`）

---

## 引用規範（SSoT）

- Branch 命名、Pre-Flight Checklist、Commit 格式 → `skills/git-flow.md`
- TDD Red-Green-Refactor 循環 → `skills/tdd.md`
- Edge Case 枚舉 + Parallel Agents → `skills/autonomous-loop.md`
- Review 完成後 handoff → `skills/post-review-handoff.md` → Protocol 1

本檔案只定義 `/feature` 獨有嘅執行流程，上述規範禁止重複。

---

## 執行流程

```
1. 讀取 shared-knowledge.md（全局 + 項目）
2. 讀取 spec 及 plan（確認功能需求及驗收標準）
3. 輸出執行計劃，等待確認（見 agent-protocols.md）
4. 執行 git-flow.md → Branch Pre-Flight Checklist（source=develop）
   → 建立：feature/[scope]/[identifier]_[description]
   ⚡ 若功能橫跨 3+ 個獨立模組：使用 Agent tool 並行派發
     （見 autonomous-loop.md → Parallel Agents）
5. 逐個功能點執行 TDD 循環（見 tdd.md）：
   ⚠️ 若涉及複雜業務規則（計算邏輯、日期邏輯、狀態機等）：
   先枚舉所有 edge cases（見 autonomous-loop.md）
6. 完成所有功能點後，執行完整測試套件確認全綠
7. Commit（Conventional Commits，見 git-flow.md）
8. 透過 Agent tool 呼叫 code-reviewer agent 執行 /review
9. **收到 Reviewer receipt 後，main agent 依序執行以下步驟（禁止跳步）：**

   **Step 9a — 驗證 receipt 格式**
   - 必須係 `` ```handoff-receipt `` fenced block（唔係 `---` YAML）
   - `next_action` 必須係以下其中一個：`merge_develop` / `invoke_developer`
   - 任何格式錯誤或非法 `next_action` → 視為 `status=fail`，re-invoke reviewer

   **Step 9b — 按 status 執行**

   | receipt status | main agent 動作 |
   |----------------|----------------|
   | `pass`（hard gates 全 pass + score ≥ 90） | 執行 Step 9c |
   | `warn` 或 `fail` | Agent tool invoke developer：「喺 `<branch>` 修正 `<blockers>` 後重新 /review」。**Main agent 禁止自己修改代碼。** 等 developer 完成後重新從 Step 9a 開始 |

   **Step 9c — pass 分支（必須依序完成，禁止在任一步後輸出「完成摘要」結束）**
   ```
   1. git checkout develop
   2. git merge --no-ff <feature-branch> -m "feat: merge <功能名> — <描述>"
   3. git branch -d <feature-branch>
   4. Agent tool invoke quality-assurance，prompt 含 receipt.context
   ```

   **Step 9d — 收到 QA receipt 後（Protocol 2）**

   | QA receipt status | main agent 動作 |
   |-------------------|----------------|
   | `pass` | 依序：① `git checkout main` ② `git merge --no-ff develop -m "release: <描述>"` ③ Agent tool invoke devops-engineer |
   | `fail` | Agent tool invoke developer：「執行 /fix <CUI ticket>」。禁止 merge main。 |

   **Step 9e — 收到 DevOps receipt 後（Protocol 4）**

   | DevOps receipt status | main agent 動作 |
   |-----------------------|----------------|
   | `pass / end` | 輸出最終完成摘要，結束 |
   | `fail / rollback` | 執行回滾，invoke developer |

   > ⛔ 禁止在 Step 9c 後、Step 9d 前輸出任何「完成摘要」或「Done」。
   > ⛔ 禁止在 Step 9d QA pass 後、執行 git merge main 前 invoke devops。
   > 只有收到 DevOps receipt `status=pass, next_action=end` 後才可結束整條鏈。

10. 如有發現 common knowledge，記錄入 shared-knowledge.md
```

---

## 完成標準

```
□ 所有功能點測試通過
□ 測試覆蓋率達標（核心邏輯 ≥ 80%）
□ ESLint / Prettier 無錯誤
□ TypeScript 無類型錯誤
□ Code Review 評分 ≥ 90 分，無 🔴 Critical
□ Commit history 清晰
□ 透過 Agent tool 觸發 /review，後續 handoff 由 Reviewer + main agent 自動執行
```

---

## 使用方式

```
/feature user-authentication         ← 開發用戶認證功能
/feature payment-webhook --backend   ← 指定只用 backend developer
/feature export-csv --frontend       ← 指定只用 frontend developer
```
