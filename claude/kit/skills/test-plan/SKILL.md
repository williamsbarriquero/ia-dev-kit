---
name: test-plan
description: "Gera o plano técnico TDD (P0 a P3, ordem, mocks) a partir da spec aprovada."
argument-hint: "[slug da spec]"
disable-model-invocation: true
context: fork
agent: rpe-test-lead
---

# Plano de Testes TDD

Gere um plano técnico de testes para a funcionalidade solicitada.

## Passos

1. Ler plano de implementação ou requisitos fornecidos.
2. Classificar testes por tipo: unitário, integração, E2E.
3. Priorizar por risco (P0-P3) e complexidade.
4. Definir ordem de execução e dependências entre testes.
5. Especificar mocks/stubs necessários.
6. **Não implementar código de teste** — handoff para subagent `rpe-tester` (unit/integration) e subagent `rpe-sdet` (E2E/contratos).

## Regras

- Carregar skill `tdd-workflow` e rule `testing-standards`
- Em Java, classificar na suíte existente. Use `java-test-layers` só se o projeto já seguir Clean Architecture ou o usuário pedir esse modelo
- Diferenciar de `/generate-test-cases` (foco funcional/BDD de negócio)

## Output

Plano estruturado com prioridade, complexidade e critérios de cobertura.
