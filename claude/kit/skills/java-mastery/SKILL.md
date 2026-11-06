---
name: java-mastery
description: >-
  Práticas modernas de engenharia Java e Spring Boot. Use ao implementar ou
  revisar código Java. SSOT de linguagem em knowledge/stacks/java.md. Clean
  Architecture é opt-in, pela skill clean-architecture.
disable-model-invocation: true
---

# Java Mastery

## Quando usar

- Implementação ou revisão de código `.java`
- Acionada por rule `java-standards`, subagent `rpe-developer` ou intent `infra` / `deep`

## Leitura obrigatória

`.claude/knowledge/stacks/java.md` — linguagem, Spring, verificação.

Siga a arquitetura e a suíte de testes que o repositório já usa.

## Clean Architecture (opt-in)

Leia as skills `clean-architecture` e `java-test-layers` somente se o projeto já tem os módulos `domain`, `application` e `infrastructure` (ou use case + gateway nesse formato), ou se o usuário pediu para adotar esse modelo.

## Verificação

Conforme rule `stack-baseline` → seção Java. Rode a task de teste que o build do projeto já define.
