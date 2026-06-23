# RPE Harness — Guia Completo do Desenvolvedor

Este guia é o **SSOT operacional** do RPE Harness no Cursor IDE. Para onboarding passo a passo (publicação Confluence), veja [confluence-how-to-guide.md](./confluence-how-to-guide.md).

---

## 0. Pré-requisitos

| Ferramenta | Obrigatório | Motivo |
|------------|-------------|--------|
| Cursor IDE 3+ | Sim | Agent mode, Plan Mode, hooks |
| Git | Sim | Workflow de PR |
| Test runner da stack | Sim | TDD e `@validate-stack.md` |
| **Bun** | Sim para UltraWork | Hook `grind-loop.ts` (`stop`) — instalado pelo `install.sh` quando `hooks` está incluído |
| Node.js 18+ / npx | Opcional | Servidores MCP |
| shellcheck | Opcional | DoD do harness (`validate-stack.md`) |

**Instalar Bun manualmente** (se usou `--skip-bun` ou instalação seletiva sem `hooks`):

```bash
curl -fsSL https://bun.sh/install | bash
```

Ou reexecute o install com módulo hooks: `bash scripts/install.sh . hooks`

Windows: use Git Bash ou WSL para os scripts shell.

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
- **Requer**: Bun no PATH (instalado automaticamente pelo `install.sh` com módulo `hooks`)

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

Skills são **índices de ativação** — o conteúdo técnico vive em `.cursor/knowledge/stacks/`. Ver [content-centralization.md](./content-centralization.md).

### Arquitetura e Padrões

- `hexagonal-architecture`, `design-patterns`, `solid-principles`

### Linguagens (SSOT em knowledge/stacks/)

- `go-mastery` → `knowledge/stacks/go.md`
- `java-mastery` → `knowledge/stacks/java.md`
- `node-mastery` → `knowledge/stacks/node.md`

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

## 5. MCP (opcional)

Template em `.cursor/mcp.json.example`. Configure variáveis de ambiente:

- `CONTEXT7_API_KEY` — documentação de bibliotecas (Context7)
- `GITHUB_PERSONAL_ACCESS_TOKEN` — PRs e issues (GitHub)
- **Atlassian** — Remote MCP via OAuth (`mcp-remote` → `https://mcp.atlassian.com/v1/mcp`); Jira + Confluence

O `mcp.json` local é ignorado pelo git. Na primeira conexão Atlassian, complete o fluxo OAuth no navegador.

---

## 6. Instalação

```bash
./scripts/install.sh --java /path/to/project       # Java only
./scripts/install.sh --java --react /monorepo      # Java + frontend
./scripts/install.sh --react /app-next             # Next.js / React
./scripts/install.sh --stack java,react /project   # atalho com lista
./scripts/install.sh /path/to/project              # todas as stacks (sem flags)
./scripts/install.sh --skip-bun --java /project    # sem instalar Bun
./scripts/validate.sh                              # validar integridade
```

**Flags de stack:** `--java`, `--go`, `--node`, `--react` (combináveis). Sem flags, instala todas as stacks.

**Módulos disponíveis:** `all`, `rules`, `agents`, `commands`, `hooks`, `skills`, `knowledge`, `mcp`, `scripts`

A instalação copia:

- **Harness core** (sempre): agentes, commands, hooks, regras globais, skills universais
- **Por stack** (conforme flags): rules contextuais, skills `*-mastery`, knowledge em `stacks/`
- `agents.md`, `agents.override.md.example`, scratchpad template e `scratchpad.md`
- `scripts/` (`install.sh`, `validate.sh`, `update.sh`, `lib/stack-manifest.sh`)
- `.cursor/harness-stacks.json` (registro das stacks instaladas)
- `.cursor/mcp.json` (criado do example, se ausente)

**Atualização:** `update.sh` reaplica as stacks de `harness-stacks.json` por padrão. Use flags para mudar o escopo.

**Overrides locais:** copie `agents.override.md.example` → `agents.override.md` (gitignored).

**Repositório canônico:**

```text
https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit
```

---

## 7. Documentação relacionada

| Documento | Uso |
|-----------|-----|
| [confluence-how-to-guide.md](./confluence-how-to-guide.md) | How-to para desenvolvedores (base Confluence) |
| [content-centralization.md](./content-centralization.md) | Centralização rules/skills/commands |
| [agentic-harness.md](./agentic-harness.md) | Fundamentação teórica |
| [agents.md](../agents.md) | Baseline universal e Definition of Done |
