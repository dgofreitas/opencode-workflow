# Estudo: Otimização de Tokens no Workflow OpenCode

## TL;DR

1. **Seu brief está no caminho certo.** `INDEX.md` flat + matar `navigation.md`
   intermediários + remover Approval Gate do ExternalScout reduz consumo de
   tokens de discovery em ~60–70%. Implemente.
2. **Obsidian NÃO reduz tokens em runtime.** O LLM continua lendo os mesmos
   arquivos `.md`. Obsidian ajuda VOCÊ (autor) a manter o sistema mais enxuto
   (graph view, Dataview, backlinks). É ferramenta de *author-time*, não de
   *inference-time*. Use-o se gostar — mas não como estratégia de custo.
3. **O ganho maior está antes do INDEX**: você tem 93 arquivos / ~12k linhas /
   ~319KB (~80–100k tokens totais) em `context/`. Dois ganhos extras de alto
   ROI (descritos abaixo): (a) `summary` em frontmatter para grep semântico
   sem `read`, (b) compressão MVI dos arquivos folha grandes.

---

## 1. Diagnóstico do estado atual

### Métricas
- 93 arquivos `.md` em `context/`
- 19 arquivos `navigation.md` (1 raiz + 18 intermediários)
- ~12.000 linhas, ~319KB → ~80–100k tokens se tudo fosse lido
- Custo típico de uma consulta do ContextScout hoje:
  - `read navigation.md` (raiz, ~42 linhas)
  - `read core/navigation.md`
  - `read core/<sub>/navigation.md`
  - 2–4 reads em folhas relevantes
  - Total: **5–7 reads, ~3–5k tokens só para descobrir o que ler**

### Problemas
- **Discovery O(profundidade)**: cada nível custa 1 read e ~500–1000 tokens
- **Redundância**: 4 arquivos sobre external-libraries (já mapeado por você)
- **Approval Gate no ExternalScout** custa 1 round-trip por execução —
  desnecessário porque as permissões já restringem write a `.tmp/external-context/**`
- **Sem cache semântico interno**: o ContextScout pode acabar invocando o
  ExternalScout para libs que JÁ TÊM contexto interno

---

## 2. Avaliação do seu brief

| Tarefa | Avaliação | Observação |
|--------|-----------|------------|
| 1. INDEX.md flat na raiz | ✅ Excelente | Reduz discovery para 1 read fixo |
| 2. Merge dos 4 external-libraries | ✅ Bom | Atenção a respeitar MVI <200 linhas |
| 3. Apagar navigation.md intermediários | ✅ Bom | **Cuidado**: ler antes para extrair conteúdo único, se houver |
| 4. Atualizar ContextScout | ✅ Excelente | Mais enxuto, read-only puro (remove `bash` da permissão — bom) |
| 5a. Remover Approval Gate | ✅ Excelente | Permissões já protegem |
| 5b. Cache de índice no ExternalScout | ✅ ótima ideia | Evita fetch externo desnecessário |

**Ganho estimado**: 5–7 reads → 2 reads fixos (INDEX + folha). Em discovery,
~60–70% menos tokens. Em fluxos completos (discovery + leitura), ~30–40% menos.

---

## 3. Obsidian ajudaria?

### Resposta curta
**Não para reduzir tokens.** Sim para manter o sistema saudável ao longo do tempo.

### O que Obsidian faz bem (autor)
- **Graph view**: identifica clusters redundantes (ex.: 4 arquivos de
  external-libraries juntos no grafo é red flag visual)
- **Dataview plugin**: pode AUTOGERAR seu `INDEX.md` lendo frontmatter de
  todos os arquivos. Você nunca mais atualiza INDEX à mão
- **Templater**: garante que todo arquivo novo nasça com frontmatter
  padronizado (`tags`, `summary`, `priority`)
- **Tag pane**: encontra arquivos órfãos (sem tag) ou tags duplicadas
- **Backlinks**: detecta arquivos nunca referenciados (candidatos a deletar)

### O que Obsidian NÃO faz
- Não muda o que o agente lê em runtime
- Não comprime o conteúdo
- Não substitui o INDEX.md para o agente — o LLM ignora `.obsidian/` e workspace metadata

### Veredicto
Use Obsidian como **ferramenta de manutenção**:
- Configure Dataview para gerar `INDEX.md` automaticamente a partir de
  frontmatter dos arquivos folha
- Use graph view periodicamente para auditar redundância
- **Não é pré-requisito.** Pode-se gerar o INDEX.md com um script `bash`/`node` simples (ver §5)

---

## 4. Otimizações ALÉM do seu brief (alto ROI)

### 4.1. Frontmatter `summary` (1 linha) em cada arquivo folha
Adicionar:
```yaml
---
summary: "Padrões de teste com Vitest + Testing Library, foco em mocking de APIs"
tags: [tests, vitest, react]
priority: high
---
```
**Por quê**: o ContextScout pode rodar `grep -l "vitest" context/**/*.md` e ler só
o frontmatter (primeiras 10 linhas com `read offset/limit`) para decidir se vale
ler o arquivo todo. Isso é **read O(N) parcial** vs read completo.

**Ganho**: arquivos folha pesados (>150 linhas) só são abertos quando realmente
relevantes. Estimativa: −20–30% adicional sobre o brief.

### 4.2. INDEX.md gerado via script (não Obsidian)
```bash
# scripts/generate-context-index.sh
# Lê frontmatter de cada *.md em context/, monta INDEX.md flat
```
Roda em pre-commit hook. Garante que INDEX nunca fica stale. Independente de Obsidian.

### 4.3. Compressão MVI dos arquivos folha existentes
Auditar os arquivos > 150 linhas. Aplicar regra MVI já documentada em
`core/context-system/standards/mvi.md`. Isso reduz tokens **toda vez que o
arquivo é lido**, não só no discovery.

Comando para listar candidatos:
```bash
find context -name "*.md" -exec wc -l {} + | sort -rn | head -20
```

### 4.4. Budget de tokens por consulta no ContextScout
Adicionar à regra do agente:
> Retorne no máximo 5 arquivos. Se houver mais de 5 candidatos, agrupe
> por prioridade e devolva top-5 com nota "X arquivos adicionais disponíveis
> sob demanda".

Evita o anti-pattern de "devolver tudo por segurança".

### 4.5. Manifesto JSON opcional (avançado)
Para queries programáticas (não LLM), um `INDEX.json` com paths+tags+summary é
mais eficiente para `grep`/`jq`. Não substitui o `INDEX.md` (LLMs preferem
markdown), mas habilita scripts de validação e auditoria.

### 4.6. Cache de respostas do ContextScout (opcional)
Se você nota que invoca ContextScout para queries similares ("write tests",
"code review"), pode cachear o resultado em `.tmp/context-cache/{hash}.md`
por 24h. Pula completamente o agente em hits.

---

## 5. Plano de execução recomendado

### Fase 1 — Implementar o brief (alto ROI, baixo risco)
1. ✅ Tarefas 1–5 do `refactoring-brief.md` como descritas
2. Validar com 3 consultas reais (test, code-review, library-fetch)
3. Medir tokens antes/depois (logs do opencode)

### Fase 2 — Quick wins extras (1–2h trabalho)
4. Adicionar `summary:` ao frontmatter de cada arquivo folha (script gera template)
5. Atualizar regra do ContextScout para usar `read offset=1 limit=10` antes de
   ler arquivo inteiro
6. Adicionar budget de 5 arquivos máx

### Fase 3 — Manutenção contínua (opcional)
7. Script `generate-context-index.sh` + pre-commit hook
8. Auditoria mensal: `wc -l` para detectar arquivos que extrapolaram MVI
9. (Opcional) Setup Obsidian + Dataview para visualização — não é obrigatório

---

## 6. Estimativa de impacto

| Mudança | Redução de tokens (discovery) | Redução (consulta total) |
|---------|------------------------------|--------------------------|
| INDEX.md flat (brief) | ~65% | ~30% |
| + Approval Gate removido | — | ~5–10% (latência mais que tokens) |
| + Frontmatter summary + read parcial | ~75% | ~45% |
| + MVI nos folhas grandes | — | ~55% |
| + Budget de 5 arquivos | — | ~60% |

Realista: **−40 a −55% de tokens por consulta** depois de Fase 1+2.
Obsidian: **0% impacto direto** em tokens.

---

## 7. Recomendação final

1. **Faça o brief inteiro.** Está bem desenhado.
2. **Adicione `summary:` ao frontmatter** — esse é o multiplicador que falta.
3. **Pule Obsidian por ora.** Se gostar de tooling visual, adicione depois
   como camada de manutenção. Não é vetor de economia de tokens.
4. **Meça**: configure log dos reads do agente em pelo menos 5 consultas
   reais antes/depois para validar o ganho. Sem medição, é fé.

Se quiser, posso:
- (a) Executar a Fase 1 (rodar o brief)
- (b) Escrever o script `generate-context-index.sh`
- (c) Gerar template de frontmatter `summary` + script para aplicar em massa
- (d) Tudo acima
