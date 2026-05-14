# Diagnóstico do Travamento — New OpenCode Workflow

## TL;DR

O travamento NÃO é causado por contexto grande nem por rate limit. A causa raiz mais provável é o **timeout de 10 horas** (`36000000`ms) em todos os providers combinado com **modelos reasoning/instáveis** que podem gerar infinitamente ou ficar sem resposta. Quando isso acontece em uma delegação encadeada (ex: TestEngineer → QAAnalyst), o agente pai fica preso esperando o `task()` retornar — e espera 10h.

---

## 1. O que foi investigado

| Item | Resultado |
|------|-----------|
| Contexto do projeto | Pequeno (18 arquivos no repo, 16 no workflow) |
| Rate limit / fallback | Plugin ativo, log limpo — **não é rate limit** |
| Timeout configurado | `36000000`ms (10h) em **todos** os providers |
| Plugin de monitoramento | Referência quebrada (`opencode-token-monitor@latest` não existe; arquivo real é `opencode-token-logger.ts`) |
| Pipeline TechLead | Impl → Test → QA → Review → MR, cada um via `task()` |
| Modelos usados | Ollama Cloud: kimi-k2.6, glm-5.1, deepseek-v4-flash, qwen3-coder-next — todos modelos grandes, alguns reasoning |

---

## 2. Causas prováveis (em ordem de probabilidade)

### 🔴 Causa #1 — Timeout de 10 horas → sessão fica "morta" esperando

```json
// opencode.json — TODOS os providers
"timeout": 36000000  // 10 horas
```

Se um modelo (ex: `deepseek-v4-flash` ou `kimi-k2.6`) entra em um loop de raciocínio, gera tokens infinitos, ou o provider Ollama Cloud simplesmente não responde, o OpenCode vai esperar **10 horas** antes de abortar. Durante esse tempo, o agente aparece "preso".

**Por que isso afeta o pipeline:**
- TechLead chama `task(subagent_type="TestEngineer")`
- TestEngineer chama `task(subagent_type="QAAnalyst")`
- QAAnalyst usa `deepseek-v4-flash` → gera raciocínio infinito
- TechLead fica preso esperando TestEngineer, que está preso esperando QAAnalyst
- Nenhum dos agentes pode aplicar o "2-strike rule" porque está bloqueado no `await task()`

### 🟡 Causa #2 — Modelos reasoning sem limite de thinking

Modelos como `deepseek-v4` e `kimi-k2.6` são reasoning models. Sem um `max_tokens` ou `thinking_budget` configurado, eles podem gerar cadeias de raciocínio de 50k+ tokens antes de começar a responder. Isso:

1. Gasta tokens absurdos
2. Parece que o agente "travou" porque não há output visível por minutos
3. Eventualmente pode estourar o context window do provider e dar erro, mas só depois de muito tempo

### 🟡 Causa #3 — Plugin de monitoramento quebrado

```json
"plugin": ["opencode-token-monitor@latest"]   // ❌ não existe
```

O arquivo real é `opencode-token-logger.ts`. Isso pode estar causando um warning de plugin não encontrado no startup. Não é a causa do travamento, mas impede que você veja logs de token usage em tempo real para diagnosticar.

### 🟢 Causa descartada: Contexto muito grande

O projeto Contopia tem apenas 18 arquivos no repo. O workflow MVI (Máximo de 200 linhas/arquivo) está sendo respeitado pelos agentes. O contexto não é o gargalo.

---

## 3. Recomendações (por impacto)

### Ação imediata — Reduzir timeout (ESSENCIAL)

```json
// opencode.json
"provider": {
  "ollama-cloud": {
    "options": {
      "timeout": 300000,        // 5 minutos (era 10h)
      "setCacheKey": true
    }
  }
}
```

**Rationale:**
- Nenhum agente do seu workflow deve precisar de mais de 3-5 minutos para uma resposta
- Se um modelo não responde em 5 min, é porque travou. Abortar rápido permite que o fallback plugin troque de modelo
- Com timeout de 10h, o fallback NUNCA é acionado porque o sistema fica esperando indefinidamente
- **Timeout afeta apenas a latência, não a qualidade do código gerado**

### Ação imediata — Fixar plugin reference

```json
// opencode.json
"plugin": ["opencode-token-logger"]   // ✅ sem @latest, nome correto
```

### ⚠️ max_tokens — Use com cuidado (pode sim prejudicar qualidade)

**A verdade:** `max_tokens` limita a **saída** (output), não o input/contexto. O modelo ainda "vê" os mesmos arquivos. O problema é quando a resposta é **cortada no meio**:

| Cenário | Risco com max_tokens baixo |
|---------|---------------------------|
| BackendDeveloper gerando um service de 300 linhas | Arquivo truncado na linha 200 → código incompleto e quebrado |
| TestEngineer gerando 40 testes | Para no teste 25 → suite incompleta, coverage falso |
| MergeRequestCreator gerando relatório | Trunca tabela de métricas → relatório inútil |

**Por que seu workflow já tem proteções contra contexto grande:**
- **MVI Principle**: Cada agente carrega no máximo 3-5 arquivos, <200 linhas cada
- **Domínio por domínio**: TechLead delega "backend" separado de "frontend"
- **TestEngineer**: Regra explícita de "um domínio por vez", limitando escopo
- **Nunca tudo de uma vez**: BackendDeveloper não recebe prompt com 50 arquivos

**Estratégia segura para max_tokens:**

```json
// ❌ NÃO aplique em agentes de implementação
"BackendDeveloper": { "options": {} }        // Deixe livre
"FrontendDeveloperReact": { "options": {} } // Deixe livre  
"TestEngineer": { "options": {} }            // Deixe livre

// ✅ PODE aplicar em agentes de orquestração/análise (respostas curtas)
"Master": {
  "model": "ollama-cloud/kimi-k2.6",
  "options": { "max_tokens": 4000 }     // Só roteia, não gera código
},
"QAAnalyst": {
  "model": "ollama-cloud/deepseek-v4-flash",
  "options": { "max_tokens": 8000 }     // Relatório de QA
}
```

> **Regra prática:** Se o agente gera **arquivos de código** (`.ts`, `.js`, `.test.ts`), NÃO limite max_tokens. Se o agente só gera **relatórios ou roteamento** (Master, QAAnalyst, CodeReviewer), pode limitar sem risco.

### Ação recomendada — Modelos mais rápidos nos orquestradores

O TechLead e o Master são os agentes mais críticos (orquestradores). Se eles travam, todo o pipeline para. Considere:

```json
"TechLead": {
  "model": "ollama-cloud/deepseek-v4-flash"   // mais rápido e estável que kimi-k2.6
},
"Master": {
  "model": "ollama-cloud/deepseek-v4-flash"
}
```

Reserve modelos grandes (kimi-k2.6, glm-5.1) para agentes de análise (Architect, CodeAnalyzer) onde a qualidade do raciocínio importa mais que a velocidade.

### Ação recomendada — Adicionar health check no início de cada sessão

No `instructions.md` do workflow (ou em cada agente crítico), adicione uma regra:

```markdown
## Anti-Stall Protocol

Before starting any long operation, run a lightweight health check:
```bash
echo "health-check-$(date +%s)"
```
If a `task()` delegation takes longer than 3 minutes without output, the parent agent MUST:
1. Log the stall
2. Mark the subtask as [BLOCKED]
3. Continue with the next task — do NOT wait indefinitely
```

### Ação avançada — Timeout por agente no fallback plugin

O fallback plugin poderia ser estendido para detectar stalls (sessões sem activity por >5 min), não só rate limits. Isso requeria uma alteração em `opencode-agent-fallback.ts` para monitorar `session.status` com timestamps.

---

## 4. Como confirmar o diagnóstico

1. **Próxima vez que travar:**
   - Verifique o horário exato do travamento
   - Olhe `/tmp/opencode-agent-fallback.log` — se não houver entrada de "Rate limit" no momento do travamento, confirma que não é rate limit
   - Olhe os logs do provider (se houver) — se a última requisição ficou pendente sem resposta por minutos, é timeout/stall

2. **Após aplicar o fix de timeout (5 min):**
   - Se o workflow passa a falhar rápido (em vez de travar para sempre) e o fallback troca de modelo → diagnóstico confirmado
   - Se o fallback não tem modelos configurados para o agente travado, ele vai falhar abertamente — aí você adiciona fallback models

3. **Monitore com token-logger ativo:**
   - Habilite o token-logger criando `.opencode/config/token-logger.json`:
   ```json
   {"enabled": true}
   ```
   - Verifique `/tmp/opencode-token-logger-*.log` durante a execução para ver o tamanho dos prompts

---

## 5. Resumo das alterações sugeridas no Contopia

### Alteração #1 — Timeout (ESSENCIAL)

Arquivo: `/home/diogo.freitas/dgo/Contopia/.opencode/opencode.json`

```json
{
  "plugin": ["opencode-token-logger"],
  "provider": {
    "ollama-cloud": {
      "options": {
        "timeout": 300000,
        "setCacheKey": true
      }
    },
    "openrouter": {
      "options": {
        "timeout": 300000,
        "setCacheKey": true
      }
    },
    "opencode": {
      "options": {
        "timeout": 300000,
        "setCacheKey": true
      }
    },
    "zai-coding-plan": {
      "options": {
        "timeout": 300000,
        "setCacheKey": true
      }
    }
  }
}
```

### Alteração #2 — Fallback models (ESSENCIAL)

Arquivo: `/home/diogo.freitas/dgo/Contopia/.opencode/config/agent-fallback.json`

Adicione fallback models para os agentes que estão com `fallbackModels: []`:

```json
{
  "agents": {
    "master": {
      "fallbackModels": [
        { "providerID": "opencode", "modelID": "minimax-m2.5-free" },
        { "providerID": "openrouter", "modelID": "nvidia/nemotron-3-super-120b-a12b:free" }
      ]
    },
    "tech-lead": {
      "fallbackModels": [
        { "providerID": "opencode", "modelID": "minimax-m2.5-free" },
        { "providerID": "zai-coding-plan", "modelID": "glm-4.5-air" }
      ]
    },
    "backend-developer": {
      "fallbackModels": [
        { "providerID": "openrouter", "modelID": "nvidia/nemotron-3-super-120b-a12b:free" },
        { "providerID": "zai-coding-plan", "modelID": "glm-4.5-air" }
      ]
    }
  }
}
```

### Alteração #3 — max_tokens (OPCIONAL, com regras)

Se quiser experimentar limitar a saída, faça **apenas** nos agentes de orquestração:

```json
{
  "agent": {
    "Master": {
      "model": "ollama-cloud/kimi-k2.6",
      "options": {
        "max_tokens": 4000
      }
    }
  }
}
```

**NUNCA** limite `max_tokens` em:
- `BackendDeveloper`
- `FrontendDeveloperReact` / `Vue` / `Angular`
- `TestEngineer`
- `ShellDeveloper`

Esses agentes **geram arquivos de código**. Limitar tokens aqui = código truncado e quebrado.

### Alteração #4 — Modelos nos orquestradores (OPCIONAL)

Se `kimi-k2.6` continuar instável no TechLead/Master, troque para `deepseek-v4-flash`:

```json
{
  "agent": {
    "TechLead": {
      "model": "ollama-cloud/deepseek-v4-flash"
    },
    "Master": {
      "model": "ollama-cloud/deepseek-v4-flash"
    }
  }
}
```

---

> **Conclusão:** O "travamento" é quase certamente o timeout de 10h combinado com modelos que ocasionalmente não respondem. Reduzir o timeout para 5 minutos vai transformar travamentos silenciosos em falhas rápidas que o fallback plugin pode tratar automaticamente.
