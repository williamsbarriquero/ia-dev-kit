# How-To Guide para Desenvolvedores com Cursor IDE

> **Rascunho para publicação no Confluence** — alinhado ao RPE Harness (`ia-dev-kit`).
> Detalhamento técnico: [harness-guide.md](./harness-guide.md) (SSOT operacional).

---

## O que é o RPE Harness (e por que importa)

O **RPE Harness** combina planejamento orientado a especificação com **TDD** em um fluxo governado por agentes especializados:

- **Planejamento antes de codificar** — definir comportamento e contratos antes da implementação
- **TDD** — testes com falha (RED) ditam quando o código está correto (GREEN)
- **Orquestração determinística** — hooks, regras e agentes `rpe-*` mitigam vibe coding

Seu papel: **arquiteto de intenção** e **revisor crítico** da saída da IA — não apenas operador de autocomplete.

| Abordagem | Velocidade inicial | Dívida técnica | Confiabilidade |
|-----------|-------------------|----------------|----------------|
| Vibe coding | Alta | Muito alta | Baixa |
| RPE Harness | Alta | Controlada | Alta |

---

## Pré-requisitos

| Ferramenta | Obrigatório | Motivo |
|------------|-------------|--------|
| **Cursor IDE 3+** | Sim | Agent mode, Plan Mode, hooks |
| **Git** | Sim | Workflow de PR e versionamento |
| **Test runner da stack** | Sim | Jest/Vitest, Pytest, `go test`, Maven/Gradle, etc. |
| **Bash** | Sim | `install.sh` e hooks shell |
| **Bun** | Sim para UltraWork | Hook `grind-loop.ts` (`stop`) — instalado pelo `install.sh` quando `hooks` está incluído |
| **Node.js 18+ / npx** | Opcional | MCP (Context7, GitHub, Atlassian) |

Windows: use **Git Bash** ou **WSL**. PowerShell nativo não é suportado para os scripts.

Familiaridade básica com Chat (`Cmd+L`) e Agent/Composer (`Cmd+I`).

---

## Passo 1: Instale o RPE Harness

O kit instala agentes, regras, commands, skills, **knowledge hub** (SSOT por stack), hooks e baseline `agents.md` em um único comando.

**Repositório:**

```text
https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit
```

### 1.1 — Clone o repositório do kit

```bash
git clone https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit
```

### 1.2 — Execute o script de instalação

Informe a stack do seu projeto com flags explícitas:

```bash
# Projeto Java
bash ai-dev-kit/scripts/install.sh --java /caminho/para/seu/projeto

# Monorepo Java + React
bash ai-dev-kit/scripts/install.sh --java --react /caminho/para/monorepo

# App Next.js (frontend completo)
bash ai-dev-kit/scripts/install.sh --react /caminho/para/app-next

# Atalho com lista
bash ai-dev-kit/scripts/install.sh --stack java,react /projeto
```

Ou no diretório atual:

```bash
bash ai-dev-kit/scripts/install.sh --java .
```

**Flags de stack (combináveis):**

| Flag | Instala |
|------|---------|
| `--java` | `java-standards`, `java-mastery`, `knowledge/stacks/java.md` |
| `--go` | `go-standards`, `go-mastery`, `knowledge/stacks/go.md` |
| `--node` | `node-standards`, `typescript`, `node-mastery`, `knowledge/stacks/node.md` |
| `--react` | `frontend-standards`, `frontend-mastery`, `typescript` + `knowledge/stacks/frontend.md` |
| `--all-stacks` | Todas as stacks (mesmo efeito de omitir flags) |

**O `install.sh` faz automaticamente:**

- Cópia do **harness core** (agentes, commands, hooks, regras globais, skills universais)
- Cópia **seletiva** de rules, skills e knowledge conforme as flags de stack
- Registro das stacks em `.cursor/harness-stacks.json`
- Cópia de `agents.md` e scratchpad
- Criação de `.cursor/docs/specs/` e templates em `.cursor/templates/` (`feature-spec.md`, `technical-spec.md`, `definition-of-done.md`)
- Criação de `.cursor/mcp.json` a partir do template (se ausente — não sobrescreve existente)
- Permissões de execução nos hooks shell
- **Instalação do Bun** (se módulo `hooks` incluído e `--skip-bun` não informado)

**Instalação seletiva por módulo:**

```bash
bash ai-dev-kit/scripts/install.sh --java /projeto rules,agents,commands
# Módulos: all | rules | agents | commands | hooks | skills | knowledge | mcp | scripts
bash ai-dev-kit/scripts/install.sh --skip-bun --java /projeto   # pula instalação do Bun
```

### 1.3 — Valide a instalação

No projeto alvo:

```bash
./scripts/validate.sh
```

### Estrutura pós-instalação

```text
/seu-projeto/
├── agents.md                    ← baseline universal (stack, DoD, comunicação)
├── scripts/
│   ├── install.sh
│   ├── validate.sh
│   └── update.sh
└── .cursor/
    ├── rules/                   ← regras .mdc (harness global + ativação por glob)
    ├── agents/                  ← 12 agentes rpe-*
    ├── commands/                ← 15 comandos @
    ├── skills/                  ← índices de ativação (→ knowledge)
    ├── knowledge/               ← SSOT por stack (java, go, node)
    │   └── stacks/
    ├── hooks/
    │   ├── guards/              ← secret, shell, write-file, mcp
    │   ├── transforms/          ← lint-on-save
    │   └── continuations/      ← grind-loop.ts (UltraWork)
    ├── hooks.json
    ├── harness-stacks.json        ← stacks instaladas (java, go, node, react)
    ├── mcp.json                 ← criado do example (opcional)
    ├── docs/
    │   └── specs/               ← specs versionadas por feature (SSOT)
    ├── templates/
    │   ├── feature-spec.md      ← template spec de negócio/comportamento
    │   ├── technical-spec.md    ← template spec técnica (contratos)
    │   └── definition-of-done.md
    ├── scratchpad.template.md
    └── scratchpad.md            ← estado de sessão (gitignored) — não substitui specs
```

---

## Passo 1.4 — Configure o agents.md

O `agents.md` descreve **Stack do Projeto**, **Arquitetura**, **Restrições** e **Verificação por Stack** (com DoD e política de comunicação). Após instalar, abra o projeto no Cursor:

```text
@agents.md

Este projeto acabou de receber o RPE Harness. Configure o agents.md — não escreva código de produção.

1. Explore o projeto no Agent mode (Cmd+I). Com a pasta do projeto aberta no Cursor,
   o índice semântico já cobre o repositório — não é necessário anexar tudo manualmente.
   Identifique a stack real a partir dos manifests (package.json, pom.xml, go.mod, etc.).
   Se quiser forçar escopo explícito na raiz: `@` → Files & Folders → pasta do projeto.

2. Preencha a seção **## Stack do Projeto** (substitua todos os _[PREENCHER]_):
   - Stack principal, runtime/build, test runner
   - Aponte knowledge SSOT e skill (@java-mastery, @go-mastery ou @node-mastery)

3. Preencha **## Arquitetura** com padrões do projeto (ex.: hexagonal, camadas, módulos)

4. Preencha **## Restrições** com limites de negócio, segurança e escopo

5. Em **## Verificação por Stack**, confirme ou ajuste os comandos da stack detectada
   (lint, format, type-check, testes). Use @validate-stack.md como referência de fechamento.

6. Remova blocos **Referência — ia-dev-kit** se não aplicáveis a este repositório

7. Liste o que foi configurado e o que ainda precisa de input humano
```

**Como o Cursor carrega contexto (Cursor 3):**

- Regras `alwaysApply: true` (`rpe-identity`, `stack-baseline`, `intent-routing`, etc.) são injetadas automaticamente.
- Regras **contextuais** ativam por extensão de arquivo (ex.: `java-standards.mdc` ao editar `*.java`) e apontam para a skill da stack, cujo conteúdo canônico está em `.cursor/knowledge/stacks/`.
- **Busca no repositório:** no Agent mode, o Cursor indexa o workspace aberto e busca semanticamente — não há `@Codebase`. Na prática, **não anexe a pasta raiz em todo prompt**; descreva a intenção e deixe o Agent localizar. Use `@Files` / `@Folders` (menu **Files & Folders** no `@`) quando souber o escopo ou quiser forçar contexto explícito.
- Para contexto adicional do harness, use `@agents.md` ou `@java-mastery` (e equivalentes `go-mastery`, `node-mastery`) no prompt.

Detalhamento da centralização rules/skills/knowledge: [content-centralization.md](./content-centralization.md).

---

## Passo 2: Design antes de codificar (Plan Mode)

Antes do Agent (`Cmd+I`), conduza design estruturado no Chat (`Cmd+L`) ou Plan Mode (`Cmd+Shift+P` → Toggle Plan Mode).

```text
@rpe-architect.md @plan-architecture.md @agents.md

Preciso adicionar a feature de "esqueci minha senha" ao módulo de autenticação.

Fase 1 — Capacidades: quais comportamentos esta feature precisa ter?
Não sugira código. Liste comportamentos do ponto de vista do usuário.
```

### Níveis de design (guia mental)

| Nível | Pergunta | Saída |
|-------|----------|-------|
| 1. Capacidades | O que deve fazer? | Comportamentos em linguagem natural |
| 2. Componentes | Quais módulos criar/alterar? | Lista ou diagrama |
| 3. Interações | Como se comunicam? | Fluxo/sequência |
| 4. Contratos | Assinaturas, DTOs, schemas? | Interfaces e tipos |
| 5. Implementação | Código | Somente após aprovação dos níveis 1–4 |

Níveis 1–4: **Plan Mode**. Nível 5: **Act Mode** após aprovação.

Skill complementar: `@hexagonal-architecture` (ports & adapters).

---

## Onde vivem as especificações (governança)

O fluxo original (TSDD / AI Dev Kit) define **`.cursor/docs/specs/`** como lugar canônico das specs — versionado no Git, referenciado em todos os passos (testes, implementação, revisão). O `scratchpad` é apenas estado de sessão.

| Artefato | Onde grava | Escopo | Versionado? |
|----------|------------|--------|-------------|
| **Baseline do projeto** | `agents.md` | Stack, arquitetura, restrições, DoD | Sim (Git) |
| **Spec de feature** | `.cursor/docs/specs/<slug>.md` | Capacidades, componentes, critérios de aceite (níveis 1–3) | Sim (Git) |
| **Spec técnica** | `.cursor/docs/specs/<slug>-technical.md` | Contratos, DTOs, schemas (nível 4) — alimenta testes | Sim (Git) |
| **Templates** | `.cursor/templates/` | `feature-spec.md`, `technical-spec.md`, `definition-of-done.md` | Sim (Git) |
| **Rascunho de sessão** | `.cursor/scratchpad.md` | Fase, testes, `ALL_TESTS_PASSED` | Não (gitignored) |
| **Espelho Confluence** (opcional) | Página no space do chapter | Visibilidade para o time; link no Jira | Sim (Confluence) |

### Dois arquivos por feature

```text
.cursor/docs/specs/
├── README.md
├── forgot-password.md              ← aprovação explícita antes de codificar
└── forgot-password-technical.md    ← insumo direto para @rpe-tester.md
```

| Arquivo | Origem (níveis de design) | Próximo passo |
|---------|---------------------------|---------------|
| `<slug>.md` | 1–3 (capacidades → interações) | Aprovação → gerar `-technical.md` |
| `<slug>-technical.md` | 4 (contratos) | `@test-plan.md` → testes RED |

### Fluxo: design → spec persistida

**1. Design (Plan Mode)** — níveis 1–4 sem código:

```text
@rpe-architect.md @plan-architecture.md @agents.md

Preciso adicionar "esqueci minha senha" ao módulo de autenticação.
Nível 1 — Capacidades: quais comportamentos? Sem código.
```

**2. Gerar specs (Act Mode)** — gravar em `.cursor/docs/specs/`:

```text
@rpe-architect.md @agents.md @.cursor/templates/feature-spec.md @.cursor/templates/technical-spec.md

Com base no design aprovado, gere os dois documentos:

1. .cursor/docs/specs/forgot-password.md — comportamentos e componentes
2. .cursor/docs/specs/forgot-password-technical.md — interfaces, DTOs, schemas

Use os templates como estrutura. NÃO escreva código de implementação.
```

A `<slug>.md` requer **aprovação explícita** antes de prosseguir. A `<slug>-technical.md` alimenta os testes na fase RED.

**3. Confluence (opcional)** — espelho para o time via `@rpe-atlassian.md`:

```text
@rpe-atlassian.md @.cursor/docs/specs/forgot-password.md

Publique resumo no Confluence e vincule ao ticket Jira FEATURE-XXX.
```

**Regra de drift:** atualize os arquivos em `.cursor/docs/specs/` como commits de primeira classe — não corrija código manualmente contornando a spec.

---

## Passo 3: Escreva a especificação técnica

Após a conversa de design (Passo 2), gere e **persista** os documentos de spec. Ainda no fluxo de planejamento — sem implementação.

```text
@rpe-architect.md @agents.md @.cursor/templates/feature-spec.md @.cursor/templates/technical-spec.md

Com base na conversa de design, gere:

1. .cursor/docs/specs/forgot-password.md
2. .cursor/docs/specs/forgot-password-technical.md

Use os templates. NÃO escreva código de implementação.
```

Em seguida, derive o plano TDD a partir da spec técnica:

```text
@rpe-test-lead.md @test-plan.md @agents.md @.cursor/docs/specs/forgot-password-technical.md

Gere o plano TDD (ordem P0 → P1, arquivos, critérios verificáveis).
Atualize a seção 5 de forgot-password-technical.md.
Registre estado da sessão em .cursor/scratchpad.md (não substitui a spec).
```

**Regra de não-edição manual:** se a IA errar depois, **atualize a spec** em `.cursor/docs/specs/` e regenere — não corrija código manualmente contornando o fluxo.

---

## Passo 4: Testes com falha primeiro (RED)

Act Mode (`Cmd+I`):

```text
@rpe-tester.md @agents.md @.cursor/docs/specs/forgot-password-technical.md

Escreva testes unitários e de integração para "esqueci minha senha".
Todos devem FALHAR — implementação ainda não existe.
Cubra critérios de aceite e edge cases da spec técnica.
```

Confirme RED imediatamente:

```bash
# TypeScript
npx vitest run forgot-password

# Go
go test ./... -run TestForgotPassword

# Java
./mvnw test -Dtest=ForgotPasswordUseCaseTest
```

Se testes passarem sem implementação, os testes estão errados — corrija antes de prosseguir.

Skill: `tdd-grinder` (integração com grind-loop).

---

## Passo 5: Implementação até GREEN

```text
@rpe-developer.md @agents.md @java-mastery @.cursor/docs/specs/forgot-password-technical.md

Implemente o código mínimo para todos os testes passarem.
Ordem hexagonal: domain → ports → use case → adapters.
Execute testes após cada arquivo. Itere até verde.
Não refatore ainda.
```

> Para Java, Go ou Node, invoque a skill da stack (`@java-mastery`, `@go-mastery`, `@node-mastery`) — o agente lê o SSOT em `.cursor/knowledge/stacks/<stack>.md`.

Deixe o agente iterar. Seu papel: **revisar diffs**, não escrever código.

---

## Passo 6: Refatoração com confiança

```text
@rpe-developer.md @agents.md @src/auth/ @tests/

Refatore para legibilidade e performance.
Não altere comportamento externo.
Execute testes após cada alteração.
```

Validação consolidada:

```text
@validate-stack.md
```

---

## Passo 7: Revisão antes do PR

Plan Mode:

```text
@rpe-reviewer.md @review-pr.md @agents.md @.cursor/docs/specs/forgot-password.md

Revise a feature "esqueci minha senha" em 4 eixos:
1. Conformidade com a spec (.cursor/docs/specs/)
2. Arquitetura (agents.md)
3. Qualidade dos testes
4. Segurança (credenciais, PII, validação de input)
```

Checklist de fechamento:

```text
@.cursor/templates/definition-of-done.md

Verifique o Definition of Done para a feature.
```

Descrição do PR:

```text
@generate-pr-description.md
```

**Definition of Done:** conforme `stack-baseline.mdc` e `agents.md` — lint, type-check, testes com exit 0.

---

## Passo 8: Comandos @ estratégicos

| Comando / Agente | Quando usar |
|------------------|-------------|
| `@rpe-architect.md` | Design e planejamento (read-only) |
| `@plan-architecture.md` | Plano arquitetural atômico |
| `@rpe-test-lead.md` | Plano TDD técnico |
| `@test-plan.md` | Ordem e prioridade dos testes |
| `@rpe-tester.md` | Testes RED |
| `@rpe-developer.md` | GREEN e refatoração |
| `@rpe-reviewer.md` | Revisão de qualidade |
| `@review-pr.md` | Auditoria de PR |
| `@validate-stack.md` | Lint, type-check, testes |
| `@ultrawork.md` | Automação total (UltraWork) |
| `@generate-pr-description.md` | Descrição de PR |
| `@audit-security.md` | OWASP e segredos |
| `@refine-story.md` | Refinamento Três Amigos (Jira) |

| Recurso Cursor | Quando usar | Exemplo |
|----------------|-------------|---------|
| Busca semântica (Agent mode) | Equivalente ao antigo `@Codebase` — exploração ampla | "Como fazemos paginação?" (sem anexar pasta) |
| `@Folders` (Files & Folders) | Escopo explícito — pasta ou subpasta | `@src/auth/`, `@.cursor/docs/specs/` |
| `@Files` (Files & Folders) | Arquivo específico | `@package.json`, `@src/auth/auth.service.ts` |
| `@Docs` | Documentação indexada (APIs externas) | `@Docs stripe` |
| `@Terminals` | Output de comandos | Após falha em testes ou build |
| `@Branch` / `@Commit` | Diff para revisão | `@Branch (Diff with Main)` |

> **Equivalência `@Codebase` → Cursor 3**
>
> | Antes (Cursor 2) | Agora (Cursor 3) |
> |------------------|------------------|
> | `@Codebase` — busca semântica no repo indexado | **Padrão:** Agent mode com projeto aberto (busca automática) |
> | Anexar “todo o código” | **Opcional:** `@` → Files & Folders → pasta raiz (ex.: `ia-dev-kit/`) |
> | Arquivos abertos na IDE | Não há `@` equivalente; o Agent lê arquivos via ferramentas quando necessário |
>
> **Atenção:** `@Codebase` nunca injetava todo o código no contexto — retornava trechos relevantes via busca semântica. Anexar a pasta raiz inteira em projetos grandes **não** replica isso de forma eficiente e pode consumir contexto à toa. Prefira deixar o Agent buscar.

**Regra de ouro:** contexto estreito e preciso = menos alucinações; para exploração ampla, confie na busca do Agent em vez de anexar a raiz manualmente.

Lista completa: [harness-guide.md §2](./harness-guide.md).

---

## Passo 9: Agentes paralelos (features grandes)

Use **Background Agents** (Cursor 3+) com worktrees Git isoladas.

**Quando paralelizar:** módulos sem arquivos compartilhados.

**Agente 1 — Planejador:**

```text
@rpe-architect.md @agents.md @.cursor/docs/specs/

Monitore as specs conforme a feature evolui.
Sinalize decisões que contradigam agents.md.
```

**Agente 2 — Executor:**

```text
@rpe-developer.md @agents.md @.cursor/docs/specs/payment-processing-technical.md

Implemente PaymentProcessingUseCase conforme a spec técnica.
Execute testes após cada arquivo. Não toque outros módulos.
```

**Agente 3 — Verificador:**

```text
@rpe-reviewer.md @agents.md @src/domain/payment/

Revise código em tempo real. Reporte problemas sem editar.
```

---

## Passo 10: Modo UltraWork (automação total)

Para features completas com auto-correção:

```text
@ultrawork.md

Objetivo: implementar notificações por email conforme plano aprovado.
```

**Pré-requisitos:** Bun no PATH (instalado pelo `install.sh` com hooks), `.cursor/scratchpad.md` preenchido, hooks ativos.

O hook `grind-loop.ts` reexecuta até **5 iterações** se testes falharem ou `ALL_TESTS_PASSED: true` estiver ausente no scratchpad.

---

## Passo 11: Hooks de segurança

Instalados automaticamente via `install.sh`. Registrados em `.cursor/hooks.json`:

| Evento | Script | Função |
|--------|--------|--------|
| `stop` | `grind-loop.ts` | Auto-correção UltraWork/TDD (requer Bun) |
| `onPreEdit` | `write-file-guard.sh` | Protege `.env`, lockfiles, CI workflows |
| `onPostEdit` | `lint-on-save.sh` | ESLint/Prettier (TS/JS) ou gofmt (Go) |
| `onPreCommit` | `secret-scanner.sh` | Detecta segredos hardcoded |
| `beforeShellExecution` | `shell-guard.sh` | Bloqueia `rm -rf /`, force push, etc. |
| `beforeMCPExecution` | `mcp-guard.sh` | Bloqueia SQL/MCP destrutivo |

Nenhuma configuração adicional necessária após instalação.

---

## Cenários com Commands (substituto de workflows)

| Cenário | Comando(s) |
|---------|------------|
| Nova feature completa | `@ultrawork.md` ou `@plan-architecture.md` → `@test-plan.md` → `@rpe-tester.md` → `@rpe-developer.md` → `@validate-stack.md` → `@review-pr.md` |
| Bug fix | `@test-plan.md` → `@rpe-tester.md` (reproduzir falha) → `@rpe-developer.md` |
| Refatoração | `@rpe-developer.md` + `@validate-stack.md` (testes como rede) |
| Migração SQL | `@review-migration.md` + `@rpe-dba.md` |
| Performance | `@scaffold-k6.md` + `@rpe-sdet.md` |

Exemplo nova feature:

```text
@ultrawork.md @agents.md

Preciso implementar notificações por email. Siga o ciclo completo TDD.
```

---

## MCP (opcional)

Template: `.cursor/mcp.json.example`. Variáveis de ambiente:

- `CONTEXT7_API_KEY` — documentação de bibliotecas
- `GITHUB_PERSONAL_ACCESS_TOKEN` — PRs e issues
- Atlassian Remote MCP — OAuth via `mcp-remote` (Jira + Confluence)

O `mcp.json` local é gitignored. Detalhes: [harness-guide.md §5](./harness-guide.md).

---

## Armadilhas comuns

**Drift de especificação** — Atualize os arquivos em `.cursor/docs/specs/` (e `agents.md` se for decisão transversal). Trate updates de spec como commits de primeira classe.

**Spec só no scratchpad ou no chat** — O scratchpad é gitignored. Spec canônica = `.cursor/docs/specs/<slug>.md` + `<slug>-technical.md`.

**Sobre-especificação precoce** — Especifique o suficiente para o próximo teste RED.

**Perda de propriedade** — Revise cada diff. Peça explicação de lógica não óbvia.

**Pular planejamento** — Sempre Plan Mode + `@rpe-architect.md` antes de implementar.

---

## Ciclo RPE Harness (referência rápida)

```text
┌─────────────────────────────────────────────────────────────┐
│  CICLO RPE HARNESS                                          │
│                                                             │
│  1. DESIGN (Plan Mode)                                      │
│     └─ @rpe-architect.md → níveis 1–4 de design            │
│                                                             │
│  2. SPEC (Act Mode)                                         │
│     └─ .cursor/docs/specs/<slug>.md + -technical.md         │
│                                                             │
│  3. PLANO TDD                                               │
│     └─ @rpe-test-lead.md + @test-plan.md                    │
│                                                             │
│  4. TESTES RED (Act Mode)                                   │
│     └─ @rpe-tester.md → confirmar falha                     │
│                                                             │
│  5. IMPLEMENTAR GREEN (Act Mode)                            │
│     └─ @rpe-developer.md → testes verdes                    │
│                                                             │
│  6. REFATORAR (Act Mode)                                    │
│     └─ @rpe-developer.md + @validate-stack.md               │
│                                                             │
│  7. REVISAR (Plan Mode)                                     │
│     └─ @rpe-reviewer.md + @review-pr.md → PR                │
└─────────────────────────────────────────────────────────────┘
```

---

## Checklist de início de feature

- [ ] `install.sh` executado e `validate.sh` passou
- [ ] `agents.md` configurado (**Stack do Projeto**, **Arquitetura**, **Restrições**)
- [ ] Bun no PATH (automático via `install.sh` com hooks, ou manual se `--skip-bun`)
- [ ] `scratchpad.md` criado (estado de sessão — não substitui specs)
- [ ] Design iniciado com `@rpe-architect.md` no Plan Mode
- [ ] **Dois documentos de spec** em `.cursor/docs/specs/` (`<slug>.md` aprovado + `<slug>-technical.md`)
- [ ] Plano TDD com `@test-plan.md` / `@rpe-test-lead.md`
- [ ] Testes RED confirmados antes de implementar
- [ ] `@validate-stack.md` passou (exit 0)
- [ ] `@rpe-reviewer.md` + `@review-pr.md` executados

---

## Documentação relacionada

| Documento | Conteúdo |
|-----------|----------|
| [harness-guide.md](./harness-guide.md) | SSOT operacional — agentes, commands, hooks, MCP |
| [content-centralization.md](./content-centralization.md) | Centralização rules/skills/knowledge |
| [agentic-harness.md](./agentic-harness.md) | Fundamentação teórica |
| [agents.md](../agents.md) | Baseline universal e Definition of Done |
| [.cursor/docs/specs/README.md](../.cursor/docs/specs/README.md) | Convenção do diretório de specs |
| [templates/feature-spec.md](../templates/feature-spec.md) | Template spec de feature (níveis 1–3) |
| [templates/technical-spec.md](../templates/technical-spec.md) | Template spec técnica (nível 4 — contratos) |
| [templates/definition-of-done.md](../templates/definition-of-done.md) | Checklist de fechamento por feature |
