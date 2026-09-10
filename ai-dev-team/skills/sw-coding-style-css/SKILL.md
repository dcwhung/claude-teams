---
name: sw-coding-style-css
description: CSS / Tailwind / SVG styling rules — load for any UI task alongside ts.md. Covers design token enforcement, SVG fill/stroke, className mapping, dead variable detection, Tailwind vs CSS file boundary, and font loading. Triggered by the black-globe incident (2026-05-17).
---

# Sub-Skill：CSS / Styling 規範

> 呢個 sub-skill 跟 `coding-style.md` entry 一起用。任何涉及 `.css`、`.scss`、Tailwind class、SVG styling 嘅 UI task 都要 load。

---

### 1. Design Token 強制（🔴 Critical）

違反視為 Critical，必須修正先可以 merge。

```
✅ 顏色 / 字體 / 字號 / spacing / radius / shadow → 必須用 CSS variable（出自 tokens.css）
✅ Tailwind 自訂 class 一樣要綁 token，喺 tailwind.config.ts 內 reference token

❌ 禁止 hardcoded：
   color: #d4a574           → ✅ color: var(--accent-gold)
   font-family: 'Cormorant' → ✅ font-family: var(--font-serif)
   font-size: 14px          → ✅ font-size: var(--text-sm)
   padding: 8px             → ✅ padding: var(--spacing-2)
```

Reviewer check：grep diff 內 hardcoded hex / px / rgb / font-family string，flag 每一個。

---

### 2. SVG element 必須明確 fill / stroke（🔴 Critical）

> **觸發原因**：2026-05-17 life-travels 地球儀全黑事件 — D3 建立 `.sphere`、`.land`、`.country-borders` 但 CSS 無任何 rule 消費 token，SVG default fill=black 將所有嘢染黑。

```
✅ 任何 D3 / 手寫 SVG 內嘅 <path> / <circle> / <rect> 必須喺 CSS 或 attribute 內 explicit set 顏色
✅ 加 unit test 確保關鍵 SVG element 有非 black fill（或 fill=none）
✅ declare token 必須有對應嘅 CSS rule 消費，唔可只 declare 唔用

❌ 禁止依賴 SVG default（default 係 fill: black, stroke: none）
❌ 禁止 declare --token: #value 但無任何 rule 用 var(--token)
```

Reviewer check：搵 D3 `.attr("class", ...)` 嘅元素係咪有對應 CSS rule；搵 tokens.css declare 嘅 variable 係咪有被消費。

---

### 3. ClassName / ID 對應 mockup（mockup origin 時）

```
✅ 由 mockup HTML port 過嚟嘅 component，className / ID 應該 1:1 對應 mockup
✅ 方便 reviewer 對比，亦方便 CSS rule 直接 port 過嚟

❌ 唔好為「React convention」就改名
   mockup 用 .now-card → React component className 要保留 now-card，唔係 NowCard / nowCard
```

---

### 4. CSS 唔可有 dead variable

```
✅ tokens.css declare 嘅 variable 必須有 rule 消費
✅ Reviewer check：grep -r "var(--" src/ 對 tokens declaration list，識別未用 token
❌ declare --color-ocean: #1a3d5c 但無任何 .class { color: var(--color-ocean) }
```

---

### 5. Tailwind 用喺 layout，CSS file 用喺 design token / 複雜選擇器

```
✅ Layout（flex / grid / spacing / responsive）→ Tailwind utility class
✅ Design token consumption（顏色 / 字體 / 動畫 / 陰影）→ CSS file，用 var()
✅ 複雜選擇器（:hover + child、::before、@keyframes）→ CSS file

❌ 唔好 mix：className="bg-gray-900" + style={{ color: 'var(--ink)' }}
❌ 唔好把 CSS variable 放入 Tailwind className（如 text-[var(--ink)]）
```

---

### 6. Font 強制由 fonts.css load

```
✅ @font-face 集中喺 fonts.css，唔散落各 component
✅ font-family 必須 declare 做 CSS variable（如 --font-serif: 'Cormorant Garamond', serif）
✅ Component 用 font-family: var(--font-serif)

❌ 禁止 inline：fontFamily: '"Cormorant Garamond", serif'
❌ 禁止喺 component CSS 內 @font-face
```
