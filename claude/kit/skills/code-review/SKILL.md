---
name: code-review
description: "Checklist e formato de relatório de code review RPE (segurança, performance, legibilidade, testes, arquitetura). Use ao revisar PR, diff ou código."
---

# Fluxo Code Review RPE

## Contexto

Ativado quando solicitada uma análise estruturada ou revisão de PR.

## Instruções

- **Checklist estruturada de revisão**:
  - [ ] **Segurança**: Credenciais em código, vulnerabilidades de injection, XSS. Aplicar também rule `safety-guardrails`; para deep dive AppSec, escalar ao subagent `rpe-security`.
  - [ ] **Performance**: Problemas de N+1, loops ineficientes, memory leaks.
  - [ ] **Legibilidade**: Nomeação adequada de variáveis, complexidade ciclomática reduzida.
  - [ ] **Testes**: Cobertura adequada e cenários (edge cases) validados conforme rule `testing-standards` e rule `qa-standards`.
  - [ ] **Arquitetura**: Separação adequada de responsabilidades (concerns), gestão correta de dependências.

- **Formato do relatório final**:
  - Status: Aprovado ✅ / Alterações Necessárias ⚠️ / Rejeitado ❌
  - Classifique os itens apontados pela sua severidade: Critical / Major / Minor / Suggestion.
