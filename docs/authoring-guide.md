# Guia de Authoring — RPE Harness Multi-IDE

Regras para escrever conteúdo no SSOT (`.cursor/`) compatível com todos os editores.

## Princípio central

Todo conteúdo nasce em `.cursor/` e é transformado automaticamente na instalação. **Nunca edite artefatos gerados** (`.github/copilot-instructions.md`, `CLAUDE.md`, etc.) no projeto alvo.

## Onde escrever cada tipo de conteúdo

| Tipo | Local SSOT | Template |
|---|---|---|
| Rule global | `.cursor/rules/*.mdc` (`alwaysApply: true`) | `templates/rule-template.mdc` |
| Rule contextual | `.cursor/rules/*.mdc` (`globs`) | `templates/rule-template.mdc` |
| Agent | `.cursor/agents/*.md` | `templates/agent-template.md` |
| Command | `.cursor/commands/*.md` | `templates/command-template.md` |
| Skill | `.cursor/skills/<name>/SKILL.md` | `templates/skill-template.md` |
| Baseline universal | `agents.md` | — |

## Regras editor-agnósticas

### Referências a outros artefatos

```markdown
# Correto
Seguir `interaction-standards.mdc` e invocar agente `rpe-developer`.

# Evitar (Cursor-only)
Seguir `.cursor/rules/core/004-interaction-standards.mdc` e usar `@rpe-developer.md`.
```

### Rules globais

- Manter concisas — impactam `CLAUDE.md` (limite recomendado ~150 linhas totais).
- Rules específicas de linguagem/framework devem usar `globs`, não `alwaysApply: true`.
- Campo `globs` no SSOT mapeia para:
  - Copilot: `applyTo` em `.instructions.md`
  - Claude: `paths` em `.claude/rules/`

### Agents

- Campo `readonly` é **obrigatório** (`true` ou `false`).
- Descrever ferramentas permitidas/bloqueadas no corpo (mapeadas automaticamente).
- Evitar referências a mecânicas exclusivas do Cursor (`@mention`, `Task` tool).

### Commands

- Incluir pelo menos um passo numerado (`1.`, `2.`, ...).
- Conteúdo deve funcionar como prompt standalone (sem dependência de `@`).

### Skills

- Campo `name` deve ser **idêntico** ao nome da pasta pai.
- `description` max 1024 caracteres (Agent Skills standard).
- Incluir seções: Propósito, Fluxo de Execução, Regras.

## Mapeamento automático de frontmatter

| SSOT | Copilot | Claude | Antigravity |
|---|---|---|---|
| `globs: ["**/*.ts"]` | `applyTo: "**/*.ts"` | `paths: ["**/*.ts"]` | — |
| `readonly: true` | `tools: [read, search]` | `permissionMode: plan` | readonly no índice |
| command body | `.prompt.md` | skill manual | workflow |

## Checklist antes de commitar

1. `./scripts/validate.sh` — estrutura e frontmatter
2. `./scripts/validate-sync.sh` — paridade de artefatos gerados
3. Sem referências Cursor-only no corpo
4. Skills com `name` = nome da pasta

## Adicionando novo artefato

1. Criar arquivo no SSOT usando template correspondente.
2. Rodar `./scripts/validate.sh`.
3. Rodar `./scripts/validate-sync.sh`.
4. Documentar equivalência de invocação em `multi-ide-quickstart.md` se for command ou agent público.
