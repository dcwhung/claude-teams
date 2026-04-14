---
name: sw-tdd
description: Red-Green-Refactor cycle for /feature and /fix. Load before writing any production code — defines how to write failing test first, minimal fix, then refactor.
---

# Skill：TDD（Test-Driven Development）

> Red-Green-Refactor 循環規範。

---

## 核心原則

**測試先行**：任何新代碼或修復，必須先有失敗測試，再有實現。
**最少代碼**：Green 階段只寫令測試通過嘅最少代碼，唔提前優化。
**持續重構**：Refactor 階段改善代碼質量，但唔改變行為。

---

## Red-Green-Refactor 循環

### 🔴 Red — 寫失敗測試

**目標**：定義預期行為

> ⚠️ **複雜業務規則例外**（計算邏輯、日期邏輯、狀態機等）：進入 Red 前先枚舉所有 edge cases
> （零值、邊界值、null、異常輸入、並發操作、跨境條件等），
> 確保後續測試全部覆蓋。詳見 `skills/autonomous-loop.md`

規則：
- 一次只寫**一個**測試
- 測試必須描述**行為**，唔係實現：
  ```
  ✅ it('should return 404 when user not found')
  ❌ it('should call findById with the given id')
  ```
- 執行測試，**確認係失敗（Fail）而非錯誤（Error）**
  - Fail = 測試執行但結果唔符預期 ✅
  - Error = 代碼無法執行（例如 import 錯誤）❌ 先修正
- 唔好一次寫多個測試

**測試命名格式**：
```
it('should [預期結果] when [條件]')

例子：
it('should return user object when valid id provided')
it('should throw NotFoundException when user not found')
it('should return 401 when token is missing')
it('should not create duplicate when request sent twice')
```

---

### 🟢 Green — 最少代碼通過測試

**目標**：以最快方式令測試通過

規則：
- 只寫**令測試通過所需嘅最少代碼**
- 允許暫時出現重複代碼（Refactor 階段處理）
- 允許暫時用硬編碼返回值（如果只有一個測試）
- **禁止提前優化**
- 通過後**立即進入 Refactor**，唔好積累

---

### 🔵 Refactor — 改善代碼質量

**目標**：消除壞味道，保持測試全綠

重構方向：
```
□ 消除重複代碼（DRY）
□ 改善變數 / 函數命名
□ 抽取過長函數（> 30 行須拆分）
□ 消除深層嵌套（> 3 層考慮重構）
□ 確保符合 SOLID 原則
□ 抽取共用 helper / utility
```

規則：
- 每次只做**一個**重構動作
- 重構後立即執行測試，確認全綠
- 如測試失敗，立即 revert，再重新嘗試

---

## 測試覆蓋要求

| 類型 | 目標覆蓋率 | 說明 |
|------|-----------|------|
| 核心業務邏輯 | ≥ 80% | Service、Use Case 層 |
| API Endpoint | 100% | 所有 endpoint 必須有測試 |
| 工具函數 | ≥ 90% | Utility、Helper 函數 |
| UI 組件 | ≥ 70% | 關鍵交互及渲染邏輯 |

---

## 測試結構（Given / When / Then）

```typescript
describe('UserService', () => {
  describe('findById', () => {
    it('should return user when valid id provided', async () => {
      // Given
      const userId = 'user-123';
      const expectedUser = { id: userId, email: 'test@example.com' };
      mockUserRepository.findById.mockResolvedValue(expectedUser);

      // When
      const result = await userService.findById(userId);

      // Then
      expect(result).toEqual(expectedUser);
    });

    it('should throw NotFoundException when user not found', async () => {
      // Given
      mockUserRepository.findById.mockResolvedValue(null);

      // When / Then
      await expect(userService.findById('invalid-id'))
        .rejects.toThrow(NotFoundException);
    });
  });
});
```

---

## 常見反模式（禁止）

| 反模式 | 問題 | 正確做法 |
|--------|------|----------|
| 先寫實現後補測試 | 測試只係為咗覆蓋率，唔係真正驗證行為 | 必須先寫測試 |
| 測試實現細節 | 重構後測試失敗，但行為冇變 | 測試行為，唔係實現 |
| 一個測試驗多件事 | 失敗時唔知係邊個條件出問題 | 每個測試只測一件事 |
| Mock 太多 | 測試唔反映真實行為 | 只 mock 外部依賴（DB、API） |
| 測試之間有依賴 | 執行順序影響結果 | 每個測試獨立，有自己嘅 setup |
| 跳過 Refactor | 技術債積累 | 每個 Green 後必須執行 Refactor |

---

## 前端 TDD 補充（React / TypeScript）

```typescript
// 測試組件行為，唔係實現
describe('LoginForm', () => {
  it('should show error message when email is empty', async () => {
    // Given
    render(<LoginForm onSubmit={mockSubmit} />);

    // When
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    // Then
    expect(screen.getByText('Email is required')).toBeInTheDocument();
    expect(mockSubmit).not.toHaveBeenCalled();
  });
});
```

---

## 後端 TDD 補充（API / Service）

```typescript
// API 層測試（Integration）
describe('POST /api/users', () => {
  it('should return 201 with created user when valid data provided', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', password: 'SecurePass123' });

    expect(response.status).toBe(201);
    expect(response.body.data).toMatchObject({ email: 'new@example.com' });
    expect(response.body.data).not.toHaveProperty('password');
  });
});
```
