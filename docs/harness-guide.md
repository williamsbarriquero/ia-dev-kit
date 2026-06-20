# RPE Harness — Guia Completo do Desenvolvedor

Este guia detalha a utilização prática de toda a infraestrutura do **RPE Harness** no Cursor IDE. A arquitetura foi projetada para garantir segurança por design, conformidade arquitetural e alta produtividade no ciclo de desenvolvimento e QA.

---

## 1. Modos de Operação

O RPE Harness suporta três modos principais de operação para atender a diferentes necessidades:

### A. Operação Interativa (Padrão)
Use o Chat (Cmd+L) ou Composer (Cmd+I) no Cursor para interações normais do dia a dia. As regras globais marcadas com `alwaysApply: true` (como [rpe-identity.mdc](../.cursor/rules/rpe-identity.mdc) e [safety-guardrails.mdc](../.cursor/rules/safety-guardrails.mdc)) são injetadas automaticamente, e as regras contextuais são acionadas conforme a extensão do arquivo (ex: `.ts`, `.sql`).

### B. Modo Subagentes Especializados
Para tarefas específicas com escopo e permissões restritas (Tool Boundary), você pode invocar o agente especialista correspondente no chat ou Composer usando a menção `@`:
*   `@rpe-architect.md` — Para planejamento arquitetural e RFCs (Read-only, sem permissão de escrita).
*   `@rpe-developer.md` — Para codificação agressiva com autonomia total de escrita e bash.
*   `@rpe-reviewer.md` — Para auditoria técnica e revisão de código antes de abrir PRs.
*   `@rpe-security.md` — Para análise rigorosa de vulnerabilidades baseada nos padrões NIST SP 800-218, OWASP ASVS/Top 10 e SLSA.
*   `@rpe-sdet.md` — Para criação de frameworks de automação E2E (Playwright/Cypress), Mocks e CI/CD de testes.
*   `@rpe-qa-analyst.md` — Para plano de testes funcionais, usabilidade, acessibilidade WCAG e cenários Gherkin/BDD.
*   `@rpe-tech-writer.md` — Para geração de documentações, READMEs e contratos Swagger/OpenAPI.
*   `@rpe-atlassian.md` — Para refinamento de histórias do Jira, escrita de RFCs e documentação no Confluence.

### C. Modo UltraWork (Automação Total de Ponta a Ponta)
Projetado para tarefas complexas que requerem autonomia completa do agente para implementar, testar e se auto-corrigir sem interromper o usuário.
*   **Como Acionar**: Digite o prefixo `ultrawork:` no chat ou inclua a palavra `ultrawork` no seu prompt (ex: *"ultrawork: corrija o bug da controller"*).
*   **Mecânica**: O roteador global [intent-routing.mdc](../.cursor/rules/intent-routing.mdc) detectará o termo e ativará a regra [ultrawork.mdc](../.cursor/rules/ultrawork.mdc). O agente entrará em um ciclo autônomo. Se os testes locais falharem, o hook de continuação [grind-loop.ts](../.cursor/hooks/continuations/grind-loop.ts) interceptará a execução e forçará o agente a depurar e consertar o código por até **5 iterações consecutivas**.

---

## 2. Comandos Rápidos (Slash Commands / Mentions)

Comandos rápidos são templates de prompts padronizados para acelerar tarefas cotidianas de engenharia e QA. Invoque-os no chat do Cursor usando `@`:

| Comando | Descrição | Exemplo de Uso |
| :--- | :--- | :--- |
| **`@generate-pr-description.md`** | Lê o `git diff` atual e gera uma descrição de PR estruturada. | *"Use o @generate-pr-description.md para o meu diff atual."* |
| **`@refine-story.md`** | Traduz requisitos e histórias do Jira em checklists Dev e QA (Gherkin). | *"@refine-story.md analise este requisito e monte as tarefas."* |
| **`@generate-mocks.md`** | Lê um payload JSON ou OpenAPI e gera a estrutura de mocks (MSW/WireMock). | *"@generate-mocks.md crie o mock da rota `/users`."* |
| **`@audit-logs-otel.md`** | Audita statements de logs, LGPD/PII e trace context (OpenTelemetry). | *"@audit-logs-otel.md verifique os logs desta classe."* |
| **`@generate-test-cases.md`** | Cria baterias de testes funcionais, unitários e E2E baseados em limites de código. | *"@generate-test-cases.md para o arquivo `userService.go`."* |
| **`@audit-security.md`** | Varredura rápida de credenciais hardcoded e checklist OWASP Top 10. | *"@audit-security.md audite o código modificado."* |
| **`@review-pr.md`** | Faz uma revisão detalhada e gera relatório de auditoria do PR atual. | *"@review-pr.md analise as alterações desta branch."* |
| **`@validate-stack.md`** | Executa a pipeline local de validação de linter, tipos e testes. | *"@validate-stack.md valide as alterações antes do commit."* |

---

## 3. Biblioteca de Skills (Conhecimento Técnico Sob Demanda)

As Skills ficam localizadas na pasta `.cursor/skills/` e servem como referências técnicas profundas que o agente consulta para garantir a aderência aos padrões de engenharia da RPE:

*   **Arquitetura & Padrões**:
    *   `hexagonal-architecture` — Diretrizes de isolamento de domínio e Ports & Adapters.
    *   `design-patterns` — Aplicação pragmática de padrões GoF e arquitetura corporativa.
    *   `solid-principles` — Heurísticas para identificação de violações de SRP, OCP, LSP, ISP e DIP.
*   **Linguagens & Runtimes**:
    *   `go-mastery` — Padrão de layout idiomático, concorrência segura, channels e tratamento de erros.
    *   `java-mastery` — Boas práticas de Java Moderno, Sealed Classes, Records, otimizações JVM e Spring.
    *   `node-mastery` — Event Loop, I/O não bloqueante, gestão e mitigação de memory leaks.
*   **Qualidade & Testes (QA)**:
    *   `bdd-gherkin` — Escrita de cenários Dado/Quando/Então focados em comportamento, evitando acoplamento físico.
    *   `e2e-testing` — Automação resiliente com Playwright/Cypress, controle de estado e isolamento.
    *   `api-contract-testing` — Testes de contrato com Pact, JSON Schema e mocks integrados.
    *   `performance-testing` — Estratégia de carga, estresse, SLAs e thresholds de latência no K6.
    *   `accessibility-visual-testing` — WCAG 2.1 (ARIA, teclado), axe-core e regressão visual pixel a pixel.

---

## 4. Hooks Determinísticos de Ciclo de Vida

Os hooks (registrados em `.cursor/hooks.json` e codificados em `.cursor/hooks/`) são executados fora do LLM para proteger o código e automatizar processos locais:

1.  **Guards (Bloqueio)**:
    *   `secret-scanner.sh`: Intercepta o salvamento e impede o commit de senhas, chaves de API e tokens de segurança baseados em assinaturas de regex corporativas.
    *   `write-file-guard.sh`: Protege arquivos críticos do repositório (como configurações de CI/CD, dependências principais e segredos `.env`) contra modificação acidental ou intencional do agente sem autorização explícita do usuário.
2.  **Transforms (Formatação)**:
    *   `lint-on-save.sh`: Roda o linter e o formatador correspondente à stack do projeto pós-salvamento para garantir um código limpo constante.
3.  **Continuations (Iteração)**:
    *   `grind-loop.ts`: Gerencia o fluxo de auto-correção UltraWork, mantendo o agente executando correções até que a flag `ALL_TESTS_PASSED: true` seja gravada com sucesso no arquivo `.cursor/scratchpad.md`.

---

## 5. Operação Multi-IDE

O SSOT vive em `.cursor/` no ia-dev-kit. Na instalação, o sync gera artefatos por editor:

| Recurso SSOT | Cursor | Copilot | Claude Code | Antigravity |
|---|---|---|---|---|
| Rules | `.cursor/rules/` | `copilot-instructions.md` + `instructions/` | `CLAUDE.md` + `.claude/rules/` | `AGENTS.md` |
| Agents | `@rpe-*.md` | `.github/agents/*.agent.md` | `.claude/agents/` | `.agents/agents.md` |
| Commands | `@command.md` | `/command` (prompts) | `/command` (skill manual) | `/command` (workflow) |
| Skills | `.cursor/skills/` | `.github/skills/` | `.claude/skills/` | `.agents/skills/` |
| Hooks | `hooks.json` | `.github/hooks/` | `.claude/settings.json` | parcial |

Instalação seletiva:

```bash
./scripts/install.sh /projeto --platforms=cursor,copilot,claude,antigravity
```

Documentação completa: [multi-ide-quickstart.md](multi-ide-quickstart.md), [multi-ide-mapping.md](multi-ide-mapping.md), [multi-ide-parity.md](multi-ide-parity.md).
