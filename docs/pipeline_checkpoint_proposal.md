# Pipeline Checkpoint — Proposta de Design

## Problema

Quando o workflow trava (rate limit, queda de energia, crash, PC reiniciado), o Master e o TechLead perdem o contexto de onde pararam. Atualmente precisam fazer uma análise profunda (`git log`, ler inventários, verificar PRs) para retomar — o que consome tokens e pode levar a implementações incompletas.

## O que já existe hoje

| Mecanismo | Escopo | Limitação |
|---|---|---|
| `.opencode/.batch-queue.json` | Fila de stories no modo batch | Só sabe qual story está "current", não em que **estágio** da pipeline ela está |
| `docs/stories/STORY-XXX-inventory.md` | Itens de domínio dentro do TechLead | Só cobre a fase de implementação (backend/frontend), não o pipeline completo |
| `git log` + `git branch` | Estado do código | Requer inferência — não diz explicitamente "QA passou, review falhou" |
| `.opencode/.exec-mode` | Modo de execução (default/auto/batch) | Não tem info de progresso |

**Gap**: nenhum deles dá uma visão **end-to-end** do pipeline para uma story específica.

## Solução: Pipeline Checkpoint File

### Localização

```
docs/stories/STORY-XXX-pipeline.md
```

> [!TIP]
> Colocar junto dos outros artefatos da story (`-technical-analysis.md`, `-inventory.md`) mantém tudo coeso e facilita o `ls docs/stories/STORY-XXX*` que o Master já faz na State Detection.

### Formato

```markdown
# Pipeline — STORY-007

> Auto-generated. Updated by Master and TechLead during execution.
> Last update: 2026-05-24T09:15:00-03:00

## SDLC Pipeline (Master)

| # | Stage              | Agent            | Status      | Timestamp           |
|---|--------------------|------------------|-------------|---------------------|
| 1 | Story Definition   | ProductManager   | ✅ DONE     | 2026-05-24 08:30    |
| 2 | Tech Stack         | SystemArchitect  | ⏭ SKIPPED   | —                   |
| 3 | Technical Analysis | Architect        | ✅ DONE     | 2026-05-24 08:45    |
| 4 | Implementation     | TechLead         | 🔄 RUNNING  | 2026-05-24 09:00    |
| 5 | Merge Request      | —                | ⬚ PENDING   | —                   |

## Implementation Pipeline (TechLead)

| # | Task                        | Agent               | Status      | Timestamp           |
|---|-----------------------------|----------------------|-------------|---------------------|
| 1 | Context Scout               | ContextScout         | ✅ DONE     | 2026-05-24 09:01    |
| 2 | Backend: models/schemas     | BackendDeveloper     | ✅ DONE     | 2026-05-24 09:05    |
| 3 | Backend: services/managers  | BackendDeveloper     | ✅ DONE     | 2026-05-24 09:10    |
| 4 | Backend: routes/controllers | BackendDeveloper     | 🔄 RUNNING  | 2026-05-24 09:15    |
| 5 | Frontend: components        | FrontendDeveloperReact | ⬚ PENDING | —                   |
| 6 | Frontend: pages             | FrontendDeveloperReact | ⬚ PENDING | —                   |
| 7 | Tests                       | TestEngineer         | ⬚ PENDING   | —                   |
| 8 | QA Validation               | QAAnalyst            | ⬚ PENDING   | —                   |
| 9 | Code Review                 | CodeReviewer         | ⬚ PENDING   | —                   |
| 10| Merge Request               | MergeRequestCreator  | ⬚ PENDING   | —                   |

## Rework Cycles

(none yet)
```

### Status possíveis

| Emoji | Status | Significado |
|-------|--------|-------------|
| ⬚ | `PENDING` | Ainda não iniciado |
| 🔄 | `RUNNING` | Em execução agora |
| ✅ | `DONE` | Concluído com sucesso |
| ❌ | `FAILED` | Falhou (ver notas) |
| 🔁 | `REWORK` | Em ciclo de correção |
| ⏭ | `SKIPPED` | Pulado (ex: SystemArchitect em projeto existente) |
| ⛔ | `BLOCKED` | Bloqueado por dependência ou erro irrecuperável |

## Quem escreve

| Agente | Responsabilidade |
|--------|-----------------|
| **Master** | Cria o arquivo quando inicia a pipeline. Atualiza a seção "SDLC Pipeline" a cada gate. |
| **TechLead** | Atualiza a seção "Implementation Pipeline" a cada delegação concluída. Adiciona ciclos de rework. |

> [!IMPORTANT]
> O Master e TechLead já têm permissão de escrita em `docs/stories/**`. Nenhuma mudança de permissões é necessária.

## Como o Master usa na retomada

Na **State Detection** (que já roda a cada request), o Master adiciona um passo:

```
# Passo extra na State Detection (1 bash call)
bash: cat docs/stories/STORY-XXX-pipeline.md 2>/dev/null | head -30
```

Se o arquivo existe → lê o último status `🔄 RUNNING` ou `❌ FAILED` → sabe exatamente onde retomar:
- Se SDLC stage 4 (Implementation) está RUNNING → delegar ao TechLead
- Se SDLC stage 5 (MR) está PENDING mas 4 está DONE → delegar ao MergeRequestCreator

## Como o TechLead usa na retomada

O TechLead já tem a **Restart Detection** rule. Em vez de depender apenas do `git log`, ele lê o pipeline file:

```
bash: cat docs/stories/STORY-XXX-pipeline.md 2>/dev/null
```

E resume a partir do primeiro item `PENDING` ou `RUNNING` na seção "Implementation Pipeline".

> [!NOTE]
> Isso **substitui parcialmente** o `STORY-XXX-inventory.md`, que hoje só tem marcações `[DONE]` sem timestamp nem status de erro. Podemos depreciar o inventory file gradualmente, ou mantê-lo como redundância.

## Mudanças necessárias nos agentes

### 1. `agent/core/master.md`

Adicionar à seção **Execution Pattern → 5. Delegate**:
- Antes de delegar: criar/atualizar `STORY-XXX-pipeline.md` com o stage como `🔄 RUNNING`
- Depois de receber resultado: atualizar para `✅ DONE` ou `❌ FAILED`

Adicionar à seção **State Detection**:
- Incluir `cat docs/stories/STORY-XXX-pipeline.md 2>/dev/null | head -30` como opção no budget de 2 bash calls

### 2. `agent/subagents/sdlc/tech-lead.md`

Adicionar à seção **Priority 2 → 4. TODO LIST**:
- Após cada delegação concluída, atualizar a seção "Implementation Pipeline" do pipeline file

Adicionar à seção **Rule: Restart Detection**:
- Ler o pipeline file como primeira fonte de verdade (antes de `git log`)

### 3. Nenhuma mudança em plugins

Este mecanismo é **100% baseado em arquivo**, escrito pelos agentes via `bash: echo "..." > file` ou edição direta. Não precisa de plugin.

## Relação com `batch-queue.json`

Em **modo batch**, o `batch-queue.json` continua sendo o dono da fila de stories. O pipeline file é **per-story** e complementar:

```
batch-queue.json → qual story está rodando
STORY-XXX-pipeline.md → em que ponto dessa story estamos
```

## Alternativa descartada: Plugin

Um plugin poderia interceptar `task()` calls e atualizar automaticamente. Descartei porque:
1. O plugin não sabe o significado semântico da task (é backend? é QA?)
2. Precisaria de uma heurística frágil para mapear agent names → pipeline stages
3. O agente já sabe exatamente o que está fazendo — é mais natural ele escrever
4. Manter em arquivo permite que **qualquer ferramenta** (não só OpenCode) leia o estado

## Próximos passos

1. **Aprovar** o formato e a localização do arquivo
2. **Implementar** as mudanças no `master.md` e `tech-lead.md`
3. **Testar** com uma story real em modo default e batch
4. **Avaliar** se o inventory file (`STORY-XXX-inventory.md`) pode ser depreciado em favor do pipeline file
