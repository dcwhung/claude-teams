# 指令：/session-close

## 用途

以 `/session-log` 相同步驟生成並儲存 session log，之後輸出 closing banner 並關閉當前 session。

## 負責 Agent

**全體**（由最後活躍嘅 agent 或 PM 整合執行）

---

## 執行流程

```
1. 完整執行 `/session-log` 嘅流程（包括 timestamp、內容整理、template 填寫、儲存位置判定）
2. Log 儲存完成後輸出 Session Closed Banner（見下方格式）
3. 執行 Bash：`kill -2 $PPID` 發送 SIGINT，自動關閉 session
```

---

## 儲存位置

```
跟 `/session-log` 完全一致：
- 項目專屬：`[project-root]/.claude/session-logs/YYYY-MM-DD_HH-MM.md`
- 無 project working directory：`{active-team-folder}/session-logs/YYYY-MM-DD_HH-MM.md`
```

---

## Log 輸出格式

跟 `/session-log` 完全一致，權威來源：

```
templates/session-log.md
```

---

## Session Closed Banner

Log 儲存完成後輸出：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Session log 已儲存
📁 [log 檔案路徑]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Session closing...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 使用方式

```
/session-close               ← 儲存 log 並自動關閉 session（kill -2 $PPID）
/session-close --preview     ← 預覽 log，唔儲存，唔關閉
```

---

## 設計原則

```
/session-close 只處理「close session」獨有行為。
Log 欄位、章節格式、儲存規則一律沿用 /session-log，禁止喺本文件重複定義。
```
