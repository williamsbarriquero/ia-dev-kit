# Guia operacional — RPE Harness para Claude Code

SSOT operacional da versão Claude Code: papéis, workflows, rules, hooks, MCP e estado.

## Como o conteúdo entra no contexto

| Camada | Onde | Quando carrega |
|--------|------|----------------|
| Baseline | `AGENTS.md`, via `@AGENTS.md` no `CLAUDE.md` | Toda sessão e todo subagent |
| Rules globais | `.claude/rules/*.md` sem `paths` | Toda sessão e todo subagent |
| Rules contextuais | `.claude/rules/*.md` com `paths` | Ao ler ou editar arquivo que casa com o glob |
| Skills de conhecimento | `.claude/skills/<nome>/SKILL.md` (`disable-model-invocation: true`) | Quando uma rule, skill ou agent manda ler o arquivo |
| Skills sob demanda | `code-review`, `git-conventions`, `tdd-workflow` | O modelo escolhe pela `description` |
| Workflows | `/comando` | O usuário digita; os ligados a um papel rodam no subagent |
| Knowledge | `.claude/knowledge/stacks/*.md` | Lido a partir da skill `*-mastery` da stack |

Cadeia por stack, igual à do kit Cursor: rule contextual (`paths`) → skill `*-mastery` → knowledge.

## Subagents

| Subagent | Modelo | Ferramentas | Papel |
|----------|--------|-------------|-------|
| `rpe-architect` | opus | Read, Grep, Glob, Edit, Write, AskUserQuestion, Plan Mode | Spec; escrita só em `AGENTS.md` e `docs/specs/` (hook) |
| `rpe-test-lead` | opus | Read, Grep, Glob | Plano técnico TDD |
| `rpe-tester` | opus | Read, Grep, Glob, Edit, Write, Bash, LSP | RED e testes pós-implementação |
| `rpe-developer` | opus | Read, Grep, Glob, Edit, Write, Bash, LSP | GREEN, REFACTOR, implementação sem TDD |
| `rpe-reviewer` | opus | Read, Grep, Glob, Bash somente leitura | Revisão e descrição de PR |
| `rpe-security` | sonnet | Read, Grep, Glob, Bash somente leitura | AppSec, supply chain, IaC |
| `rpe-qa-analyst` | sonnet | Read, Grep, Glob | BDD, valor limite, a11y, refinamento |
| `rpe-sdet` | sonnet | Read, Grep, Glob, Edit, Write, Bash | E2E, contratos, mocks, k6 |
| `rpe-tech-writer` | sonnet | Read, Grep, Glob, Edit, Write | Docs e OpenAPI |
| `rpe-atlassian` | sonnet | leitura + MCP `atlassian` | Jira e Confluence |
| `rpe-infra` | sonnet | Read, Grep, Glob, Edit, Write, Bash | CI/CD, Docker, K8s, Terraform |
| `rpe-dba` | sonnet | Read, Grep, Glob, Edit, Write, Bash | Migrações e queries |

- Subagents de escrita têm `disallowedTools: Agent` (não delegam).
- "Somente leitura" com `Bash`: o hook `rpe-guard-bash.ts` libera só comandos de leitura (`git diff/log/show`, `grep`, `cat`, auditorias) para `rpe-reviewer`, `rpe-security`, `rpe-test-lead`, `rpe-qa-analyst` e `rpe-atlassian`.
- Invocação: o thread principal delega pela tool `Agent`; o usuário pode pedir em linguagem natural, mencionar `@agent-rpe-<papel>` ou abrir uma sessão inteira como o papel com `claude --agent rpe-<papel>`.
- Subagent não conversa com o usuário. Por isso desenho e aprovação ficam no thread principal (`/plan-architecture`).

## Workflows (`/comando`)

| Skill | Roda em | Uso |
|-------|---------|-----|
| `/plan-architecture` | thread principal | Spec da feature e aprovação |
| `/test-plan` | `rpe-test-lead` | Plano TDD P0–P3 |
| `/ultrawork` | thread principal | Ciclo TDD autônomo com grind-loop |
| `/validate-stack` | thread principal | DoD: lint, format, type-check, testes |
| `/review-pr`, `/generate-pr-description` | `rpe-reviewer` | Revisão e descrição de PR |
| `/refine-story`, `/generate-test-cases` | `rpe-qa-analyst` | Três Amigos, BDD |
| `/generate-mocks`, `/scaffold-e2e`, `/scaffold-k6` | `rpe-sdet` | Mocks, E2E, carga |
| `/review-migration` | `rpe-dba` | Checklist de migração |
| `/generate-openapi` | `rpe-tech-writer` | OpenAPI 3.x |
| `/audit-security`, `/audit-logs-otel` | `rpe-security` | OWASP, segredos, PII, trace context |

Os que rodam num subagent usam `context: fork` + `agent:` no frontmatter. O texto após o comando vira o pedido.

## Fluxo ponta a ponta

1. **Baseline** (uma vez): peça para preencher o `AGENTS.md`. O validate avisa enquanto houver `_[PREENCHER]_`.
2. **Design**: Shift+Tab até Plan Mode e `/plan-architecture <feature>`. O rascunho da spec vai no plano.
3. **Aprovação**: aceitar o plano no `ExitPlanMode` (ou responder `aprovado`). O hook `rpe-plan-to-specs.ts` injeta o lembrete com o slug, e a rule `plan-to-specs` manda gravar `docs/specs/<slug>/feature.md` e `technical.md` e parar. `aprovado sem tdd` muda o handoff para `rpe-developer` → `rpe-tester`.
4. **Plano de testes**: `/test-plan <slug>`.
5. **TDD**: RED com `rpe-tester`, GREEN com `rpe-developer` (recebe a lista de testes), REFACTOR numa nova delegação a `rpe-developer`. Ou `/ultrawork <slug>`.
6. **Verificação**: `/validate-stack`.
7. **Revisão**: `/review-pr`, depois `/generate-pr-description`.

## Hooks

| Script | Evento | Comportamento |
|--------|--------|---------------|
| `rpe-guard-bash.ts` | PreToolUse `Bash` | Nega rm -rf em `/` ou `~`, curl/wget piped para shell, push --force, DROP/TRUNCATE; política somente leitura por subagent; secret scan das linhas staged antes de `git commit` (`-a` inclui o working tree) |
| `rpe-guard-mcp.ts` | PreToolUse `mcp__.*` | Nega DROP, TRUNCATE, DELETE sem WHERE, ALTER ... DROP |
| `rpe-guard-write.ts` | PreToolUse `Write\|Edit\|NotebookEdit` | Escopo de escrita por subagent, aviso em `package.json`, log em `.rpe/logs/` |
| `rpe-lint.ts` | PostToolUse `Write\|Edit` | eslint/prettier locais (`node_modules/.bin`) ou gofmt no arquivo editado |
| `rpe-plan-to-specs.ts` | PostToolUse `ExitPlanMode` | `additionalContext` com a regra spec-antes-do-código e o slug |
| `rpe-grind-loop.ts` | Stop | UltraWork (abaixo) |

Proteção estática fica em `permissions` (mesclado no `settings.json`): `deny` para `.env`, `.env.local`, `.env.production`, `.env.*.local` e lockfiles; `ask` para `Dockerfile`, `docker-compose*.yml` e `.github/workflows/**`.

Todos os hooks leem JSON do stdin e bloqueiam com `permissionDecision: "deny"`. Erro interno de hook é não bloqueante (exit 1, mensagem no transcript). **Sem Bun, os hooks não rodam e os guards ficam inativos**; o validate trata isso como erro.

Para usar o secret scan também fora do Claude Code: `.git/hooks/pre-commit` com `bun .claude/hooks/rpe-secret-scan.ts`.

## UltraWork e scratchpad

- `/ultrawork <slug>` copia `.claude/scratchpad.template.md` para `.rpe/scratchpad.md` com `Modo: ultrawork`. Sem esse marcador o hook `Stop` não faz nada.
- A cada fim de turno, o hook roda os testes (`npm test` se houver script de teste, `go test ./...`, `./gradlew test`, `./mvnw test` ou `mvn test`) e só libera com exit 0 **e** `ALL_TESTS_PASSED: true` no scratchpad. Senão devolve o motivo e as últimas linhas da saída, e o Claude continua.
- Limite de 5 continuações seguidas (zera numa nova cadeia). A partir da 3ª pede revisão da abordagem. No sucesso ou no limite, troca o modo para `concluido`.
- Overrides na chave `env` do `settings.json`: `RPE_TEST_COMMAND`, `RPE_TEST_TIMEOUT_MS`, `RPE_GRIND_MAX`.
- O Claude Code tem um teto próprio de 8 bloqueios seguidos de Stop (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`); o limite do kit fica abaixo dele.

## MCP

`.mcp.json` com `context7`, `mcp-github` (`GITHUB_PERSONAL_ACCESS_TOKEN`) e `atlassian` (`mcp-remote`, OAuth no navegador). Segredos só por variável de ambiente (`${VAR}`, `${VAR:-padrão}`). Cada servidor de projeto pede aprovação na primeira sessão; `claude mcp reset-project-choices` refaz as escolhas.

## LSP

A tool `LSP` (definição, referências, diagnósticos) só existe com plugin de code intelligence: `typescript-lsp`, `gopls-lsp`, `jdtls-lsp` etc., via `/plugin install <plugin>@claude-plugins-official`, mais o binário do language server. Sem plugin, o type-check ou build da stack faz o papel.

## Personalização

- Arquivos do kit (`.claude/rules`, `agents`, `skills`, `hooks`, `knowledge`, `templates`) são sobrescritos no update. Para ajustar, crie arquivos com outro nome (por exemplo `.claude/rules/time-x.md`) ou use `CLAUDE.local.md`.
- `AGENTS.md`, `CLAUDE.md`, `.mcp.json` e o restante do `settings.json` são do projeto e nunca são sobrescritos.
- Para retirar uma regra de `permissions` vinda do kit, edite o `settings.json`; o update não remove regras de permissão (só reescreve os hooks do kit).
