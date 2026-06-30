### Regra crítica: npm
Sempre use a forma longa `npm run <script>`, NUNCA a forma curta:
- ❌ `npm test`   → ✅ `npm run test`
- ❌ `npm start`  → ✅ `npm run start`
- ❌ `npm build`  → ✅ `npm run build`
-

## 🧪 Regras Rígidas para Testes e Cobertura

Agentes frequentemente erram ao rodar testes. Siga **OBRIGATORIAMENTE** a estratégia definida em `.opencode/skills/test-execution/SKILL.md`:

1. **NO PIPES:** Nunca use `| grep`, `| tail` ou `| head` ao rodar vitest/jest/mocha/npm test.
2. **VERIFY CWD:** Sempre dê `cd backend` ou `cd frontend` antes de rodar o teste. Não rode da raiz se o `package.json` de teste estiver em uma sub-pasta.
3. **TEXT COVERAGE:** Nunca tente ler arquivos JSON de cobertura (`coverage-summary.json` etc). Use repórteres de texto direto no console:
   - Vitest: `npx vitest run --coverage.enabled=true --coverage.reporter=text-summary`
   - Jest: `npx jest --coverage --coverageReporters="text-summary"`
4. **ISOLATE FAILURES:** Se uma suíte inteira falhar com log gigante, **NÃO** tente ler o log bruto. Isole e rode apenas o arquivo que falhou (`npm run test -- arquivo_especifico.test.ts`).

---

## Resposta inesperada de comando

Se um comando de ferramenta (lint, test, typecheck) devolver uma resposta
inválida, vazia, ou com erro de parse (ex.: saída que não faz sentido para o
comando executado), **não tente contornar o proxy nem ajustar a ferramenta**.
Trate como qualquer outro comando que falhou:

1. **NÃO faça loop** — mesmo erro 2x = PARE (regra dos 2 strikes, genérica).
2. **NÃO modifique configurações da ferramenta** (ex.: não altere `.eslintrc`
   porque um `lint` quebrou — o config está correto; o problema está na
   execução, não na regra).
3. Use a forma nativa do binário do projeto (`npx <bin>` ou `npm run <script>`).
4. Se persistir, marque `[BLOCKED]`, reporte e avance para o próximo item.

O comando nativo é a fonte da verdade.