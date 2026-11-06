---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
---

# Padrões de Teste RPE

## Contexto

Ativado ao editar ou criar arquivos de teste.

## Instruções

- **Estrutura AAA**: Padrão Arrange, Act, Assert obrigatório.
- **Nomenclatura**: Títulos descritivos e comportamentais. Ex: `it('should return 404 when user not found')`. Em Java, o padrão de nome que o projeto já usa. `givenX_whenY_shouldZ` e as bases de `java-test-layers` só no modelo Clean Architecture.
- **Mocking Strategy**: Faça mock das integrações e dependências externas, nunca faça mock interno (teste o comportamento, não a implementação).
- **Cobertura**: O mínimo exigido é de 80% de code coverage para novas funcionalidades.

## Verificação (Command-First)

Definition of Done:

1. Comando de testes da stack (ver `AGENTS.md`) finaliza com exit code `0`.
2. `npx eslint . --fix` (Node/TS) ou equivalente da stack finaliza com exit code `0`.
3. Nenhuma regressão de snapshot.
