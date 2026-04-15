---
name: sw-coding-style-py
description: Python naming, PEP 8, type hints, exception handling, context managers, and anti-pattern rules. Load when writing or reviewing Python code.
---

# Skill：Coding Style — Python

> 違反標記為 🔴 Critical 或 🟡 Warning。
> 通用規範（函數長度、magic number、注釋）見 `skills/coding-style.md`。

---

## 命名規範

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

## Python 規範（PEP 8 + Type Hints）

### Type Hints（Python 3.9+）

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

### 函數設計

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

### 例外處理

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

### Context Manager

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

### List / Dict Comprehension

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

### Import 規範

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

### 禁止事項

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
