---
name: sw-coding-style-ts
description: TypeScript / React naming, types, hooks, imports, circular dependency, and anti-pattern rules. Load when writing or reviewing TypeScript / React code.
---

# Skill：Coding Style — TypeScript / React

> 違反標記為 🔴 Critical（循環依賴、any 類型）或 🟡 Warning（過度抽象、magic number）。
> 通用規範（函數長度、magic number、注釋）見 `skills/coding-style.md`。

---

## 命名規範

| 類型 | 格式 | 例子 |
|------|------|------|
| 元件 | `PascalCase` | `UserProfile`, `GameCard` |
| 函數 / 變數 | `camelCase` | `getUserInfo`, `isLoading` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `API_URL` |
| 類型 / 介面 | `PascalCase`，`I/T` 前綴可選 | `UserProps`, `IGameState` |
| 元件檔案 | `PascalCase.tsx` | `UserProfile.tsx` |
| 工具函數檔案 | `camelCase.ts` | `formatDate.ts` |
| 資料夾 | `kebab-case` | `user-profile/` |
| Hook | `use` 開頭 | `useAuth()`, `useFormState()` |
| 事件處理函數 | `handle` 開頭 | `handleSubmit()`, `handleInputChange()` |
| 布林值 | `is` / `has` / `can` 開頭 | `isLoading`, `hasError`, `canEdit` |
| 私有 class 屬性 | `_camelCase` | `_userId`, `_cache` |

---

## TypeScript 規範

### 類型定義

```typescript
// ✅ 優先使用 interface
interface UserProps {
  name: string;
  age: number;
}

// ✅ 使用 type 於聯合類型
type Status = 'idle' | 'loading' | 'success' | 'error';

// ❌ 嚴禁 any — 標記為 🔴 Critical
const data: any = fetchData();

// ✅ 改用 unknown 並做類型收窄
const data: unknown = fetchData();
if (isUserData(data)) {
  // 安全使用 data
}
```

### 可選鏈與空值合併

```typescript
// ✅
const name = user?.profile?.name;
const displayName = user.name ?? 'Guest';

// ❌
const name = user && user.profile && user.profile.name;
```

### 嚴格模式規定

- `tsconfig.json` 必須啟用 `"strict": true`
- 禁止 `@ts-ignore`，如有特殊情況須加注釋說明
- 禁止 `as any`，改用 type guard 或 `as unknown as T`

---

## React 規範

### 函數元件

```typescript
// ✅ 箭頭函數 + 明確 Props 類型
const UserCard: React.FC<UserCardProps> = ({ name, avatar }) => {
  return (
    <div className="user-card">
      <img src={avatar} alt={name} />
      <span>{name}</span>
    </div>
  );
};

// ✅ 或函數宣告形式
function UserCard({ name, avatar }: UserCardProps) {
  return (/* ... */);
}
```

### Hooks 規範

```typescript
// ✅ 依賴陣列必須完整
useEffect(() => {
  fetchUser(userId);
}, [userId, fetchUser]);

// ❌ 缺少依賴 — 標記為 🟡 Warning
useEffect(() => {
  fetchUser(userId);
}, []); // eslint-disable-line

// ✅ useCallback 避免不必要 re-render
const handleClick = useCallback(() => {
  setCount((c) => c + 1);
}, []);
```

### 條件渲染

```typescript
// ✅
{isLoggedIn && <UserMenu />}
{isLoading ? <Spinner /> : <Content />}

// ❌ 複雜巢狀條件 — 標記為 🟡 Warning
{a && b ? (c ? <X /> : <Y />) : <Z />}
```

### Error Boundary

```typescript
// ✅ 關鍵區域必須包 ErrorBoundary
<ErrorBoundary fallback={<ErrorFallback />}>
  <GameTable />
</ErrorBoundary>
```

---

## Import 順序

```typescript
// 1. React
import React, { useState, useEffect } from 'react';

// 2. 第三方套件
import { observer } from 'mobx-react-lite';
import classNames from 'classnames';

// 3. 項目模組（絕對路徑 / alias）
import { useStore } from '@/stores';
import { formatDate } from '@/utils';

// 4. 相對路徑
import { UserCard } from './components';
import { useUserData } from './hooks';

// 5. 樣式
import styles from './User.module.scss';

// 6. 類型（type-only import）
import type { UserProps } from './types';
```

每組之間空一行，禁止混合排列。

---

## 禁止循環依賴 🔴 Critical

任何形式嘅循環依賴都係嚴重問題，必須修復。

### 違規模式

```typescript
// ❌ 模組 import 自己 alias export 嘅內容
import { someUtil } from '@project-core'; // alias 指向自己

// ❌ 透過 index.ts re-export 造成間接循環
// core/index.ts: export * from './moduleA';
// core/moduleA.ts: import { funcB } from './index';
```

### 正確做法

```typescript
// ✅ 直接使用相對路徑
import { funcB } from './moduleB';

// ✅ 共用依賴提取至獨立模組
// shared/types.ts → 被 moduleA 同 moduleB 共同 import
```

### 檢查方式

```bash
npx madge --circular src/
grep -r "from '@project-core'" lib/packages/core/
```

---

## 禁止過度抽象 🟡 Warning

```typescript
// ❌ 不必要嘅抽象層疊加
const myFunc = withLogger(withValidator(withCache(actualFunc)));

// ✅ 直接明確嘅實作
function myFunc(...args) {
  console.log('calling');
  validate(args);
  // 直接邏輯
}
```

---

## 禁止大量 className 覆蓋 🟡 Warning

```typescript
// ❌ 大量覆蓋 + !important
<Button className="override-padding override-margin override-color" />

// ✅ 使用元件 props
<Button size="small" variant="primary" />

// ✅ 建立新元件變體
const PrimaryButton: React.FC<ButtonProps> = (props) => (
  <Button {...props} className={styles.primaryButton} />
);
```

**判斷標準**：
- className 覆蓋超過 3 個屬性 → 建立新元件
- 使用 `!important` → 必須加注釋說明原因
- 覆蓋第三方元件內部 class → 改用官方 API 或主題配置

---

## 錯誤處理

```typescript
// ✅ 捕捉具體錯誤類型
async function fetchUser(id: string) {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data;
  } catch (error) {
    if (error instanceof ApiError) {
      logger.error('API Error:', error.code);
    }
    throw error;
  }
}
```

---

## 常見問題

```typescript
// ❌ Magic number
if (status === 1) { }

// ✅ 命名常數或 enum
const STATUS = { ACTIVE: 1, INACTIVE: 0 } as const;
if (status === STATUS.ACTIVE) { }

// ❌ 未使用變數
const { unused, ...rest } = props;

// ✅ 底線標記有意忽略
const { _unused, ...rest } = props;

// ❌ console.log 喺生產代碼
console.log('debug');

// ✅ 使用項目 logger
logger.debug('debug info');
```
