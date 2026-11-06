# Notas do port Cursor → Claude Code

Registro das decisões, dos pressupostos verificados e do que ficou diferente do kit Cursor.

## Pressupostos verificados (2026-11-06, Claude Code 2.1.319)

Testados num projeto descartável com `claude -p` e hooks que registravam o stdin.

| # | Pressuposto | Resultado | Consequência |
|---|-------------|-----------|--------------|
| a | `skills:` no subagent pré-carrega skill com `disable-model-invocation: true` | **Não.** Só a skill sem a flag foi carregada | Agents e rules leem skills por caminho (`.claude/skills/<nome>/SKILL.md`); convenção em `rules/rpe-harness.md` |
| b | `Glob`/`Grep` disponíveis num subagent que os lista em `tools` sem `Bash` | Sim | Allowlists dos agents somente leitura usam `Read, Grep, Glob` |
| c | `PostToolUse` em `ExitPlanMode` com `additionalContext` | **Não verificável em `-p`**: `ExitPlanMode` não existe no modo headless | Hook `rpe-plan-to-specs.ts` + rule `plan-to-specs` como rede de segurança. Verificar manualmente numa sessão interativa |
| d | Hook em shell form com `"$CLAUDE_PROJECT_DIR"/.claude/hooks/x.ts` e `bun run` | Sim | Formato usado no `settings.fragment.json` |
| e | `Stop` com `decision: block` continua o turno; `stop_hook_active` true nas continuações | Sim | Base do `rpe-grind-loop.ts` |
| f | Rule com `paths` e brace (`src/**/*.{ts,tsx}`) carrega só após Read de arquivo que casa | Sim | Rules contextuais com `paths:` |
| — | `agent_type` no stdin de hook disparado dentro de subagent | Sim | Escopo de escrita do architect e política somente leitura via hook |
| — | `permissionDecision: "deny"` bloqueia a tool | Sim | Protocolo de todos os guards |
| — | `if: "Bash(git commit *)"` filtra o handler | Sim (comando simples) | Não usado: comandos compostos (`git add && git commit`) não são garantidos; o guard detecta `git commit` sozinho |
| — | Skill com `context: fork` + `agent:` roda no subagent | Sim | 12 workflows ligados a papéis |
| — | Plan Mode grava o plano via `Write` em `~/.claude/plans/` | Sim | `rpe-guard-write.ts` ignora caminhos fora do projeto |
| — | O agente escreve em `.claude/` com `acceptEdits` | **Não**: "sensitive file", pede permissão a cada escrita (achado no teste real do `/ultrawork`) | Estado de execução (scratchpad, contador, logs) fica em `.rpe/`, fora do git |

## Mapeamento

| Cursor | Claude Code |
|--------|-------------|
| `agents.md` ("entra sozinho") | `AGENTS.md` + `CLAUDE.md` com `@AGENTS.md` (AGENTS.md só é lido nativamente quando não existe CLAUDE.md) |
| 8 rules `alwaysApply` | `.claude/rules/*.md` sem `paths` + `rpe-harness.md` (convenções) |
| 9 rules com `globs` | `.claude/rules/*.md` com `paths:` (único campo de frontmatter lido) |
| `code-review`, `git-conventions`, `tdd-workflow` (agent-requestable) | Skills escolhidas pelo modelo pela `description` |
| rule + command `ultrawork` | Skill `/ultrawork` |
| `plan-to-specs` (Plan → Build sem hook) | Rule + hook `PostToolUse(ExitPlanMode)` |
| `model: claude-opus-4-8[]` | `model: opus` / `sonnet` (alias) |
| `readonly: true` + prosa "Permitidas/Bloqueadas" | `tools:` allowlist e `disallowedTools` |
| `Task` bloqueado | `disallowedTools: Agent` |
| `SemanticSearch` | `Grep`, `Glob`, `LSP` |
| `CallMcpTool` | tools `mcp__<servidor>__*` |
| `TodoWrite` | removido (as tools de tarefa do Claude Code dependem do modelo) |
| `@rpe-x.md` | subagent `rpe-x` (delegação pela tool `Agent`) |
| `@comando.md` | skill `/comando` |
| `.cursor/docs/specs/<slug>/` | `docs/specs/<slug>/` |
| `.cursor/scratchpad.md` | `.rpe/scratchpad.md` |
| `hooks.json` (`$1`, exit 1) | `settings.json` mesclado, stdin JSON, `permissionDecision: deny` |
| `onPreEdit` / `onPostEdit` | `PreToolUse` / `PostToolUse` em `Write\|Edit` |
| `onPreCommit` | Secret scan dentro do `rpe-guard-bash.ts` ao detectar `git commit` |
| `beforeShellExecution` / `beforeMCPExecution` | `PreToolUse` em `Bash` / `mcp__.*` |
| `stop` + `followup_message` + `loop_count` | `Stop` + `decision: block`; contador próprio em `.rpe/state/` |
| `mcp.json` com `${env:X}` | `.mcp.json` com `${X}` |
| `install.sh` sobrescreve tudo | Instalador com merge, estado e remoção de órfãos |

## Decisões

- **Árvore independente**: conversão única pelo `tools/migrate-from-cursor.py`, seguida de reescrita manual de `intent-routing`, `plan-to-specs`, `project-baseline`, `tdd-workflow`, `ultrawork`, `plan-architecture`, `lsp-integration`, `specs/README` e do baseline. O script recusa rodar de novo sem `--force`, porque isso apagaria as edições manuais.
- **Payload em `claude/kit/`**, não `claude/.claude/`: evita que o Claude Code descubra skills e rules aninhadas ao editar o próprio kit.
- **Design no thread principal**: subagent não conversa com o usuário, então `/plan-architecture` roda inline e a aprovação é o `ExitPlanMode` ou a palavra `aprovado`. Execução vai para subagents, o que dá de graça o "REFACTOR em chat novo".
- **Somente leitura com `Bash`**: `review-pr` precisa de `git diff`. Em vez de negar `Bash`, o guard aplica uma lista de comandos de leitura por `agent_type`.
- **CI e Dockerfile em `ask`, não `deny`**: o guard do Cursor bloqueava esses arquivos, mas nunca funcionou de fato (lia `$1`); aplicá-lo agora inutilizaria o `rpe-infra`.
- **Specs em `docs/specs/`**: local neutro, legível por humanos e por qualquer ferramenta.
- **Hooks em TypeScript/Bun**: Bun já era dependência (grind-loop); parsing de JSON confiável e testável com `bun test`.

## Defeitos do kit Cursor que não foram portados

- Guards liam `$1` e bloqueavam com exit 1: nunca bloqueavam nada.
- `grind-loop.ts` procurava o literal `ALL_TESTS_PASSED: true`, que não casa com o `**ALL_TESTS_PASSED**: true` do template; chamava `./mvnw` sem wrapper; `npm test` sem script de teste falhava sempre.
- `lint-on-save.sh` sem caminho lintava o projeto inteiro; `npx` podia baixar pacotes.
- `secret-scanner.sh` não filtrava linhas adicionadas no diff staged.
- `install.sh` sobrescrevia `agents.md` no update; não removia arquivos que saíram do kit; `mcp.json` existente nunca recebia servidores novos; módulo desconhecido era ignorado em silêncio.
- `update.sh` quebrava com `unbound variable` no bash 3.2 e copiava a si mesmo no alvo.
- `validate.sh` exigia `templates/` na raiz do alvo (falhava após instalar).
- Referências `AGENTS.md` versus `agents.md` divergentes (quebram em filesystem case-sensitive).

## Pendências

- Verificar manualmente o hook `rpe-plan-to-specs.ts` numa sessão interativa (pressuposto c).
- Empacotar como plugin (`.claude-plugin/` + `marketplace.json`) para agents, skills, hooks e MCP, mantendo o instalador para `CLAUDE.md`, rules e `permissions`, que plugins não carregam.
- O update não remove regras de `permissions` que saírem do fragmento do kit.
- `shellcheck` não estava disponível na máquina do port; o `validate.sh` roda quando houver.
