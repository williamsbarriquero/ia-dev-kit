---
name: validate-stack
description: "Roda lint, format, type-check e testes da stack e reporta exit codes (Definition of Done)."
disable-model-invocation: true
---

# Validação da Stack

Execute os passos a seguir para validar a saúde da stack e reportar status consolidado.

## Passos

1. Identificar a stack principal do projeto (Node/TS, Go, Java ou Harness).
2. Executar comandos conforme rule `stack-baseline` e `AGENTS.md`:

| Stack | Lint | Type-check | Testes |
|-------|------|------------|--------|
| Node/TS | `npx eslint . --fix` | `npx tsc --noEmit` | `npm test` |
| Go | `golangci-lint run --fix` | — | `go test ./...` |
| Java | `./gradlew spotlessApply` | — | `./gradlew test` |
| Harness | `shellcheck scripts/*.sh` (se houver) | — | `bash .claude/rpe/validate.sh` |

3. Reportar status consolidado por comando (✅ exit 0 / ❌ exit ≠ 0).
4. Se algum check falhar, listar erros e sugerir correções.

## Output

Tabela com comando, exit code e status final.
