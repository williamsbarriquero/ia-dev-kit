# Definition of Done — [slug-da-feature]

Checklist antes de abrir o PR. Complementa `AGENTS.md` e rule `stack-baseline`.

## Especificação

- [ ] `docs/specs/<slug>/feature.md` existe e está **aprovada**
- [ ] `docs/specs/<slug>/technical.md` reflete os contratos implementados
- [ ] Spec atualizada se houve drift durante a implementação

## Testes

- [ ] Testes RED confirmados antes da implementação
- [ ] Suíte relevante passa (exit 0)
- [ ] Edge cases da spec cobertos

## Qualidade

- [ ] `/validate-stack` passou (lint, format, type-check, testes)
- [ ] `/review-pr` executado (roda no subagent `rpe-reviewer`)
- [ ] Sem segredos hardcoded; input validado onde aplicável

## Entrega

- [ ] PR vinculado ao ticket Jira (se aplicável)
- [ ] Descrição gerada com `/generate-pr-description`
