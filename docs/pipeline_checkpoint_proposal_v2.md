# Pipeline Checkpoint v2 — Proposta Final

## 1. O Problema
Atualmente, se o workflow trava ou a energia cai no meio da implementação, o sistema perde o contexto exato de onde parou. O `inventory.md` quase nunca é criado porque não é obrigatório, e mesmo quando criado, ele não captura o progresso *durante* a execução de um agente (ex: se o Backend cai no meio do código).

## 2. A Solução: Arquivo de Checkpoint Obrigatório e Granular
O arquivo `docs/stories/STORY-XXX-checkpoint.md` será a única fonte da verdade para o andamento de uma story. Ele substitui e evolui o antigo conceito de "inventory".

### Formato Sugerido
Usaremos listas de caixas de seleção (`- [ ]`) em vez de tabelas. Motivo: É muito mais fácil e seguro para os agentes de código (Backend/Frontend) editarem o arquivo para mudar um `[ ]` para `[x]` do que manipularem colunas de uma tabela Markdown.

```markdown
# Checkpoint de Execução — STORY-007

## 1. BACKEND
- [x] model: Criar Auth Schema
- [x] dao: Criar Repositório
- [ ] router: Criar Controller de Login

## 2. FRONTEND
- [ ] component: Criar formulário de Login
- [ ] page: Criar /login
- [ ] context: Integrar com Auth API

## 3. QUALIDADE E ENTREGA
- [ ] TESTES (Backend & Frontend)
- [ ] QA (Validação Funcional)
- [ ] CODE REVIEW (Revisão de Qualidade)
- [ ] MERGE REQUEST
```

---

## 3. A Dinâmica de Responsabilidades (Quem faz o que)

Para evitar sobreposição de papéis e manter o foco de cada IA, o fluxo funcionará assim:

### 🌟 3.1. Master (O Telefonista)
- **Regra:** NÃO gerencia, NÃO lê e NÃO atualiza o Checkpoint. Fica 100% isolado disso.
- **Recuperação:** Se você disser apenas *"continuar"*, o Master fará um simples `git branch --show-current`. Ao ver que a branch atual é `feat/STORY-007`, ele saberá automaticamente que a story ativa é a 007 e fará a delegação padrão: *"Vou chamar o TechLead para terminar a 007"*.

### 🏗️ 3.2. TechLead (O Gerente e Dono do Checkpoint)
- **Hard Gate de Criação:** A **primeira** coisa que o TechLead fará antes de mandar alguém codar é criar fisicamente o arquivo `docs/stories/STORY-XXX-checkpoint.md` baseado na *Technical Analysis*. Se não criar o arquivo, ele é proibido de chamar os trabalhadores.
- **A Delegação:** Quando o TechLead chamar um desenvolvedor, ele incluirá esta instrução no prompt: 
  > *"Ref: STORY-007-checkpoint.md. Ao concluir e commitar cada item, você é OBRIGADO a editar este arquivo marcando com [x] a respectiva tarefa."*
- **Recuperação (Restart):** Se a máquina desligar, quando o Master acordar o TechLead, ele usará sua regra de `Restart Detection`, vai abrir o `checkpoint.md` e verá exatamente que o Backend marcou 2 de 3 caixinhas. Ele então delega novamente ao Backend: *"Termine o item 3"*.

### 👷 3.3. Agentes Especialistas (Os Atualizadores)
- BackendDeveloper, FrontendDeveloper, TestEngineer, QAAnalyst.
- Como o prompt do TechLead exigirá atualização do arquivo, os especialistas vão usar suas ferramentas nativas de edição (ex: `replace_file_content`) para marcar o `[x]` assim que terminarem o código de um módulo, logo após o `git commit`.
- **Vantagem:** Visibilidade em tempo real para você (usuário) e recuperação cirúrgica em caso de crash.

---

## 4. Mudanças Técnicas Necessárias
Vamos precisar alterar **apenas um arquivo** no OpenCode:

**Em `agent/subagents/sdlc/tech-lead.md`:**
1. Alterar a regra de *Domain Inventory* para **Checkpoint Creation** (Obrigando a escrever o `.md` fisicamente antes de qualquer delegação).
2. Atualizar o formato da **AGENT DELEGATION FORMAT** para incluir o "contrato" de que o agente convocado deve atualizar o checkpoint.
3. Atualizar a regra de **Restart Detection** para o TechLead ler o arquivo `checkpoint.md` como a principal fonte de progresso, complementada pelo `git log`.

*(O `master.md` nem precisa ser alterado, pois ele já tem na sua lógica verificar qual story fazer pelo prompt do usuário, e se você pedir algo como "Continue a story atual", ele pode simplesmente checar a branch atual no terminal).*
