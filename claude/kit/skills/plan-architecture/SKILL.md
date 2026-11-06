---
name: plan-architecture
description: "Desenha a spec da feature e, após a aprovação, grava docs/specs/<slug>/feature.md e technical.md."
argument-hint: "[descrição da feature]"
disable-model-invocation: true
---

# Desenho da spec

Conduza o desenho da feature no thread principal. A spec aprovada é a fonte da verdade. A lista de tarefas não existe ainda.

Pedido: $ARGUMENTS

## Passos

1. O baseline vem do `AGENTS.md`, importado pelo `CLAUDE.md`. Se houver `_[PREENCHER]_`, preencha Stack, Arquitetura, Restrições e Verificação antes do desenho.
2. Analise requisitos e constraints do pedido. Use `AskUserQuestion` para lacunas que mudam o desenho.
3. Investigue o codebase (dependências, padrões existentes, pontos de integração). Para varredura ampla, delegue ao subagent `Explore`.
4. Leia as skills `hexagonal-architecture`, `design-patterns` e `solid-principles` (`.claude/skills/<nome>/SKILL.md`). Em Java, `clean-architecture`, `java-test-layers` e `clean-architecture-ddd` só se o repositório já usar `domain` / `application` / `infrastructure` ou o usuário pedir esse modelo. Caso contrário, planeje na arquitetura existente.
5. Produza o rascunho da spec, sem lista de tarefas:
   - Contexto, capacidades, componentes e interações
   - Contratos: interfaces, DTOs, erros
   - Decisões e riscos
   - Slug kebab-case
6. Não grave a spec ainda. Em Plan Mode, o rascunho vai no arquivo do plano e o `ExitPlanMode` pede a aprovação.

## Aprovação

A aprovação é a resposta `aprovado`, `pode gravar`, `segue` ou `aprovado sem tdd`, ou a aceitação do plano no `ExitPlanMode`. Então:

1. Grave `docs/specs/<slug>/feature.md` e `technical.md` a partir de `.claude/templates/feature-spec.md` e `technical-spec.md`. Status `aprovado`.
2. Pare. Não implemente código. Não gere lista de tarefas neste passo.
3. Handoff padrão: `/test-plan` (subagent `rpe-test-lead`). Se a aprovação for `aprovado sem tdd`: subagent `rpe-developer` e, após o código, subagent `rpe-tester`.

## Plano de tarefas

Só depois que a pasta da feature existir, e só se o usuário pedir a ordem de execução. Leia `feature.md` e `technical.md` e derive tarefas numeradas, dependências e critérios. A lista não altera a spec e não é a fonte dela.

## Output

Seguir rule `interaction-standards` com foco em Análise e Proposta.
