# STORY-001: Technical Analysis

**Investment Management System**  
**Created**: 2026-03-31  
**Architect**: Technical Planning Specialist  
**Status**: Ready for TechLead Execution

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Database Design](#2-database-design)
3. [API Design](#3-api-design)
4. [Frontend Architecture](#4-frontend-architecture)
5. [External API Integration](#5-external-api-integration)
6. [Security Architecture](#6-security-architecture)
7. [Caching Strategy](#7-caching-strategy)
8. [Performance Considerations](#8-performance-considerations)
9. [Task Decomposition](#9-task-decomposition)
10. [Execution Plan](#10-execution-plan)
11. [Risk Mitigation](#11-risk-mitigation)

---

## 1. Architecture Overview

### 1.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DOCKER COMPOSE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         NGINX (Reverse Proxy)                        │   │
│  │  • Port: 80/443                                                      │   │
│  │  • SSL Termination                                                   │   │
│  │  • Static file serving (frontend)                                    │   │
│  │  • API routing: /api/* → backend:3000                               │   │
│  │  • Rate limiting                                                     │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│          ┌───────────────────────┴───────────────────────┐                  │
│          │                                               │                  │
│          ▼                                               ▼                  │
│  ┌───────────────────────┐                    ┌───────────────────────┐   │
│  │   FRONTEND (React)    │                    │   BACKEND (Node.js)   │   │
│  │  • Port: 5173 (dev)   │                    │  • Port: 3000         │   │
│  │  • Vite + PWA         │                    │  • Express + TS       │   │
│  │  • TanStack Query     │                    │  • JWT Auth           │   │
│  │  • Zustand            │                    │  • OAuth 2.0          │   │
│  │  • Tailwind CSS       │                    │  • REST API           │   │
│  └───────────────────────┘                    └───────────┬───────────┘   │
│                                                            │               │
│                                    ┌───────────────────────┴───────────┐   │
│                                    │                                   │   │
│                                    ▼                                   ▼   │
│                          ┌─────────────────────┐         ┌─────────────────┐
│                          │   MONGODB           │         │   REDIS         │
│                          │  • Port: 27017      │         │  • Port: 6379   │
│                          │  • No auth (local)  │         │  • API Cache    │
│                          │  • Collections:      │         │  • Sessions     │
│                          │    - users           │         │  • Rate Limits  │
│                          │    - portfolios      │         └─────────────────┘
│                          │    - transactions    │
│                          │    - assets          │
│                          │    - dividends       │
│                          │    - audit_logs      │
│                          └─────────────────────┘
│
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ External APIs
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL API LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   BRAPI     │  │   Yahoo     │  │  CoinGecko  │  │  Banco Central      │ │
│  │  (Primary)  │  │  Finance    │  │  + Binance  │  │  (CDI/IPCA/PTAX)    │ │
│  │  B3 Stocks  │  │  (Fallback) │  │  (Crypto)   │  │  (Economic Ind.)    │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Frontend** | React | 18.x | UI Framework |
| | TypeScript | 5.x | Type Safety |
| | Vite | 5.x | Build Tool + PWA |
| | TanStack Query | 5.x | Server State Management |
| | Zustand | 4.x | Client State Management |
| | Tailwind CSS | 3.x | Styling |
| | Headless UI | 1.x | Accessible Components |
| | Recharts | 2.x | Static Charts |
| | Lightweight Charts | 4.x | Real-time Charts |
| **Backend** | Node.js | 20.x LTS | Runtime |
| | Express | 4.x | Web Framework |
| | TypeScript | 5.x | Type Safety |
| | JWT | - | Authentication |
| | Passport.js | - | OAuth 2.0 |
| **Database** | MongoDB | 7.x | Document Store |
| **Cache** | Redis | 7.x | Caching + Sessions |
| **Infrastructure** | Docker | 24.x | Containerization |
| | Nginx | 1.25 | Reverse Proxy |
| | Docker Compose | 2.x | Orchestration |

### 1.3 Language Detection

| Indicator | Detected | Language |
|-----------|----------|----------|
| `package.json` | Required | **Node.js** |
| `tsconfig.json` | Required | TypeScript |
| `.eslintrc` | Required | Node.js |

**Primary Language**: Node.js (TypeScript)  
**Frontend Framework**: React (detected from story requirements)

### 1.4 Frontend-Backend Integration Pattern

**Pattern**: Node.js SPA Mode

| Aspect | Implementation |
|--------|----------------|
| **API Client** | Axios + shared TypeScript interfaces |
| **Repository** | Single monorepo |
| **Development** | Vite dev server + proxy to Express |
| **Deployment** | Nginx serves static frontend, proxies API |
| **Auth** | JWT in httpOnly cookies |
| **Type Sharing** | Shared types package in monorepo |

---

## 2. Database Design

### 2.1 MongoDB Collections

#### Collection: `users`

```javascript
{
  _id: ObjectId,
  email: String,              // unique, indexed
  passwordHash: String,        // bcrypt hash (nullable for OAuth users)
  googleId: String,           // Google OAuth ID (nullable)
  name: String,
  avatar: String,             // URL to avatar image
  preferences: {
    theme: String,            // 'light' | 'dark'
    language: String,         // 'pt-BR'
    currency: String          // 'BRL'
  },
  createdAt: Date,
  updatedAt: Date,
  lastLoginAt: Date,
  isActive: Boolean,
  isDeleted: Boolean          // Soft delete
}

// Indexes
{ email: 1 }                  // unique
{ googleId: 1 }               // sparse, unique
{ isDeleted: 1 }
```

#### Collection: `portfolios`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,            // indexed, ref: users
  name: String,                // unique per user
  description: String,
  isDefault: Boolean,
  currency: String,            // 'BRL' | 'USD'
  dashboardLayout: {           // Widget positions
    widgets: [{
      id: String,
      type: String,
      position: { x: Number, y: Number, w: Number, h: Number }
    }]
  },
  createdAt: Date,
  updatedAt: Date,
  isDeleted: Boolean
}

// Indexes
{ userId: 1, name: 1 }         // unique compound
{ userId: 1, isDeleted: 1 }
```

#### Collection: `transactions`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,            // indexed, ref: users
  portfolioId: ObjectId,       // indexed, ref: portfolios
  assetId: ObjectId,           // ref: assets
  type: String,                // 'BUY' | 'SELL'
  assetType: String,           // 'STOCK' | 'CRYPTO' | 'FIXED_INCOME'
  quantity: Number,           // Decimal128
  price: Number,              // Decimal128 (price per unit)
  totalValue: Number,         // Decimal128 (quantity * price)
  fees: Number,               // Decimal128
  currency: String,            // 'BRL' | 'USD'
  exchangeRate: Number,        // USD to BRL rate (if applicable)
  date: Date,                  // Transaction date
  broker: String,              // Broker name
  notes: String,
  createdAt: Date,
  updatedAt: Date,
  isDeleted: Boolean,
  auditLog: [{                 // Change history
    action: String,            // 'CREATE' | 'UPDATE' | 'DELETE'
    timestamp: Date,
    changes: Object,
    userId: ObjectId
  }]
}

// Indexes
{ userId: 1, portfolioId: 1 }
{ userId: 1, date: -1 }
{ assetId: 1 }
{ portfolioId: 1, assetId: 1 }
```

#### Collection: `assets`

```javascript
{
  _id: ObjectId,
  symbol: String,              // 'PETR4', 'BTC', 'AAPL'
  name: String,
  type: String,                // 'STOCK_BR' | 'STOCK_US' | 'CRYPTO' | 'FIXED_INCOME'
  exchange: String,            // 'B3' | 'NASDAQ' | 'BINANCE'
  currency: String,            // 'BRL' | 'USD'
  sector: String,
  industry: String,
  logo: String,                // URL to logo
  isActive: Boolean,
  lastPriceUpdate: Date,
  currentPrice: Number,        // Decimal128
  previousClose: Number,       // Decimal128
  priceChange: Number,
  priceChangePercent: Number,
  marketCap: Number,
  metadata: {                  // Type-specific data
    // For FIXED_INCOME
    indexType: String,         // 'CDI' | 'IPCA' | 'PREFIXADO'
    rate: Number,              // Rate over index
    maturityDate: Date,
    // For CRYPTO
    coingeckoId: String,
    binanceSymbol: String
  }
}

// Indexes
{ symbol: 1, type: 1 }         // unique compound
{ type: 1, isActive: 1 }
```

#### Collection: `positions`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,            // indexed
  portfolioId: ObjectId,       // indexed
  assetId: ObjectId,           // indexed
  quantity: Number,           // Decimal128
  averagePrice: Number,        // Decimal128
  totalInvested: Number,       // Decimal128 (including fees)
  totalFees: Number,           // Decimal128
  currency: String,
  currentValue: Number,        // Decimal128 (quantity * currentPrice)
  gainLoss: Number,            // Decimal128
  gainLossPercent: Number,
  lastCalculated: Date,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ userId: 1, portfolioId: 1, assetId: 1 }  // unique compound
{ portfolioId: 1 }
```

#### Collection: `dividends`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  portfolioId: ObjectId,
  assetId: ObjectId,
  type: String,                // 'DIVIDENDO' | 'JCP'
  valuePerShare: Number,       // Decimal128
  totalValue: Number,          // Decimal128
  quantity: Number,            // Shares entitled
  exDate: Date,                // Ex-dividend date
  paymentDate: Date,
  currency: String,
  isReinvested: Boolean,
  createdAt: Date,
  isDeleted: Boolean
}

// Indexes
{ userId: 1, portfolioId: 1, paymentDate: -1 }
{ assetId: 1, exDate: -1 }
```

#### Collection: `corporate_events`

```javascript
{
  _id: ObjectId,
  assetId: ObjectId,
  type: String,                // 'SPLIT' | 'GRUPAMENTO' | 'BONUS' | 'MERGER'
  date: Date,
  factor: Number,              // e.g., 2 for 2:1 split
  description: String,
  isApplied: Boolean,
  appliedAt: Date,
  appliedBy: ObjectId,         // userId
  createdAt: Date
}

// Indexes
{ assetId: 1, date: -1 }
```

#### Collection: `economic_indicators`

```javascript
{
  _id: ObjectId,
  code: String,                // 'CDI' | 'IPCA' | 'SELIC' | 'PTAX'
  date: Date,                  // Date of the rate
  value: Number,               // Decimal128
  source: String,              // 'BANCO_CENTRAL'
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ code: 1, date: -1 }          // unique compound
```

#### Collection: `import_templates`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  name: String,                // Template name
  broker: String,              // Broker name
  type: String,                // 'CSV' | 'PDF'
  fieldMapping: {              // Column/field mappings
    date: String,
    type: String,
    symbol: String,
    quantity: String,
    price: String,
    fees: String
  },
  pdfPattern: String,          // Regex for PDF parsing
  createdAt: Date,
  isDeleted: Boolean
}

// Indexes
{ userId: 1, broker: 1 }
```

#### Collection: `cache_metadata`

```javascript
{
  _id: ObjectId,
  key: String,                 // Cache key
  source: String,              // 'BRAPI' | 'YAHOO' | 'COINGECKO' | 'BANCO_CENTRAL'
  lastUpdate: Date,
  expiresAt: Date,
  etag: String,                // For conditional requests
  status: String               // 'SUCCESS' | 'FAILED' | 'FALLBACK'
}

// Indexes
{ key: 1 }                     // unique
{ expiresAt: 1 }               // TTL index
```

### 2.2 Data Relationships

```
users (1) ──────────── (N) portfolios
  │                          │
  │                          │
  │                          ▼
  │                    (N) positions
  │                          │
  │                          │
  ▼                          ▼
(N) transactions ◄─────── (1) assets
  │                          │
  │                          │
  │                          ▼
  │                    (N) dividends
  │                          │
  │                          │
  │                          ▼
  │                    (N) corporate_events
  │
  ▼
(N) import_templates
```

---

## 3. API Design

### 3.1 API Structure

**Base URL**: `/api/v1`

### 3.2 Authentication Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/register` | Email/password registration | Public |
| POST | `/auth/login` | Email/password login | Public |
| POST | `/auth/google` | Google OAuth callback | Public |
| POST | `/auth/logout` | Logout user | Required |
| POST | `/auth/refresh` | Refresh JWT token | Required |
| POST | `/auth/forgot-password` | Request password reset | Public |
| POST | `/auth/reset-password` | Reset password with token | Public |
| GET | `/auth/me` | Get current user | Required |

### 3.3 Portfolio Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/portfolios` | List all user portfolios | Required |
| POST | `/portfolios` | Create new portfolio | Required |
| GET | `/portfolios/:id` | Get portfolio details | Required |
| PUT | `/portfolios/:id` | Update portfolio | Required |
| DELETE | `/portfolios/:id` | Soft delete portfolio | Required |
| GET | `/portfolios/consolidated` | Get consolidated view | Required |
| PUT | `/portfolios/:id/layout` | Save dashboard layout | Required |

### 3.4 Transaction Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/transactions` | List transactions (paginated) | Required |
| POST | `/transactions` | Create transaction | Required |
| GET | `/transactions/:id` | Get transaction details | Required |
| PUT | `/transactions/:id` | Update transaction | Required |
| DELETE | `/transactions/:id` | Soft delete transaction | Required |
| GET | `/transactions/export` | Export transactions CSV | Required |

### 3.5 Position Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/positions` | List all positions | Required |
| GET | `/positions/:assetId` | Get position for asset | Required |
| GET | `/positions/summary` | Get portfolio summary | Required |

### 3.6 Asset Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/assets` | List assets (search) | Required |
| GET | `/assets/:symbol` | Get asset details | Required |
| GET | `/assets/:symbol/history` | Get price history | Required |
| GET | `/assets/:symbol/dividends` | Get dividend history | Required |

### 3.7 Market Data Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/market/quotes` | Get current quotes | Required |
| GET | `/market/search` | Search assets | Required |
| GET | `/market/indices` | Get economic indices | Required |
| GET | `/market/exchange-rate` | Get USD/BRL rate | Required |

### 3.8 Import Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/import/csv` | Import CSV file | Required |
| POST | `/import/pdf` | Import PDF file | Required |
| GET | `/import/templates` | List import templates | Required |
| POST | `/import/templates` | Create template | Required |
| PUT | `/import/templates/:id` | Update template | Required |
| DELETE | `/import/templates/:id` | Delete template | Required |

### 3.9 Dividend Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/dividends` | List dividends | Required |
| POST | `/dividends` | Register dividend | Required |
| GET | `/dividends/summary` | Get dividend summary | Required |

### 3.10 Corporate Events Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/corporate-events` | List pending events | Required |
| POST | `/corporate-events/:id/apply` | Apply corporate event | Required |

### 3.11 API Response Format

```typescript
// Success Response
interface ApiResponse<T> {
  data: T;
  meta?: {
    timestamp: string;
    requestId: string;
    page?: number;
    pageSize?: number;
    total?: number;
    totalPages?: number;
  };
}

// Error Response
interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Array<{
      field: string;
      message: string;
    }>;
  };
  meta: {
    timestamp: string;
    requestId: string;
  };
}
```

### 3.12 Rate Limiting

| Endpoint Category | Rate Limit | Window |
|-------------------|------------|--------|
| Authentication | 10 requests | 1 minute |
| Read Operations | 100 requests | 1 minute |
| Write Operations | 30 requests | 1 minute |
| Import Operations | 5 requests | 1 minute |

---

## 4. Frontend Architecture

### 4.1 Project Structure

```
frontend/
├── src/
│   ├── app/                    # App configuration
│   │   ├── App.tsx
│   │   ├── Router.tsx
│   │   └── Providers.tsx
│   ├── features/               # Feature-based modules
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   ├── GoogleLoginButton.tsx
│   │   │   │   └── PasswordRecovery.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useAuth.ts
│   │   │   │   └── useLogin.ts
│   │   │   ├── api/
│   │   │   │   └── authApi.ts
│   │   │   └── types.ts
│   │   ├── portfolios/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── api/
│   │   │   └── types.ts
│   │   ├── transactions/
│   │   ├── dashboard/
│   │   ├── charts/
│   │   ├── import/
│   │   └── settings/
│   ├── components/             # Shared components
│   │   ├── ui/                 # Base UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Select.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Table.tsx
│   │   │   └── Card.tsx
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   ├── MainLayout.tsx
│   │   │   └── MobileNav.tsx
│   │   └── feedback/
│   │       ├── LoadingSpinner.tsx
│   │       ├── Toast.tsx
│   │       └── ErrorBoundary.tsx
│   ├── hooks/                  # Global hooks
│   │   ├── useDebounce.ts
│   │   ├── useLocalStorage.ts
│   │   └── useMediaQuery.ts
│   ├── lib/                    # Utilities
│   │   ├── api/
│   │   │   ├── client.ts
│   │   │   └── interceptors.ts
│   │   ├── calculations/
│   │   │   ├── averagePrice.ts
│   │   │   ├── fixedIncome.ts
│   │   │   └── currencyExchange.ts
│   │   └── utils/
│   │       ├── format.ts
│   │       ├── validation.ts
│   │       └── date.ts
│   ├── stores/                 # Zustand stores
│   │   ├── authStore.ts
│   │   ├── portfolioStore.ts
│   │   └── uiStore.ts
│   ├── types/                  # Shared types
│   │   ├── api.ts
│   │   ├── portfolio.ts
│   │   └── transaction.ts
│   └── pwa/
│       ├── service-worker.ts
│       └── manifest.json
├── public/
├── index.html
├── vite.config.ts
├── tailwind.config.js
└── tsconfig.json
```

### 4.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         App.tsx                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     Providers.tsx                          │  │
│  │  • QueryClientProvider (TanStack Query)                    │  │
│  │  • AuthProvider                                            │  │
│  │  • ThemeProvider                                           │  │
│  │  • ToastProvider                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│  ┌───────────────────────────┴───────────────────────────────┐  │
│  │                     Router.tsx                             │  │
│  │  • BrowserRouter                                           │  │
│  │  • ProtectedRoute wrapper                                  │  │
│  │  • Lazy loading for all routes                             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Public Routes  │  │ Protected Routes│  │  Auth Routes    │
│                 │  │                 │  │                 │
│  /login        │  │  /              │  │  /forgot-pass   │
│  /register     │  │  /portfolios    │  │  /reset-pass    │
│  /google-cb    │  │  /transactions  │  │                 │
│                 │  │  /import        │  │                 │
│                 │  │  /settings      │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### 4.3 State Management Strategy

| State Type | Tool | Use Case |
|------------|------|----------|
| **Server State** | TanStack Query | API data, caching, synchronization |
| **Client State** | Zustand | UI state, user preferences, modals |
| **Form State** | React Hook Form | Form validation and submission |
| **URL State** | React Router | Pagination, filters, navigation |

### 4.4 Key Components

#### Sidebar Component
```typescript
// Collapsible sidebar with menu items
interface SidebarProps {
  isCollapsed: boolean;
  onToggle: () => void;
}

// Menu items:
// - Dashboard
// - Transactions
// - Import
// - Registers
// - Portfolios
```

#### Dashboard Component
```typescript
// Customizable dashboard with widgets
interface DashboardProps {
  portfolioId: string;
  layout: WidgetLayout[];
  onLayoutChange: (layout: WidgetLayout[]) => void;
}

// Widget types:
// - Portfolio Summary
// - Performance Chart
// - Asset Allocation (Pie)
// - Recent Transactions
// - Dividend Income
```

#### Transaction Table Component
```typescript
// Full transaction list with filters
interface TransactionTableProps {
  portfolioId: string;
  filters: TransactionFilters;
  sorting: SortConfig;
  pagination: PaginationConfig;
}
```

---

## 5. External API Integration

### 5.1 Integration Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL API ORCHESTRATOR                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    API Gateway Layer                      │   │
│  │  • Rate limiting                                          │   │
│  │  • Request queuing                                        │   │
│  │  • Circuit breaker                                        │   │
│  │  • Fallback routing                                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│          ┌───────────────────┼───────────────────┐              │
│          │                   │                   │              │
│          ▼                   ▼                   ▼              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │   BRAPI    │    │   Yahoo     │    │   CoinGecko         │  │
│  │  Client    │    │  Finance    │    │   + Binance         │  │
│  │            │    │  Client     │    │   Clients           │  │
│  │  Primary:  │    │  Fallback:  │    │  Crypto:            │  │
│  │  B3 Stocks │    │  B3 Stocks  │    │  • CoinGecko (hist) │  │
│  │  Dividends │    │  Intl Stocks│    │  • Binance (realtime)│  │
│  │  Events    │    │  Currency   │    │                     │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Banco Central Client                         │   │
│  │  • CDI (Code 12)                                          │   │
│  │  • IPCA (Code 433)                                        │   │
│  │  • SELIC (Code 11)                                        │   │
│  │  • PTAX USD/BRL (Code 1)                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 API Configuration

| API | Base URL | Auth | Rate Limit | Primary Use |
|-----|----------|------|------------|-------------|
| **BRAPI** | `https://brapi.dev/api` | Bearer Token | 500K/month (Pro) | Brazilian stocks |
| **Yahoo Finance** | `https://query1.finance.yahoo.com` | User-Agent header | ~2 req/s | International stocks |
| **CoinGecko** | `https://api.coingecko.com/api/v3` | API Key | 30 req/min (Demo) | Crypto historical |
| **Binance** | `wss://stream.binance.com:9443` | None | 5 msg/s | Crypto real-time |
| **Banco Central** | `https://api.bcb.gov.br/dados/serie` | None | ~5 req/s | Economic indicators |

### 5.3 Fallback Strategy

```typescript
// Fallback chain for Brazilian stocks
const BRAZILIAN_STOCK_FALLBACK = {
  primary: 'BRAPI',
  fallback: 'YAHOO_FINANCE',
  timeout: 5000, // 5 seconds
  retryAttempts: 2
};

// Fallback chain for international stocks
const INTERNATIONAL_STOCK_FALLBACK = {
  primary: 'YAHOO_FINANCE',
  fallback: null, // No fallback for international
  timeout: 5000,
  retryAttempts: 2
};

// Fallback chain for crypto
const CRYPTO_FALLBACK = {
  historical: 'COINGECKO',
  realtime: 'BINANCE_WEBSOCKET',
  fallback: 'COINGECKO',
  timeout: 3000,
  retryAttempts: 3
};
```

### 5.4 Caching Strategy per API

| API | Cache Duration | Cache Key Pattern | Invalidation |
|-----|----------------|-------------------|--------------|
| BRAPI Quotes | 5 minutes | `brapi:quote:{symbol}` | TTL |
| BRAPI Dividends | 24 hours | `brapi:dividends:{symbol}` | TTL |
| Yahoo Quotes | 5 minutes | `yahoo:quote:{symbol}` | TTL |
| Yahoo History | 1 hour | `yahoo:history:{symbol}:{range}` | TTL |
| CoinGecko | 1 minute | `coingecko:price:{coinId}` | TTL |
| Binance WS | Real-time | N/A (WebSocket) | Connection |
| Banco Central | 24 hours | `bc:{code}:{date}` | TTL |

### 5.5 WebSocket Management (Binance)

```typescript
// Binance WebSocket configuration
const BINANCE_CONFIG = {
  baseUrl: 'wss://stream.binance.com:9443',
  streams: {
    ticker: '{symbol}@ticker',        // 1s updates
    aggTrade: '{symbol}@aggTrade',    // Real-time trades
    miniTicker: '{symbol}@miniTicker' // 1s mini updates
  },
  reconnect: {
    maxAttempts: 5,
    delay: 1000, // exponential backoff
    maxDelay: 30000
  },
  pingInterval: 20000, // Server sends ping every 20s
  maxStreamsPerConnection: 1024
};
```

---

## 6. Security Architecture

### 6.1 Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOWS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  FLOW 1: Email/Password Registration                            │
│  ─────────────────────────────────────                           │
│  1. User submits email + password                               │
│  2. Backend validates input                                     │
│  3. Backend hashes password (bcrypt, cost 12)                   │
│  4. Backend creates user in MongoDB                             │
│  5. Backend generates JWT (access + refresh)                   │
│  6. Backend sets httpOnly cookie with refresh token             │
│  7. Backend returns access token in response body               │
│                                                                  │
│  FLOW 2: Email/Password Login                                   │
│  ─────────────────────────────                                  │
│  1. User submits email + password                               │
│  2. Backend validates credentials                               │
│  3. Backend generates JWT tokens                                │
│  4. Backend sets httpOnly cookie + returns access token         │
│                                                                  │
│  FLOW 3: Google OAuth                                           │
│  ──────────────────────                                         │
│  1. User clicks "Login with Google"                             │
│  2. Frontend redirects to Google OAuth consent screen          │
│  3. User grants permission                                     │
│  4. Google redirects to /auth/google/callback with code        │
│  5. Backend exchanges code for Google tokens                   │
│  6. Backend retrieves user info from Google                    │
│  7. Backend creates/updates user in MongoDB                    │
│  8. Backend generates JWT tokens                               │
│  9. Backend sets httpOnly cookie + redirects to app            │
│                                                                  │
│  FLOW 4: Token Refresh                                         │
│  ────────────────────                                           │
│  1. Access token expires                                       │
│  2. Frontend sends refresh request with httpOnly cookie        │
│  3. Backend validates refresh token                            │
│  4. Backend generates new access token                         │
│  5. Backend returns new access token                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 JWT Token Structure

```typescript
// Access Token (15 minutes)
interface AccessToken {
  sub: string;        // User ID
  email: string;
  name: string;
  iat: number;        // Issued at
  exp: number;        // Expiration (15 min)
  type: 'access';
}

// Refresh Token (7 days)
interface RefreshToken {
  sub: string;        // User ID
  iat: number;
  exp: number;        // Expiration (7 days)
  type: 'refresh';
  jti: string;        // Unique token ID (for revocation)
}
```

### 6.3 Data Isolation Strategy

```typescript
// Middleware: Ensure user data isolation
const ensureDataIsolation = (req, res, next) => {
  // All queries must include userId filter
  req.query.userId = req.user.sub;
  next();
};

// Repository pattern with automatic user scoping
class PortfolioRepository {
  async findByUserId(userId: string) {
    return Portfolio.find({ userId, isDeleted: false });
  }
  
  async findById(id: string, userId: string) {
    return Portfolio.findOne({ _id: id, userId, isDeleted: false });
  }
}
```

### 6.4 Security Headers

```typescript
// Helmet.js configuration
const securityHeaders = {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "https://accounts.google.com"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://brapi.dev", "https://query1.finance.yahoo.com"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameSrc: ["https://accounts.google.com"]
    }
  },
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: { policy: "same-origin" },
  hsts: { maxAge: 31536000, includeSubDomains: true },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" }
};
```

### 6.5 Input Validation

```typescript
// Using Zod for validation
const transactionSchema = z.object({
  portfolioId: z.string().regex(/^[0-9a-fA-F]{24}$/),
  assetId: z.string().regex(/^[0-9a-fA-F]{24}$/),
  type: z.enum(['BUY', 'SELL']),
  quantity: z.number().positive(),
  price: z.number().positive(),
  fees: z.number().min(0).default(0),
  date: z.string().datetime(),
  currency: z.enum(['BRL', 'USD']),
  broker: z.string().max(100).optional(),
  notes: z.string().max(500).optional()
});
```

---

## 7. Caching Strategy

### 7.1 Redis Cache Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       REDIS CACHE LAYERS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LAYER 1: API Response Cache (TTL-based)                        │
│  ────────────────────────────────────────                       │
│  • External API responses                                       │
│  • Market data (quotes, history)                                │
│  • Economic indicators                                          │
│  • Key pattern: `{api}:{type}:{identifier}`                    │
│                                                                  │
│  LAYER 2: Session Cache                                         │
│  ───────────────────────                                        │
│  • User sessions                                                │
│  • Refresh tokens                                               │
│  • Key pattern: `session:{userId}:{sessionId}`                 │
│                                                                  │
│  LAYER 3: Rate Limiting                                        │
│  ─────────────────────                                           │
│  • Request counters per IP/user                                │
│  • Key pattern: `ratelimit:{type}:{identifier}`               │
│                                                                  │
│  LAYER 4: Real-time Data (Binance)                             │
│  ──────────────────────────────────                             │
│  • Latest crypto prices                                         │
│  • Key pattern: `crypto:price:{symbol}`                       │
│  • TTL: 1 second (updated via WebSocket)                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Cache Invalidation Strategy

| Cache Type | Invalidation Method | Trigger |
|------------|---------------------|---------|
| API Response | TTL expiration | Time-based |
| User Session | Manual delete | Logout |
| Portfolio Data | Manual delete | Transaction update |
| Market Data | TTL + WebSocket update | Price change |
| Economic Indicators | TTL expiration | Daily update |

### 7.3 Cache Hit Rate Targets

| Data Type | Target Hit Rate | Cache Duration |
|-----------|-----------------|----------------|
| Stock Quotes | ≥80% | 5 minutes |
| Historical Data | ≥90% | 1 hour |
| Economic Indicators | ≥95% | 24 hours |
| User Portfolios | ≥70% | 1 minute |
| Crypto Prices | ≥60% | 1 second |

---

## 8. Performance Considerations

### 8.1 Frontend Performance

| Optimization | Implementation |
|--------------|----------------|
| **Code Splitting** | Lazy loading for all routes |
| **Bundle Size** | Tree shaking, dynamic imports |
| **Asset Optimization** | Image lazy loading, WebP format |
| **Rendering** | React.memo, useMemo, useCallback |
| **Virtualization** | react-window for large lists |
| **Prefetching** | TanStack Query prefetch on hover |
| **Service Worker** | Cache static assets, API responses |

### 8.2 Backend Performance

| Optimization | Implementation |
|--------------|----------------|
| **Database Indexing** | All query fields indexed |
| **Connection Pooling** | MongoDB connection pool |
| **Query Optimization** | Projection, lean queries |
| **Caching** | Redis for hot data |
| **Compression** | gzip/brotli for responses |
| **Rate Limiting** | Prevent abuse |
| **Request Queuing** | Bull/BullMQ for imports |

### 8.3 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint | <1.5s | Lighthouse |
| Largest Contentful Paint | <2.5s | Lighthouse |
| Time to Interactive | <3s | Lighthouse |
| API Response Time (p95) | <200ms | APM |
| Database Query Time (p95) | <50ms | APM |
| Cache Hit Rate | ≥80% | Redis metrics |

---

## 9. Task Decomposition

### 9.1 Task Overview

| Task ID | Description | Agent | Dependencies | Effort | Sprint |
|---------|-------------|-------|--------------|--------|--------|
| **T001** | Docker Compose Infrastructure | BackendDeveloper | None | 8h | 1 |
| **T002** | MongoDB Schema & Models | BackendDeveloper | T001 | 6h | 1 |
| **T003** | Redis Configuration | BackendDeveloper | T001 | 2h | 1 |
| **T004** | Express Server Setup | BackendDeveloper | T001 | 4h | 1 |
| **T005** | JWT Authentication | BackendDeveloper | T004 | 8h | 1-2 |
| **T006** | Google OAuth Integration | BackendDeveloper | T005 | 6h | 2 |
| **T007** | Password Recovery Flow | BackendDeveloper | T005 | 4h | 2 |
| **T008** | Auth Middleware & Guards | BackendDeveloper | T005 | 4h | 2 |
| **T009** | User API Endpoints | BackendDeveloper | T005 | 4h | 2 |
| **T010** | Portfolio CRUD API | BackendDeveloper | T009 | 6h | 3 |
| **T011** | Transaction CRUD API | BackendDeveloper | T010 | 8h | 3 |
| **T012** | Average Price Calculator | BackendDeveloper | T011 | 6h | 5 |
| **T013** | Position Calculator | BackendDeveloper | T011 | 6h | 5 |
| **T014** | BRAPI Integration | BackendDeveloper | T004 | 8h | 3 |
| **T015** | Yahoo Finance Integration | BackendDeveloper | T014 | 6h | 3 |
| **T016** | CoinGecko Integration | BackendDeveloper | T014 | 6h | 3 |
| **T017** | Binance WebSocket Integration | BackendDeveloper | T014 | 8h | 4 |
| **T018** | Banco Central Integration | BackendDeveloper | T014 | 4h | 3 |
| **T019** | API Fallback Strategy | BackendDeveloper | T014-T018 | 6h | 4 |
| **T020** | Currency Exchange Service | BackendDeveloper | T018 | 4h | 5 |
| **T021** | Fixed Income Calculator | BackendDeveloper | T018 | 6h | 5 |
| **T022** | Dividend Service | BackendDeveloper | T014 | 6h | 9 |
| **T023** | Corporate Events Service | BackendDeveloper | T014 | 8h | 9 |
| **T024** | CSV Import Service | BackendDeveloper | T011 | 6h | 9 |
| **T025** | PDF Import Service | BackendDeveloper | T011 | 10h | 11 |
| **T026** | Audit Log Service | BackendDeveloper | T011 | 4h | 9 |
| **T027** | Market Data Update Jobs | BackendDeveloper | T014-T018 | 6h | 4 |
| **T028** | React Project Setup | FrontendDeveloperReact | None | 4h | 1 |
| **T029** | Tailwind CSS Setup | FrontendDeveloperReact | T028 | 2h | 1 |
| **T030** | Base Layout Component | FrontendDeveloperReact | T029 | 4h | 1 |
| **T031** | Router Setup | FrontendDeveloperReact | T030 | 4h | 1 |
| **T032** | Protected Routes | FrontendDeveloperReact | T031 | 2h | 2 |
| **T033** | Auth Context & Hooks | FrontendDeveloperReact | T028 | 4h | 2 |
| **T034** | Login Page | FrontendDeveloperReact | T033 | 4h | 2 |
| **T035** | Google Login Button | FrontendDeveloperReact | T034 | 2h | 2 |
| **T036** | Password Recovery Page | FrontendDeveloperReact | T034 | 2h | 2 |
| **T037** | Sidebar Component | FrontendDeveloperReact | T030 | 6h | 7 |
| **T038** | Dashboard Page | FrontendDeveloperReact | T037 | 8h | 7 |
| **T039** | Portfolio Selector | FrontendDeveloperReact | T038 | 4h | 7 |
| **T040** | Transaction Form | FrontendDeveloperReact | T038 | 6h | 7 |
| **T041** | Transaction Table | FrontendDeveloperReact | T040 | 6h | 7 |
| **T042** | Performance Chart | FrontendDeveloperReact | T038 | 8h | 7 |
| **T043** | Asset Allocation Chart | FrontendDeveloperReact | T038 | 4h | 7 |
| **T044** | Chart Editor Component | FrontendDeveloperReact | T042 | 6h | 9 |
| **T045** | CSV Import UI | FrontendDeveloperReact | T038 | 4h | 9 |
| **T046** | PDF Import UI | FrontendDeveloperReact | T038 | 6h | 11 |
| **T047** | Dividend Dashboard | FrontendDeveloperReact | T038 | 4h | 9 |
| **T048** | Corporate Events UI | FrontendDeveloperReact | T038 | 4h | 9 |
| **T049** | Responsive Layout | FrontendDeveloperReact | T030 | 6h | 7 |
| **T050** | PWA Configuration | FrontendDeveloperReact | T028 | 4h | 11 |
| **T051** | Service Worker | FrontendDeveloperReact | T050 | 6h | 11 |
| **T052** | Loading & Error States | FrontendDeveloperReact | T028 | 4h | 7 |
| **T053** | Toast Notifications | FrontendDeveloperReact | T028 | 2h | 7 |
| **T054** | Backend Unit Tests | TestEngineer | T005-T027 | 16h | Ongoing |
| **T055** | Frontend Unit Tests | TestEngineer | T028-T053 | 12h | Ongoing |
| **T056** | Integration Tests | TestEngineer | T054-T055 | 12h | Ongoing |
| **T057** | E2E Tests | TestEngineer | T056 | 16h | 12 |
| **T058** | QA Validation | QAAnalyst | T057 | 8h | 12 |
| **T059** | Code Review | CodeReviewer | T054-T057 | 8h | Ongoing |
| **T060** | Merge Request | MergeRequestCreator | T059 | 2h | 12 |

### 9.2 Parallel Execution Opportunities

| Parallel Group | Tasks | Agents | Sprint |
|----------------|-------|--------|--------|
| **PG1** | T001 (Docker) + T028 (React Setup) | BackendDeveloper + FrontendDeveloperReact | 1 |
| **PG2** | T002 (MongoDB) + T029 (Tailwind) | BackendDeveloper + FrontendDeveloperReact | 1 |
| **PG3** | T005 (JWT Auth) + T030 (Layout) | BackendDeveloper + FrontendDeveloperReact | 1-2 |
| **PG4** | T006 (OAuth) + T031 (Router) | BackendDeveloper + FrontendDeveloperReact | 2 |
| **PG5** | T010 (Portfolio API) + T033 (Auth Context) | BackendDeveloper + FrontendDeveloperReact | 3 |
| **PG6** | T011 (Transaction API) + T034 (Login Page) | BackendDeveloper + FrontendDeveloperReact | 3 |
| **PG7** | T014-T018 (API Integrations) | BackendDeveloper (sequential) | 3-4 |
| **PG8** | T012-T013 (Calculators) + T037 (Sidebar) | BackendDeveloper + FrontendDeveloperReact | 5-7 |
| **PG9** | T020-T021 (Currency/Fixed Income) + T038 (Dashboard) | BackendDeveloper + FrontendDeveloperReact | 5-7 |
| **PG10** | T022-T024 (Dividends/Events/CSV) + T044-T045 (Chart/CSV UI) | BackendDeveloper + FrontendDeveloperReact | 9 |
| **PG11** | T025 (PDF Import) + T046 (PDF UI) | BackendDeveloper + FrontendDeveloperReact | 11 |
| **PG12** | T050-T051 (PWA) + T054 (Backend Tests) | FrontendDeveloperReact + TestEngineer | 11 |

### 9.3 Critical Path

```
T001 (Docker) → T004 (Express) → T005 (JWT) → T009 (User API) → T010 (Portfolio API)
    → T011 (Transaction API) → T012 (Avg Price) → T013 (Position)
    → T014-T018 (API Integrations) → T019 (Fallback) → T027 (Update Jobs)
    → T054-T057 (Tests) → T058 (QA) → T059 (Review) → T060 (Merge)
```

**Critical Path Duration**: ~10-12 sprints

---

## 10. Execution Plan

### 10.1 Sprint 1-2: Foundation (Architecture, Auth, Layout, Navigation, Security)

**Duration**: 2 sprints (4 weeks)

#### Sprint 1 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T001 - Docker Compose Infrastructure | BackendDeveloper | PG1 | Pending |
| T028 - React Project Setup | FrontendDeveloperReact | PG1 | Pending |
| T002 - MongoDB Schema & Models | BackendDeveloper | PG2 | Pending |
| T029 - Tailwind CSS Setup | FrontendDeveloperReact | PG2 | Pending |
| T003 - Redis Configuration | BackendDeveloper | Sequential | Pending |
| T004 - Express Server Setup | BackendDeveloper | Sequential | Pending |
| T030 - Base Layout Component | FrontendDeveloperReact | Sequential | Pending |

#### Sprint 2 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T005 - JWT Authentication | BackendDeveloper | PG3 | Pending |
| T031 - Router Setup | FrontendDeveloperReact | PG4 | Pending |
| T006 - Google OAuth Integration | BackendDeveloper | PG4 | Pending |
| T032 - Protected Routes | FrontendDeveloperReact | Sequential | Pending |
| T007 - Password Recovery Flow | BackendDeveloper | Sequential | Pending |
| T008 - Auth Middleware & Guards | BackendDeveloper | Sequential | Pending |
| T033 - Auth Context & Hooks | FrontendDeveloperReact | Sequential | Pending |
| T034 - Login Page | FrontendDeveloperReact | Sequential | Pending |
| T035 - Google Login Button | FrontendDeveloperReact | Sequential | Pending |
| T036 - Password Recovery Page | FrontendDeveloperReact | Sequential | Pending |
| T009 - User API Endpoints | BackendDeveloper | Sequential | Pending |

**Deliverables**:
- ✅ Docker Compose running all services
- ✅ MongoDB with initial schema
- ✅ Redis configured
- ✅ Express server with JWT auth
- ✅ Google OAuth working
- ✅ Password recovery flow
- ✅ React app with base layout
- ✅ Protected routes
- ✅ Login/logout functionality

### 10.2 Sprint 3-4: Core Data Layer (Market Data, Portfolios, Transactions)

**Duration**: 2 sprints (4 weeks)

#### Sprint 3 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T010 - Portfolio CRUD API | BackendDeveloper | PG5 | Pending |
| T014 - BRAPI Integration | BackendDeveloper | Sequential | Pending |
| T015 - Yahoo Finance Integration | BackendDeveloper | Sequential | Pending |
| T016 - CoinGecko Integration | BackendDeveloper | Sequential | Pending |
| T018 - Banco Central Integration | BackendDeveloper | Sequential | Pending |

#### Sprint 4 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T011 - Transaction CRUD API | BackendDeveloper | PG6 | Pending |
| T017 - Binance WebSocket Integration | BackendDeveloper | Sequential | Pending |
| T019 - API Fallback Strategy | BackendDeveloper | Sequential | Pending |
| T027 - Market Data Update Jobs | BackendDeveloper | Sequential | Pending |

**Deliverables**:
- ✅ Portfolio CRUD operations
- ✅ Transaction CRUD operations
- ✅ BRAPI integration with fallback
- ✅ Yahoo Finance integration
- ✅ CoinGecko integration
- ✅ Binance WebSocket for real-time crypto
- ✅ Banco Central integration (CDI, IPCA, PTAX)
- ✅ Fallback strategy working
- ✅ Scheduled update jobs

### 10.3 Sprint 5-6: Business Logic (Average Price, Currency, Fixed Income, Crypto)

**Duration**: 2 sprints (4 weeks)

#### Sprint 5 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T012 - Average Price Calculator | BackendDeveloper | PG8 | Pending |
| T013 - Position Calculator | BackendDeveloper | Sequential | Pending |
| T020 - Currency Exchange Service | BackendDeveloper | PG9 | Pending |
| T021 - Fixed Income Calculator | BackendDeveloper | Sequential | Pending |

#### Sprint 6 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T037 - Sidebar Component | FrontendDeveloperReact | PG8 | Pending |
| T038 - Dashboard Page | FrontendDeveloperReact | PG9 | Pending |
| T039 - Portfolio Selector | FrontendDeveloperReact | Sequential | Pending |
| T040 - Transaction Form | FrontendDeveloperReact | Sequential | Pending |

**Deliverables**:
- ✅ Average price calculation (pure functions)
- ✅ Position calculation with gains/losses
- ✅ Currency exchange (USD to BRL)
- ✅ Fixed income calculations (CDI, IPCA, Fixed)
- ✅ Sidebar with navigation
- ✅ Dashboard page structure
- ✅ Portfolio selector
- ✅ Transaction form

### 10.4 Sprint 7-8: UI/UX Core (Sidebar, Charts, Dashboard, Transactions UI)

**Duration**: 2 sprints (4 weeks)

#### Sprint 7 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T041 - Transaction Table | FrontendDeveloperReact | Sequential | Pending |
| T042 - Performance Chart | FrontendDeveloperReact | Sequential | Pending |
| T043 - Asset Allocation Chart | FrontendDeveloperReact | Sequential | Pending |
| T049 - Responsive Layout | FrontendDeveloperReact | Sequential | Pending |
| T052 - Loading & Error States | FrontendDeveloperReact | Sequential | Pending |
| T053 - Toast Notifications | FrontendDeveloperReact | Sequential | Pending |

#### Sprint 8 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T054 - Backend Unit Tests | TestEngineer | PG12 | Pending |
| T055 - Frontend Unit Tests | TestEngineer | Sequential | Pending |

**Deliverables**:
- ✅ Transaction table with filters/sorting
- ✅ Performance line chart
- ✅ Asset allocation pie chart
- ✅ Responsive layout (mobile/desktop)
- ✅ Loading indicators
- ✅ Error handling UI
- ✅ Toast notifications
- ✅ Backend unit tests (≥90% coverage)
- ✅ Frontend unit tests

### 10.5 Sprint 9-10: Advanced Features (Dividends, Import, Events, Audit)

**Duration**: 2 sprints (4 weeks)

#### Sprint 9 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T022 - Dividend Service | BackendDeveloper | PG10 | Pending |
| T023 - Corporate Events Service | BackendDeveloper | Sequential | Pending |
| T024 - CSV Import Service | BackendDeveloper | PG10 | Pending |
| T026 - Audit Log Service | BackendDeveloper | Sequential | Pending |
| T044 - Chart Editor Component | FrontendDeveloperReact | PG10 | Pending |
| T045 - CSV Import UI | FrontendDeveloperReact | PG10 | Pending |
| T047 - Dividend Dashboard | FrontendDeveloperReact | Sequential | Pending |
| T048 - Corporate Events UI | FrontendDeveloperReact | Sequential | Pending |

#### Sprint 10 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T056 - Integration Tests | TestEngineer | Sequential | Pending |

**Deliverables**:
- ✅ Dividend tracking and filtering
- ✅ Corporate events detection and application
- ✅ CSV import with duplicate detection
- ✅ Audit log for transactions
- ✅ Chart editor (line, bar, pie, donut)
- ✅ CSV import UI
- ✅ Dividend dashboard
- ✅ Corporate events approval UI
- ✅ Integration tests passing

### 10.6 Sprint 11-12: Polish & PWA (PDF Import, PWA)

**Duration**: 2 sprints (4 weeks)

#### Sprint 11 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T025 - PDF Import Service | BackendDeveloper | PG11 | Pending |
| T046 - PDF Import UI | FrontendDeveloperReact | PG11 | Pending |
| T050 - PWA Configuration | FrontendDeveloperReact | PG12 | Pending |
| T051 - Service Worker | FrontendDeveloperReact | Sequential | Pending |

#### Sprint 12 Tasks
| Task | Agent | Parallel | Status |
|------|-------|----------|--------|
| T057 - E2E Tests | TestEngineer | Sequential | Pending |
| T058 - QA Validation | QAAnalyst | Sequential | Pending |
| T059 - Code Review | CodeReviewer | Sequential | Pending |
| T060 - Merge Request | MergeRequestCreator | Sequential | Pending |

**Deliverables**:
- ✅ PDF import with template management
- ✅ PDF import UI
- ✅ PWA manifest
- ✅ Service worker for offline
- ✅ Installable app
- ✅ E2E tests passing
- ✅ All 73 acceptance criteria validated
- ✅ Code review approved
- ✅ Ready for production

---

## 11. Risk Mitigation

### 11.1 Technical Risks

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| **External API rate limits** | High | Medium | Implement Redis caching (5min TTL), use fallback APIs, respect rate limits, queue requests |
| **API breaking changes** | High | Low | Version API clients, monitor API changelogs, implement fallback, abstract API layer |
| **MongoDB performance degradation** | Medium | Low | Implement proper indexing, use Redis for hot data, monitor query performance, use projection |
| **PWA offline limitations** | Medium | Medium | Clearly define offline scope, implement service worker correctly, cache critical assets |
| **Real-time crypto updates overload** | Medium | Medium | Implement WebSocket connection pooling, use Binance streams efficiently, limit subscriptions |
| **Currency exchange rate delays** | Medium | Medium | Cache daily rates, use PTAX as fallback, implement retry logic, show last update time |
| **Incorrect financial calculations** | Critical | Low | Extensive unit tests, use decimal.js for precision, peer review, pure functions |

### 11.2 Business Risks

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| **Data loss** | Critical | Low | Implement soft delete, regular backups, audit trail, MongoDB replica set |
| **User data leakage** | Critical | Low | Strict data isolation, security audit, penetration testing, encryption at rest |
| **Regulatory compliance issues** | High | Low | Consult legal team, implement audit trail, data retention policies, GDPR compliance |

### 11.3 External Risks

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| **BRAPI service outage** | High | Medium | Yahoo Finance fallback, cache historical data, show last known price with timestamp |
| **Banco Central API changes** | Medium | Low | Monitor API updates, implement versioning, cache indicators |
| **Google OAuth policy changes** | Medium | Low | Monitor Google developer updates, maintain email/password fallback |
| **Binance API restrictions** | Medium | Medium | CoinGecko fallback, implement rate limiting, use REST API as backup |

### 11.4 Fallback Implementation

```typescript
// API Fallback Service
class MarketDataService {
  async getQuote(symbol: string): Promise<Quote> {
    const cacheKey = `quote:${symbol}`;
    
    // Try cache first
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);
    
    // Try BRAPI (primary for Brazilian stocks)
    try {
      const quote = await this.brapiClient.getQuote(symbol);
      await redis.setex(cacheKey, 300, JSON.stringify(quote)); // 5 min TTL
      return quote;
    } catch (error) {
      logger.warn('BRAPI failed, trying Yahoo Finance', { symbol, error });
    }
    
    // Fallback to Yahoo Finance
    try {
      const quote = await this.yahooClient.getQuote(symbol);
      await redis.setex(cacheKey, 300, JSON.stringify(quote));
      return quote;
    } catch (error) {
      logger.error('All APIs failed', { symbol, error });
      throw new ServiceUnavailableError('Unable to fetch quote');
    }
  }
}
```

---

## 12. Summary

### 12.1 Technical Analysis File Location
- **File**: `/docs/stories/STORY-001-technical-analysis.md`
- **Created**: 2026-03-31
- **Status**: Ready for TechLead

### 12.2 Total Tasks Count
- **Total Tasks**: 60
- **Backend Tasks**: 27
- **Frontend Tasks**: 26
- **Testing Tasks**: 4
- **QA/Review Tasks**: 3

### 12.3 Parallel Execution Opportunities
- **Parallel Groups**: 12
- **Max Concurrent Agents**: 2
- **Estimated Time Savings**: 30-40% vs sequential

### 12.4 Critical Path
- **Duration**: 10-12 sprints (20-24 weeks)
- **Critical Tasks**: T001 → T004 → T005 → T009 → T010 → T011 → T012 → T013 → T014-T018 → T019 → T027 → T054-T057 → T058 → T059 → T060

### 12.5 Risk Mitigation Strategies
1. **API Rate Limits**: Redis caching + fallback APIs + request queuing
2. **Data Loss**: Soft delete + audit trail + backups
3. **Security**: Data isolation + JWT + OAuth + input validation
4. **Performance**: Indexing + caching + lazy loading
5. **External Dependencies**: Fallback chains + monitoring + alerts

### 12.6 Recommended Agent Assignments

| Agent | Tasks | Estimated Hours |
|-------|-------|-----------------|
| **BackendDeveloper** | T001-T027 | 140h |
| **FrontendDeveloperReact** | T028-T053 | 100h |
| **TestEngineer** | T054-T057 | 56h |
| **QAAnalyst** | T058 | 8h |
| **CodeReviewer** | T059 | 8h |
| **MergeRequestCreator** | T060 | 2h |

**Total Estimated Effort**: 314 hours (~8 person-weeks)

---

## 13. Delegation Instructions for TechLead

### 13.1 Documents to Reference
1. **PM Story**: `/docs/stories/STORY-001-investment-management-system.md`
2. **Technical Analysis**: `/docs/stories/STORY-001-technical-analysis.md` (this document)
3. **Code Analysis**: N/A (greenfield project)

### 13.2 Language & Framework
- **Primary Language**: Node.js (TypeScript)
- **Frontend Framework**: React
- **Integration Pattern**: Node.js SPA Mode

### 13.3 Execution Order
1. **Sequential**: Task 0 (Code Analysis) - SKIPPED (greenfield)
2. **Sequential**: Task 1 (Coordination) - TechLead starts
3. **Parallel**: Tasks 2 (Backend) and 3 (Frontend) when independent
4. **Sequential**: Task 4 (Tests) → Task 5 (QA) → Task 6 (Review) → Task 7 (Merge)

### 13.4 Key Technical Decisions
1. Use **decimal.js** for all financial calculations
2. All external API calls must go through **Redis cache**
3. Implement **fallback strategy** for all external APIs
4. Use **pure functions** for all calculations
5. **Soft delete** for all user data
6. **Data isolation** by userId on all queries

---

**Document Status**: ✅ Complete  
**Ready for**: TechLead Execution  
**Next Step**: Delegate to TechLead with all document references
