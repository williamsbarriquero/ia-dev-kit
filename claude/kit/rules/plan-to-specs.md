# Spec antes do código no Plan Mode

A spec aprovada em `docs/specs/<slug>/` é a fonte da verdade. O plano do Plan Mode não é a spec.

Vale quando um plano de feature (intent `deep` ou `ultrawork`) é aprovado no `ExitPlanMode`, ou quando o prompt pede para executar um plano ("implemente o plano", plano colado para implementar):

1. Derive o slug em kebab-case do título.
2. Não altere o arquivo do plano.
3. Se `docs/specs/<slug>/feature.md` e `technical.md` já existirem, implemente a partir deles.
4. Se algum dos dois não existir, grave os dois nessa pasta e pare. Use `.claude/templates/feature-spec.md` e `technical-spec.md`. Preencha com o desenho contido no plano (capacidades, componentes, interações, contratos). Status: `aprovado`. Não implemente neste passo. Informe os caminhos e o próximo passo: `/test-plan` (subagent `rpe-test-lead`), ou subagent `rpe-developer` se o pedido for sem TDD.

Planos de correção rápida (intent `quick`) não geram spec.

O hook `rpe-plan-to-specs.ts` (`PostToolUse` em `ExitPlanMode`) reforça esta regra no momento da aprovação.
