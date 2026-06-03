# Prompt: Conversão OpenCode → Claude Code

Cole este prompt no Windsurf para converter seus agentes.

---

## PROMPT

Você é um especialista em migração de configurações de ferramentas de AI coding.
Sua tarefa é converter meus agentes e configurações do **OpenCode** para o **Claude Code**, garantindo paridade total de comportamento.

---

### CONTEXTO DO MEU PROJETO

Minha estrutura atual no OpenCode:

```
agent/
├── core/
│   └── master.md          ← agente primário (orquestrador SDLC)
└── subagents/
    ├── analysis/
    │   ├── code-analyzer.md
    │   └── impl-reviewer-nodejs.md
    ├── code/
    │   ├── backend-developer.md
    │   ├── bug-fixer-nodejs.md
    │   ├── build-agent.md
    │   ├── code-reviewer.md
    │   ├── __OLD_teste.md     ← IGNORAR, não converter
    │   └── test-engineer.md
    ├── core/
    │   ├── contextscout.md
    │   ├── documentation.md
    │   ├── externalscout.md
    │   └── task-manager.md
    ├── development/
    │   ├── devops-specialist.md
    │   ├── frontend-developer-angular.md
    │   ├── frontend-developer.md
    │   ├── frontend-developer-react.md
    │   ├── frontend-developer-vue.md
    │   ├── shell-developer.md
    │   └── ux-designer.md
    ├── sdlc/
    │   ├── architect.md
    │   ├── merge-request-creator.md
    │   ├── product-manager.md
    │   ├── product-owner.md
    │   ├── qa-analyst.md
    │   ├── system-architect.md
    │   └── tech-lead.md       ← subagente orquestrador de story
    └── system-builder/
        └── context-organizer.md
```

Provedor: **Ollama cloud** com modelos `glm-5.1:cloud` e `deepseek-v4-flash:cloud`.
Variável de ambiente já configurada: `ANTHROPIC_BASE_URL` apontando para o Ollama.

---

### REGRAS DE CONVERSÃO

Aplique estas regras a CADA arquivo convertido:

**Estrutura de destino:**
- Todos os agentes vão para `.claude/agents/` (estrutura plana, sem subpastas)
- O nome do arquivo é preservado exatamente como está
- `__OLD_teste.md` deve ser ignorado (não converter)

**Frontmatter — campo a campo:**

| Campo OpenCode | Ação no Claude Code |
|---|---|
| `name` | Manter igual |
| `description` | Manter LITERALMENTE — é o gatilho de invocação automática |
| `mode: primary` | Remover — `master.md` vira o `defaultAgent` no `settings.json` |
| `mode: subagent` | Remover — todos em `.claude/agents/` são tratados como subagentes |
| `model: ollama/xxx` | Trocar para só o nome: `glm-5.1:cloud` ou `deepseek-v4-flash:cloud` |
| `temperature` | Remover do frontmatter — CC não suporta por agente |
| `steps` / `maxSteps` | Remover — sem equivalente no frontmatter CC |
| `permission.edit: allow` + `permission.bash: allow` | `tools: ["Read","Write","Edit","Bash","Glob","Grep","LS"]` |
| `permission.edit: deny` + `permission.bash: allow` | `tools: ["Read","Bash","Glob","Grep","LS"]` |
| `permission.edit: deny` + `permission.bash: deny` | `tools: ["Read","Glob","Grep","LS"]` |
| `permission.edit: allow` + `permission.bash: deny` | `tools: ["Read","Write","Edit","Glob","Grep","LS"]` |
| `permission.write` com glob por caminho | Sem equivalente — remover e documentar em comentário YAML |
| `permission.task` | Sem equivalente — remover e documentar em comentário YAML |
| `permission.read` com glob deny | Sem equivalente — remover e documentar em comentário YAML |
| `permission.skill` | Sem equivalente — remover |
| `permission.webfetch: allow` | Adicionar `"WebFetch"` à lista de tools |
| `permission.websearch: allow` | Adicionar `"WebSearch"` à lista de tools |
| `permission.todowrite: allow` | Adicionar `"TodoWrite"` à lista de tools |
| `hidden: true` | Sem equivalente — remover |
| `color` | Sem equivalente — remover |
| `top_p` | Sem equivalente — remover |
| `disable: true` | Não converter o arquivo |

**System prompt (corpo do markdown):**
- Copiar LITERALMENTE sem nenhuma alteração de conteúdo
- Substituir referências `.opencode/` por `.claude/` onde aparecerem em caminhos de arquivo
- Não reescrever, resumir, ou "melhorar" o prompt — paridade total é a meta

**Caso especial — `master.md`:**
- Remover `mode: primary` do frontmatter
- Gerar também o arquivo `.claude/settings.json` com `"defaultAgent": "master"`
- Manter toda a lógica de orquestração intacta

**Caso especial — `tech-lead.md`:**
- O campo `write: "docs/stories/**": allow` não tem equivalente no CC
- Colocar `tools: ["Read","Write","Edit","Bash","Glob","Grep","LS","TodoWrite"]`
- Adicionar comentário YAML: `# NOTA: OC restringia write a docs/stories/** — CC não suporta glob por caminho`

---

### FORMATO DE SAÍDA ESPERADO

Para cada arquivo, gere:

```
## Convertendo: <nome-do-arquivo>.md

### Diferenças aplicadas:
- <lista apenas o que mudou no frontmatter>

### Arquivo convertido:
<bloco de código com o conteúdo completo do arquivo .md>
```

Ao final, gere o `.claude/settings.json`.

---

### ORDEM DE CONVERSÃO

Converta nesta ordem (do mais crítico para o menos):
1. `master.md` + `settings.json`
2. `tech-lead.md`
3. `contextscout.md`, `externalscout.md`
4. Todos os agentes de `sdlc/` (architect, product-manager, product-owner, qa-analyst, system-architect, merge-request-creator)
5. Todos os agentes de `code/` (backend-developer, bug-fixer-nodejs, build-agent, code-reviewer, test-engineer)
6. Todos os agentes de `analysis/`
7. Todos os agentes de `development/`
8. Agentes restantes de `core/` e `system-builder/`

---

### CHECKLIST PÓS-CONVERSÃO

Após converter todos os arquivos, gere um checklist confirmando para cada agente:

- [ ] `description` preservado literalmente
- [ ] `model` sem prefixo `ollama/`
- [ ] `permission.*` mapeado para lista `tools`
- [ ] System prompt copiado sem alteração
- [ ] Referências `.opencode/` atualizadas para `.claude/`
- [ ] Campos sem equivalente documentados em comentário YAML

---

**Pode começar pelo `master.md` e `settings.json`. Leia o arquivo original antes de converter.**
