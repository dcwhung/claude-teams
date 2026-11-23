---
name: sw-modern-web
description: SSoT for using Chrome's Modern Web Guidance (MWG) in this team — Baseline target, guide search / retrieve before writing UI, legacy-scan for review and /audit, and how its findings pass the Validation Gate. Load before writing or reviewing ANY HTML / CSS / browser-side JS or TS (dialogs, popovers, forms, animation, layout, Core Web Vitals, accessibility, CSP, passkeys), when running /audit on a project with a frontend, or when the user says "modernize", "legacy patterns", "Baseline", "browser support", or "is this following modern web guidance".
---

# Skill：Modern Web Guidance（MWG）

> 權威來源：<https://developer.chrome.com/docs/modern-web-guidance>
> MWG 係 Chrome team 出嘅 guide 庫（約 200 篇）+ CLI。本 skill 只定義**本 team 點用**，唔複製 guide 內容。
> Guide 內容永遠用 CLI 即時 `retrieve`，唔好憑記憶寫。

---

## 1. Baseline Target（L1 基準）

Project `CLAUDE.md` §Tech Stack 嘅 Baseline target 一行決定邊啲 web feature 要 fallback。

| 設定 | 意思 | 幾時揀 |
|------|------|--------|
| `Baseline Widely available` | 所有主流 browser engine 已支援 ≥ 30 個月 | **預設**；有舊機 / 公眾用戶嘅 project |
| `Baseline <年份>`（例如 `Baseline 2024`） | 該年底或之前變成 interoperable 嘅 feature | 想用新啲 feature，但要一個固定、可審計嘅界線 |
| `Baseline Newly available` | 所有主流 engine 啱啱支援（< 30 個月） | 內部工具 / 用戶 browser 長期最新 |

```
✅ CLAUDE.md 冇寫 → 當 Baseline Widely available（MWG 自己嘅 default）
✅ 用到 target 以外嘅 feature → 必須跟 guide 嘅 fallback（progressive enhancement / @supports / 條件載入 polyfill）
❌ 未經用戶同意行 `set-allow-volatile-features` / `set-allow-origin-trials`（單一 engine / 實驗性 feature）
```

---

## 2. CLI（唔使安裝，靠 npx）

```bash
npx -y modern-web-guidance@latest search "<用自然語言描述 use case>"   # → JSON：id / description / category / tokenCount
npx -y modern-web-guidance@latest retrieve "<guide-id>"               # → 該 guide 嘅 Markdown
npx -y modern-web-guidance@latest legacy-scan <path> --json           # → 本地 AST / CSS / HTML 掃描，零 LLM 成本
```

```
✅ search 之後睇 description 揀 id；retrieve 前睇 tokenCount，一次只攞當前 task 需要嘅 guide（Context Budget）
✅ CLI 行唔到（冇網絡 / 被 permission 擋）→ 報告寫一行「MWG CLI 不可用，已跳過」，照常做其他檢查
❌ CLI 行唔到就當 pass，或者憑記憶作 finding
❌ 為咗行 CLI 而改 permission / network 設定（要用戶自己決定）
```

可選：project 想 agent 原生識 MWG，可以另外裝官方 plugin（`claude plugin marketplace add GoogleChrome/modern-web-guidance` + `claude plugin install modern-web-guidance@googlechrome`）。本 skill 唔依賴佢。

---

## 3. 幾時用

| 場景 | 負責 | 動作 |
|------|------|------|
| 寫新 UI / 改 browser-side 行為 | Frontend Developer | 寫 code **之前** `search` → `retrieve` 相關 guide，按 Baseline target 實現 |
| `/review`（diff 有 FE 檔案） | Code Reviewer | 只對 **diff 涉及嘅 FE 路徑** 行 `legacy-scan`；finding 過 §4 |
| `/audit`（project 有 frontend） | Architect | 對成個 FE source root 行 `legacy-scan`，結果入報告「Modern Web 檢查」一節 |
| `/refactor` 做 modernization | Frontend Developer | §5 四步流程 |

FE 檔案 = `.html` `.css` `.scss` `.js` `.jsx` `.ts` `.tsx` `.vue` `.svelte` 同 `package.json`。純 backend diff 唔使行。

---

## 4. Finding 點過 Validation Gate

> 定級規則嘅 SSoT 係 `skills/sw-validation-gate/SKILL.md` §4；呢度只講 MWG 證據屬邊一層。

| 證據 | 層 |
|------|----|
| Project `CLAUDE.md` 嘅 Baseline target、AC、Hard Rule | **L1** |
| `legacy-scan --json` 輸出節錄（rule id + `file:line`） | **L2** |
| 對照該 finding 附帶嘅 keepWhen / dropWhen checklist 之後嘅判斷 | **L3** |
| MWG guide 本身（「建議用 X」） | **L3**（最佳實踐，唔係 L1） |

```
✅ 每個 scan match 必須逐條對 keepWhen / dropWhen 睇上下文；係刻意 fallback、已有 @supports guard、或者 lookalike → 靜靜剔走，唔入報告
✅ Legacy pattern 本身冇違反 AC / Hard Rule → 最多 🟢（入 backlog，唔 block）
✅ 只有同時違反 L1（例如用咗 Baseline target 以外嘅 feature 又冇 fallback、a11y AC、安全要求）先可以 🟡 / 🔴
❌ 用「MWG 話應該咁做」單獨作 L1 去 block
❌ Review 階段掃成個 repo（只掃 diff 路徑；全 repo 係 /audit 嘅事）
```

---

## 5. Modernization 四步（`/refactor` 或用戶講「modernize」）

```
1. Scan     — legacy-scan <path> --json
2. Verify   — 逐條 keepWhen / dropWhen，剔走 false positive
3. Report   — 列出已驗證 finding + modernization plan；等用戶確認先改 code（MWG 刻意冇 --fix）
4. Refactor — 逐個 finding：retrieve <guide-id> → TDD 改 → 對改過嘅檔案重跑 legacy-scan + 相關 unit test
```

---

## 6. 限制（報告必須如實寫）

```
- legacy-scan 只覆蓋約 20% guide（可以確定性偵測嗰批）→「scan 冇 finding」≠「全部 follow guideline」
  報告用字：「legacy-scan：0 finding（只覆蓋確定性規則）」
- MWG 只睇 source；LCP / INP / CLS、實際 a11y 行為要靠 runtime 工具（Lighthouse / Chrome DevTools for agents / Playwright）
- 官方 CI/CD integration 仲未推出 → 唔好喺 pipeline 當 blocking gate
```

---

## 7. Cross-link

- Finding 定級 → `skills/sw-validation-gate/SKILL.md` §4
- CSS token / SVG 規則（本 team 自己嘅 Critical 規則，優先過 MWG 建議）→ `skills/sw-coding-style-css/SKILL.md`
- a11y Checklist → `agents/frontend-developer.md` §Accessibility
- Baseline target 填喺邊 → `templates/project-claude.md` §Tech Stack
