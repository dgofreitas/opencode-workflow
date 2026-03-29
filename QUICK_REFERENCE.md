# Quick Reference: Fluxo de Agentes

## Pipeline SDLC em 30 Segundos

```
┌─────────┐    ┌──────────┐    ┌─────────┐    ┌──────────┐    ┌──────┐    ┌────┐
│   PM    │ -> │ Architect│ -> │ TechLead│ -> │   Devs   │ -> │  QA  │ -> │ MR │
│ /story  │    │  /plan   │    │/implement│   │ /review  │    │ /qa  │    │/mr │
└─────────┘    └──────────┘    └─────────┘    └──────────┘    └──────┘    └────┘
     │              │               │               │            │
     ▼              ▼               ▼               ▼            ▼
  Story.md     TechPlan.md    Implementation   CodeReview   QAReport
                               Reports          Reports
```

## Agentes por Função

### Entry Points (Você fala com eles)
| Agente | Quando usar |
|--------|-------------|
| **OpenAgent** | Qualquer pedido - ele roteia automaticamente |
| **OpenCoder** | Tarefas de código diretas (sem SDLC completo) |

### SDLC Pipeline
| Agente | Função | Output |
|--------|--------|--------|
| **ProductManager** | Transforma pedidos em stories | `docs/stories/STORY-XXX.md` |
| **Architect** | Cria plano técnico | `docs/stories/STORY-XXX-technical-analysis.md` |
| **TechLead** | Coordena implementação | Execução dos batches |
| **QAAnalyst** | Valida aceitação | QA Report (APPROVE/REJECT) |
| **MergeRequestCreator** | Cria MR/PR | PR no GitHub/GitLab |

### Implementação (por linguagem)
| Node.js/TS | Python | C |
|------------|--------|---|
| BackendDeveloper | BackendDeveloperPython | BackendDeveloperC |
| CoderAgent | CoderAgentPython | CoderAgentC |
| TestEngineer | TestEngineerPython | TestEngineerC |
| CodeReviewer | CodeReviewerPython | CodeReviewerC |
| BugFixerNodejs | BugFixerPython | BugFixerC |

### Frontend (por framework)
| React | Vue | Angular | Genérico |
|-------|-----|---------|----------|
| FrontendDeveloperReact | FrontendDeveloperVue | FrontendDeveloperAngular | FrontendDeveloper |

### Infraestrutura
| Agente | Função |
|--------|--------|
| **ContextScout** | Descobre context files relevantes |
| **ExternalScout** | Busca docs de bibliotecas externas |
| **TaskManager** | Decompõe features em tarefas JSON |
| **DocWriter** | Gera documentação |

## Comandos Rápidos

| Comando | O que faz | Agente invocado |
|---------|-----------|-----------------|
| `/story <desc>` | Cria user story | ProductManager |
| `/plan <story>` | Cria plano técnico | Architect |
| `/implement <story>` | Executa implementação | TechLead |
| `/review [files]` | Code review | CodeReviewer* |
| `/qa <story>` | Validação QA | QAAnalyst |
| `/mr [base]` | Cria merge request | MergeRequestCreator |
| `/bugfix <desc>` | Diagnostica e corrige | BugFixer* |
| `/analyze [scope]` | Analisa codebase | CodeAnalyzer* |
| `/commit` | Cria commit formatado | (direto) |
| `/test` | Roda testes | (direto) |
| `/context` | Gerencia contexto | ContextOrganizer |

*Variantes por linguagem detectada automaticamente

## Regras de Ouro

1. **ContextScout SEMPRE** - Todo agente carrega contexto antes de agir
2. **ExternalScout para libs** - Documentação atualizada de bibliotecas
3. **Testes >= 90%** - Cobertura obrigatória
4. **Aprovação primeiro** - Nunca executar sem aprovação do usuário

## Exemplo: "Criar app de finanças"

```
1. Você: "Criar app de finanças com dashboard e gráficos"
   └─> OpenAgent recebe

2. OpenAgent: "Isso é uma Story complexa"
   └─> Delega para ProductManager

3. ProductManager: Cria STORY-001.md com acceptance criteria
   └─> Retorna para OpenAgent

4. OpenAgent: "Story criada, preciso de arquitetura"
   └─> Delega para Architect

5. Architect: Detecta React + Node.js, cria plano com batches
   └─> Retorna para OpenAgent

6. OpenAgent: "Plano pronto, executar"
   └─> Delega para TechLead

7. TechLead: Executa batches
   ├─> Batch 1 (paralelo): BackendDeveloper + FrontendDeveloperReact
   ├─> Batch 2 (sequencial): Mais implementação
   ├─> Batch 3: TestEngineer + CodeReviewer
   └─> Batch 4: QAAnalyst

8. QAAnalyst: Valida todos critérios
   └─> APPROVE

9. MergeRequestCreator: Cria PR com tudo agregado
   └─> PR criado no GitHub

10. FIM: App de finanças implementado, testado, e pronto para merge
```

## Detecção de Linguagem

O sistema detecta automaticamente:

```
package.json + tsconfig.json  →  Node.js/TypeScript
pyproject.toml                →  Python
CMakeLists.txt                →  C
package.json + "react"        →  React
package.json + "vue"          →  Vue
angular.json                  →  Angular
```

E roteia para os agentes corretos automaticamente!
