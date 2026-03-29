# Guia Prático de Uso

Este documento explica como usar o New OpenCode Workflow no dia a dia.

---

## Iniciando o OpenCode

### Com OpenAgent (Recomendado para Início)

```bash
opencode --agent OpenAgent
```

**Use quando:**
- Quer fazer qualquer coisa (perguntas, tarefas, features completas)
- Não sabe qual agente usar
- Quer o pipeline SDLC automático
- Quer delegação automática para especialistas

### Com OpenCoder (Desenvolvimento Focado)

```bash
opencode --agent OpenCoder
```

**Use quando:**
- Sabe que vai implementar código
- Quer desenvolvimento direto, sem passar pelo ProductManager
- Está trabalhando em tarefas de código específicas
- Não precisa de story/plano (já sabe o que fazer)

---

## Diferença: OpenAgent vs OpenCoder

| Característica | OpenAgent | OpenCoder |
|----------------|-----------|-----------|
| **Propósito** | Universal - faz tudo | Especializado em código |
| **SDLC Pipeline** | Detecta automaticamente e inicia | Executa diretamente |
| **Perguntas** | Responde diretamente | Redireciona para OpenAgent |
| **Features completas** | PM → Architect → TechLead → ... | TechLead direto |
| **Delegação** | Delega para qualquer subagent | Delega para agentes de código |
| **Melhor para** | Início de qualquer tarefa | Implementação de código conhecido |

### Quando Usar Cada Um

```
┌─────────────────────────────────────────────────────────────────┐
│                     QUAL AGENTE USAR?                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  "Quero criar um app de finanças"                               │
│  → OpenAgent (detecta feature, inicia SDLC)                     │
│                                                                  │
│  "Como funciona o JWT?"                                         │
│  → OpenAgent (responde pergunta)                                 │
│                                                                  │
│  "Implemente a função de login que planejamos"                   │
│  → OpenCoder (implementação direta)                             │
│                                                                  │
│  "Corrija o bug no arquivo auth.ts"                             │
│  → OpenCoder (correção de código)                               │
│                                                                  │
│  "Adicione testes para o módulo de pagamentos"                   │
│  → OpenCoder (delega para TestEngineer)                         │
│                                                                  │
│  "Analise a arquitetura do projeto"                             │
│  → OpenAgent (delega para Architect/CodeAnalyzer)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Usando Linguagem Natural

### Features Completas (SDLC Automático)

**Diga:**
```
"Crie um site de investimento com:
 - Dashboard de portfólio
 - Gráficos de performance
 - Exportação CSV
 - Login com Google"
```

**O que acontece:**
```
OpenAgent detecta: Feature request complexa
    ↓
ProductManager: Cria STORY-001.md
    ↓
Architect: Cria plano técnico
    ↓
TechLead: Coordena implementação
    ↓
BackendDeveloper + FrontendDeveloperReact: Implementam
    ↓
TestEngineer: Cria testes
    ↓
CodeReviewer: Revisa código
    ↓
QAAnalyst: Valida acceptance criteria
    ↓
MergeRequestCreator: Cria MR
    ↓
PR pronto para merge!
```

### Perguntas (Resposta Direta)

**Diga:**
```
"Como funciona o sistema de contexto?"
"O que faz o ContextScout?"
"Quais agentes estão disponíveis?"
```

**O que acontece:**
```
OpenAgent detecta: Pergunta informativa
    ↓
Resposta direta (sem execução)
```

### Tarefas Simples (Execução Direta)

**Diga:**
```
"Adicione um botão no header"
"Corrija o typo no README"
"Mude a cor do botão para azul"
```

**O que acontece:**
```
OpenAgent detecta: Tarefa simples
    ↓
ContextScout: Carrega padrões
    ↓
Execução direta (sem SDLC completo)
    ↓
Aprovação → Implementação
```

### Bugs (Diagnóstico e Correção)

**Diga:**
```
"O login não está funcionando, aparece erro 500"
"Corrija o bug no módulo de pagamentos"
```

**O que acontece:**
```
OpenAgent detecta: Bug report
    ↓
BugFixer[Language]: Diagnóstica
    ↓
Root cause analysis
    ↓
Propõe correção
    ↓
Aprovação → Correção → Testes
```

---

## Usando Comandos Slash

### Quando Usar Comandos

| Comando | Quando Usar |
|---------|-------------|
| `/story` | Quer APENAS criar a story, sem implementar ainda |
| `/plan` | Quer APENAS o plano técnico, revisar antes |
| `/implement` | Já tem story/plano, quer executar |
| `/review` | Quer review de código existente |
| `/qa` | Quer validação QA |
| `/mr` | Quer criar MR |
| `/bugfix` | Quer diagnosticar e corrigir bug |
| `/analyze` | Quer análise de arquitetura |
| `/commit` | Quer criar commit formatado |
| `/test` | Quer rodar testes |
| `/context` | Quer gerenciar contexto |

### Fluxo com Comandos (Controle Passo a Passo)

```bash
opencode --agent OpenAgent

# Passo 1: Criar story
> /story criar sistema de notificações por email

# OpenAgent: ProductManager cria STORY-001.md
# Você: Revisa a story, ajusta se necessário

# Passo 2: Criar plano técnico
> /plan STORY-001

# OpenAgent: Architect cria technical-analysis.md
# Você: Revisa o plano, ajusta se necessário

# Passo 3: Implementar
> /implement STORY-001

# OpenAgent: TechLead coordena implementação completa

# Passo 4: Review (opcional, já foi feito no implement)
> /review

# Passo 5: QA (opcional, já foi feito no implement)
> /qa STORY-001

# Passo 6: Criar MR
> /mr main
```

### Fluxo com Linguagem Natural (Automático)

```bash
opencode --agent OpenAgent

# Uma frase, pipeline completo
> "Crie um sistema de notificações por email com templates, fila, e retry"

# OpenAgent faz TUDO automaticamente:
# - ProductManager cria story
# - Architect cria plano
# - TechLead implementa
# - QA valida
# - MR criado

# Você só aprova nas etapas!
```

---

## Exemplos Práticos

### Exemplo 1: App de Finanças

```bash
opencode --agent OpenAgent

> "Crie um aplicativo de finanças pessoais com:
   - Dashboard de gastos mensais
   - Categorização automática de transações
   - Gráficos de evolução
   - Exportação para Excel
   - Login com email/senha"

# OpenAgent detecta: Feature completa
# Pipeline: PM → Architect → TechLead → BackendDeveloper + FrontendDeveloperReact → TestEngineer → CodeReviewer → QAAnalyst → MR
```

### Exemplo 2: Bug em Produção

```bash
opencode --agent OpenCoder

> "O endpoint /api/payments está retornando 500 quando o usuário usa cupom de desconto. Corrija."

# OpenCoder detecta: Bug
# Pipeline: BugFixerNodejs → Diagnóstico → Correção → Testes
```

### Exemplo 3: Adicionar Feature em Código Existente

```bash
opencode --agent OpenCoder

> "Adicione autenticação de dois fatores (2FA) no sistema de login existente"

# OpenCoder detecta: Feature em código existente
# Pipeline: ContextScout → Implementação direta → TestEngineer → CodeReviewer
```

### Exemplo 4: Análise de Arquitetura

```bash
opencode --agent OpenAgent

> /analyze

# OpenAgent delega para CodeAnalyzer
# Output: Análise completa da arquitetura, padrões, e débitos técnicos
```

### Exemplo 5: Code Review

```bash
opencode --agent OpenAgent

> /review src/

# OpenAgent delega para CodeReviewer
# Output: Relatório de segurança, qualidade, e sugestões
```

### Exemplo 6: Apenas Pergunta

```bash
opencode --agent OpenAgent

> "Como implementar websockets com Socket.io no Next.js?"

# OpenAgent responde diretamente
# Sem execução, sem pipeline
```

---

## Fluxos por Tipo de Pedido

### Feature Nova Completa

```
Pedido: "Crie um sistema de X com Y e Z"
    ↓
OpenAgent detecta: SDLC Pipeline
    ↓
┌─────────────────────────────────────────────────────────────┐
│  1. ProductManager                                           │
│     → Cria STORY-XXX.md com acceptance criteria             │
│                                                              │
│  2. Architect                                                │
│     → Cria technical-analysis.md com batches                │
│                                                              │
│  3. TechLead                                                 │
│     → Coordena execução                                      │
│     → Delega para BackendDeveloper + FrontendDeveloper       │
│                                                              │
│  4. TestEngineer                                             │
│     → Cria testes (≥90% coverage)                           │
│                                                              │
│  5. CodeReviewer                                              │
│     → Review de segurança e qualidade                       │
│                                                              │
│  6. QAAnalyst                                                │
│     → Valida acceptance criteria                            │
│                                                              │
│  7. MergeRequestCreator                                      │
│     → Cria MR com toda evidência                            │
└─────────────────────────────────────────────────────────────┘
```

### Modificação Simples

```
Pedido: "Mude a cor do botão para azul"
    ↓
OpenAgent detecta: Task simples
    ↓
┌─────────────────────────────────────────────────────────────┐
│  1. ContextScout                                             │
│     → Carrega padrões de styling                            │
│                                                              │
│  2. Execução direta                                          │
│     → Edita o arquivo                                        │
│     → Sem pipeline SDLC                                      │
└─────────────────────────────────────────────────────────────┘
```

### Bug

```
Pedido: "O login não funciona, erro 500"
    ↓
OpenAgent/OpenCoder detecta: Bug
    ↓
┌─────────────────────────────────────────────────────────────┐
│  1. BugFixer[Language]                                       │
│     → Reproduz o bug                                         │
│     → Root cause analysis                                    │
│                                                              │
│  2. Proposta de correção                                     │
│     → Você aprova                                            │
│                                                              │
│  3. Correção                                                 │
│     → Implementa fix                                         │
│     → Adiciona testes de regressão                          │
│                                                              │
│  4. Validação                                                │
│     → Testes passando                                        │
│     → Bug corrigido                                          │
└─────────────────────────────────────────────────────────────┘
```

### Pergunta

```
Pedido: "Como funciona X?"
    ↓
OpenAgent detecta: Pergunta
    ↓
┌─────────────────────────────────────────────────────────────┐
│  Resposta direta                                             │
│  → Sem execução                                              │
│  → Sem pipeline                                              │
│  → Sem aprovação                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Dicas Práticas

### 1. Comece com OpenAgent

Sempre comece com `opencode --agent OpenAgent`. Ele sabe quando delegar para OpenCoder ou outros especialistas.

### 2. Seja Específico

**Bom:**
```
"Crie um sistema de agendamento com:
 - Calendário visual mensal
 - Criação de eventos com título, data, hora
 - Notificações por email 1h antes
 - Compartilhamento de eventos entre usuários"
```

**Ruim:**
```
"Crie um calendário"
```

### 3. Use Comandos para Controle

Se quer revisar antes de prosseguir:
```
/story criar sistema X    # Para, revisa story
/plan STORY-001           # Para, revisa plano
/implement STORY-001      # Executa
```

### 4. Deixe o Pipeline Rodar

Para features completas, use linguagem natural e deixe o OpenAgent gerenciar:
```
"Crie um e-commerce completo com carrinho, checkout, e pagamentos"
# OpenAgent faz tudo, você só aprova nas etapas
```

### 5. Para Bugs, Seja Preciso

```
"O endpoint POST /api/users retorna 500 quando o email já existe.
 Esperado: retornar 409 Conflict com mensagem 'Email already registered'.
 Atual: retorna 500 Internal Server Error."
```

---

## Resumo Rápido

| Situação | Agente | Como Pedir |
|----------|--------|------------|
| Feature completa | OpenAgent | Linguagem natural: "Crie um..." |
| Pergunta | OpenAgent | Linguagem natural: "Como funciona...?" |
| Bug | OpenAgent ou OpenCoder | "O bug X acontece quando..." |
| Modificação simples | OpenAgent ou OpenCoder | "Mude X para Y" |
| Implementação direta | OpenCoder | "Implemente a função X" |
| Code review | OpenAgent | `/review` |
| Análise | OpenAgent | `/analyze` |
| Controle passo a passo | OpenAgent | `/story` → `/plan` → `/implement` |
