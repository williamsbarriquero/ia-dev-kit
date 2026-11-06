# Changelog — RPE Harness para Claude Code

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). Versões seguem [SemVer](https://semver.org/lang/pt-BR/); tags no formato `claude-vX.Y.Z`.

## [0.1.0] — 2026-11-06

### Adicionado

- Port do RPE Harness para Claude Code em `claude/`, independente do kit Cursor.
- 18 rules (9 globais, 9 contextuais por `paths`), 12 subagents `rpe-*`, 38 skills (20 de conhecimento, 3 ex-rules sob demanda, 15 workflows `/comando`), knowledge por stack e templates de spec.
- Hooks em TypeScript/Bun: `rpe-guard-bash`, `rpe-guard-mcp`, `rpe-guard-write`, `rpe-secret-scan`, `rpe-lint`, `rpe-plan-to-specs`, `rpe-grind-loop`.
- `install.sh` com merge de `settings.json` e `.mcp.json`, preservação de `AGENTS.md`/`CLAUDE.md`, registro de estado e remoção de órfãos; `update.sh`; `validate.sh` para kit e alvo.
- Testes: `bun test` dos hooks e smoke ponta a ponta do instalador.
