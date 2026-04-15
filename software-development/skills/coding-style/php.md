---
name: sw-coding-style-php
description: PHP naming, PSR-12, type declarations, null handling, DI, and anti-pattern rules. Load when writing or reviewing PHP code.
---

# Skill：Coding Style — PHP

> 違反標記為 🔴 Critical 或 🟡 Warning。
> 通用規範（函數長度、magic number、注釋）見 `skills/coding-style.md`。

---

## 命名規範

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

## PHP 規範（PSR-12）

### 類型宣告（PHP 8+）

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

### Null 處理

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

### 例外處理

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

### 依賴注入

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

### 陣列

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

### 禁止事項

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
