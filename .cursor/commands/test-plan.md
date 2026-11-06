# Plano de Testes TDD

Gere um plano técnico de testes para a funcionalidade solicitada.

## Passos

1. Ler plano de implementação ou requisitos fornecidos.
2. Classificar testes por tipo: unitário, integração, E2E.
3. Priorizar por risco (P0-P3) e complexidade.
4. Definir ordem de execução e dependências entre testes.
5. Especificar mocks/stubs necessários.
6. **Não implementar código de teste** — handoff para `@rpe-tester.md` (unit/integration) e `@rpe-sdet.md` (E2E/contratos).

## Regras

- Carregar `tdd-workflow.mdc` e `testing-standards.mdc`
- Em Java, classificar na suíte existente. Use `java-test-layers` só se o projeto já seguir Clean Architecture ou o usuário pedir esse modelo
- Diferenciar de `@generate-test-cases.md` (foco funcional/BDD de negócio)

## Output

Plano estruturado com prioridade, complexidade e critérios de cobertura.
