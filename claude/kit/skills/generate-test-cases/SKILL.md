---
name: generate-test-cases
description: "Gera cenários BDD/Gherkin, casos de valor limite e checklist não funcional."
argument-hint: "[arquivo ou funcionalidade]"
disable-model-invocation: true
context: fork
agent: rpe-qa-analyst
---

# Geração de Casos de Teste (QA)

Execute as seguintes ações para gerar cenários e casos de teste a partir do arquivo ou trecho de código selecionado:

1. Identifique as principais regras de negócio e fluxos de usuário.
2. Crie cenários em BDD/Gherkin (Dado, Quando, Então) cobrindo o caminho feliz e fluxos alternativos.
3. Proponha casos de teste de limites e valores extremos (Equivalence Partitioning & Boundary Value Analysis).
4. Produza um checklist detalhado de testes não-funcionais aplicáveis (acessibilidade, segurança e performance).
