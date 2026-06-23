<!-- Context: stacks/fullstack-containerized | Priority: high | Version: 2.0 | Updated: 2026-06-21 -->

# Fullstack Containerized Blueprint

**Purpose**: Reference architecture for fullstack web apps with nginx reverse proxy, Node.js API, React PWA, MongoDB, and Redis — fully isolated via Docker networks.

**When to use**: Medium-to-large apps needing service isolation, horizontal scaling readiness, offline-first frontend, and production-grade observability.

---

## Architecture

```mermaid
graph LR
    Client([Client]) --> Nginx[nginx :8088]

    subgraph net_frontend[network: frontend]
        Nginx --> Frontend[frontend:80<br/>React + PWA]
        Nginx --> Backend[backend:8000<br/>Node.js API]
    end

    subgraph net_backend[network: backend<br/>internal: true]
        Backend --> Mongo[(mongodb:27017)]
        Backend --> Redis[(redis:6379)]
    end

    style net_backend fill:#ffe0e0
    style net_frontend fill:#e0f0ff
```

**Key decisions:**

- **nginx** = único entry point público (TLS, rate limit, headers de segurança centralizados)
- **frontend + backend** compartilham rede pública (nginx pode proxy para ambos)
- **backend** acessa mongo/redis por rede interna (`internal: true`) — DBs **nunca** expõem portas externamente
- Todas as portas internas usam `expose` (não `ports:`) — apenas o nginx expõe ao host

---

## Service Responsibilities

| Service | Image | Purpose | Expose |
|---------|-------|---------|--------|
| nginx | `nginx:alpine` | Reverse proxy, TLS termination, static assets cache, rate-limit | `ports: "8088:80"` |
| frontend | built locally | Serve SPA/PWA assets (production: nginx dentro do container) | `expose: "80"` |
| backend | built locally | Express API, business logic, auth | `expose: "8000"` |
| mongodb | `mongo:7.0` | Primary database | `expose: "27017"` |
| redis | `redis:7.2-alpine` | Cache, sessions, pub/sub | `expose: "6379"` |

---

## Environment Variables Strategy

**Rule**: Vite variables são **build-time**, não runtime.

```yaml
# docker-compose.yml — NÃO coloque VITE_* aqui!
frontend:
  image: myapp/frontend:${FRONTEND_VERSION:-1.0.0}
  # VITE_API_URL must be --build-arg at build time
```

```bash
# Build com variáveis embutidas
docker build \
  --build-arg VITE_API_URL=https://api.myapp.com \
  --target production \
  -t myapp/frontend:1.0.0 \
  -f frontend/Dockerfile .
```

**Backend**: runtime env vars normais (`MONGODB_URI`, `JWT_SECRET`, etc).

---

## Healthchecks — Mandatory

Todos os serviços **precisam** healthcheck. `depends_on` usa `condition: service_healthy`:

```yaml
nginx:
  healthcheck:
    test: ["CMD", "nginx", "-t"]
    interval: 30s
    timeout: 3s
    retries: 3
    start_period: 5s

backend:
  healthcheck:
    test: ["CMD", "wget", "--spider", "http://localhost:8000/health"]
    interval: 30s
    timeout: 3s
    retries: 3
    start_period: 15s

mongodb:
  healthcheck:
    test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
    interval: 10s
    start_period: 20s

redis:
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
```

**Sem healthcheck → sem `depends_on condition`** — ordem de startup vira caótica.

---

## Log Rotation — Mandatory

Todos os serviços:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

Impede disk-full em produção.

---

## Compose Override Pattern (NOT .yml.bak)

**Estrutura recomendada:**

```
docker-compose.yml              # Base — production-ready
docker-compose.override.yml     # Dev — hot reload, volume mounts (auto-loaded)
docker-compose.prod.yml         # Explicit prod overrides (CI/CD)
```

**Start dev**: `docker compose up` (carrega base + override)
**Start prod**: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up`

Nunca: `.yml.bak` no repo. Use git para versioning.

---

## Dev Workflow — Two-Target Pattern (default)

Two pre-built images per service: `<service>:dev` (dev) and `<service>:<version>` (prod). The override swaps `image:` to `:dev`, adds bind mounts, and overrides `command:` when needed.

### docker-compose.yml (base, prod-ready)

```yaml
services:
  frontend:
    image: myapp/frontend:${FRONTEND_VERSION:-1.0.0}
    expose: ["80"]
    # VITE_* NÃO aqui — build-arg na imagem de prod

  backend:
    image: myapp/backend:${BACKEND_VERSION:-1.0.0}
    expose: ["8000"]
```

### docker-compose.override.yml (auto-loaded in dev)

```yaml
services:
  frontend:
    image: myapp/frontend:dev            # ← swap to dev image (node + vite)
    volumes:
      - ./frontend:/app
      - ./shared:/app/shared
      - /app/node_modules          # anônimo — protege deps do container (não shadora host)
    environment:
      - NODE_ENV=development
      - VITE_API_URL=http://localhost:8088/api   # Vite dev server lê process.env em runtime
    # CMD já é `vite` no stage development — não precisa override de command

  backend:
    image: myapp/backend:dev              # ← swap to dev image (node + devDeps)
    volumes:
      - ./backend:/app
      - ./shared:/shared
      - /app/node_modules          # anônimo
    environment:
      - NODE_ENV=development
    command: ["npm", "run", "dev"]        # nodemon

  mongodb:
    ports:
      - "27017:27017"   # Expose for Compass/mongosh
```

### Build commands

**Dev images** (rebuild only when `package.json`/`package-lock.json` muda):

```bash
docker build --target development -t myapp/frontend:dev -f frontend/Dockerfile .
docker build --target development -t myapp/backend:dev  -f backend/Dockerfile .
```

**Prod images** (release flow):

```bash
docker build --target production --build-arg VITE_API_URL=$URL -t myapp/frontend:1.0.0 -f frontend/Dockerfile .
docker build --target production                          -t myapp/backend:1.0.0  -f backend/Dockerfile .
```

### .gitignore for Vite artifacts

Bind-mount da pasta inteira significa que o Vite grava `.timestamp-*` e `.vite/`
no diretório do host. Adicione ao `.gitignore` do frontend:

```
.vite/
.timestamp-*
```

### Vite vars in dev vs prod

| Env | VITE_API_URL | Por quê |
|-----|--------------|---------|
| Dev | runtime env em `docker-compose.override.yml` | Vite dev server lê `process.env` em tempo de request |
| Prod | `--build-arg VITE_API_URL=...` no build | Vite bakes env no bundle; runtime não tem efeito |

---

## Alternative: Unified-Image Pattern

Quando o custo de manter 2 imagens por serviço pesa mais que o tamanho da imagem de prod (ex.: muitos microserviços, deploys frequentes, você aceita devDeps em prod). Ver `standards/dockerfile-patterns.md` → Unified-Image Pattern.

Com unified-image, o `docker-compose.override.yml` **não** troca `image:` — só faz override de `command:` e adiciona `volumes`. Mesma imagem em dev e prod.

---

## Shared Constants (cross-stack)

Pasta `shared/` na raiz com constantes reutilizadas entre backend e frontend:

```
shared/
├── package.json               # "name": "@myapp/shared"
└── constants/
    └── asset-types.js         # export const ASSET_TYPES = { ... }
```

**No Dockerfile** (ambos back e front):

```dockerfile
COPY shared/ /shared/          # Self-contained, no volume mounts
```

**Não use symlinks absolutos** (`shared -> /home/user/...`) — quebra em CI. Use:
- Vite alias: `resolve.alias: { '@shared': path.resolve('./shared') }`
- npm workspaces no package.json raiz

---

## Secrets Management

**Dev**: `.env` (gitignored) + `.env.example` versionado

**Prod**: Docker secrets ou HashiCorp Vault — nunca `.env` em servidor prod.

```yaml
# docker-compose.prod.yml
backend:
  secrets:
    - jwt_secret
    - google_client_secret

secrets:
  jwt_secret:
    external: true
```

---

## Networks — Isolation Mandatory

```yaml
networks:
  frontend:
    driver: bridge
    name: myapp_frontend         # Named network
  backend:
    driver: bridge
    name: myapp_backend
    internal: true               # ⚠️ CRITICAL: no external access
```

**Regra**: backend network **sempre** `internal: true`. DBs e cache nunca devem ser acessíveis externamente.

---

## Related Context

- `standards/dockerfile-patterns.md` — multi-stage, non-root, dumb-init
- `stacks/nodejs-domain-structure.md` — backend modular pattern
- `stacks/react-domain-structure.md` — frontend PWA pattern
- `standards/security.md` — nginx hardening checklist
