---
name: sw-ci-cd
description: Pipeline stages, environment variable management, blocking conditions, rollback procedures. Load before /deploy, when configuring a new environment, troubleshooting a failed deploy, or whenever the user mentions CI, CD, GitHub Actions, pipelines, staging, production deploy, env vars, secrets, or rollback. Also load when a deploy is about to happen and there's no pipeline config yet.
---

# Skill：CI/CD

> 持續整合及持續部署標準流程。

---

## Pipeline 標準架構

```
觸發（PR opened / merge to main）
  │
  ├─ 🔍 Lint & Type Check
  │     └─ ESLint、TypeScript、Prettier check
  │
  ├─ 🧪 Unit Tests
  │     └─ 覆蓋率報告
  │
  ├─ 🔗 Integration Tests
  │     └─ 需要 test DB / mock services
  │
  ├─ 🏗️  Build
  │     └─ 確認 build artifact 正常生成
  │
  ├─ 🔒 Security Scan
  │     └─ 依賴漏洞掃描（Snyk / Dependabot）
  │     └─ SAST 靜態代碼分析
  │
  ├─ 🚀 Deploy to Staging
  │     └─ 自動（merge to staging branch）
  │
  ├─ 🎭 E2E Tests（Staging）
  │     └─ 核心 user journey 測試
  │
  ├─ 👍 Manual Approval（Production only）
  │     └─ 需要明確授權先可以繼續
  │
  ├─ 🚀 Deploy to Production
  │     └─ 自動執行（獲授權後）
  │
  ├─ 💨 Smoke Test（Production）
  │     └─ 關鍵 endpoint 健康檢查
  │
  └─ 📣 通知
        └─ 成功 / 失敗通知（Slack / Email）
```

---

## 各階段阻止條件

任何階段失敗，Pipeline 立即停止：

| 階段 | 阻止條件 |
|------|----------|
| Lint & Type Check | 任何 ESLint error 或 TypeScript error |
| Unit Tests | 任何測試失敗 |
| Integration Tests | 任何測試失敗 |
| Build | Build 失敗或警告升級為錯誤 |
| Security Scan | 發現 Critical 或 High 漏洞 |
| E2E Tests | 核心 user journey 測試失敗 |
| Smoke Test | 關鍵 endpoint 無響應或返回錯誤 |

---

## GitHub Actions 標準模板

### PR Validation（`pr.yml`）

```yaml
name: PR Validation

on:
  pull_request:
    branches: [main, staging]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run type-check

      - name: Unit tests
        run: npm run test:unit -- --coverage

      - name: Integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

      - name: Build
        run: npm run build

      - name: Security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Deploy to Staging（`deploy-staging.yml`）

```yaml
name: Deploy to Staging

on:
  push:
    branches: [staging]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        run: |
          # 視乎平台（Vercel / Railway / AWS 等）調整
          npm run deploy:staging
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}

      - name: E2E Tests
        run: npm run test:e2e
        env:
          BASE_URL: ${{ vars.STAGING_URL }}

      - name: Notify success
        if: success()
        run: echo "Staging deployment successful"

      - name: Notify failure
        if: failure()
        run: echo "Staging deployment failed"
```

### Deploy to Production（`deploy-production.yml`）

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production    # 需要 GitHub Environment 保護規則
    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        run: npm run deploy:production
        env:
          DEPLOY_TOKEN: ${{ secrets.PRODUCTION_DEPLOY_TOKEN }}

      - name: Smoke test
        run: npm run test:smoke
        env:
          BASE_URL: ${{ vars.PRODUCTION_URL }}

      - name: Notify
        if: always()
        run: |
          if [ "${{ job.status }}" == "success" ]; then
            echo "Production deployment successful"
          else
            echo "Production deployment FAILED - consider rollback"
          fi
```

---

## 環境變數管理

### 分層原則

```
代碼倉庫（公開）
  └─ .env.example          ← 列出所有需要嘅變數，值為空或示例值

本地開發
  └─ .env.local            ← gitignore，開發者自行填寫

CI/CD
  └─ GitHub Secrets        ← 敏感值（token、密碼、key）
  └─ GitHub Variables      ← 非敏感配置（URL、port、feature flag）

生產環境
  └─ Secret Manager        ← AWS SSM / GCP Secret Manager 等
```

### `.env.example` 格式

```bash
# 數據庫
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# 認證
JWT_SECRET=your-secret-here
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d

# 外部服務
STRIPE_SECRET_KEY=sk_test_...
SENDGRID_API_KEY=SG....

# 應用配置
APP_PORT=3000
APP_ENV=development
```

---

## 回滾流程

### 觸發條件

```
- Smoke test 失敗
- 生產環境錯誤率急升（> 1%）
- 關鍵功能無法使用
- 數據異常
```

### 回滾步驟

```bash
# 1. 確認上一個穩定版本
git log --oneline -10

# 2. Revert commit（保留 history）
git revert HEAD --no-edit
git push origin main

# 3. 或直接 deploy 上一個 tag
git checkout v1.2.3
# 觸發 deploy pipeline

# 4. 驗證回滾成功
npm run test:smoke
```

---

## 監控指標（部署後必須確認）

```
□ Error rate < 0.1%
□ P95 response time < 500ms
□ 關鍵 endpoint 正常響應
□ DB connection pool 正常
□ 記憶體使用率正常
□ 無異常 log 輸出
```
