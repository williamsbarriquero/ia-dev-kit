# Matriz de Paridade Multi-IDE — RPE Harness

Guia de equivalências, limitações e escolha de editor por caso de uso.

## Paridade por capacidade

| Capacidade | Cursor | Copilot | Claude Code | Antigravity |
|---|---|---|---|---|
| Rules always-on | 100% | ~95% | ~90% | ~90% |
| Rules por glob | 100% | 100% | 100% | ~70% |
| Subagentes | 100% | ~85% | ~90% | ~80% |
| Slash commands | 100% | 100% | ~85% | 100% |
| Skills | 100% | 100% | 100% | 100% |
| Hooks determinísticos | 100% | ~80% (Preview) | ~90% | ~70% |
| UltraWork / grind-loop | 100% | parcial | parcial | parcial |
| MCP corporativo | 100% | 100% | 100% | variável |

## O que funciona igual

- **Skills**: padrão Agent Skills (`SKILL.md` em pasta nomeada).
- **Baseline de políticas**: DoD, verificação por stack, formato de resposta via `AGENTS.md`.
- **Rules contextuais**: globs mapeados para `applyTo` (Copilot) e `paths` (Claude).
- **Comandos de verificação**: lint, test, type-check definidos em `agents.md`.

## O que é adaptado

| Recurso SSOT | Adaptação |
|---|---|
| `@rpe-developer.md` (Cursor) | Agent selector (Copilot), subagent `rpe-developer` (Claude), índice em `.agents/agents.md` (Antigravity) |
| `@review-pr.md` (Cursor) | `/review-pr` slash command |
| `.mdc` rules | Agregação em `copilot-instructions.md` / `CLAUDE.md` |
| `hooks.json` eventos Cursor | PascalCase (`PreToolUse`, `PostToolUse`, `Stop`) |
| `onPreCommit` | Git hook `pre-commit` no projeto alvo |

## Cursor-only (sem paridade total)

- **Menção `@` de agents/commands**: mecânica nativa do Cursor.
- **UltraWork com grind-loop**: hook `stop` + `.cursor/scratchpad.md` — parcialmente replicável via `Stop` hook.
- **Rules agent-requestable**: flag `alwaysApply: false` sem globs (ex.: `code-review.mdc`, `ultrawork.mdc`) — carregadas sob demanda no Cursor; em outros editores, incluir manualmente ou invocar via skill/command.
- **mcp.json com comentários**: Cursor aceita JSONC; outros editores recebem JSON puro.

## Guia de escolha por caso de uso

| Caso de uso | Editor recomendado | Motivo |
|---|---|---|
| Desenvolvimento autônomo com auto-correção (UltraWork) | Cursor | grind-loop nativo |
| Time padronizado em VS Code corporativo | Copilot | integração GitHub, custom agents |
| Fluxo terminal + subagentes paralelos | Claude Code | subagents, hooks maduros |
| Pipelines multi-agente Google Cloud | Antigravity | workflows, Agent Manager |
| Revisão de PR no GitHub.com | Copilot | coding agent + AGENTS.md |
| Skills compartilhadas entre editores | Qualquer | sync gera cópias idênticas |

## Verificação de paridade

Após instalação, execute:

```bash
./scripts/validate-sync.sh
```

O script valida contagem estrutural SSOT vs artefatos gerados e executa dry-run de sync.

## Overrides locais

| Editor | Arquivo de override (gitignored) |
|---|---|
| Universal | `agents.override.md` |
| Claude Code | `CLAUDE.local.md` |
| Cursor | `.cursor/scratchpad.md` |

Overrides locais não são sobrescritos pelo sync.
