# Quick Start Multi-IDE — RPE Harness

Guia rápido de instalação e uso por editor.

## Instalação

```bash
# Todas as plataformas
./scripts/install.sh /caminho/para/seu/projeto/

# Seletivo por editor
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=cursor
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=copilot
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=claude
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=antigravity

# Time misto
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=cursor,copilot,claude,antigravity
```

Re-sync sem reinstalar tudo:

```bash
./scripts/sync-platforms.sh /caminho/para/seu/projeto/ --platforms=copilot,claude
```

## Equivalências por editor

| Editor | Instalação | Invocar agente | Invocar command | Skills |
|---|---|---|---|---|
| Cursor | `--platforms=cursor` | `@rpe-developer.md` | `@review-pr.md` | automático |
| VS Code + Copilot | `--platforms=copilot` | selecionar agent no chat | `/review-pr` | automático |
| Claude Code | `--platforms=claude` | subagent `rpe-developer` | `/review-pr` | automático |
| Antigravity | `--platforms=antigravity` | via `.agents/agents.md` | `/review-pr` | automático |

## Artefatos gerados

| Editor | Diretórios principais |
|---|---|
| Cursor | `.cursor/` |
| Copilot | `.github/copilot-instructions.md`, `.github/instructions/`, `.github/prompts/`, `.github/agents/`, `.github/skills/`, `.github/hooks/` |
| Claude Code | `CLAUDE.md`, `.claude/rules/`, `.claude/agents/`, `.claude/skills/`, `.claude/settings.json` |
| Antigravity | `AGENTS.md`, `.agents/skills/`, `.agents/workflows/`, `.agents/agents.md` |
| Universal | `AGENTS.md`, `scripts/ai-hooks/` |

## Validação

```bash
./scripts/validate.sh          # integridade do SSOT
./scripts/validate-sync.sh     # paridade dos artefatos gerados
```

## Overrides locais (preservados no sync)

| Arquivo | Escopo |
|---|---|
| `agents.override.md` | universal |
| `CLAUDE.local.md` | Claude Code |
| `.cursor/scratchpad.md` | Cursor (UltraWork) |

## Documentação relacionada

- [multi-ide-mapping.md](multi-ide-mapping.md) — contrato de transformação
- [multi-ide-parity.md](multi-ide-parity.md) — matriz de paridade e limitações
- [authoring-guide.md](authoring-guide.md) — como escrever conteúdo SSOT editor-agnóstico
