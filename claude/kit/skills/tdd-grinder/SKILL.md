---
name: tdd-grinder
description: "Orquestrador de ciclo TDD com verificação automática de testes e integração com grind-loop."
disable-model-invocation: true
---

# TDD Grinder

Orquestra o ciclo Red-Green-Refactor com persistência em `.rpe/scratchpad.md` e validação pelo hook `rpe-grind-loop.ts`.

## Ciclo Obrigatório

1. **RED**: Escrever teste que falha para o comportamento desejado.
2. **GREEN**: Implementar código mínimo para o teste passar.
3. **REFACTOR**: Melhorar código mantendo testes verdes.
4. **VERIFY**: Executar comando de testes da stack (ver `AGENTS.md` ou rule `stack-baseline`).
5. **RECORD**: Atualizar scratchpad com exit code e `ALL_TESTS_PASSED: true|false`.

## Scratchpad

Use `.rpe/scratchpad.md` (template: `.claude/scratchpad.template.md`). Campos obrigatórios:

```markdown
## Testes
- **Comando executado**: npm test
- **Exit code**: 0
- **ALL_TESTS_PASSED**: true
```

Só marque `ALL_TESTS_PASSED: true` após exit code `0` do comando de testes.

## Integração grind-loop

O hook `.claude/hooks/rpe-grind-loop.ts` roda no evento `Stop`, só quando o scratchpad tem `Modo: ultrawork` (ver `/ultrawork`). Ele:

- Roda o comando de testes detectado (npm, go, gradle, maven) e lê `ALL_TESTS_PASSED` no scratchpad
- Libera o fim do turno só com exit `0` **e** `ALL_TESTS_PASSED: true`; ao liberar, troca o modo para `concluido`
- Caso contrário devolve o motivo e a saída dos testes, e o Claude continua, até 5 continuações seguidas
- A partir da 3ª iteração pede revisão da abordagem; no limite, libera e pede escalada ao usuário

## Comandos por Stack

| Stack | Teste | Lint | Type-check |
|-------|-------|------|------------|
| Node/TS | `npm test` | `npx eslint . --fix` | `npx tsc --noEmit` |
| Go | `go test ./...` | `golangci-lint run --fix` | — |
| Java | `./gradlew test` ou `./mvnw test` | `./gradlew spotlessApply` | — |

Se o build Java já define `unitTests`, `integrationTests` e `e2eTests`, rode a task da camada alterada. A organização da skill `java-test-layers` só vale quando `clean-architecture` se aplica.

## Agentes Relacionados

- subagent `rpe-test-lead` — plano de testes (não implementa)
- subagent `rpe-tester` — implementa e executa testes unitários/integração
- subagent `rpe-developer` — testes mínimos de produção junto ao código
