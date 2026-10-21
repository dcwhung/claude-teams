---
description: 生成 app 宣傳包（FB post、LinkedIn post、2 頁 Google Slides deck、CV project 段落）
argument-hint: [repo-path]
---

# 指令：/showcase

## 用途

App 完成或 MAJOR release 之後，生成四樣嘢：
1. Facebook post（廣東話，開心 share）
2. LinkedIn post（英文，portfolio 用）
3. 兩頁 Google Slides pitch deck（附真實截圖）
4. CV「Selected Projects」段落（markdown，由用戶自行 paste）

所有數字都嚟自 git、測試同 token 記錄。

## 負責 Agent

**Main agent**（直接同用戶對話，因為要問確認題）

---

## 引用規範（SSoT）

- 完整流程、硬性規則、輸出位置、數字來源 → `skills/sw-showcase/SKILL.md`
- Token 記錄 → `hooks/usage-logger.sh`
- Commit 格式 → `skills/sw-git-flow/SKILL.md`

本檔案只定義入口同參數；流程唔喺度重複。

---

## 執行流程

```
1. 載入 skill：ai-dev-team:sw-showcase
2. 確定目標 repo（參數，或者 cwd 嘅 git root）同目前版本
3. 輸出執行計劃（輸出路徑 .proj-docs/showcase/v<version>/），等用戶確認
4. 跟 SKILL.md §執行流程 Step 1–10 執行
```

## 使用方式

```
/showcase                       ← 用當前 repo
/showcase ../life-in-uk-test    ← 指定 repo
```
