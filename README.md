# RPE Harness — Agentic Dev Kit

O **RPE Harness** é um kit de desenvolvimento de IA de nível corporativo para o **Cursor IDE**. Fornece orquestração determinística via agentes especializados, hooks, regras modulares e automação iterativa (UltraWork).

Inspirado no **Oh My OpenAgent**, implementa roteamento por intenção (IntentGate), persistência de sessão (scratchpad), ganchos de ciclo de vida e TDD guiado por agentes.

---

## Quick Start

```bash
git clone https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit
bash ai-dev-kit/scripts/install.sh --java /caminho/para/seu/projeto
cd /caminho/para/seu/projeto && ./scripts/validate.sh
```

**Stacks:** use `--java`, `--go`, `--node`, `--react` (combináveis) ou `--stack java,react`. Sem flags, instala todas.

**Pré-requisitos:** Cursor 3+, Git, test runner da stack, Node/npx (MCP opcional). **Bun** (UltraWork) é instalado automaticamente pelo `install.sh` quando o módulo `hooks` está incluído; use `--skip-bun` para pular.

---

## Estrutura do Harness (SSOT)

```text
ia-dev-kit/
├── .cursor/
│   ├── rules/          # 17 regras .mdc
│   ├── agents/         # 12 agentes rpe-*
│   ├── commands/       # 15 comandos @
│   ├── skills/         # 16 skills (índices → knowledge)
│   ├── knowledge/      # SSOT por stack (java, go, node)
│   ├── hooks/          # guards, transforms, continuations
│   ├── hooks.json
│   ├── mcp.json.example
│   ├── mcp.json.example
│   ├── docs/specs/     # SSOT de specs por feature
│   └── scratchpad.template.md
├── scripts/            # install.sh, validate.sh, update.sh, lib/stack-manifest.sh
├── templates/          # feature-spec, technical-spec, definition-of-done
├── docs/
│   ├── harness-guide.md           # SSOT operacional
│   ├── confluence-how-to-guide.md # How-to (base Confluence)
│   └── agentic-harness.md         # fundamentação teórica
└── agents.md                      # baseline universal (DoD, stack, comunicação)
```

### Agentes (12)

`rpe-architect`, `rpe-developer`, `rpe-reviewer`, `rpe-security`, `rpe-qa-analyst`, `rpe-test-lead`, `rpe-tester`, `rpe-sdet`, `rpe-tech-writer`, `rpe-atlassian`, `rpe-infra`, `rpe-dba`

### Commands (15)

`ultrawork`, `plan-architecture`, `test-plan`, `validate-stack`, `review-pr`, `generate-pr-description`, `refine-story`, `generate-test-cases`, `generate-mocks`, `scaffold-e2e`, `scaffold-k6`, `review-migration`, `generate-openapi`, `audit-security`, `audit-logs-otel`

### Rules (18)

Always-on: `rpe-identity`, `interaction-standards`, `coding-standards`, `intent-routing`, `safety-guardrails`, `stack-baseline`

Contextuais: `typescript`, `frontend-standards`, `go-standards`, `java-standards`, `node-standards`, `database-migrations`, `observability`, `testing-standards`, `qa-standards`, `tdd-workflow`, `code-review`, `git-conventions`, `ultrawork`

---

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [harness-guide.md](docs/harness-guide.md) | SSOT — agentes, commands, hooks, MCP, instalação |
| [confluence-how-to-guide.md](docs/confluence-how-to-guide.md) | How-to passo a passo para desenvolvedores |
| [content-centralization.md](docs/content-centralization.md) | SSOT — como centralizar rules, skills e commands |
| [agentic-harness.md](docs/agentic-harness.md) | Fundamentação teórica |
| [agents.md](agents.md) | Baseline universal e Definition of Done |

---

## Contribuindo

Use os templates em `templates/` e execute `./scripts/validate.sh` antes de submeter alterações.
