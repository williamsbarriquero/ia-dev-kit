# Operational Policies for Coding Agents

Baseline do **RPE Harness** para este projeto. No Claude Code ele entra no contexto pelo import `@AGENTS.md` do `CLAUDE.md`; outros agentes de IA leem o mesmo arquivo. O primeiro agente com permissão de escrita preenche **Stack do Projeto**, **Arquitetura**, **Restrições** e **Verificação** quando ainda houver `_[PREENCHER]_`.

| Onde | Conteúdo |
|------|----------|
| `.claude/rules/` | Rules globais e contextuais do harness |
| `.claude/agents/rpe-*.md` | Subagents por papel (design, TDD, implementação, revisão) |
| `.claude/skills/` | Workflows `/comando` e skills de conhecimento |
| `.claude/knowledge/stacks/` | SSOT técnico por linguagem (java, go, node, frontend) |
| `docs/specs/<slug>/` | Specs aprovadas, fonte da verdade de cada feature |

---

## Stack do Projeto

Substitua os placeholders após explorar o codebase (`package.json`, `go.mod`, `pom.xml`, `build.gradle`, etc.). As stacks instaladas ficam registradas em `.claude/harness-stacks.json`.

| Item | Valor |
|------|-------|
| **Stack principal** | _[PREENCHER]_ |
| **Runtime / build** | _[PREENCHER]_ |
| **Test runner** | _[PREENCHER]_ |
| **Knowledge SSOT** | `.claude/knowledge/stacks/<stack>.md` |
| **Skill sob demanda** | `java-mastery`, `go-mastery`, `node-mastery` ou `frontend-mastery` (`.claude/skills/<nome>/SKILL.md`) |

---

## Arquitetura

Descreva padrões, camadas e decisões que agentes devem respeitar ao implementar ou revisar código.

_[PREENCHER com a arquitetura deste repositório. Clean Architecture Java (skills clean-architecture e java-test-layers) só se o código já usar domain/application/infrastructure ou se a equipe pedir para adotar.]_

**Artefatos do harness (não duplicar aqui o conteúdo técnico de stack):**

- Rules globais: `.claude/rules/rpe-identity.md`, `stack-baseline.md`, `intent-routing.md`, `safety-guardrails.md`
- Rules contextuais (por `paths`): `java-standards.md`, `go-standards.md`, `node-standards.md`, `typescript.md`, `frontend-standards.md`
- Subagents: `.claude/agents/rpe-*.md`, delegados conforme a fase

---

## Restrições

Limites de negócio, segurança e escopo que agentes não devem violar.

- _[PREENCHER: ex. sem PII em logs, validação de input obrigatória, limites de SLA, módulos fora de escopo]_
- Segredos: nunca hardcodar credenciais. Hooks `rpe-secret-scan.ts` (no `git commit`) e `rpe-guard-write.ts`, e `permissions.deny` para `.env*`
- Shell e MCP: os hooks `rpe-guard-bash.ts` e `rpe-guard-mcp.ts` bloqueiam comandos destrutivos
- Linguagem e runtime: editar `.claude/knowledge/stacks/<stack>.md`
- Clean Architecture Java é opt-in: skills `clean-architecture` e `java-test-layers` só quando o repositório já usa o modelo ou alguém pede para adotá-lo. Não copiar esse mapa para rules como padrão de todo Java

---

## Verificação por Stack

Identifique a stack principal e execute os comandos correspondentes antes de considerar a tarefa concluída.

**Comando consolidado:** `/validate-stack` (orquestra os checks abaixo conforme a rule `stack-baseline`).

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

### RPE Harness

* Harness validation: `bash .claude/rpe/validate.sh`

> Frontend (React/Next.js): SSOT em `.claude/knowledge/stacks/frontend.md`, ativado pela rule `frontend-standards` e pela skill `frontend-mastery`.

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
2. **Links de Arquivos**: Sempre utilize links markdown absolutos ou relativos com o esquema `file:///` para apontar para arquivos e trechos de código (ex: `[AGENTS.md](file:///caminho/para/AGENTS.md)`). Não envolva o texto do link com crase.
3. **Template de Saída (Output Structure)**: Para tarefas complexas, divida sua resposta usando cabeçalhos de nível 2 na seguinte ordem:
   * `## 🔍 Análise`: Diagnóstico do problema e constraints identificados.
   * `## 🛠️ Proposta`: Arquivos que serão lidos, modificados, criados ou deletados.
   * `## 💻 Execução`: Implementação real do código ou saída de comandos.
   * `## ✅ Verificação`: Como a alteração foi validada localmente (testes, linters, etc.).
   * `## 📌 Status e Próximos Passos`: O estado final e ações requeridas do usuário.
