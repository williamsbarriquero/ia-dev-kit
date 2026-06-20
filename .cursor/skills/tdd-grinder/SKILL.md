---
name: tdd-grinder
description: "Orquestrador de ciclo TDD com verificação automática de testes."
disable-model-invocation: false
---

# TDD Grinder

Orquestra o ciclo Red-Green-Refactor com verificação automática e integração com hooks de continuação.

## Propósito

Garantir que implementações sigam TDD estrito: teste falhando primeiro, implementação mínima, refatoração com suite verde.

## Fluxo de Execução

1. Ler o plano de testes do agente `rpe-test-lead`.
2. Escrever ou atualizar testes que falham (Red).
3. Implementar código mínimo para passar (Green).
4. Refatorar mantendo suite verde (Refactor).
5. Executar lint, type-check e testes da stack do projeto.
6. Registrar estado no scratchpad: `ALL_TESTS_PASSED: true` ou `ALL_TESTS_PASSED: false`.

## Integração com Hooks

- Hook de continuação `grind-loop.ts` (Cursor) ou equivalente `Stop` em outros editores.
- Se testes falharem, o hook força nova iteração de correção (até 5 ciclos no modo UltraWork).

## Regras

- Nunca declarar conclusão com testes falhando.
- Cobertura mínima conforme `testing-standards.mdc`.
- Anotar progresso e blockers no scratchpad do projeto.
