# Convenções do RPE Harness no Claude Code

- **Baseline**: `AGENTS.md` na raiz, importado pelo `CLAUDE.md`. Versão do kit e stacks instaladas em `.claude/harness-stacks.json`.
- **Rules**: `.claude/rules/`. As sem `paths` carregam sempre; as com `paths` carregam ao ler ou editar arquivo que casa.
- **Skills de conhecimento**: "leia a skill `<nome>`" significa ler `.claude/skills/<nome>/SKILL.md` com a tool `Read`. Elas têm `disable-model-invocation: true` e não carregam pela tool `Skill`.
- **Workflows**: skills `/nome` (`/plan-architecture`, `/test-plan`, `/ultrawork`, `/validate-stack`, `/review-pr` e outras). As ligadas a um papel rodam no subagent correspondente.
- **Subagents**: "subagent `rpe-<papel>`" significa delegar com a tool `Agent` a esse subagent, passando no prompt o slug da spec e o contexto necessário. Subagent não conversa com o usuário; ele devolve um relatório.
- **Specs**: `docs/specs/<slug>/feature.md` e `technical.md`, a partir de `.claude/templates/`.
- **Estado de sessão longa**: `.rpe/scratchpad.md` (template em `.claude/scratchpad.template.md`, fora do git).
- **Hooks**: `.claude/hooks/rpe-*.ts`, registrados em `.claude/settings.json`. Um bloqueio de hook traz o motivo: corrija a causa, não contorne o hook.
