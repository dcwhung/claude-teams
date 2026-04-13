# 指令：/hotfix

## 用途

針對生產環境嘅緊急問題，繞過 `develop` 直接 patch `main`，最快速度恢復服務。
完成後必須同步合併回 `develop`，確保改動唔會喺下次 release 時遺失。

> ⚠️ **只適用於生產緊急情況。** 非緊急問題一律使用 `/fix` 經正常流程處理。

---

## Git Flow 規則

完全遵從 `skills/git-flow.md`。

> ⚠️ Hotfix 係唯一合法從 **main** 建立 branch 嘅情況（Pre-Flight Checklist source=main）。
> Back-merge to develop 係唯一合法嘅 main → develop 操作，hotfix 專屬例外。
> 一般 fix/feature/refactor 必須從 develop 建立。
>
> Review / handoff 使用 `skills/git-flow.md` → Post-Review Handoff Protocol → **Hotfix 特殊流程**（門檻 75 分）。

## 負責 Agent

**Backend Developer** 及/或 **Frontend Developer**（視問題範圍）
**DevOps Engineer**（部署及監控）
**Project Manager**（授權及通知）

---

## 啟動條件（必須符合其中一項）

```
🔴 生產環境服務完全中斷（outage）
🔴 核心功能無法使用，影響大量用戶
🔴 嚴重安全漏洞已被利用或即將被利用
🔴 數據洩露或數據損壞風險
```

**不符合以上條件 → 使用 `/fix` 正常流程。**

---

## 執行流程

```
1.  Project Manager 確認符合 hotfix 啟動條件
2.  輸出執行計劃（精簡版），等待確認
3.  執行 `skills/git-flow.md` → Branch 建立強制 Pre-Flight Checklist（source=main），
    檢查通過後建立：hotfix/[TICKET_NUMBER]_[描述]
4.  快速定位根源（Root Cause Analysis）
5.  🔴 先寫重現問題嘅失敗測試
6.  🟢 最少改動修復問題
7.  執行關鍵測試（最少：unit + smoke test）
8.  Commit，透過 Agent tool 呼叫 code-reviewer agent 執行 /review（聚焦 Critical 問題）
9.  其後 handoff 由 Reviewer 按 `skills/git-flow.md` Post-Review Handoff Protocol →
    Hotfix 特殊流程（門檻 75 分）自動執行：merge main、invoke DevOps 部署、invoke QA smoke test + back-merge。
10. QA Smoke test 完成後建立 post-mortem ticket
11. 執行 /session-log
12. ⚠️ 提示：開新對話執行 /start ai-dev-team --task=postmortem 進行根源分析
```

---

## Branch 命名

```bash
# 從 main checkout
git checkout main && git pull origin main
git checkout -b hotfix/[TICKET_NUMBER]_[簡短描述]

# 例子：
hotfix/CUI-0099_payment_service_down
hotfix/CUI-0100_auth_token_bypass
hotfix/CUI-0101_data_corruption_on_save
```

---

## Hotfix vs Fix 對照

| 項目 | `/fix` | `/hotfix` |
|------|--------|-----------|
| 適用場景 | 一般 bug | 生產緊急事故 |
| Checkout 自 | `develop` | `main` |
| Merge target | `develop` → `main` | `main` 直接，再 back-merge to `develop` |
| 測試要求 | 完整測試套件 | 最少可接受測試（unit + smoke） |
| Review 要求 | 標準 review（≥ 90 分） | 快速 review（聚焦 Critical） |
| 完成後 | 等 QA 驗證 | 即時部署，事後補 post-mortem |

---

## 測試要求（精簡但不可省略）

```
□ 重現問題嘅測試（證明 bug 存在）
□ 修復後測試通過（證明 bug 消失）
□ Smoke test 通過（關鍵流程正常）
□ 冇明顯 regression（快速人工驗證核心功能）
```

> 完整測試留待 hotfix 後補充，加入正常 PR 流程。

---

## Code Review（快速版）

**執行者**：由另一位 Developer 或 Code Reviewer 執行，**唔可自我 review**。
**最低合格分數**：≥ 75 分（緊急情況豁免 90 分標準門檻）。

Hotfix review 聚焦：
```
🔴 修復是否正確解決問題？
🔴 有冇引入新嘅安全漏洞？
🔴 有冇明顯 side effect 影響其他功能？
🟡 改動範圍是否最小化？
```

允許跳過 🟢 Suggestion，允許評分低於 90 分，**但 🔴 Critical 不可存在**。

---

## Back-merge to Develop（必須執行）

> ⚠️ 呢個係整個 Git Flow 中**唯一合法嘅 main → develop 操作**。
> 目的係同步 hotfix 改動，防止下次 release 覆蓋修復。
> 任何其他情況下嘅 main → develop merge 均屬禁止。

```bash
# hotfix 部署成功後，立即 merge back
git checkout develop
git merge --no-ff main -m "chore: sync hotfix [TICKET_NUMBER] back to develop"
```

**唔做 back-merge 嘅後果：** 下次 develop → main release 時，hotfix 改動會被覆蓋，問題復發。

### Back-merge Conflict 處理

若 `develop` 在 hotfix 期間有新 commit，back-merge 可能出現 conflict：

```bash
git merge --no-ff main -m "chore: sync hotfix [TICKET_NUMBER] back to develop"
# 出現 conflict 時：
git status                        # 查看 conflict 檔案
# 手動解決 conflict，優先保留 hotfix 改動
git add [resolved-files]
git commit -m "chore: resolve back-merge conflict for hotfix [TICKET_NUMBER]"
git push origin develop
```

> ⚠️ 如 conflict 涉及複雜業務邏輯，立即通知 PM 及相關 Developer 協助，唔好獨自決定合併方式。

---

## Post-mortem Ticket（必須建立）

> **儲存位置**：`.proj-docs/audits/YYYY-MM-DD_HH-MM_postmortem_[描述].md`
> **後續分析**：由 Engineering Manager 主導，執行 `/start ai-dev-team --task=postmortem`
> **注意**：此格式係 post-mortem 專用文件，獨立於 `skills/ticket-management.md` 嘅標準 QA ticket 格式

Hotfix 完成後，QA 必須建立 post-mortem 文件，記錄：

```markdown
# [TICKET_NUMBER] Post-mortem：[事故標題]

**事故時間**：YYYY-MM-DD HH:MM
**影響時長**：[X 分鐘 / 小時]
**影響範圍**：[受影響功能 / 用戶數]
**嚴重程度**：🔴 Critical

## 事故時間線
| 時間 | 事件 |
|------|------|
| HH:MM | 發現問題 |
| HH:MM | 開始調查 |
| HH:MM | 定位根源 |
| HH:MM | 部署修復 |
| HH:MM | 確認恢復 |

## 根源分析（Root Cause）
[真正嘅原因，唔係表面現象]

## 修復方案
[做咗乜嘢修復]

## 預防措施
- [ ] [點樣避免同類問題再發生]
- [ ] [需要補充嘅測試]
- [ ] [需要改善嘅監控]
```

---

## Commit 格式

Hotfix commit 使用 `fix:` 類型（`hotfix:` 不是合法 Conventional Commits 類型），必須帶 ticket number：

```
fix: [TICKET_NUMBER] | [問題描述]

例子：
fix: CUI-0099 | 修復 payment service 503 錯誤
fix: CUI-0100 | 撤銷導致 auth bypass 嘅改動
fix: CUI-0101 | 修正 save 操作數據覆蓋問題
```

---

## 使用方式

```
/hotfix                                        ← 開始緊急修復流程
/hotfix CUI-0099                               ← 按 ticket number
/hotfix "payment service down" --backend       ← 描述 + 指定範圍
```
