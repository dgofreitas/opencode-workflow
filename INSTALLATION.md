# Instalação e Configuração

Este documento explica como instalar e configurar o New OpenCode Workflow no OpenCode CLI.

---

## Instalação Rápida (Recomendado)

Use o script de instalação automatizado:

```bash
# Clone ou baixe o workflow
git clone <repo-url> new-opencode-workflow
cd new-opencode-workflow

# Executar instalador (modo interativo)
bash install.sh

# Ou especificar tipo diretamente:
bash install.sh --global   # Instalar em ~/.config/opencode/
bash install.sh --local    # Instalar em ./.opencode/
bash install.sh --hybrid   # Global core + local project
```

### Scripts Disponíveis

| Script | Uso | Descrição |
|--------|-----|-----------|
| `install.sh` | `bash install.sh [--global\|--local\|--hybrid]` | Instala o workflow |
| `update.sh` | `bash update.sh [--global\|--local]` | Atualiza instalação existente |
| `uninstall.sh` | `bash uninstall.sh [--global\|--local\|--all]` | Remove instalação |

---

## Pré-requisitos

1. **OpenCode CLI** instalado - [Documentação oficial](https://opencode.ai/docs)
   ```bash
   # Verificar se está instalado
   opencode --version
   ```

2. **Bun** (runtime JavaScript) - [Instalar Bun](https://bun.sh)
   ```bash
   # Verificar se está instalado
   bun --version
   ```

---

## Opções de Instalação

| Tipo | Localização | Quando usar |
|------|-------------|-------------|
| **Global** | `~/.config/opencode/` | Padrões pessoais, usar em múltiplos projetos |
| **Local** | `.opencode/` no projeto | Padrões específicos do projeto, compartilhar com equipe |

---

## Instalação Global

Use quando quiser ter os agentes disponíveis em **todos os seus projetos**.

### Passo 1: Criar diretório de configuração

```bash
# Criar diretório se não existir
mkdir -p ~/.config/opencode
```

### Passo 2: Copiar o workflow

```bash
# Copiar todos os componentes
cp -r /caminho/para/new-opencode-workflow/agent ~/.config/opencode/
cp -r /caminho/para/new-opencode-workflow/command ~/.config/opencode/
cp -r /caminho/para/new-opencode-workflow/config ~/.config/opencode/
cp -r /caminho/para/new-opencode-workflow/context ~/.config/opencode/
cp -r /caminho/para/new-opencode-workflow/skills ~/.config/opencode/
cp -r /caminho/para/new-opencode-workflow/tool ~/.config/opencode/
cp /caminho/para/new-opencode-workflow/package.json ~/.config/opencode/
```

### Passo 3: Instalar dependências

```bash
cd ~/.config/opencode
bun install
```

### Passo 4: Verificar instalação

```bash
# Verificar estrutura
ls ~/.config/opencode/
# Deve mostrar: agent/ command/ config/ context/ skills/ tool/ package.json

# Verificar agentes
ls ~/.config/opencode/agent/core/
# Deve mostrar: openagent.md opencoder.md
```

### Passo 5: Executar

```bash
# Em qualquer projeto
cd /caminho/para/seu/projeto
opencode --agent OpenAgent
```

---

## Instalação Local (Por Projeto)

Use quando quiser **padrões específicos do projeto** que serão compartilhados com a equipe via Git.

### Passo 1: Criar diretório no projeto

```bash
cd /caminho/para/seu/projeto
mkdir -p .opencode
```

### Passo 2: Copiar o workflow

```bash
# Copiar todos os componentes
cp -r /caminho/para/new-opencode-workflow/agent .opencode/
cp -r /caminho/para/new-opencode-workflow/command .opencode/
cp -r /caminho/para/new-opencode-workflow/config .opencode/
cp -r /caminho/para/new-opencode-workflow/context .opencode/
cp -r /caminho/para/new-opencode-workflow/skills .opencode/
cp -r /caminho/para/new-opencode-workflow/tool .opencode/
cp /caminho/para/new-opencode-workflow/package.json .opencode/
```

### Passo 3: Instalar dependências

```bash
cd .opencode
bun install
```

### Passo 4: Adicionar ao .gitignore (apenas node_modules)

```bash
# No .gitignore do projeto
echo ".opencode/node_modules/" >> .gitignore
```

**Importante:** NÃO adicione `.opencode/` inteiro ao .gitignore. A equipe precisa dos agentes e contextos!

### Passo 5: Commit para compartilhar com equipe

```bash
git add .opencode/
git commit -m "Add OpenCode workflow with SDLC agents"
git push
```

### Passo 6: Executar

```bash
# Na raiz do projeto
opencode --agent OpenAgent
```

---

## Instalação Híbrida (Recomendado para Equipes)

Use **global** para os padrões core + **local** para inteligência do projeto.

### Estrutura resultante:

```
~/.config/opencode/           # Global (seus padrões pessoais)
├── agent/core/               # OpenAgent, OpenCoder
├── context/core/             # Standards, workflows
└── ...

/projeto/.opencode/           # Local (específico do projeto)
├── context/project-intelligence/  # Living notes, decisions
├── context/project/          # Project context
└── ...
```

### Como funciona:

1. **ContextScout** verifica primeiro o local (`.opencode/context/`)
2. Se não encontrar, verifica o global (`~/.config/opencode/context/`)
3. **Local sempre vence** - permite customizar por projeto

### Passos:

```bash
# 1. Instalar global (conforme instruções acima)

# 2. No projeto, criar apenas o que é específico
cd /caminho/para/seu/projeto
mkdir -p .opencode/context/project-intelligence
mkdir -p .opencode/context/project

# 3. Criar contexto do projeto
# (veja seção "Configurar Contexto do Projeto" abaixo)
```

---

## Executar o OpenCode

### Modo Interativo (Recomendado)

```bash
# Iniciar com OpenAgent (entry point universal)
opencode --agent OpenAgent

# Ou com OpenCoder (foco em desenvolvimento)
opencode --agent OpenCoder
```

### Usar Comandos Slash

```bash
opencode --agent OpenAgent

# Dentro do OpenCode, digite:
/story criar um app de finanças
/plan docs/stories/STORY-001.md
/implement docs/stories/STORY-001.md
/review
/qa docs/stories/STORY-001.md
/mr main
```

### Especificar Agente Diretamente

```bash
# Executar agente específico
opencode --agent ProductManager
> "Criar story para autenticação de usuários"

opencode --agent Architect
> "Analisar arquitetura para sistema de pagamentos"

opencode --agent TechLead
> "Implementar STORY-001"
```

---

## Configurar Contexto do Projeto

Para que os agentes gerem código que **combina com seu projeto**, configure o contexto.

### Opção 1: Usar o comando /add-context

```bash
opencode --agent OpenAgent

# Dentro do OpenCode:
/add-context
```

O agente fará perguntas sobre:
1. Tech stack (frameworks, linguagens, databases)
2. Padrões de API
3. Padrões de componentes
4. Convenções de nomenclatura
5. Padrões de segurança
6. Requisitos específicos

### Opção 2: Criar manualmente

Criar arquivo `.opencode/context/project/project-context.md`:

```markdown
# Project Context

## Tech Stack
- Frontend: React 18 + TypeScript + Tailwind CSS
- Backend: Node.js + Express + TypeScript
- Database: PostgreSQL + Prisma ORM
- Testing: Jest + React Testing Library

## API Patterns
- Validation: Zod schemas
- Error handling: Centralized error middleware
- Response format: `{ success: boolean, data?: T, error?: string }`

## Component Patterns
- Functional components only
- Props interface defined above component
- Tailwind for styling (no CSS modules)
- React Query for data fetching

## Naming Conventions
- Files: kebab-case (`user-profile.tsx`)
- Components: PascalCase (`UserProfile`)
- Functions: camelCase (`fetchUserData`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)

## Security
- Input validation on all endpoints
- JWT for authentication
- Rate limiting on public APIs
- Parameterized queries only (no string interpolation)
```

---

## Verificar Instalação

### Checklist de Verificação

```bash
# 1. Verificar estrutura
ls -la ~/.config/opencode/          # Global
ls -la .opencode/                   # Local (no projeto)

# 2. Verificar agentes
find ~/.config/opencode/agent -name "*.md" | wc -l
# Deve retornar: 41

# 3. Verificar comandos
find ~/.config/opencode/command -name "*.md" | wc -l
# Deve retornar: 12

# 4. Verificar contexto
ls ~/.config/opencode/context/core/navigation.md
# Deve existir

# 5. Verificar metadata
cat ~/.config/opencode/config/agent-metadata.json | grep -c '"id"'
# Deve retornar: 41
```

### Teste Rápido

```bash
opencode --agent OpenAgent

# Digite:
> "Olá, qual é o seu propósito?"

# Resposta esperada: OpenAgent deve explicar que é o agente universal
# que recebe pedidos, classifica, e delega para especialistas.
```

---

## Estrutura Final Esperada

### Instalação Global

```
~/.config/opencode/
├── agent/
│   ├── core/
│   │   ├── openagent.md
│   │   └── opencoder.md
│   └── subagents/
│       ├── analysis/          # 6 agentes
│       ├── code/              # 16 agentes
│       ├── core/              # 4 agentes
│       ├── development/       # 6 agentes
│       ├── sdlc/              # 5 agentes
│       └── system-builder/    # 1 agente
├── command/
│   ├── sdlc/                  # 8 comandos SDLC
│   ├── commit.md
│   ├── test.md
│   ├── context.md
│   └── clean.md
├── config/
│   └── agent-metadata.json
├── context/
│   ├── core/                  # Standards, workflows
│   ├── development/           # Language guides
│   ├── project-intelligence/  # Living notes
│   └── project/               # Project context
├── skills/
│   ├── task-management/
│   └── context7/
├── tool/
│   └── env/
├── package.json
└── node_modules/
```

### Instalação Local

```
/projeto/.opencode/
├── agent/                     # Mesma estrutura
├── command/
├── config/
├── context/
├── skills/
├── tool/
├── package.json
└── node_modules/              # No .gitignore
```

---

## Troubleshooting

### "Agent not found"

```bash
# Verificar se o agente existe
ls ~/.config/opencode/agent/core/openagent.md

# Verificar metadata
cat ~/.config/opencode/config/agent-metadata.json | grep OpenAgent
```

### "Context not loading"

```bash
# Verificar navigation.md
cat ~/.config/opencode/context/core/navigation.md

# Verificar se ContextScout existe
ls ~/.config/opencode/agent/subagents/core/contextscout.md
```

### "Commands not working"

```bash
# Verificar se comandos existem
ls ~/.config/opencode/command/sdlc/

# Verificar frontmatter dos comandos
head -5 ~/.config/opencode/command/sdlc/story.md
# Deve ter: ---
#           description: ...
#           ---
```

### "Bun install fails"

```bash
# Verificar versão do Bun
bun --version  # Deve ser >= 1.0.0

# Limpar cache e reinstalar
rm -rf ~/.config/opencode/node_modules
cd ~/.config/opencode && bun install
```

---

## Próximos Passos

1. **Configure o contexto do projeto** - Use `/add-context` ou crie manualmente
2. **Teste o pipeline SDLC** - Digite `/story criar uma feature de login`
3. **Explore os agentes** - Use `/plan`, `/implement`, `/review`, `/qa`, `/mr`
4. **Personalize** - Edite os agentes em `.md` para ajustar ao seu workflow

---

## Referência Rápida

| Comando | Descrição |
|---------|-----------|
| `opencode --agent OpenAgent` | Inicia com agente universal |
| `opencode --agent OpenCoder` | Inicia com agente de desenvolvimento |
| `/story <desc>` | Cria user story |
| `/plan <story>` | Cria plano técnico |
| `/implement <story>` | Executa implementação |
| `/review` | Code review |
| `/qa <story>` | Validação QA |
| `/mr` | Cria merge request |
| `/bugfix <desc>` | Diagnostica e corrige bug |
| `/analyze` | Analisa codebase |
