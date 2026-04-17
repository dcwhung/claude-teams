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
| PHP | `skills/coding-style/php.md` | 寫或 review PHP 代碼時 |
| Python | `skills/coding-style/py.md` | 寫或 review Python 代碼時 |

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

### Magic Number / String

```
❌ 直接使用數字或字串字面量
✅ 抽取為命名常數，放係模組頂部或常數檔案
```

### Console / Log

```
❌ console.log / print / var_dump 喺生產代碼
✅ 使用項目統一嘅 logger（logger.debug / logger.info / logger.error）
```

### 注釋規範

```
✅ 複雜業務邏輯必須有注釋，說明「為何」，唔係「做乜」
✅ 公開 API / 函數必須有 JSDoc / PHPDoc / docstring
❌ 唔好注釋掉嘅代碼留係 codebase，直接刪除，git 有記錄
```

### Critical / Warning 標記（所有語言）

Code Review 使用以下等級標記問題，並按 `skills/ticket-management.md` 嘅 Review Item ID 系統（C-NNN / W-NNN / S-NNN）追蹤：

| 嚴重程度 | Review ID 前綴 | 觸發條件 | PR 影響 |
|---------|--------------|---------|---------|
| 🔴 Critical | `C-NNN` | 循環依賴、`any` 類型、無類型宣告（PHP/Python public func）、`eval()`/`exec()` | 必須修正先可以 merge |
| 🟡 Warning | `W-NNN` | 過度抽象、magic number、函數超長、複雜巢狀條件 | 建議修正，score 扣分 |
| 💡 Suggestion | `S-NNN` | 可讀性改善、命名優化 | 可選，唔影響 merge |
