# RPE Harness — Guia Completo do Desenvolvedor

Este guia detalha a utilização prática de toda a infraestrutura do **RPE Harness** no Cursor IDE.

---

## 1. Modos de Operação

### A. Operação Interativa (Padrão)

Use o Chat (Cmd+L) ou Composer (Cmd+I). Regras `alwaysApply: true` são injetadas automaticamente:

- `rpe-identity.mdc`, `interaction-standards.mdc`, `coding-standards.mdc`
- `intent-routing.mdc`, `safety-guardrails.mdc`, `stack-baseline.mdc`

Regras contextuais ativam por extensão: `.ts`, `.go`, `.java`, `.sql`, `*.test.*`, `*.feature`.

### B. Modo Subagentes Especializados

Invoque com `@` no chat ou Composer:

| Agente | Escopo |
|--------|--------|
| `@rpe-architect.md` | Planejamento arquitetural (read-only) |
| `@rpe-developer.md` | Implementação de código |
| `@rpe-reviewer.md` | Revisão geral de qualidade |
| `@rpe-security.md` | Deep dive AppSec, SLSA, IaC |
| `@rpe-qa-analyst.md` | Estratégia funcional, BDD, a11y |
| `@rpe-test-lead.md` | Plano técnico TDD |
| `@rpe-tester.md` | Testes unitários/integração TDD |
| `@rpe-sdet.md` | E2E, contratos, mocks, k6, CI |
| `@rpe-tech-writer.md` | Documentação e OpenAPI |
| `@rpe-atlassian.md` | Jira, Confluence, governança ágil |
| `@rpe-infra.md` | CI/CD, Docker, K8s, Terraform |
| `@rpe-dba.md` | Migrações, schema, queries |

### C. Modo UltraWork

Automação total com auto-correção via `grind-loop.ts`.

- **Acionar**: prefixo `ultrawork:`, palavra `ultrawork`, ou `@ultrawork.md`
- **Scratchpad**: `.cursor/scratchpad.md` (template: `.cursor/scratchpad.template.md`)
- **Limite**: 5 iterações automáticas

---

## 2. Comandos Rápidos

| Comando | Descrição |
|---------|-----------|
| `@ultrawork.md` | Modo automação total |
| `@plan-architecture.md` | Plano arquitetural atômico |
| `@test-plan.md` | Plano técnico TDD |
| `@generate-pr-description.md` | Descrição de PR |
| `@review-pr.md` | Revisão de PR |
| `@refine-story.md` | Refinamento Três Amigos |
| `@generate-test-cases.md` | Cenários BDD funcionais |
| `@generate-mocks.md` | Mocks MSW/WireMock |
| `@scaffold-e2e.md` | Scaffold Playwright/Cypress |
| `@scaffold-k6.md` | Script de performance k6 |
| `@review-migration.md` | Revisão de migração SQL |
| `@generate-openapi.md` | Spec OpenAPI/Swagger |
| `@audit-security.md` | Varredura OWASP e segredos |
| `@audit-logs-otel.md` | Auditoria de logs e PII |
| `@validate-stack.md` | Lint, type-check e testes |

---

## 3. Biblioteca de Skills

### Arquitetura e Padrões

- `hexagonal-architecture`, `design-patterns`, `solid-principles`

### Linguagens

- `go-mastery`, `java-mastery`, `node-mastery`

### Qualidade e Testes

- `bdd-gherkin`, `e2e-testing`, `api-contract-testing`
- `performance-testing`, `accessibility-visual-testing`

### Harness

- `tdd-grinder` — ciclo TDD + grind-loop
- `session-persistence` — scratchpad e checkpoints
- `pipeline-gateway` — roteamento MCP
- `lsp-integration` — diagnósticos LSP
- `mcp-integration` — diretrizes MCP

---

## 4. Hooks Determinísticos

Registrados em `.cursor/hooks.json`:

| Evento | Script | Função |
|--------|--------|--------|
| `stop` | `grind-loop.ts` | Auto-correção UltraWork/TDD |
| `onPreEdit` | `write-file-guard.sh` | Protege arquivos críticos |
| `onPostEdit` | `lint-on-save.sh` | Lint/format stack-aware |
| `onPreCommit` | `secret-scanner.sh` | Detecta segredos |
| `beforeShellExecution` | `shell-guard.sh` | Bloqueia comandos destrutivos |
| `beforeMCPExecution` | `mcp-guard.sh` | Bloqueia SQL destrutivo |

---

## 5. MCP

Template em `.cursor/mcp.json.example`. Configure variáveis de ambiente:

- `CONTEXT7_API_KEY`, `GITHUB_PERSONAL_ACCESS_TOKEN`
- `JIRA_API_TOKEN`, `JIRA_EMAIL`, `JIRA_URL` (opcional)

O `mcp.json` local é ignorado pelo git.

---

## 6. Instalação

```bash
./scripts/install.sh /path/to/project          # instalação completa
./scripts/install.sh /path/to/project rules,agents  # seletiva
./scripts/validate.sh                          # validar integridade
```
