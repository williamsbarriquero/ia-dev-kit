# How-To Guide para Desenvolvedores com Cursor IDE

> **Rascunho para publicação no Confluence** — onboarding do RPE Harness (`ia-dev-kit`).
> Catálogo de agentes, commands, skills e hooks: [harness-guide.md](./harness-guide.md).

---

## O que é o RPE Harness

Planejamento orientado a especificação. A spec aprovada em `.cursor/docs/specs/<slug>/` é a fonte da verdade. TDD é o caminho padrão. Dá para implementar a spec e testar depois. Você define a intenção e revisa o diff. O agente da fase lê sozinho o command, as skills e os templates.

| Abordagem | Velocidade inicial | Dívida técnica | Confiabilidade |
|-----------|-------------------|----------------|----------------|
| Vibe coding | Alta | Muito alta | Baixa |
| RPE Harness | Alta | Controlada | Alta |

---

## Como chamar

**Uma entrada por prompt.** Anexe o agente da fase e o contexto da tarefa (a spec, a pasta). Não anexe `agents.md`, command, skill nem template: o agente já lê esses arquivos.

| Fase | Chame só isto | Anexe | Modo |
|------|----------------|-------|------|
| Design | `@rpe-architect.md` | — | Plan. Rascunho da spec, sem lista de tarefas. `aprovado` grava a spec |
| Plano de testes (TDD) | `@rpe-test-lead.md` | `technical.md` | Plan |
| RED e GREEN (TDD) | `@rpe-tester.md`, depois `@rpe-developer.md` | `technical.md` | Act, no mesmo chat. O refactor é outro chat |
| Implementar sem TDD | `@rpe-developer.md` | `technical.md` | Act, logo após as specs |
| Testes depois da implementação | `@rpe-tester.md` | `technical.md` | Act. Só no caminho sem TDD |
| Revisar e descrever o PR | `@rpe-reviewer.md` | spec de feature | Plan |
| Feature inteira, sem parar | `@ultrawork.md` | objetivo | Act |
| Lint, tipos e testes | `@validate-stack.md` | — | Act |

`@ultrawork.md` e `@validate-stack.md` não têm agente. São os únicos commands que entram no prompt.

Fora desse fluxo, a mesma regra: `@rpe-security.md`, `@rpe-dba.md`, `@rpe-qa-analyst.md`, `@rpe-sdet.md`, `@rpe-atlassian.md`, `@rpe-tech-writer.md`. Cada um abre o command do pedido.

O `@rpe-architect.md` já segue `plan-architecture`, lê `agents.md` e as skills de arquitetura (`hexagonal-architecture`, `design-patterns`, `solid-principles`). Em Java, `clean-architecture`, `java-test-layers` e `clean-architecture-ddd` só se o repositório já usar esse modelo ou o pedido for adotá-lo.

---

## Pré-requisitos

| Ferramenta | Obrigatório | Motivo |
|------------|-------------|--------|
| **Cursor IDE 3+** | Sim | Agent mode, Plan Mode, hooks |
| **Git** | Sim | PR e versionamento |
| **Test runner da stack** | Sim | Jest/Vitest, `go test`, Maven/Gradle |
| **Bash** | Sim | `install.sh` e hooks shell |
| **Bun** | Sim para UltraWork | Hook `grind-loop.ts` — o `install.sh` instala quando `hooks` entra |
| **Node.js 18+ / npx** | Opcional | MCP |

Windows: Git Bash ou WSL. PowerShell nativo não executa os scripts.

Chat: `Cmd+L`. Agent: `Cmd+I`. Plan Mode: `Cmd+Shift+P` → Toggle Plan Mode.

---

## 1. Instalar

Repositório: `https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit`

```bash
git clone https://gitlab.rpe.tech/rpe-bus/rpe-vertical/chapter-backend/ai-engineering/ai-dev-kit

bash ai-dev-kit/scripts/install.sh --java /caminho/para/seu/projeto
bash ai-dev-kit/scripts/install.sh --java --react /caminho/para/monorepo
bash ai-dev-kit/scripts/install.sh --react /caminho/para/app-next
bash ai-dev-kit/scripts/install.sh --stack java,react /projeto
bash ai-dev-kit/scripts/install.sh --skip-bun --java /projeto
```

Sem flag de stack, instala java, go, node e react.

| Flag | O que entra além do harness core |
|------|----------------------------------|
| `--java` | `java-standards`, `java-mastery`, `clean-architecture`, `java-test-layers`, `clean-architecture-ddd`, `knowledge/stacks/java.md` |
| `--go` | `go-standards`, `go-mastery`, `knowledge/stacks/go.md` |
| `--node` | `node-standards`, `typescript`, `node-mastery`, `knowledge/stacks/node.md` |
| `--react` | `frontend-standards`, `frontend-mastery`, `typescript`, `knowledge/stacks/frontend.md` |

Módulos, se não quiser `all`: `rules`, `agents`, `commands`, `hooks`, `skills`, `knowledge`, `mcp`, `scripts`.

```bash
bash ai-dev-kit/scripts/install.sh --java /projeto rules,agents,commands
```

No projeto alvo:

```bash
./scripts/validate.sh
```

O script copia o harness, grava `.cursor/harness-stacks.json`, cria `agents.md`, `.cursor/docs/specs/`, `.cursor/templates/` e `.cursor/mcp.json` (não sobrescreve um `mcp.json` que já exista) e dá permissão de execução nos hooks.

```text
/seu-projeto/
├── agents.md                         ← stack, arquitetura, restrições, DoD
├── scripts/                          ← install.sh, validate.sh, update.sh
└── .cursor/
    ├── rules/                        ← globais + uma regra por stack
    ├── agents/                       ← 12 agentes rpe-*
    ├── commands/                     ← lidos pelos agentes, não pelo prompt
    ├── skills/                       ← lidas pelos agentes e pelas regras de glob
    ├── knowledge/stacks/             ← SSOT da linguagem
    ├── hooks/                        ← guards, lint-on-save, grind-loop.ts
    ├── hooks.json
    ├── harness-stacks.json
    ├── mcp.json
    ├── docs/specs/<slug>/            ← feature.md e technical.md
    ├── templates/                    ← feature-spec, technical-spec, definition-of-done
    └── scratchpad.md                 ← sessão (gitignored); não substitui a spec
```

---

## 2. Setup do projeto existente

Rode uma vez, depois do `install.sh`, com o repositório já aberto. O architect lê os manifests e grava o `agents.md`. Não anexe o arquivo: ele já está na raiz.

```text
@rpe-architect.md

Configure o agents.md deste projeto. Não escreva código de produção e não gere plano de feature.

1. Explore o repositório. Identifique a stack por package.json, pom.xml,
   build.gradle, go.mod e .cursor/harness-stacks.json.
2. Preencha Stack do Projeto, Arquitetura, Restrições e Verificação por Stack.
   Substitua todos os _[PREENCHER]_.
3. Em Arquitetura, descreva o padrão que o código já usa.
4. Restrição de negócio que não estiver no código: deixe _pendente_ e liste
   o que precisa de input humano.
5. Remova os blocos "Referência — ia-dev-kit".
6. Liste o que foi preenchido.
```

Projeto vazio: o mesmo prompt, descrevendo a stack na mensagem. Sem manifest, ele usa o que você escreveu.

Nos chats seguintes o arquivo entra sozinho. Se alguém pedir uma feature com `_[PREENCHER]_` ainda no arquivo, o agente preenche antes do plano. O setup acima é o momento em que um projeto existente é lido de ponta a ponta.

Regras `alwaysApply` entram sozinhas. A regra da extensão (`java-standards.mdc` em `*.java`, e o equivalente Go, Node ou frontend) aponta a skill da stack. Não cite `@java-mastery` no prompt do dia a dia.

No Agent mode o workspace já está indexado. Descreva a intenção e deixe o agente buscar. Use `@Files` ou `@Folders` quando quiser limitar a pasta (`@src/auth/`, `@.cursor/docs/specs/`). Anexar a raiz inteira não melhora a busca e gasta contexto.

Detalhe de rules, skills e knowledge: [content-centralization.md](./content-centralization.md).

---

## 3. Uma feature, do design ao PR

Exemplo: "esqueci minha senha". Specs versionadas em `.cursor/docs/specs/`. O scratchpad só guarda a sessão.

| Arquivo | Conteúdo | Quando seguir |
|---------|----------|----------------|
| `agents.md` | Stack, arquitetura, restrições, DoD | Decisão do projeto |
| `.cursor/docs/specs/<slug>/feature.md` | Comportamento e componentes | Aprovação explícita antes de codar |
| `.cursor/docs/specs/<slug>/technical.md` | Contratos, DTOs, schemas | Insumo dos testes |
| `.cursor/templates/` | Forma desses documentos | O architect lê; não anexe |
| `.cursor/scratchpad.md` | Fase e `ALL_TESTS_PASSED` | Não vai para o Git |

Níveis de design, todos com o architect, sem código até o último:

| Nível | Pergunta | Onde para |
|-------|----------|-----------|
| 1. Capacidades | O que a pessoa consegue fazer? | `feature.md` |
| 2. Componentes | Quais módulos mudam? | `feature.md` |
| 3. Interações | Como se falam? | `feature.md` |
| 4. Contratos | Assinaturas, DTOs, schemas | `technical.md` |
| 5. Implementação | Código | Só depois da spec aprovada |

Se a implementação divergir, atualize a spec e regenere. Não corrija o código por fora dela.

### 3.1 Design

Plan Mode.

```text
@rpe-architect.md

Preciso adicionar "esqueci minha senha" ao módulo de autenticação.

Nível 1 — quais comportamentos, do ponto de vista de quem usa?
Não sugira código.
```

Siga os níveis 2, 3 e 4 na mesma conversa. O desenho traz o slug (`forgot-password`). Ainda não há lista de tarefas: isso é o rascunho da spec.

Quando o desenho estiver certo, responda com um dos dois:

```text
aprovado
```

```text
aprovado sem tdd
```

O architect grava `.cursor/docs/specs/forgot-password/feature.md` e `technical.md` e para. Essa aprovação é da spec. Não há segundo prompt pedindo os arquivos. `aprovado` segue para o TDD. `aprovado sem tdd` segue para a implementação.

A lista de tarefas, se você pedir, sai dessa pasta. Ela não reescreve a spec.

No Build do Plan Mode, se a pasta da feature ainda não existir, a regra `plan-to-specs` grava a spec e para. Se `feature.md` e `technical.md` já existirem, o Build implementa a partir deles. O Cursor não oferece um hook só para esse clique.

Publicar no Confluence é opcional:

```text
@rpe-atlassian.md @.cursor/docs/specs/forgot-password/feature.md

Publique um resumo no Confluence e vincule ao ticket Jira FEATURE-XXX.
```

### 3.2 TDD

RED e GREEN ficam no mesmo chat. São dois prompts porque são dois agentes: o tester escreve o teste que falha, o developer faz passar sem alterar o teste. O motivo de cada teste ainda está na conversa.

Um chat novo não herda esse raciocínio. Quando a janela enche, Cursor e Claude Code compactam o histórico num resumo e perdem detalhe. O que sobrevive é o que está em arquivo: spec, teste e código. Por isso o refactor abre chat novo, com a spec e a pasta do código. A suíte verde no disco é a memória.

Plano de testes:

```text
@rpe-test-lead.md @.cursor/docs/specs/forgot-password/technical.md

Gere o plano TDD (P0 → P1, arquivos, critérios verificáveis).
Atualize a seção 5 de technical.md.
Registre a sessão em .cursor/scratchpad.md.
```

Testes RED, em Act Mode.

```text
@rpe-tester.md @.cursor/docs/specs/forgot-password/technical.md

Escreva testes unitários e de integração de "esqueci minha senha".
Todos devem falhar — a implementação ainda não existe.
Cubra os critérios de aceite e os edge cases da spec técnica.
```

Confirme a falha antes de implementar. Teste verde sem código de produção significa teste errado.

```bash
npx vitest run forgot-password
go test ./... -run TestForgotPassword
./mvnw test -Dtest=ForgotPasswordUseCaseTest
```

Implementar até o GREEN:

```text
@rpe-developer.md @.cursor/docs/specs/forgot-password/technical.md

Implemente o mínimo para os testes passarem.
Siga a arquitetura descrita no agents.md.
Se o Java do projeto já for Clean Architecture, ou o pedido for adotá-la: domínio e gateway → use case → adapter. Nos demais, implemente na arquitetura existente.
Execute os testes depois de cada arquivo.
Não refatore ainda.
```

Revise o diff. Não escreva o código no lugar do agente.

> O developer lê a skill da stack (`java-mastery`, `go-mastery`, `node-mastery`) e o SSOT em `.cursor/knowledge/stacks/<stack>.md`. `clean-architecture`, `java-test-layers` e `clean-architecture-ddd` só entram se o repositório Java já seguir esse modelo ou o usuário pedir para adotá-lo.

### 3.3 Sem TDD

Implementar a partir da spec:

```text
@rpe-developer.md @.cursor/docs/specs/forgot-password/technical.md

Implemente "esqueci minha senha" conforme a spec técnica.
Sem TDD: não espere testes RED.
Siga a arquitetura descrita no agents.md.
```

Testes depois, contra o código já existente:

```text
@rpe-tester.md @.cursor/docs/specs/forgot-password/technical.md

A implementação já existe.
Escreva testes unitários e de integração que cubram a spec técnica.
Eles devem passar.
```

Falha aqui é desvio entre código e spec. O tester reporta. Quem corrige o código é o `@rpe-developer.md`.

`@ultrawork.md` segue o ciclo TDD. No caminho sem TDD, não use esse command.

### 3.4 Refatorar e verificar

Chat novo. Não continue o chat do RED.

```text
@rpe-developer.md @.cursor/docs/specs/forgot-password/technical.md @src/auth/

Refatore para legibilidade.
Não mude o comportamento externo.
Execute os testes depois de cada alteração.
```

Em seguida, sem agente:

```text
@validate-stack.md
```

### 3.5 Revisar

Plan Mode. O reviewer aplica o checklist de PR, o Definition of Done e, se você pedir, a descrição do PR.

```text
@rpe-reviewer.md @.cursor/docs/specs/forgot-password/feature.md

Revise "esqueci minha senha":
1. Conformidade com a spec
2. Arquitetura do agents.md
3. Testes
4. Segurança (credenciais, PII, validação de input)

Se estiver aprovado, escreva a descrição do PR.
```

---

## 4. Agentes em paralelo

Só quando os módulos não compartilham arquivo. Cada um leva o próprio worktree.

```text
@rpe-architect.md @.cursor/docs/specs/

Acompanhe as specs. Sinalize decisão que contradiga o agents.md.
```

```text
@rpe-developer.md @.cursor/docs/specs/payment-processing/technical.md

Implemente PaymentProcessingUseCase conforme a spec técnica.
Execute os testes depois de cada arquivo. Não altere outros módulos.
```

```text
@rpe-reviewer.md @src/domain/payment/

Revise em tempo real. Reporte problemas sem editar.
```

---

## 5. UltraWork

Uma feature inteira, com o hook reexecutando até 5 vezes se os testes falharem ou se `ALL_TESTS_PASSED: true` não estiver no scratchpad. Exige Bun no PATH e hooks ativos.

```text
@ultrawork.md

Objetivo: implementar notificações por email conforme o plano aprovado.
```

---

## 6. Outras frentes

Chame só o agente e diga o pedido. Ele abre o command.

| Pedido | Agente |
|--------|--------|
| OWASP, segredos, PII em log | `@rpe-security.md` |
| Migração SQL | `@rpe-dba.md` |
| Cenários BDD ou refinamento de história | `@rpe-qa-analyst.md` |
| E2E, contrato, mock ou k6 | `@rpe-sdet.md` |
| Jira ou Confluence | `@rpe-atlassian.md` |
| OpenAPI ou texto de documentação | `@rpe-tech-writer.md` |
| CI/CD, Docker, Kubernetes | `@rpe-infra.md` |

---

## 7. Hooks e MCP

Hooks vêm no `install.sh` e não pedem configuração extra: bloqueio de comando destrutivo, scan de segredo, proteção de `.env` e lockfile, lint ao salvar e o loop do UltraWork. Tabela de eventos: [harness-guide.md §4](./harness-guide.md).

MCP é opcional. O `mcp.json` local é gitignored. Variáveis: `CONTEXT7_API_KEY`, `GITHUB_PERSONAL_ACCESS_TOKEN`, OAuth do Atlassian. Detalhe: [harness-guide.md §5](./harness-guide.md).

---

## Armadilhas

- **Dois `@` de kit no mesmo prompt.** Agente mais command, ou agente mais skill, manda o mesmo texto duas vezes.
- **Spec só no chat ou no scratchpad.** O canônico é `.cursor/docs/specs/<slug>/feature.md` e `technical.md`.
- **Spec desatualizada.** Corrija a spec e regenere. Não contorne com edição manual.
- **No TDD, especificar além do próximo teste RED.**
- **Implementar sem o architect.** Plan Mode e `@rpe-architect.md` vêm antes do código.
- **Diff sem leitura.** Peça explicação do que não estiver óbvio.

---

## Checklist de início

- [ ] `install.sh` executado e `validate.sh` passou
- [ ] Setup único com `@rpe-architect.md` — `agents.md` preenchido a partir do código existente
- [ ] Bun no PATH, se for usar UltraWork
- [ ] Design com `@rpe-architect.md` no Plan Mode
- [ ] `aprovado` ou `aprovado sem tdd` — a spec está em `.cursor/docs/specs/<slug>/`. A lista de tarefas, se houver, foi lida dessa pasta
- [ ] TDD no mesmo chat: `@rpe-test-lead.md`, RED com `@rpe-tester.md`, GREEN com `@rpe-developer.md`. Refactor em chat novo
- [ ] Sem TDD: `@rpe-developer.md` e, em seguida, `@rpe-tester.md`
- [ ] `@validate-stack.md` com exit 0
- [ ] Revisão com `@rpe-reviewer.md`

---

## Documentação relacionada

| Documento | Conteúdo |
|-----------|----------|
| [harness-guide.md](./harness-guide.md) | Catálogo operacional — agentes, commands, hooks, MCP |
| [content-centralization.md](./content-centralization.md) | O que fica em rule, skill e knowledge |
| [agentic-harness.md](./agentic-harness.md) | Fundamentação |
| [agents.md](../agents.md) | Baseline e Definition of Done |
| [.cursor/docs/specs/README.md](../.cursor/docs/specs/README.md) | Convenção das specs |
| [templates/feature-spec.md](../templates/feature-spec.md) | Spec de feature |
| [templates/technical-spec.md](../templates/technical-spec.md) | Spec técnica |
| [templates/definition-of-done.md](../templates/definition-of-done.md) | Fechamento da feature |
