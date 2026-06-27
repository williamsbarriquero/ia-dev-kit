# Operational Policies for Coding Agents

Baseline universal do **RPE Harness**, compatível com múltiplos agentes de IA (Cursor, Claude Code, GitHub Copilot, Cline, Aider). Copiado pelo `install.sh` para projetos alvo — personalize **Stack do Projeto**, **Arquitetura** e **Restrições** após a instalação (ver [confluence-how-to-guide.md](docs/confluence-how-to-guide.md) §1.4).

| Documento | Conteúdo |
|-----------|----------|
| [harness-guide.md](docs/harness-guide.md) | SSOT operacional — agentes, commands, hooks, MCP |
| [content-centralization.md](docs/content-centralization.md) | Modelo rules → skills → knowledge |
| `.cursor/knowledge/stacks/` | SSOT técnico por linguagem (java, go, node) |

---

## Stack do Projeto

Substitua os placeholders após explorar o codebase (`package.json`, `go.mod`, `pom.xml`, `build.gradle`, etc.). As stacks instaladas pelo `install.sh` ficam registradas em `.cursor/harness-stacks.json`.

| Item | Valor |
|------|-------|
| **Stack principal** | _[PREENCHER]_ |
| **Runtime / build** | _[PREENCHER]_ |
| **Test runner** | _[PREENCHER]_ |
| **Knowledge SSOT** | `.cursor/knowledge/stacks/<stack>.md` |
| **Skill sob demanda** | `@java-mastery`, `@go-mastery` ou `@node-mastery` |

**Referência — repositório ia-dev-kit (kit do harness):**

| Item | Valor |
|------|-------|
| **Stack principal** | RPE Harness (Shell + TypeScript hooks) |
| **Runtime / build** | Bash (`scripts/`), Bun (`grind-loop.ts`) |
| **Test runner** | `./scripts/validate.sh` |
| **Knowledge SSOT** | `.cursor/knowledge/stacks/{java,go,node}.md` |

---

## Arquitetura

Descreva padrões, camadas e decisões que agentes devem respeitar ao implementar ou revisar código.

_[PREENCHER: ex. hexagonal — domain → ports → use case → adapters; monólito modular; REST + eventos; etc.]_

**Artefatos do harness (não duplicar aqui o conteúdo técnico de stack):**

- Regras globais: `.cursor/rules/rpe-identity.mdc`, `stack-baseline.mdc`, `intent-routing.mdc`, `safety-guardrails.mdc`
- Regras contextuais (por glob): `java-standards.mdc`, `go-standards.mdc`, `node-standards.mdc`, `tdd-workflow.mdc`
- Agentes: `.cursor/agents/rpe-*.md` — invocar com `@` conforme a fase (design, TDD, implementação, revisão)

**Referência — ia-dev-kit:** kit distribuível (`rules`, `agents`, `commands`, `skills`, `knowledge`, `hooks`). Alterações devem preservar compatibilidade com `install.sh`, `update.sh` e `validate.sh`.

---

## Restrições

Limites de negócio, segurança e escopo que agentes não devem violar.

- _[PREENCHER: ex. sem PII em logs, validação de input obrigatória, limites de SLA, módulos fora de escopo]_
- Segredos: nunca hardcodar credenciais; hooks `secret-scanner.sh` e `write-file-guard.sh`
- Shell/MCP: guards em `.cursor/hooks/guards/` bloqueiam comandos destrutivos
- Conteúdo de stack: editar **somente** `.cursor/knowledge/stacks/<stack>.md` — não duplicar em rules/skills

**Referência — ia-dev-kit:** não sobrescrever `mcp.json` existente no install; validar com `./scripts/validate.sh` antes de concluir; UltraWork requer Bun (`grind-loop.ts`).

---

## Verificação por Stack

Identifique a stack principal e execute os comandos correspondentes antes de considerar a tarefa concluída.

**Comando consolidado no Cursor:** `@validate-stack.md` (orquestra os checks abaixo conforme `stack-baseline.mdc`).

### Node.js / TypeScript

* Linter validation: `npx eslint . --fix`
* Formatting validation: `npx prettier --write .`
* Type checking: `npx tsc --noEmit`
* Test suite: `npm test`

### Go

* Linter validation: `golangci-lint run --fix`
* Formatting validation: `gofmt -w .`
* Test suite: `go test ./...`

### Java

* Build & Quality: `./gradlew spotlessApply` ou `./mvnw spotless:apply`
* Test suite: `./gradlew test` ou `./mvnw test`

### RPE Harness / Shell Scripts

* Harness validation: `./scripts/validate.sh`
* Shell script lint: `shellcheck scripts/*.sh` (se disponível no ambiente)

> Frontend (React/Next.js): SSOT em `.cursor/knowledge/stacks/frontend.md`, ativado por `frontend-standards.mdc` e skill `frontend-mastery`. Ver [content-centralization.md](docs/content-centralization.md).

---

## Definition of Done (DoD)

Uma tarefa é considerada fisicamente concluída se e somente se todos os checkpoints de verificação aplicáveis à stack do projeto retornarem com código de status zero (0):

1. O código compila sem erros de tipagem/compilação.
2. A suíte de testes do projeto executa com zero falhas.
3. Linter e formatadores rodam com sucesso e não há violações.
4. O estado do Git é validado (se inicializado), e as modificações estão prontas para commit com mensagens convencionais (Conventional Commits) quando o usuário solicitar.

---

## Communication and Response Policy

Para garantir clareza, rastreabilidade e evitar poluição visual, todo agente deve responder ao usuário seguindo estritamente as diretrizes abaixo:

1. **Tom de Voz**: Profissional, técnico, direto e em Português (BR). Evite introduções e conclusões prolixas ou clichês (ex: *"Certamente, posso ajudar..."* ou *"Espero ter ajudado!"*).
2. **Links de Arquivos**: Sempre utilize links markdown absolutos ou relativos com o esquema `file:///` para apontar para arquivos e trechos de código (ex: `[agents.md](file:///caminho/para/agents.md)`). Não envolva o texto do link com crase.
3. **Template de Saída (Output Structure)**: Para tarefas complexas, divida sua resposta usando cabeçalhos de nível 2 na seguinte ordem:
   * `## 🔍 Análise`: Diagnóstico do problema e constraints identificados.
   * `## 🛠️ Proposta`: Arquivos que serão lidos, modificados, criados ou deletados.
   * `## 💻 Execução`: Implementação real do código ou saída de comandos.
   * `## ✅ Verificação`: Como a alteração foi validada localmente (testes, linters, etc.).
   * `## 📌 Status e Próximos Passos`: O estado final e ações requeridas do usuário.
