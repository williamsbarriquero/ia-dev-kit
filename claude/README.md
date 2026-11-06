# RPE Harness para Claude Code

Versão do ia-dev-kit para o **Claude Code**. Mesmas fases, papéis e conteúdo do kit Cursor (spec antes do código, TDD com papéis, DoD por stack, UltraWork), usando os primitivos nativos do Claude Code: `CLAUDE.md`, `.claude/rules`, subagents, skills, hooks e `.mcp.json`.

A árvore `claude/` é independente do kit Cursor (`.cursor/` na raiz). Ela nasceu de uma conversão única ([tools/migrate-from-cursor.py](tools/migrate-from-cursor.py)) e evolui por conta própria.

---

## Quick Start

```bash
git clone https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit
bash ai-dev-kit/claude/scripts/install.sh --java /caminho/para/seu/projeto
cd /caminho/para/seu/projeto && bash .claude/rpe/validate.sh
```

Depois abra o projeto com `claude`, aceite a confiança no workspace (habilita os hooks de projeto) e aprove os servidores do `.mcp.json`.

**Stacks:** `--java`, `--go`, `--node`, `--react` (combináveis) ou `--stack java,react`. Sem flag, instala todas.

**Pré-requisitos:** Claude Code, Git, Python 3.9+ (instalador), **Bun** (hooks; o instalador instala se faltar, `--skip-bun` pula) e o test runner da stack. Node/npx só para os servidores MCP.

**Atualizar** (a partir do clone do kit; reaproveita as stacks registradas e remove arquivos que saíram do kit):

```bash
bash ai-dev-kit/claude/scripts/update.sh /caminho/para/seu/projeto
```

---

## O que é instalado

| No projeto | Conteúdo |
|------------|----------|
| `CLAUDE.md` | Criado com `@AGENTS.md`; se já existir, só ganha o import |
| `AGENTS.md` | Baseline com placeholders `_[PREENCHER]_`; nunca sobrescrito |
| `.claude/rules/` | 9 rules globais (sem `paths`) + contextuais por `paths` da stack |
| `.claude/agents/` | 12 subagents `rpe-*` |
| `.claude/skills/` | Skills de conhecimento + workflows `/comando` (15 ex-commands) |
| `.claude/knowledge/stacks/` | SSOT técnico por linguagem |
| `.claude/hooks/rpe-*.ts` | Guards, lint, plan-to-specs, grind-loop (Bun) |
| `.claude/settings.json` | **Mesclado**: hooks e `permissions` do kit; o resto é preservado |
| `.mcp.json` | **Mesclado**: só acrescenta servidores ausentes |
| `.claude/templates/`, `docs/specs/README.md` | Templates de spec e DoD |
| `.claude/rpe/validate.sh` | Validação do harness no projeto |
| `.claude/harness-stacks.json` | Versão do kit, stacks e arquivos instalados |

Módulos para instalação parcial: `rules,agents,skills,knowledge,hooks,settings,mcp,templates,baseline,validate`.

---

## Fluxo de trabalho

| Fase | Como |
|------|------|
| Baseline | "Preencha o baseline do AGENTS.md" (uma vez por projeto) |
| Design e aprovação | `/plan-architecture <feature>`, de preferência em Plan Mode. Aprovar o plano grava `docs/specs/<slug>/` |
| Plano de testes | `/test-plan <slug>` (roda no subagent `rpe-test-lead`) |
| RED → GREEN → REFACTOR | Delegação aos subagents `rpe-tester` e `rpe-developer`, ou `/ultrawork <slug>` |
| Verificação | `/validate-stack` |
| Revisão e PR | `/review-pr`, `/generate-pr-description` (subagent `rpe-reviewer`) |

Detalhes em [docs/harness-guide.md](docs/harness-guide.md). Diferenças em relação ao Cursor e decisões do port em [docs/porting-notes.md](docs/porting-notes.md).

---

## Desenvolvimento do kit

```text
claude/
├── kit/                 # payload (vira <alvo>/.claude/); não se chama .claude/ de propósito
├── scripts/             # install.sh, update.sh, validate.sh, lib/
├── tests/hooks/         # bun test (hooks como processos reais, JSON no stdin)
├── tests/install/       # install/update/validate ponta a ponta
├── tools/               # conversão única a partir do kit Cursor (histórico)
├── docs/
├── VERSION
└── CHANGELOG.md
```

Antes de submeter alterações:

```bash
bash claude/scripts/validate.sh
```

Ele valida frontmatter, referências cruzadas, resíduos de sintaxe Cursor, manifesto de stacks, roda os testes dos hooks e o smoke do instalador. Ao mudar o payload, suba `VERSION` e registre no `CHANGELOG.md`.
