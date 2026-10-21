---
name: sw-showcase
description: App showcase pack — after an app ships, generate a Cantonese Facebook post, an English LinkedIn post (≤800 chars), a 2-slide Google Slides pitch deck with real screenshots, and a CV "Selected Projects" entry, all backed by real git / test / token metrics. Load when the user runs /showcase, says "出 post", "介紹個 app", "portfolio", "LinkedIn post", "pitch deck", "加入 CV", or when DevOps reminds after a MAJOR release.
---

# Skill：Showcase（App 發佈宣傳包）

> 一個 app 完成（或 MAJOR release）後，輸出 4 樣嘢：FB post、LinkedIn post、2 頁 Google Slides deck、CV project 段落。
> 目的：FB = 開心 share 俾朋友；LinkedIn / CV = 俾潛在僱主睇 AI-first 工程能力（portfolio）。

---

## 硬性規則

| # | 規則 |
|---|------|
| R1 | **數字只可以嚟自 `scripts/collect-metrics.sh` 或用戶親口提供**。禁止估算、禁止四捨五入到「好睇」嘅數。冇數據 → 唔顯示嗰項 |
| R2 | Token：`tokens.display` 係 `null` → 問用戶有冇手動數字（claude.ai usage 頁）；冇就**整項唔出**。用戶提供嘅數寫入 `.proj-docs/showcase/manual-metrics.json` 方便下次重用 |
| R3 | 語言：FB = 廣東話書面口語（可夾英文詞）；LinkedIn / Deck / CV = 英文 |
| R4 | 字數：LinkedIn **≤ 800 字元**；FB **400–600 字元**；用 `scripts/check-length.py` 驗證，唔合格就改到合格先交 |
| R5 | 賣點：Deck = 5–10 個（主清單）；LinkedIn = 揀頭 5 個極短 bullet（每個 ≤ 45 字元）；FB = 揀 3–5 個最好玩 |
| R6 | 第三方內容 / 自用 app（例如串流其他網站內容、未經授權 API）→ 輸出 risk flag；**LinkedIn 同 CV 唔放 app link**（改放 repo 或「screenshots in comments」）；FB 照放 |
| R7 | 唔可以直接改用戶 CV Google Doc —— CV 只出 markdown 段落俾用戶自己 paste |
| R8 | 動機 / pain point 由 AI 起草，**必須**問用戶 2–3 條確認問題先定稿（見 Step 3） |

---

## 輸出位置

```
<project-root>/.proj-docs/showcase/v<version>/
  metrics.json          ← collect-metrics.sh 輸出（凍結當刻數字）
  facebook.md           ← FB post（純文字，可直接 copy）
  linkedin.md           ← LinkedIn post（純文字，可直接 copy）
  linkedin-images.md    ← LinkedIn 附圖建議（次序 + 檔案）
  cv-project.md         ← CV Selected Projects 段落
  deck-spec.json        ← build-deck.py 輸入
  deck.pptx / deck.pdf  ← 生成嘅 deck（pptx 拖入 Drive 即變 Google Slides）
  screenshots/          ← mobile-*.png / desktop-*.png
  README.md             ← 索引：數字、risk flags、驗證結果、Slides link（用戶轉好後補）
```

同一版本重行 → 覆寫（idempotent）；新版本 → 新資料夾，保留舊版方便比較。完成後更新 `.proj-docs/index.md`（如有）。

---

## 執行流程

```
Step 1  收集數字
        bash ${CLAUDE_PLUGIN_ROOT}/skills/sw-showcase/scripts/collect-metrics.sh <repo> > metrics.json
        （script 會自動 unshallow；shallow: true → 喺 README.md 標明數字可能偏細）
Step 2  理解 app：README / HANDOFF / package.json / 主要 screens / .claude/session-logs / .proj-docs
        → 列出 8–12 個候選賣點（必須對應真實 code，記低檔案路徑作證）
        → 判斷 R6 risk flag；搵 live URL（README、vercel.json、vite base、GitHub Pages workflow）
        → 搵 app 主色（manifest theme_color / CSS design tokens）
Step 3  起草動機（pain point → solution）＋ 一次過問用戶 2–3 條確認題（AskUserQuestion）：
          a. 「點解整」嘅草稿啱唔啱 / 要補咩個人故事
          b. 目標用家 / 已有幾多人用（有就用，冇就唔講）
          c. Token 數（只喺 tokens.display == null 時問）
Step 4  揀賣點：由候選清單排序 → Deck 5–10 / LinkedIn 5 / FB 3–5（R5）
Step 5  截圖（見 §截圖）
Step 6  生成 4 樣輸出（見 templates/）
Step 7  驗證：check-length.py（R4）；數字逐個對 metrics.json（R1）；link 規則（R6）
Step 8  Deck → pptx + pdf；交用戶拖入 Drive 轉 Google Slides（見 §Deck）
Step 9  寫 README.md 索引，commit 入項目 branch（跟 sw-git-flow；只係文件 → `docs:` commit）
Step 10 向用戶交付：deck.pptx / deck.pdf 路徑（+ 轉 Slides 步驟）+ 4 樣輸出路徑 + risk flags + 「CV 請自行 paste」
```

---

## 開發數字（SSoT = collect-metrics.sh）

| 顯示 | JSON 欄位 | 格式例子 |
|------|-----------|----------|
| 開發日數 | `active_days` + `first_commit`/`last_commit` | `12 active days (Sep–Oct 2026)` |
| Commits | `commits` | `1,568 commits` |
| PRs | `merged_prs` | `143 merged PRs` |
| AI sessions | `ai_sessions` | `41 Claude Code sessions` |
| Tokens | `tokens.display` | `~4.7M tokens`（null → 唔顯示） |
| Version | `version` | `v2.10.0` |
| Tests | `tests.cases` / `tests.assertions` | 揀大嗰個，寫清楚單位：`678 unit tests` / `3.3k test assertions` |

- Token 數由 `hooks/usage-logger.sh`（Stop hook）自動寫入 `.claude/usage/<session>.json`；`total_tokens` 包含 cache read，對外寫 "tokens processed"
- 千位用逗號；≥ 10,000 可用 `3.3k` / `4.7M`（只可以向下取一位小數，唔可以誇大）

---

## 截圖

- 用 Playwright（全域已裝；cloud 用 `executablePath: '/opt/pw-browsers/chromium'`），兩個 viewport：
  - mobile `390×844`，`deviceScaleFactor: 3` → Deck P1 hero
  - desktop `1280×800`，`deviceScaleFactor: 2` → Deck P2
- 起 app：有 `npm run dev` / `preview` 就用；純靜態用 `python3 -m http.server` 或 `file://`
- **要有真實感嘅數據**：優先重用項目現成 e2e fixture / mock（例如 localStorage seed、mock server）；外部服務擋 data-center IP 時必須用 mock
- 優先重用 repo 現有截圖 / design baseline（`design/`、`tests/shot-*.png`、`.proj-docs/design-baselines/`），但要確認係最新版本 UI
- 每張截圖用 Read tool 親眼睇一次：空白頁、loading spinner、error、個人資料 → 重影

---

## Deck（2 頁，固定版面 + app 主色）

| 頁 | 內容 |
|----|------|
| P1 Hero | label（PORTFOLIO PROJECT）、app 名、一句 tagline、Problem 卡、Solution 卡、link label、QR（只限可公開 link）、右邊主色 panel + 手機截圖 |
| P2 Features | 5–10 個賣點 grid（title ≤ 4 字 + desc ≤ 70 字元）、右邊桌面截圖、底部主色 KPI 列（4–6 個數字） |

1. 按 `templates/deck-spec.example.json` 寫 `deck-spec.json`（screenshot 路徑相對 spec 檔）
2. `python3 ${CLAUDE_PLUGIN_ROOT}/skills/sw-showcase/scripts/build-deck.py deck-spec.json deck.pptx`
   （需要 `python-pptx`；`qrcode` 可選 —— 冇就 `pip install python-pptx qrcode`）
3. Render 檢查：`soffice --headless --convert-to pdf deck.pptx` → 轉 PNG 用 Read 睇一次，修正溢出 / 重疊
4. 輸出 PDF：`soffice --headless --convert-to pdf deck.pptx`（`deck.pdf` 一齊存檔，方便 attach / LinkedIn Featured）
5. 轉 Google Slides：由用戶將 `deck.pptx` 拖入 Google Drive → 右掣「開啟工具 › Google 簡報」（或者 Drive 設定開咗「轉換上載檔案」就自動轉）。
   ⚠️ **唔好用 Drive connector `create_file` upload**：佢只收 inline base64，含截圖嘅 deck（~200 KB）要成幾十萬 output token，實際做唔到（2026-10-21 試點發現）。
   交付時必須清楚講明呢一步要用戶手動做（唔可以靜靜跳過）

---

## Templates

| 檔案 | 用途 |
|------|------|
| `templates/facebook.md` | FB post 結構 + 語氣 |
| `templates/linkedin.md` | LinkedIn Builder story 結構 |
| `templates/cv-project.md` | CV Selected Projects 格式（跟用戶 CV） |
| `templates/deck-spec.example.json` | build-deck.py 輸入範例 |

---

## 觸發

- 手動：`/showcase [repo-path]`
- 自動提醒：`/deploy` 完成 MAJOR release（`vX.0.0`）後，DevOps 提示用戶「要唔要行 /showcase？」—— 只提醒，唔自動行
