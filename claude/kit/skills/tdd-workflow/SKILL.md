---
name: tdd-workflow
description: "Fluxo TDD RPE (RED, GREEN, REFACTOR) com subagents e scratchpad. Use ao implementar com testes primeiro ou quando o pedido citar TDD."
---

# Workflow TDD RPE

## Contexto

Fluxo para implementação orientada a testes a partir da spec aprovada em `docs/specs/<slug>/`.

## Instruções

- **Java**: se o projeto já segue Clean Architecture ou o usuário pediu esse modelo, use a ordem da skill `java-test-layers`. Nos demais, o ciclo abaixo na suíte que o repositório já tem.
- **Ciclo Red-Green-Refactor com subagents**:
  1. **RED**: o subagent `rpe-tester` escreve os testes que falham a partir de `technical.md` (ou do plano do `rpe-test-lead`) e devolve a lista de testes e o comando.
  2. **GREEN**: o subagent `rpe-developer` recebe essa lista e implementa o mínimo para a suíte passar, sem editar os testes.
  3. **REFACTOR**: nova delegação ao subagent `rpe-developer`, com contexto limpo. A suíte verde em disco é a memória; o histórico anterior não é contexto.
- **Integração grind-loop**: anotar `ALL_TESTS_PASSED: true|false` em `.rpe/scratchpad.md` ao concluir as execuções.
- **Closure**: a tarefa só está completa quando o comando de testes da stack (ver `AGENTS.md` ou rule `stack-baseline`) retornar exit code `0`.
- **Scratchpad**: `.rpe/scratchpad.md` (template em `.claude/scratchpad.template.md`) persiste o estado entre iterações e delegações.
