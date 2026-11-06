# Desenho da spec

Conduza o desenho da feature. A spec aprovada é a fonte da verdade. A lista de tarefas não existe ainda.

## Passos

1. Ler `agents.md`. Se houver `_[PREENCHER]_`, preencher Stack, Arquitetura, Restrições e Verificação antes do desenho. O usuário não anexa esse arquivo.
2. Analisar requisitos e constraints do usuário.
3. Investigar o codebase (dependências, padrões existentes, pontos de integração).
4. Consultar skills: `hexagonal-architecture`, `design-patterns`, `solid-principles`. Em Java, consultar `clean-architecture`, `java-test-layers` e `clean-architecture-ddd` só se o repositório já usar `domain` / `application` / `infrastructure` ou o usuário pedir esse modelo. Caso contrário, planeje na arquitetura existente.
5. Produzir o rascunho da spec, sem lista de tarefas:
   - Contexto, capacidades, componentes e interações
   - Contratos: interfaces, DTOs, erros
   - Decisões e riscos
   - Slug kebab-case
6. Não gravar arquivo ainda.

## Aprovação

Quando o usuário aprovar (`aprovado`, `pode gravar`, `segue`, `aprovado sem tdd`):

1. Gravar `.cursor/docs/specs/<slug>/feature.md` e `technical.md` a partir de `.cursor/templates/feature-spec.md` e `technical-spec.md`. Status `aprovado`.
2. Parar. Não implementar código. Não gerar lista de tarefas neste passo.
3. Handoff padrão: `@rpe-test-lead.md`. Se a aprovação for `aprovado sem tdd`: `@rpe-developer.md` e, após o código, `@rpe-tester.md`.

## Plano de tarefas

Só depois que a pasta da feature existir, e só se o usuário pedir a ordem de execução. Ler `feature.md` e `technical.md` e derivar tarefas numeradas, dependências e critérios. A lista não altera a spec e não é a fonte dela.

## Output

Seguir `interaction-standards.mdc` com foco em Análise e Proposta.
