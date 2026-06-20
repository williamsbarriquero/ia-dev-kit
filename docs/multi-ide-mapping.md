# Mapeamento Multi-IDE — RPE Harness

Contrato de transformação SSOT (`.cursor/`) para artefatos específicos de cada editor.

## Princípios

1. **SSOT**: todo conteúdo é autoria em [`.cursor/`](../.cursor/).
2. **Geração na instalação**: artefatos por editor são produzidos por [`scripts/sync-platforms.sh`](../scripts/sync-platforms.sh).
3. **Baseline universal**: [`agents.md`](../agents.md) é a política mínima; o output gerado usa `AGENTS.md` (convenção cross-tool).

## Matriz de primitivos

| Primitivo RPE | SSOT | Cursor | VS Code + Copilot | Claude Code | Antigravity |
|---|---|---|---|---|---|
| Rules globais | `rules/*.mdc` (`alwaysApply: true`) | nativo | `.github/copilot-instructions.md` | `CLAUDE.md` + imports | `AGENTS.md` |
| Rules contextuais | `rules/*.mdc` (`globs`) | nativo | `.github/instructions/*.instructions.md` | `.claude/rules/*.md` | via skills/workflows |
| Agents | `agents/*.md` | `@rpe-*.md` | `.github/agents/*.agent.md` | `.claude/agents/*.md` | `.agents/agents.md` |
| Commands | `commands/*.md` | `@command` | `.github/prompts/*.prompt.md` | `.claude/skills/<cmd>/SKILL.md` | `.agents/workflows/*.md` |
| Skills | `skills/**/SKILL.md` | nativo | `.github/skills/` | `.claude/skills/` | `.agents/skills/` |
| Hooks | `hooks.json` + `hooks/` | nativo | `.github/hooks/*.json` | `.claude/settings.json` | SDK/hooks |
| MCP | `mcp.json` | nativo | VS Code MCP config | `.mcp.json` | config Antigravity |
| Baseline | `agents.md` | referência | `AGENTS.md` | import em `CLAUDE.md` | `AGENTS.md` |

## Transformação de frontmatter — Rules

### SSOT (`.mdc`)

```yaml
---
description: "Regras TypeScript"
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
```

### Copilot (`.instructions.md`)

```yaml
---
applyTo: "**/*.ts,**/*.tsx"
description: "Regras TypeScript"
---
```

### Claude Code (`.claude/rules/typescript.md`)

```yaml
---
paths: ["**/*.ts", "**/*.tsx"]
---
```

## Transformação de frontmatter — Agents

| Campo Cursor | Copilot `.agent.md` | Claude `.claude/agents/` |
|---|---|---|
| `name` | `name` | filename `rpe-<name>.md` |
| `description` | `description` | `description` |
| `model` | `model` | `model` |
| `readonly: true` | `tools: ["read", "search"]` | `permissionMode: plan` |
| `readonly: false` | omitir tools (todas) | `permissionMode: default` |
| `is_background: true` | `background: true` | `background: true` |

## Transformação de frontmatter — Commands

### Copilot (`.prompt.md`)

```yaml
---
name: review-pr
description: "Revisão de Pull Request"
agent: agent
---
```

### Claude Code (skill manual)

```yaml
---
name: review-pr
description: "Revisão de Pull Request"
disable-model-invocation: true
---
```

### Antigravity (`.agents/workflows/review-pr.md`)

```yaml
---
name: review-pr
description: "Revisão de Pull Request"
---
```

## Mapeamento de hooks

| Cursor (`hooks.json`) | Copilot/VS Code | Claude Code | Fallback cross-tool |
|---|---|---|---|
| `onPreEdit` | `PreToolUse` | `PreToolUse` | — |
| `onPostEdit` | `PostToolUse` | `PostToolUse` | — |
| `onPreCommit` | git hook | git hook | `.git/hooks/pre-commit` |
| `stop` | `Stop` | `Stop` | parcial (UltraWork) |

Scripts de hooks são copiados para `scripts/ai-hooks/` no projeto alvo e referenciados relativamente.

## Skills — Agent Skills open standard

Skills em `.cursor/skills/<name>/SKILL.md` são copiadas sem transformação estrutural para:

- `.github/skills/<name>/SKILL.md`
- `.claude/skills/<name>/SKILL.md`
- `.agents/skills/<name>/SKILL.md`

Validação: campo `name` no frontmatter deve corresponder ao nome da pasta pai.

## MCP

`.cursor/mcp.json` é sanitizado (remoção de comentários JSON) e copiado para:

- `.vscode/mcp.json` (Copilot/VS Code)
- `.mcp.json` (Claude Code)

Placeholders de secrets (`YOUR_*`, `password@`) são preservados como placeholders — nunca valores reais.

## Comandos de sync

```bash
# Todas as plataformas
./scripts/sync-platforms.sh /path/to/project

# Seletivo
./scripts/sync-platforms.sh /path/to/project --platforms=copilot,claude

# Dry-run
./scripts/sync-platforms.sh /path/to/project --dry-run
```

Plataformas suportadas: `cursor`, `copilot`, `claude`, `antigravity`.
