---
name: ultrawork
description: "Modo UltraWork: ciclo TDD autônomo com auto-correção até a suíte passar (até 5 iterações)."
argument-hint: "[slug da spec ou objetivo]"
disable-model-invocation: true
---

# Modo UltraWork

Automação total: implementar, testar e auto-corrigir sem interrupção até a suíte passar.

Pedido: $ARGUMENTS

## Pré-requisitos

- **Bun** no PATH. O hook `.claude/hooks/rpe-grind-loop.ts` roda com `bun run`.
- Hook `Stop` do kit registrado em `.claude/settings.json` (o instalador mescla).
- Spec aprovada em `docs/specs/<slug>/`.

## Passos

1. **Spec antes do código**: se `docs/specs/<slug>/feature.md` e `technical.md` não existirem, siga `/plan-architecture` só até gravá-los e pare. Sem spec, não arme o loop.
2. **Armar o loop**: copie `.claude/scratchpad.template.md` para `.rpe/scratchpad.md` e preencha objetivo, `Intent: ultrawork`, `Modo: ultrawork` e o caminho da spec. Sem `Modo: ultrawork` o hook não atua.
3. **RED**: delegue ao subagent `rpe-tester` os testes que falham, a partir de `technical.md`.
4. **GREEN**: delegue ao subagent `rpe-developer` a implementação mínima, passando a lista de testes do RED.
5. **REFACTOR**: nova delegação ao subagent `rpe-developer` com a suíte verde.
6. **Verificação**: rode `/validate-stack` (comandos da rule `stack-baseline` e do `AGENTS.md`).
7. **Registro**: após cada execução de testes, anote no scratchpad comando, exit code e `ALL_TESTS_PASSED: true|false`. Só `true` com exit `0`.
8. **Diagnósticos**: zero erros de compilação nos arquivos alterados (tool `LSP` se disponível; senão type-check ou build da stack).

## Critério de parada (rpe-grind-loop.ts)

O hook `Stop` roda o comando de testes detectado (npm, go, gradle, maven) e só libera o fim do turno com exit `0` **e** `ALL_TESTS_PASSED: true` no scratchpad. Ao liberar, troca `Modo: ultrawork` por `Modo: concluido`. Caso contrário devolve o motivo e o Claude continua.

Limite: 5 continuações seguidas (configurável por `RPE_GRIND_MAX` na chave `env` do settings). A partir da 3ª, revise a abordagem antes de insistir. No limite, o hook desarma o loop e devolve a decisão ao usuário. Para trocar o comando de testes detectado, defina `RPE_TEST_COMMAND`.

## Fluxo autônomo

1. Auto-planejamento a partir da spec.
2. Pesquisa do codebase e das dependências envolvidas.
3. Implementação validando as suposições a cada passo.
4. Auto-verificação: lint, type-check e testes.
5. Auto-correção até tudo passar ou até o limite de iterações.

## Rules e skills

- rule `stack-baseline` (DoD), rule `testing-standards`, rule `safety-guardrails`
- skills `tdd-workflow`, `tdd-grinder`, `session-persistence`, `lsp-integration` (`.claude/skills/<nome>/SKILL.md`)

## Comandos auxiliares

| Skill | Quando usar |
|-------|-------------|
| `/plan-architecture` | A spec ainda não existe |
| `/test-plan` | Ordem e prioridade dos testes P0 |
| `/validate-stack` | Fechamento do DoD |
| `/review-pr` | Revisão final antes do PR |

## Output

Seguir rule `interaction-standards`. Ao encerrar, reportar:

1. Tabela de verificação (comando | exit code | status)
2. Estado final do scratchpad (`ALL_TESTS_PASSED`, fase, blockers)
3. Iterações consumidas do grind-loop
