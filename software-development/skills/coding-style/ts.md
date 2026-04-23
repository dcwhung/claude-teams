---
name: sw-coding-style-ts
description: TypeScript / React naming, types, hooks, folder structure, i18n, state management, and anti-pattern rules. Load when writing or reviewing TypeScript / React code.
---

# Skill：Coding Style — TypeScript / React

> 違反標記為 🔴 Critical（循環依賴、`any`、magic value）或 🟡 Warning（過度抽象、函數過長）。
> 通用規範（注釋、review 標準）見 `skills/coding-style.md`。

---

## 命名規範

| 類型 | 格式 | 例子 |
|------|------|------|
| 元件 | `PascalCase` | `UserProfile`, `GameCard` |
| 函數 / 變數 | `camelCase` | `getUserInfo`, `isLoading` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `API_URL` |
| 類型 / 介面 | `PascalCase` | `UserProps`, `GameState` |
| 元件檔案 | `PascalCase.tsx` | `UserProfile.tsx` |
| 工具函數檔案 | `camelCase.ts` | `formatDate.ts` |
| 資料夾 | `kebab-case` | `user-profile/` |
| Hook | `use` 開頭 | `useAuth()`, `useFormState()` |
| 事件處理函數 | `handle` 開頭 | `handleSubmit()`, `handleInputChange()` |
| 布林值 | `is` / `has` / `can` 開頭 | `isLoading`, `hasError`, `canEdit` |

---

## React Folder Structure（基礎）

```text
src/
  app/
  assets/
  atomic-design/
    atoms/
    molecules/
    organisms/
    templates/
    pages/
  components/
  context/
  features/
    {feature_name}/
      components/
      hooks/
      interfaces/
      types/
      constants/
      services/
      stores/
      utils/
      styles/
      context/
  hooks/
  i18n/
    locales/
      en.json
      zh.json
  interfaces/
  services/
  stores/
  types/
  utils/
```

### 結構落位規則

| 類別 | 放置位置 |
|------|----------|
| Atomic components | `atomic-design/`（`atoms/`, `molecules/`, `organisms/`, `templates/`, `pages/`） |
| Common components | `components/` |
| Feature components | `features/{feature_name}/components/` |
| 全域 interfaces | `interfaces/` |
| 全域 constants | `utils/constants/` 或獨立 `constants/`（按專案） |
| Feature 專屬 interfaces/constants | `features/{feature_name}/interfaces/`、`features/{feature_name}/constants/` |
| 全域 Context | `context/` |
| Feature Context | `features/{feature_name}/context/` |

### Constants 命名與分層規範

| 類別 | 用途 | 建議路徑 | 檔名規範 | 例子 |
|------|------|----------|----------|------|
| domain constants | 業務語意、枚舉、狀態碼 | `src/constants/domain/` | `{domain}.constants.ts` | `entry.constants.ts`, `order.constants.ts` |
| ui constants | UI 尺寸、z-index、breakpoints、呈現層設定 | `src/constants/ui/` | `{scope}.constants.ts` | `layout.constants.ts`, `modal.constants.ts` |
| api constants | API 路徑、timeout、query key、header key | `src/constants/api/` | `{service}.constants.ts` | `user-api.constants.ts`, `http.constants.ts` |

| 命名層級 | 規範 |
|----------|------|
| constant key | 一律 `UPPER_SNAKE_CASE`（例如 `ENTRY_TYPE`, `DEFAULT_TIMEOUT_MS`） |
| 常數集合命名 | 使用領域語意（例如 `API_ENDPOINTS`, `UI_BREAKPOINTS`） |
| 禁止事項 | 禁止在 component 內定義跨模組常數；禁止直接使用 magic string / magic number |

---

## 檔案拆分與行數規範

| 規則 | 要求 |
|------|------|
| `interface` 拆分 | `interface` 必須放獨立檔案，禁止同 component 同檔 |
| `constants` 拆分 | 常數必須放獨立檔案，禁止同 component 同檔 |
| 一檔一元件 | 每個 `.tsx` 檔案只允許一個 component |
| component 行數上限 | 每個 component 檔案最多 150 行，超過必須拆分 |
| CSS 拆分 | 每個 component 必須有對應樣式檔，禁止多個 component 共用同一個 component-level CSS 檔 |

---

## TypeScript 規範

### 類型定義

```typescript
// ✅ 優先使用 interface
export interface UserProps {
  name: string;
  age: number;
}

// ✅ type 用於映射、聯合、工具型別
export type UserStatus = 'idle' | 'loading' | 'success' | 'error';

// ❌ 嚴禁 any（🔴 Critical）
const data: any = fetchData();

// ✅ 改用 unknown 並做收窄
const data: unknown = fetchData();
if (isUserData(data)) {
  // safe usage
}
```

### 嚴格模式

- `tsconfig.json` 必須啟用 `"strict": true`
- 禁止 `@ts-ignore`，如必須使用要有理由註解
- 禁止 `as any`，改用 type guard 或 `unknown` 收窄

---

## React 實作規範

### Arrow Function 優先

```typescript
// ✅ component 用 arrow function
const UserCard = ({ name, avatar }: UserCardProps) => {
  return (
    <div>
      <img src={avatar} alt={name} />
      <span>{name}</span>
    </div>
  );
};

// ✅ handlers/helpers 同樣用 arrow function
const handleClick = () => {
  // ...
};
```

### Hooks 規範

```typescript
useEffect(() => {
  fetchUser(userId);
}, [userId, fetchUser]);
```

- 依賴陣列必須完整
- `useMemo` / `useCallback` 用於有明確 re-render 成本場景

### 條件渲染

```typescript
{isLoggedIn && <UserMenu />}
{isLoading ? <Spinner /> : <Content />}
```

禁止多層巢狀 ternary；超過一層需拆 helper variable 或子元件。

---

## Tailwind CSS 規範

| 規則 | 要求 |
|------|------|
| CSS Framework | 必須使用 Tailwind CSS |
| class 使用方式 | 優先 utility-first class 組合 |
| 自定樣式 | 只在必要時建立 component 專屬 CSS/module 檔案 |
| 禁止事項 | 禁止大量 inline style 取代 Tailwind；禁止無命名規則的散落自定義 class |

---

## i18n 規範（專案支援多語言時必須）

### 基本要求

| 規則 | 要求 |
|------|------|
| i18n Hook | 必須用 `useTranslation`（`react-i18next`） |
| 語系檔格式 | 每種語言一個 JSON 檔，`i18n/locales/` 目錄下 |
| 初始化檔 | `i18n/index.ts` 只做 i18next init + 匯出 instance；禁止在此定義任何 interface 或手動 key mapping |

### JSON Key 結構規範

**必須使用 nested namespace 結構**，禁止單層平鋪：

```json
// ✅ 正確：依功能分組，dot-notation 存取
{
  "add": {
    "heading": "加入新日子",
    "name_placeholder": {
      "birth": "例如：小明"
    }
  },
  "filter": {
    "all": "全部",
    "search_placeholder": "搜尋…"
  }
}

// ❌ 錯誤：所有 key 放 top-level
{
  "add_heading": "加入新日子",
  "name_ph_birth": "例如：小明",
  "filter_all": "全部",
  "search_ph": "搜尋…"
}
```

**標準 Namespace 分組**：

| Namespace | 用途 |
|-----------|------|
| `app` | 應用標題、tagline、loading、語言切換 |
| `entries` | 已儲存列表標題、空狀態、刪除確認 |
| `add` | 新增表單所有 label、placeholder、按鈕 |
| `filter` | 篩選按鈕、搜尋、空結果、結果數量 |
| `timeline` | 時間軸標頭、today/past/upcoming |
| `person` | 人物全部/未命名 |
| `entry_type` | 各種 entry 類型名稱 |
| `calendar` | 月份名稱陣列、weekday 縮寫 |
| `actions` | 下載、工具按鈕 |

### Key 命名規則

| 規則 | 說明 | 範例 |
|------|------|------|
| `snake_case` | 所有 key 使用 snake_case | `search_placeholder` ✅，`searchPh` ❌ |
| 不縮寫 | 不用 `_ph_`、`_btn`（btn 除外）、`_dd_` | `name_placeholder` ✅，`name_ph` ❌ |
| 動詞前綴 | 動作類 key 用動詞開頭 | `confirm_delete`，`download_ics` |
| 狀態描述 | 狀態 key 用名詞或形容詞 | `empty`，`no_results`，`heading` |

### 複數（Pluralization）

使用 i18next count interpolation，禁止用 function property：

```json
// zh.json — 無語法複數，單一 key
"filter": { "results_count": "{{count}} 個紀念日" }

// en.json — 必須提供 _one + _other
"filter": {
  "results_count_one": "{{count}} milestone",
  "results_count_other": "{{count}} milestones"
}
```

```tsx
// ✅ 正確
const label = t('filter.results_count', { count: n })

// ❌ 錯誤：function property
results_count: (n: number) => `${n} milestone${n === 1 ? '' : 's'}`
```

### 動態 Key（同類型 key 批量存取）

```tsx
// ✅ 正確：namespace prefix + 變數 suffix
const label = t(`entry_type.${type}`)           // type = 'birth' | 'dating' | 'wedding'
const placeholder = t(`add.name_placeholder.${type}`)
const weekday = t(`calendar.weekday.${dowKey}`) // dowKey = 'sun' | 'mon' | ...

// ❌ 錯誤：直接用 type 值作為 top-level key
const label = t(type)                           // 無 namespace，無法追蹤
```

### returnObjects（陣列取用）

```tsx
// ✅ 正確：nested path + returnObjects
const months = t('calendar.months', { returnObjects: true }) as string[]

// ❌ 錯誤：top-level key
const months = t('months', { returnObjects: true }) as string[]
```

### 測試 Pattern

```tsx
// ✅ 正確：直接 import JSON 取值，用 nestedLookup mock
import zh from '../../src/i18n/locales/zh.json'
screen.getByPlaceholderText(zh.add.name_placeholder.birth)
screen.getByText(zh.filter.all)

// ❌ 錯誤：import 手動 mapping 物件（legacy I18N pattern）
import { I18N } from '../../src/i18n'
const t = I18N['ZH']
screen.getByPlaceholderText(t.name_ph_birth)
```

`test-setup.ts` 的 mock 必須支援 nested key lookup：

```typescript
function nestedLookup(obj: Record<string, unknown>, key: string) {
    return key.split('.').reduce<unknown>((node, part) => {
        if (typeof node === 'object' && node !== null)
            return (node as Record<string, unknown>)[part]
        return undefined
    }, obj)
}
```

### 禁止事項

| 禁止 | 原因 |
|------|------|
| 在 `i18n/index.ts` 定義 `I18nStrings` interface | 每加一個 key 需改三處，線性膨脹 |
| 手動維護 `ZH`/`EN` mapping 物件 | 同上，且與 JSON 重複 |
| Top-level flat JSON key | 無法分組，key 命名衝突風險高 |
| 縮寫 key（`_ph_`、`_dd_`） | 可讀性差，新成員難以理解 |
| function property 作複數邏輯 | 違反 i18next 標準，無法切換 locale |

```tsx
// ✅ 完整範例
import { useTranslation } from 'react-i18next'

export function AddCard() {
    const { t } = useTranslation()
    return (
        <div>
            <h2>{t('add.heading')}</h2>
            <input placeholder={t(`add.name_placeholder.${type}`)} />
            <button>{t('add.btn')}</button>
        </div>
    )
}
```

---

## State Management 與 Context 規範

### Store 優先級

| 情境 | 選型 |
|------|------|
| 一般全域/feature 狀態 | `Zustand`（第一優先） |
| 需要 Redux 生態（時間旅行、複雜 middleware、既有 Redux 基建） | `Redux`（第二優先） |

### Context Provider

| 規則 | 要求 |
|------|------|
| 目的 | 管理跨層共享依賴（theme、auth、i18n、service instance、feature flags） |
| 原則 | 高頻業務 state 優先放 store（Zustand/Redux），Context 不作主要高頻 state 容器 |
| 拆分方式 | Provider 單一職責，避免 Mega Provider |
| 掛載位置 | 在 app root 組合 provider，避免 page-level 重覆包裝 |

```tsx
<ThemeProvider>
  <AuthProvider>
    <I18nextProvider i18n={i18n}>
      <App />
    </I18nextProvider>
  </AuthProvider>
</ThemeProvider>
```

---

## Magic Value 禁止規範 🔴 Critical

### 禁止 magic string / magic number

```typescript
// ❌
if (status === 1) {
  // ...
}

// ✅
export const STATUS = {
  ACTIVE: 1,
  INACTIVE: 0,
} as const;

if (status === STATUS.ACTIVE) {
  // ...
}
```

### Compare type 禁止字面量比較

```typescript
// ❌
export type EntryType = 'birth' | 'dating' | 'wedding';
if (entryType === 'birth') {
  // ...
}

// ✅
export const ENTRY_TYPE = {
  BIRTH: 'birth',
  DATING: 'dating',
  WEDDING: 'wedding',
} as const;

export type EntryType = (typeof ENTRY_TYPE)[keyof typeof ENTRY_TYPE];

if (entryType === ENTRY_TYPE.BIRTH) {
  // ...
}
```

---

## Import 順序

```typescript
// 1. React
import { useEffect } from 'react';

// 2. 第三方套件
import { useTranslation } from 'react-i18next';

// 3. 項目模組（alias）
import { useUserStore } from '@/stores/userStore';
import { ENTRY_TYPE } from '@/constants/entryType';

// 4. 相對路徑
import { UserMeta } from './UserMeta';

// 5. 樣式
import styles from './UserCard.module.css';

// 6. type-only import
import type { UserCardProps } from '@/interfaces/user';
```

每組之間空一行，禁止混排。

---

## 禁止循環依賴 🔴 Critical

- 任何直接或間接循環依賴都必須修復
- 共用型別/常數請抽到獨立 shared 模組

檢查命令：

```bash
npx madge --circular src/
```

---

## 禁止過度抽象 🟡 Warning

```typescript
// ❌
const myFunc = withLogger(withValidator(withCache(actualFunc)));

// ✅
const myFunc = (...args: FuncArgs) => {
  validate(args);
  return actualFunc(args);
};
```

---

## 錯誤處理

```typescript
const fetchUser = async (id: string) => {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data;
  } catch (error: unknown) {
    if (error instanceof ApiError) {
      logger.error('API Error', { code: error.code, userId: id });
    }
    throw error;
  }
};
```
