# Operational Policies for Coding Agents

Esta é a baseline universal para o repositório RPE, compatível com múltiplos agentes de IA (Cursor, Claude Code, GitHub Copilot, Cline, Aider). Todos os agentes atuando neste repositório devem seguir estas diretrizes de forma estrita de acordo com a stack tecnológica identificada.

## Stack-Specific Verification Commands

O agente deve identificar a stack principal do projeto e executar as verificações correspondentes antes de considerar a tarefa concluída:

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

* Harness Validation: `./scripts/validate.sh` (se presente)
* Shell script lint: `shellcheck scripts/*.sh` (se disponível no ambiente)

## Definition of Done (DoD)

Uma tarefa é considerada fisicamente concluída se e somente se todos os checkpoints de verificação aplicáveis à stack do projeto retornarem com código de status zero (0):

1. O código compila sem erros de tipagem/compilação.
2. A suíte de testes do projeto executa com zero falhas.
3. Linter e formatadores rodam com sucesso e não há violações.
4. O estado do Git é validado (se inicializado), e as modificações estão prontas para commit com mensagens convencionais (Conventional Commits) quando o usuário solicitar.

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

## Local Overrides

Para configurações específicas da máquina local (como portas diferentes, flags de teste ou comandos customizados da stack), crie um arquivo `agents.override.md` na raiz do repositório. O arquivo de override será ignorado pelo git.
