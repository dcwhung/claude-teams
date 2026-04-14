---
name: sw-coding-style
description: TypeScript / React / PHP / Python naming, function length, DRY, SOLID rules. Load when writing or reviewing code in these languages, or when a style question arises.
---

# Skill：Coding Style

> 所有 Developer Agent 必須嚴格遵守。
> 違反標記為 🔴 Critical（循環依賴、any 類型）或 🟡 Warning（過度抽象、magic number）。

---

## TypeScript / React

### 命名規範

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

### TypeScript 規範

#### 類型定義

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

#### 可選鏈與空值合併

```typescript
// ✅
const name = user?.profile?.name;
const displayName = user.name ?? 'Guest';

// ❌
const name = user && user.profile && user.profile.name;
```

#### 嚴格模式規定

- `tsconfig.json` 必須啟用 `"strict": true`
- 禁止 `@ts-ignore`，如有特殊情況須加注釋說明
- 禁止 `as any`，改用 type guard 或 `as unknown as T`

---

### React 規範

#### 函數元件

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

#### Hooks 規範

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

#### 條件渲染

```typescript
// ✅
{isLoggedIn && <UserMenu />}
{isLoading ? <Spinner /> : <Content />}

// ❌ 複雜巢狀條件 — 標記為 🟡 Warning
{a && b ? (c ? <X /> : <Y />) : <Z />}
```

#### Error Boundary

```typescript
// ✅ 關鍵區域必須包 ErrorBoundary
<ErrorBoundary fallback={<ErrorFallback />}>
  <GameTable />
</ErrorBoundary>
```

---

### Import 順序

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

### 禁止循環依賴 🔴 Critical

任何形式嘅循環依賴都係嚴重問題，必須修復。

#### 違規模式

```typescript
// ❌ 模組 import 自己 alias export 嘅內容
// file: lib/packages/core/utils/helper.ts
import { someUtil } from '@project-core'; // alias 指向自己

// ❌ 透過 index.ts re-export 造成間接循環
// file: core/index.ts
export * from './moduleA';
// file: core/moduleA.ts
import { funcB } from './index'; // 間接 import 自己
```

#### 正確做法

```typescript
// ✅ 直接使用相對路徑
import { funcB } from './moduleB';

// ✅ 共用依賴提取至獨立模組
// shared/types.ts → 被 moduleA 同 moduleB 共同 import
```

#### 檢查方式

```bash
# 使用 madge 檢查循環依賴
npx madge --circular src/

# 搜尋內部 alias 引用
grep -r "from '@project-core'" lib/packages/core/
```

---

### 禁止過度抽象 🟡 Warning

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

### 禁止大量 className 覆蓋 🟡 Warning

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

### 錯誤處理

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

### 常見問題

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

**函數長度**：單一函數不超過 **50 行**（React 組件），工具函數不超過 **30 行**，超過須拆分。

---

## PHP

### 命名規範

| 類型 | 格式 | 例子 |
|------|------|------|
| Class | `PascalCase` | `UserService`, `PaymentProcessor` |
| Interface | `PascalCase` + `Interface` 後綴 | `UserRepositoryInterface` |
| Trait | `PascalCase` + `Trait` 後綴 | `TimestampableTrait` |
| 方法 / 函數 | `camelCase` | `getUserById()`, `calculateTotal()` |
| 變數 | `camelCase` | `$userName`, `$isActive` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| 私有屬性 | `camelCase`（PHP 用 visibility 控制） | `private $userId` |
| 檔案 | 同 class 名 | `UserService.php` |
| 資料夾 | `PascalCase`（PSR-4） | `Services/`, `Repositories/` |

---

### PHP 規範（PSR-12）

#### 類型宣告（PHP 8+）

```php
// ✅ 必須宣告返回類型及參數類型
public function getUserById(int $id): ?User
{
    return $this->userRepository->find($id);
}

// ✅ 使用 union type（PHP 8.0+）
public function process(int|string $id): User|null
{
    // ...
}

// ✅ 使用 named arguments（PHP 8.0+）
$user = createUser(name: 'Donald', email: 'donald@example.com');

// ❌ 禁止無類型宣告
public function getUser($id)
{
    // ...
}
```

#### Null 處理

```php
// ✅ 使用 nullsafe operator（PHP 8.0+）
$city = $user?->getAddress()?->getCity();

// ✅ 使用 match expression（PHP 8.0+）
$status = match($code) {
    200 => 'OK',
    404 => 'Not Found',
    500 => 'Server Error',
    default => 'Unknown',
};

// ❌ 避免
if ($user !== null) {
    if ($user->getAddress() !== null) {
        $city = $user->getAddress()->getCity();
    }
}
```

#### 例外處理

```php
// ✅ 使用具體 Exception 類型，唔好 catch 所有
try {
    $user = $this->userService->findOrFail($id);
} catch (UserNotFoundException $e) {
    throw new HttpException(404, $e->getMessage());
} catch (DatabaseException $e) {
    $this->logger->error('DB error', ['exception' => $e]);
    throw $e;
}

// ❌ 禁止 catch-all 吞掉錯誤
try {
    // ...
} catch (\Exception $e) {
    // 靜默失敗
}
```

#### 依賴注入

```php
// ✅ Constructor injection，唔用 static calls 或 facade
class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $userRepository,
        private readonly LoggerInterface $logger,
    ) {}
}

// ❌ 禁止
class UserService
{
    public function getUser(int $id): User
    {
        return DB::table('users')->find($id); // 直接依賴具體實現
    }
}
```

#### 陣列

```php
// ✅ 短語法
$users = ['Alice', 'Bob', 'Charlie'];

// ✅ 明確 typed array（docblock）
/** @var User[] $users */
$users = $this->userRepository->findAll();

// ✅ 使用 array functions，唔用手寫 loop
$names = array_map(fn(User $u) => $u->getName(), $users);
$active = array_filter($users, fn(User $u) => $u->isActive());
```

#### 禁止事項

```php
// ❌ 禁止 extract()
extract($data); // 污染作用域，難以追蹤

// ❌ 禁止 eval()
eval($userInput); // 安全漏洞

// ❌ 禁止 @error suppression
$result = @file_get_contents($url); // 吞掉錯誤

// ❌ 禁止 global 變數
global $db;
```

---

## Python

### 命名規範

| 類型 | 格式 | 例子 |
|------|------|------|
| 模組 / 檔案 | `snake_case` | `user_service.py` |
| Class | `PascalCase` | `UserService`, `PaymentProcessor` |
| 函數 / 方法 | `snake_case` | `get_user_by_id()`, `calculate_total()` |
| 變數 | `snake_case` | `user_name`, `is_active` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `API_BASE_URL` |
| 私有方法 / 屬性 | `_snake_case` | `_validate_input()` |
| 「真正」私有（name mangling） | `__snake_case` | `__secret_key` |
| 資料夾 / 套件 | `snake_case` | `user_profile/` |

---

### Python 規範（PEP 8 + Type Hints）

#### Type Hints（Python 3.9+）

```python
# ✅ 所有函數必須有 type hints
def get_user_by_id(user_id: int) -> User | None:
    return user_repository.find(user_id)

# ✅ 使用 dataclass 或 TypedDict 代替裸 dict
from dataclasses import dataclass

@dataclass
class UserDTO:
    id: int
    email: str
    name: str

# ✅ 複雜類型使用 type alias
from typing import TypeAlias
UserList: TypeAlias = list[User]

# ❌ 禁止無 type hints 嘅 public 函數
def get_user(id):  # 無類型
    pass
```

#### 函數設計

```python
# ✅ 使用 keyword-only arguments 提高可讀性
def create_user(*, name: str, email: str, role: str = 'user') -> User:
    ...

# ✅ 使用 @property 代替 getter / setter
class User:
    @property
    def display_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

# ❌ 避免可變預設參數
def add_item(item: str, items: list = []) -> list:  # 危險！
    items.append(item)
    return items

# ✅ 正確做法
def add_item(item: str, items: list | None = None) -> list:
    if items is None:
        items = []
    items.append(item)
    return items
```

#### 例外處理

```python
# ✅ 使用具體 Exception 類型
try:
    user = user_service.find_or_raise(user_id)
except UserNotFoundException as e:
    raise HTTPException(status_code=404, detail=str(e)) from e
except DatabaseError as e:
    logger.error("DB error", exc_info=e)
    raise

# ❌ 禁止裸 except
try:
    ...
except:  # 吞掉所有錯誤，包括 KeyboardInterrupt
    pass

# ❌ 禁止 except Exception 靜默失敗
try:
    ...
except Exception:
    pass
```

#### Context Manager

```python
# ✅ 使用 with statement 管理資源
with open('file.txt', 'r', encoding='utf-8') as f:
    content = f.read()

# ✅ 數據庫 transaction
with db.transaction():
    user = User(email=email)
    db.add(user)

# ❌ 手動管理資源
f = open('file.txt')
content = f.read()
f.close()  # 例外發生時唔會執行
```

#### List / Dict Comprehension

```python
# ✅ 簡單 comprehension
names = [user.name for user in users if user.is_active]
user_map = {user.id: user for user in users}

# ❌ 複雜巢狀 comprehension — 標記為 🟡 Warning
result = [x for xs in matrix for x in xs if x > 0 and x < 100]

# ✅ 改用普通 loop 提高可讀性
result = []
for xs in matrix:
    for x in xs:
        if 0 < x < 100:
            result.append(x)
```

#### Import 規範

```python
# 順序：標準庫 → 第三方 → 本地模組
# 每組之間空一行

# 1. 標準庫
import os
import sys
from pathlib import Path

# 2. 第三方
import fastapi
from pydantic import BaseModel

# 3. 本地模組
from app.services.user_service import UserService
from app.repositories.user_repository import UserRepository

# ✅ 使用絕對 import
from app.utils.format import format_date

# ❌ 避免 wildcard import
from app.models import *
```

#### 禁止事項

```python
# ❌ 禁止 exec() / eval()
exec(user_input)  # 安全漏洞

# ❌ 禁止 global 變數修改（函數內）
counter = 0
def increment():
    global counter  # 難以追蹤，難以測試
    counter += 1

# ✅ 改用 class 或傳參
class Counter:
    def __init__(self) -> None:
        self._count = 0

    def increment(self) -> None:
        self._count += 1

# ❌ Magic number
if status == 1:
    ...

# ✅ 命名常數
ACTIVE_STATUS = 1
if status == ACTIVE_STATUS:
    ...
```

---

## 通用規範（所有語言）

### Magic Number / String

```
❌ 直接使用數字或字串字面量
✅ 抽取為命名常數，放係模組頂部或常數檔案
```

### 函數長度

| 語言 | 最大行數 |
|------|---------|
| TypeScript / React 組件 | 50 行 |
| TypeScript 工具函數 | 30 行 |
| PHP 方法 | 30 行 |
| Python 函數 | 30 行 |

超過須拆分，每個函數只做一件事。

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
