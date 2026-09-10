# Global Rules — Digest
# 核心規則摘要，預設載入版本（~50 行）
# 需要詳細規則時，讀取 global-rules.md 對應章節

---

## 語言
繁體中文（廣東話書面語）。代碼、技術術語、變數用英文。

## Agent 行為（所有 agent 必守）
- **Fact-Check Before Answer**：唔靠估，不確定就說不確定，列出假設
- **Plan Before Do**：每次任務前輸出執行計劃。Main agent 等用戶確認；Subagent（Agent tool invoke）立即執行，唔等確認
- **問清楚先做**：需求模糊必須提問，一次問清楚，唔好逐條問
- **Step Execution Integrity**：禁止 Ghost Referencing（提及步驟但唔執行）。每步完成後必須輸出 `✅ 步驟 [N] 完成：[可驗證結果]` 先可進行下一步。跳步必須向用戶說明並取得確認。→ 詳見 `skills/sw-agent-protocols/SKILL.md` §8
- **Workflow Self-Check**（main agent）：接到代碼修改任務前，必須確認對應 command（feature/fix/refactor/hotfix）已載入、目前喺正確 branch、任務 type 已識別。→ 詳見 `skills/sw-agent-protocols/SKILL.md` §9 + `commands/start.md` Task Type Enforcement
- **Compact Protection**：執行 conversation compaction 時，summary 頂部必須保留 `## Active Workflow State` block（active command / branch / pipeline stage / next handoff）。→ 詳見 `skills/sw-agent-protocols/SKILL.md` §10

## 代碼原則
SOLID + DRY。函數 ≤ 30 行（組件 ≤ 50 行）。禁止 magic number / magic string。
→ 詳細: global-rules.md#代碼原則

## 命名（速查）
變數: `camelCase` ｜ 常數: `UPPER_SNAKE_CASE` ｜ Class: `PascalCase`
檔案: `PascalCase.tsx`（組件）/ `camelCase.ts`（其他）/ `kebab-case`（資料夾）
→ 詳細規則: global-rules.md#命名規範

## Coding Style
Prettier: `tabWidth=4`, `singleQuote`, `trailingComma`, `printWidth=100`
→ 詳細 ESLint 規則: global-rules.md#coding-style

## TDD
Red → Green → Refactor。禁止先寫實現後補測試。核心邏輯覆蓋率 ≥ 80%。

## Git
`main` + `develop`。所有 branch checkout 自 `develop`（`hotfix` 除外，checkout 自 `main`）。
Branch: `[類型]/[模組]/[TICKET]_[描述]`
Commit: `feat / fix / refactor / chore / docs / test`
→ 詳細: global-rules.md#git-規範

## 安全
禁止 hardcode secret。所有外部輸入必須 validation。
新依賴引入前必須執行 `npm audit` / `pip-audit`。License 禁止 GPL。
→ 詳細: global-rules.md#安全規範

## Session
每次結束執行 `/session-log` → 儲存至 `.claude/session-logs/`。保留 90 天。
每次開始先讀上次 session log。

## Definition of Done（速查）
```
代碼:   測試通過 + ESLint clean + 覆蓋率 ≥ 80%
Review: ≥ 90 分 + 無 🔴 Critical
QA:     無 🔴 Critical + regression 通過
文件:   .proj-docs/ 更新 + index.md 同步
Git:    Conventional Commits + 無 secret commit
```
→ 完整 DoD: global-rules.md#definition-of-done

## 文件輸出（速查）
所有產出存入 `.proj-docs/` 對應子資料夾，每次輸出後更新 `index.md`。
PM 每次工作前必讀 `.proj-docs/index.md` + 相關文件 + 最新 session log。
→ 結構: global-rules.md#文件輸出規範

## Sub-Agent 觸發（速查）
```
🔴 立即 spawn: 連續重複同一內容 / 前後矛盾 / 引用不存在嘅資訊
🟡 建議 spawn: 3+ 任務混雜 / 20+ 來回仍未完成 / response 越長資訊越少
🔵 必須新 context: review 驗證他人輸出 / QA 驗證 developer 修復 / security audit
```
→ 詳細流程: global-rules.md#sub-agent-規範
