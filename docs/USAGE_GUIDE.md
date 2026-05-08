# Guia Prático de Uso

Este documento explica como usar o New OpenCode Workflow no dia a dia.

---

## Iniciando o OpenCode

### Com Master (Recomendado para Início)

```bash
opencode --agent Master
```

**Use quando:**
- Quer fazer qualquer coisa (perguntas, tarefas, features completas)
- Não sabe qual agente usar
- Quer o pipeline SDLC automático
- Quer delegação automática para especialistas

---

## Fluxo de Decisão

```mermaid
graph TD
    Q{{"QUAL FLUXO USAR?"}}
    Q -->|"Criar um app de finanças"| A1["Master detecta feature,<br/>inicia SDLC Pipeline"]
    Q -->|"Como funciona o JWT?"| A2["Master responde pergunta<br/>(Sem execução)"]
    Q -->|"Defina a visão e épicos do produto"| A5["Master delega para ProductOwner<br/>(Visão, épicos, estratégia)"]
    Q -->|"Implemente a função de login"| A3["Master delega para especialista<br/>(Backend/Frontend)"]
    Q -->|"Corrija o bug em auth.ts"| A4["Master delega para BugFixer"]
    Q -->|"Analise a arquitetura"| A6["Master delega para Architect"]
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
```mermaid
graph TD
    Start["Pedido: 'Crie um site de investimento...'"] --> Detect["Master detecta: SDLC Pipeline"]
    Detect --> PO["0. ProductOwner (se necessário)\nCria visão, épicos, roadmap"]
    PO --> G0{{"GATE #0\nVocê revê épicos e aprova"}}
    G0 --> PM["1. ProductManager\nDecompõe épicos em STORY-001.md"]
    PM --> G1{{"GATE #1\nVocê revê stories e aprova"}}
    G1 --> SA["1.5. SystemArchitect (se greenfield)\nDefine stack e scaffold"]
    SA --> GSA{{"GATE #SA\nVocê aprova a stack"}}
    GSA --> Arch["2. Architect\nCria technical-analysis.md com batches"]
    G1 -->|"se projeto existente"| Arch
    Arch --> G2{{"GATE #2\nVocê revê plano técnico e aprova"}}
    G2 --> TL["3. TechLead - ciclo completo\nbranch feat/STORY-001\nImpl → Test → QA → Review → MR"]
    TL --> G3{{"GATE #3\nStory completa → próxima story?"}}
    G3 -->|"sim"| TL
```

### Perguntas (Resposta Direta)

**Diga:**
```
"Como funciona o sistema de contexto?"
"O que faz o ContextScout?"
"Quais agentes estão disponíveis?"
```

**O que acontece:**
```mermaid
graph TD
    Start["Pedido: 'Como funciona o sistema de contexto?'"] --> Detect["Master detecta: Pergunta"]
    Detect --> Resp["Resposta direta\nSem execução, sem pipeline, sem aprovação"]
```

### Tarefas Simples (Execução Direta)

**Diga:**
```
"Adicione um botão no header"
"Corrija o typo no README"
"Mude a cor do botão para azul"
```

**O que acontece:**
```mermaid
graph TD
    Start["Pedido: 'Mude a cor do botão para azul'"] --> Detect["Master detecta: Task simples"]
    Detect --> CS["1. ContextScout\nCarrega padrões de styling"]
    CS --> Exec["2. Execução direta\nEdita o arquivo (sem pipeline SDLC)"]
```

### Bugs (Diagnóstico e Correção)

**Diga:**
```
"O login não está funcionando, aparece erro 500"
"Corrija o bug no módulo de pagamentos"
```

**O que acontece:**
```mermaid
graph TD
    Start["Pedido: 'O login não funciona, erro 500'"] --> Detect["Master detecta: Bug"]
    Detect --> BF["1. BugFixer\nReproduz o bug + Root cause analysis"]
    BF --> Prop["2. Proposta de correção\nVocê aprova"]
    Prop --> Fix["3. Correção\nImplementa fix + testes de regressão"]
    Fix --> Val["4. Validação\nTestes passando, bug corrigido"]
```

---

## Usando Comandos Slash

### Quando Usar Comandos

| Comando | Quando Usar |
|---------|-------------|
| `/epic` | Quer criar/analisar épicos, visão, roadmap (ProductOwner) |
| `/scaffold` | Quer definir stack e criar estrutura para projeto novo (SystemArchitect) |
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
opencode --agent Master

# Passo 0: Definir épicos (opcional, para features grandes)
> /epic criar visão e épicos para sistema de notificações
# ProductOwner cria visão e épicos
# ⏸️ GATE #0: Você revisa épicos, aprova para prosseguir

# Passo 1: Criar story
> /story criar sistema de notificações por email

# ProductManager cria STORY-001.md
# ⏸️ GATE #1: Você revisa a story, aprova para prosseguir

# Passo 1.5: Setup da Stack (Apenas projetos greenfield)
> /scaffold

# SystemArchitect propõe a stack e faz o scaffolding
# ⏸️ GATE #SA: Você revisa a stack, aprova para criar os arquivos

# Passo 2: Criar plano técnico
> /plan STORY-001

# Architect cria technical-analysis.md
# ⏸️ GATE #2: Você revisa o plano, aprova para implementar

# Passo 3: Implementar (ciclo completo!)
> /implement STORY-001

# TechLead orquestra o ciclo completo:
# impl → testes → QA → review → MR
# (NÃO precisa de /review, /qa, /mr separados!)
# ⏸️ GATE #3: Story completa, você aprova para próxima
```

### Fluxo com Linguagem Natural (Automático)

```bash
opencode --agent Master

# Uma frase, pipeline completo
> "Crie um sistema de notificações por email com templates, fila, e retry"

# Master orquestra o SDLC com 3-5 approval gates:
# 0. ProductOwner cria épicos (se necessário)
#    ⏸️ GATE #0: Você aprova
# 1. ProductManager cria stories
#    ⏸️ GATE #1: Você aprova
# 1.5. SystemArchitect (se greenfield) define stack
#    ⏸️ GATE #SA: Você aprova
# 2. Architect cria plano
#    ⏸️ GATE #2: Você aprova
# 3. TechLead executa ciclo completo (impl→test→QA→review→MR)
#    ⏸️ GATE #3: Story completa, próxima story?
```

---

## Exemplos Práticos

### Exemplo 1: App de Finanças (Projeto Greenfield)

```bash
opencode --agent Master

> "Crie um aplicativo de finanças pessoais com:
   - Dashboard de gastos mensais
   - Categorização automática de transações
   - Gráficos de evolução
   - Exportação para Excel
   - Login com email/senha"

# Master detecta: Feature completa em greenfield
# Pipeline: ProductOwner(épicos) → PM(stories) → ⏸️#1 → SystemArchitect(stack) → ⏸️#SA → Architect → ⏸️#2 → TechLead(impl→test→QA→review→MR) → ⏸️#3
```

### Exemplo 2: Bug em Backend Node.js

```bash
opencode --agent Master

> "O endpoint /api/payments está retornando 500 quando o usuário usa cupom de desconto. Corrija."

# Master detecta: Bug
# Pipeline: BugFixerNodejs → Diagnóstico → Correção → Testes
```

### Exemplo 3: Adicionar Feature em Código Existente

```bash
opencode --agent Master

> "Adicione autenticação de dois fatores (2FA) no sistema de login existente"

# Master detecta: Feature em código existente
# Pipeline: ContextScout → Implementação direta (Especialista) → TestEngineer → CodeReviewer
```

### Exemplo 4: Análise de Arquitetura

```bash
opencode --agent Master

> /analyze

# Master delega para CodeAnalyzer
# Output: Análise completa da arquitetura, padrões, e débitos técnicos
```

### Exemplo 5: Code Review

```bash
opencode --agent Master

> /review src/

# Master delega para CodeReviewer
# Output: Relatório de segurança, qualidade, e sugestões
```

### Exemplo 6: Apenas Pergunta

```bash
opencode --agent Master

> "Como implementar websockets com Socket.io no Next.js?"

# Master responde diretamente
# Sem execução, sem pipeline
```

---

## Fluxos por Tipo de Pedido

### Feature Nova Completa

```mermaid
graph TD
    Start["Pedido: 'Crie um sistema de X com Y e Z'"] --> Detect["Master detecta: SDLC Pipeline"]
    Detect --> PO["0. ProductOwner (se estratégico)\nCria visão, épicos, roadmap"]
    PO --> G0{{"GATE #0\nVocê revê épicos e aprova"}}
    G0 --> PM["1. ProductManager\nDecompõe épicos em STORY-XXX.md"]
    PM --> G1{{"GATE #1\nVocê revê stories e aprova"}}
    G1 --> SA["1.5. SystemArchitect (se greenfield)\nDefine stack e scaffold"]
    SA --> GSA{{"GATE #SA\nVocê aprova a stack"}}
    GSA --> Arch["2. Architect\nCria technical-analysis.md com batches"]
    G1 -->|"se projeto existente"| Arch
    Arch --> G2{{"GATE #2\nVocê revê plano técnico e aprova"}}
    G2 --> TL["3. TechLead - ciclo completo\nbranch feat/STORY-XXX\nImpl → Test → QA → Review → MR"]
    TL --> G3{{"GATE #3\nStory completa → próxima story?"}}
    G3 -->|"sim"| TL
```

### Modificação Simples

```mermaid
graph TD
    Start["Pedido: 'Mude a cor do botão para azul'"] --> Detect["Master detecta: Task simples"]
    Detect --> CS["1. ContextScout\nCarrega padrões de styling"]
    CS --> Exec["2. Execução direta\nEdita o arquivo (sem pipeline SDLC)"]
```

### Bug

```mermaid
graph TD
    Start["Pedido: 'O login não funciona, erro 500'"] --> Detect["Master detecta: Bug"]
    Detect --> BF["1. BugFixer\nReproduz o bug + Root cause analysis"]
    BF --> Prop["2. Proposta de correção\nVocê aprova"]
    Prop --> Fix["3. Correção\nImplementa fix + testes de regressão"]
    Fix --> Val["4. Validação\nTestes passando, bug corrigido"]
```

### Pergunta

```mermaid
graph TD
    Start["Pedido: 'Como funciona X?'"] --> Detect["Master detecta: Pergunta"]
    Detect --> Resp["Resposta direta\nSem execução, sem pipeline, sem aprovação"]
```

---

## Dicas Práticas

### 1. Comece com Master

Sempre comece com `opencode --agent Master`. Ele sabe como orquestrar e delegar para os especialistas certos.

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
/epic definir visão e épicos  # Para, revisa estratégia
/story criar sistema X        # Para, revisa story
/plan STORY-001              # Para, revisa plano
/implement STORY-001         # Executa
```

### 4. Deixe o Pipeline Rodar

Para features completas, use linguagem natural e deixe o Master gerenciar:
```
"Crie um e-commerce completo com carrinho, checkout, e pagamentos"
# Master orquestra tudo com 3-5 gates:
# ⏸️#0 após épicos (ProductOwner, se aplicável)
# ⏸️#1 após stories | ⏸️#SA após stack (greenfield) | ⏸️#2 após plano | ⏸️#3 após cada story completa
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
| Épicos/Visão/Strategy | Master | "Defina a visão e épicos..." (ProductOwner) |
| Feature completa | Master | Linguagem natural: "Crie um..." (3-5 gates) |
| Scaffold de projeto novo | Master | `/scaffold` |
| Pergunta | Master | Linguagem natural: "Como funciona...?" |
| Bug | Master | "O bug X acontece quando..." |
| Modificação simples | Master | "Mude X para Y" |
| Implementação direta | Master | "Implemente a função X" |
| Code review | Master | `/review` |
| Análise | Master | `/analyze` |
| Controle passo a passo | Master | `/epic` → `/scaffold` → `/story` → `/plan` → `/implement` |