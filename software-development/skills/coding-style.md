---
name: sw-coding-style
description: Coding style entry point — universal rules (function length, magic number, comments) + pointers to language-specific sub-skills. Load this before writing or reviewing ANY code. If you're about to implement a feature, fix a bug, refactor, or do a code review, load this skill first. Then load the language-specific sub-skill (ts.md / php.md / py.md) on demand.
---

# Skill：Coding Style（入口）

> 此檔案係 coding style 嘅入口同通用規範。
> 語言專屬規則喺對應 sub-skill，**按需 load，唔好全部預載**。

---

## 語言 Sub-Skills

| 語言 | Sub-Skill 檔案 | 何時 Load |
|------|---------------|---------|
| TypeScript / React | `skills/coding-style/ts.md` | 寫或 review TS / TSX 代碼時 |
| CSS / Styling | `skills/coding-style/css.md` | 寫或 review CSS / styled-jsx / Tailwind 樣式時，**任何 UI task 都要 load** |
| PHP | `skills/coding-style/php.md` | 寫或 review PHP 代碼時 |
| Python | `skills/coding-style/py.md` | 寫或 review Python 代碼時 |

---

### Design Source Citation 🔴 Critical（所有語言）

違反視為 Critical，Reviewer 必須 reject PR。

```
✅ 寫 / 改任何 UI component / page（*.tsx / *.jsx / *.css / *.scss）前，
   PR description 必須有 `Design Origin:` 行（5 種 origin 之一）
✅ 詳細規則見 ~/.claude/global-rules.md §Design-Source Binding Rule
❌ 冇 Design Origin → Reviewer 必須 reject，唔可 merge
❌ Origin 係 `none-required` 但 diff 有新 className / layout → reject
```

---

## 通用規範（所有語言）

### 函數長度

| 語言 | 最大行數 |
|------|---------|
| TypeScript / React 組件 | 50 行 |
| TypeScript 工具函數 | 30 行 |
| PHP 方法 | 30 行 |
| Python 函數 | 30 行 |

超過須拆分，每個函數只做一件事。

### Magic Number / String 🔴 Critical（所有語言）

違反視為 Critical，必須修正先可以 merge。

```
❌ 直接使用數字或字串字面量
❌ type 比較使用字面量（if type == "birth"）
✅ 抽取為命名常數，放係語言對應嘅 constants 檔案（見各語言 sub-skill）
✅ type 比較必須透過常數（if entry_type == BIRTH）
```

### Constants 命名規則 🔴 Critical（所有語言）

違反視為 Critical，必須修正先可以 merge。

```
✅ 所有放於 constants/（或 Constants/）目錄下的常數，名稱一律 UPPER_SNAKE_CASE
❌ camelCase、PascalCase、lowercase 常數名
```

> 語言專屬嘅 constants 目錄結構見各語言 sub-skill。

### Statement Terminator（語句結尾）

| 語言 | 規則 |
|------|------|
| TypeScript / JavaScript | 🔴 **必須**加 `;`，Prettier `semi: true` 強制執行 |
| PHP | 🔴 **必須**加 `;`，PSR-12 + PHP 語法要求 |
| Python | 🔴 **禁止**加 `;`，PEP 8 視為反模式（除非同行多 statement，亦不鼓勵） |

> 詳細規則見各語言 sub-skill。

---

### Console / Log

```
❌ console.log / print / var_dump 喺生產代碼
✅ 使用項目統一嘅 logger（logger.debug / logger.info / logger.error）
```

### Comments 規範（所有語言）

```
✅ Non-obvious 嘅 WHY 必須有 comment：隱藏約束、協議要求、設計選擇、會令讀者驚訝嘅行為
✅ 一行最多，禁止多行 comment 塊
❌ 禁止 WHAT comment（說明代碼已清楚表達嘅事）
❌ 唔好注釋掉嘅代碼留係 codebase，直接刪除，git 有記錄

WHY ✅ 例子：
  # RFC 5545 §3.1 mandates CRLF as the line separator.
  # Use UTC to avoid DST transitions skewing the day count.
  # 204 No Content has no body; calling res.json() would throw.

WHAT ❌ 例子（禁止）：
  # Connect to database
  # Loop through all entries
  # Return the result
```

### Critical / Warning 標記（所有語言）

Code Review 使用以下等級標記問題，並按 `skills/ticket-management.md` 嘅 Review Item ID 系統（C-NNN / W-NNN / S-NNN）追蹤：

| 嚴重程度 | Review ID 前綴 | 觸發條件 | PR 影響 |
|---------|--------------|---------|---------|
| 🔴 Critical | `C-NNN` | 循環依賴、`any` 類型、無類型宣告（PHP/Python public func）、`eval()`/`exec()` | 必須修正先可以 merge |
| 🟡 Warning | `W-NNN` | 過度抽象、magic number、函數超長、複雜巢狀條件 | 建議修正，score 扣分 |
| 💡 Suggestion | `S-NNN` | 可讀性改善、命名優化 | 可選，唔影響 merge |
