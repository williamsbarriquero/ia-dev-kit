# Roteamento por Intenção (IntentGate)

## Contexto

Define como classificar e rotear tarefas antes da execução. Os papéis RPE são subagents em `.claude/agents/` e os workflows são skills `/nome` em `.claude/skills/`.

## Instruções

Antes de iniciar qualquer tarefa, classifique internamente a intenção e siga o fluxo correspondente:

- **`quick`**: correções rápidas e refatorações pontuais. Resposta direta e implementação no thread principal.
- **`deep`**: implementação complexa ou novo módulo. Spec primeiro, com `/plan-architecture` (de preferência em Plan Mode). Depois TDD, salvo se o usuário pedir implementação direta: aí subagent `rpe-developer` e só depois subagent `rpe-tester`. Em Java, leia `.claude/skills/java-mastery/SKILL.md`. Leia `clean-architecture`, `java-test-layers` e `clean-architecture-ddd` só se o repositório já usar esse modelo ou o usuário pedir para adotá-lo.
- **`analysis`**: investigação de código e debugging. Use leitura, busca e a tool `LSP` (quando disponível) extensivamente antes de intervir.
- **`review`**: revisão de PR ou código. `/review-pr`, que roda no subagent `rpe-reviewer`. Skill `code-review` e rule `safety-guardrails`.
- **`test`**: criação ou execução de testes. Fluxo TDD: `/test-plan` (subagent `rpe-test-lead`) → subagent `rpe-tester`. Skills `tdd-workflow` e `tdd-grinder`, rule `testing-standards`. Em Java, `java-test-layers` só se o repositório já seguir Clean Architecture ou o usuário pedir esse modelo. Nos demais, use a suíte existente.
- **`infra`**: infra, CI/CD, Docker. Subagent `rpe-infra` e a skill da stack (`node-mastery`, `go-mastery`, `java-mastery`).
- **`ultrawork`**: prefixo `ultrawork:`, palavra `ultrawork`, `/ultrawork` ou pedido explícito. Siga a skill `/ultrawork`. O hook `rpe-grind-loop.ts` força até 5 iterações de auto-correção.

## Delegação

- Desenho e aprovação de spec ficam no thread principal: precisam de diálogo com o usuário, e um subagent não conversa, só devolve o resultado.
- Execução (testes, implementação, revisão, auditoria) vai para o subagent do papel. Cada delegação começa com contexto limpo: passe no prompt o slug da spec e o que o subagent precisa saber.
- Subagents de implementação não delegam a outros (`disallowedTools: Agent`).

## Validação de Compilação

Antes de finalizar alteração de código (em especial `quick`, `deep` e `ultrawork`), confirme zero erros de tipagem, import e compilação nos arquivos alterados. Use os diagnósticos da tool `LSP` quando houver plugin de code intelligence. Sem ele, rode o type-check ou build da stack (rule `stack-baseline`).
