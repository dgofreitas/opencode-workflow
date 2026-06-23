<!-- Context: standards/dockerfile-patterns | Priority: high | Version: 2.0 | Updated: 2026-06-21 -->

# Dockerfile Patterns — Production-grade Multi-stage Builds

**Purpose**: Define canonical Dockerfile patterns for Node.js backends and Vite frontends. Two patterns with explicit default — choose based on tradeoffs.

**When to use**: Every Dockerfile in the project. Non-negotiable for production images.

---

## Two Patterns — Pick One Per Service

| Pattern | Default? | When | Cost |
|---------|----------|------|------|
| **Two-Target** | ✅ Default (frontend + backend) | Always — when prod image must be minimal and secure | Rebuild `:dev` image when `package.json`/`package-lock.json` changes (rare) |
| **Unified-Image** | Alternative | When you want one image per service and accept devDeps in prod | devDeps ship to prod (larger image, more CVE surface, dev tools in runtime) |

**Rule**: Start with Two-Target. Use Unified-Image only when image-build ops cost matters more than prod image size (e.g., many microservices, frequent deploys).

---

## Two-Target Pattern (default)

Two images per service: `<service>:dev` (devDeps + dev tools) and `<service>:<version>` (production, minimal).

### Backend — 4 Stages

```dockerfile
# ============================================================================
# Stage 1: Base
# ============================================================================
FROM node:20-alpine AS base
RUN apk add --no-cache dumb-init
WORKDIR /app

# ============================================================================
# Stage 2: Development (devDeps + nodemon)
# ============================================================================
FROM base AS development
COPY backend/package*.json ./
RUN npm ci --include=dev
COPY backend/ .
COPY shared/ /shared/
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1
ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "run", "dev"]   # nodemon via package.json script

# ============================================================================
# Stage 3: Build (prod deps only)
# ============================================================================
FROM base AS build
COPY backend/package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY backend/ .
COPY shared/ /shared/

# ============================================================================
# Stage 4: Production (non-root, minimal)
# ============================================================================
FROM base AS production
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=build --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs backend/ .
COPY --chown=nodejs:nodejs shared/ /shared/
USER nodejs
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/main.js"]
```

**Build:**

```bash
docker build --target development -t myapp/backend:dev -f backend/Dockerfile .
docker build --target production  -t myapp/backend:1.0.0 -f backend/Dockerfile .
```

### Frontend — 3 Stages

```dockerfile
# ============================================================================
# Stage 1: Development (Vite HMR)
# ============================================================================
FROM node:20-alpine AS development
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
COPY shared/ ./shared/
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["npm", "run", "dev", "--", "--host"]

# ============================================================================
# Stage 2: Build (Vite → dist)
# ============================================================================
FROM node:20-alpine AS build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
COPY shared/ ./shared/

# ⚠️ VITE_* são BUILD-TIME. Precisam ser --build-arg.
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

RUN npm run lint && npm run build

# ============================================================================
# Stage 3: Production (nginx serving dist/)
# ============================================================================
FROM nginx:alpine AS production
COPY frontend/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1
CMD ["nginx", "-g", "daemon off;"]
```

**Build:**

```bash
# Dev
docker build --target development -t myapp/frontend:dev -f frontend/Dockerfile .

# Prod
docker build \
  --target production \
  --build-arg VITE_API_URL=https://api.myapp.com \
  -t myapp/frontend:1.0.0 \
  -f frontend/Dockerfile .
```

---

## Unified-Image Pattern (alternative)

**When**: One image per service, dev via CMD override + bind mount. Accept devDeps in prod image.

**Tradeoff**: prod image ships devDeps (nodemon, vitest, eslint, etc.) — larger image, more CVE surface, dev tools available in prod runtime. Choose only when image-build ops cost matters more than prod image size.

### Backend (single stage)

```dockerfile
FROM node:20-alpine AS production
RUN apk add --no-cache dumb-init
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --include=dev && npm cache clean --force
COPY backend/ .
COPY shared/ /shared/
RUN chown nodejs:nodejs /app
USER nodejs
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/main.js"]
# Dev override (compose): command: ["npm", "run", "dev"]
```

### Frontend (single stage — vite preview, NOT nginx)

**Extra tradeoff**: prod serves `dist/` via `vite preview` (not nginx). Weaker static-serve features (no gzip config, no custom cache headers, no security headers). Node process in prod just to serve statics.

```dockerfile
FROM node:20-alpine AS production
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci --include=dev
COPY frontend/ .
COPY shared/ ./shared/
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build
RUN chown nodejs:nodejs /app
USER nodejs
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/80/ || exit 1
CMD ["npx", "vite", "preview", "--host", "--port", "80"]
# Dev override (compose): command: ["npm", "run", "dev", "--", "--host", "--port", "80"]
```

---

## Mandatory Principles (both patterns)

1. **Multi-stage**: separar deps, build e runtime → imagem final mínima (Two-Target é o extremo disso)
2. **Non-root user**: nunca root em produção. UID ≥ 1000
3. **dumb-init**: reencaminha SIGTERM para Node.js
4. **Healthcheck**: `HEALTHCHECK` no Dockerfile + `healthcheck:` no compose (defense-in-depth)
5. **No secrets in layers**: `.env` nunca entra na imagem — runtime env ou Docker secrets
6. **`npm ci`**: sempre. Nunca `npm install` em Dockerfile.
   - `npm ci --include=dev` → quando devDeps são necessários (dev stage, ou unified-image)
   - `npm ci --only=production` → no stage de build de prod do Two-Target backend
7. **`.dockerignore`**: mandatory — ver abaixo
8. **Layer caching order**: `COPY package*.json` → `npm ci` → `COPY src/`. Nunca `COPY . .` antes de `npm ci`

---

## Build-args for Vite

VITE_* são **build-time**, não runtime. No compose de prod, NÃO coloque VITE_* em `environment:`. Passe via `--build-arg`:

```bash
docker build --target production --build-arg VITE_API_URL=https://api.myapp.com -t myapp/frontend:1.0.0 .
```

No `docker-compose.yml` (prod build flow):

```yaml
frontend:
  build:
    context: .
    dockerfile: frontend/Dockerfile
    target: production
    args:
      VITE_API_URL: ${VITE_API_URL}
  image: myapp/frontend:${FRONTEND_VERSION}
```

**Exceção**: Vite dev server (stage `development` / unified-image dev override) lê `process.env` em runtime — nesse caso VITE_* pode ir em `environment:` do `docker-compose.override.yml`.

---

## Why dumb-init?

Node.js como PID 1 **não propaga SIGTERM** corretamente. Sem dumb-init:

- `docker stop` → Node ignora sinal → força SIGKILL após 10s
- Conexões DB não fecham graciosamente
- Testes de integração com `.close()` vazam

**Com dumb-init:** signals reencaminhados, shutdown graceful.

---

## Non-root User — Why

Root dentro do container + escape de kernel = root no host.

```dockerfile
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs
```

**Regra**: UID ≥ 1000, nunca `USER 0` (root).

---

## Healthcheck Strategy

**Redundância proposital:**

| Camada | Mecanismo |
|--------|-----------|
| Dockerfile | `HEALTHCHECK` — usado por `docker ps` |
| docker-compose | `healthcheck:` + `depends_on: condition: service_healthy` |
| Endpoint HTTP | `/health` no app — `200 OK` só se DB+Redis OK |

**Never** use `curl` no healthcheck de imagem alpine — não vem instalado. Use `wget`.

---

## Layer Caching — Order Matters

**Ordem correta** (invalidation minima):

```dockerfile
# 1. Dependências (muda raramente)
COPY package*.json ./
RUN npm ci

# 2. Source code (muda frequentemente)
COPY src/ ./src/
```

**Errado** (cache busted em cada mudança):

```dockerfile
COPY . .
RUN npm ci  # ← re-run em toda mudança de código
```

---

## .dockerignore — Mandatory

```
node_modules
coverage
dist
.git
.env
.env.*
*.log
__tests__
.tmp
.opencode
```

Sem `.dockerignore` → context build de 500MB+, cache invalidado em mudança trivial.

---

## Common Anti-patterns

| ❌ Evitar | ✅ Correto |
|----------|-----------|
| `FROM node:latest` | `FROM node:20-alpine` (versão fixa) |
| `USER root` / sem `USER` | `USER nodejs` (non-root, UID ≥ 1000) |
| `CMD node src/main.js` | `ENTRYPOINT ["dumb-init", "--"]` + `CMD` |
| Env vars Vite em compose de prod | `--build-arg VITE_*` |
| `COPY . .` no início | `COPY package*.json` → `npm ci` → `COPY src/` |
| `npm install` em Dockerfile | `npm ci` (ou `npm ci --include=dev`) |
| devDeps na imagem de prod (Two-Target) | `npm ci --only=production` no build stage |
| `.env` copiado na imagem | Runtime env + Docker secrets |
| Sem `HEALTHCHECK` | Healthcheck em todos os stages |
| `curl` no healthcheck alpine | `wget` (alpine não tem curl por default) |

---

## Related Context

- `stacks/fullstack-containerized.md` — full blueprint + compose override pattern (dev workflow)
- `stacks/nodejs-domain-structure.md` — backend modular pattern
- `standards/security.md` — nginx hardening, non-root rationale