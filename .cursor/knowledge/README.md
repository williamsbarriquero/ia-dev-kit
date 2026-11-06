# Knowledge Hub — SSOT de Conteúdo por Stack

Este diretório centraliza o **conteúdo técnico** que antes estava duplicado entre rules, skills e commands.

## Camadas (responsabilidade única)

| Camada | Pasta | Papel | Tamanho típico |
|--------|-------|-------|----------------|
| **Knowledge** | `.cursor/knowledge/stacks/` | SSOT — padrões, convenções, ecossistema | Completo |
| **Skill** | `.cursor/skills/` | `*-mastery` índice; `clean-architecture` e `java-test-layers` são o modelo Java opt-in | Curto a médio |
| **Rule contextual** | `.cursor/rules/*-standards.mdc` | Globs + ponte para skill/knowledge + verificação | Curto (~25 linhas) |
| **Rule global** | `.cursor/rules/*.mdc` | Harness (identidade, segurança, DoD) — **nunca** conteúdo de stack | Médio |
| **Command** | `.cursor/commands/*.md` | Workflow acionável — referencia rules/skills, não duplica conteúdo | Curto |

## Fluxo de ativação

```text
Arquivo aberto (*.java)
    → java-standards.mdc (glob)
        → skill java-mastery → knowledge/stacks/java.md
        → clean-architecture e java-test-layers
          só se o repo já usa o modelo ou o usuário pediu
```

## Regras de manutenção

1. **Edite o knowledge** quando mudar linguagem, runtime ou ecossistema da stack.
2. **Edite `clean-architecture` e `java-test-layers`** quando mudar o modelo opt-in. Elas não são o padrão de todo projeto Java.
3. **Não duplique** conteúdo técnico em rules `alwaysApply: true` — isso polui todas as sessões.
4. Skills `*-mastery` e rules contextuais **apontam** para o knowledge; não copiam parágrafos. As skills de arquitetura e de camadas de teste guardam o modelo operacional.
5. Commands referenciam `stack-baseline.mdc` para verificação — não repetem tabelas de comandos.

## Stacks disponíveis

- [stacks/java.md](stacks/java.md)
- [stacks/go.md](stacks/go.md)
- [stacks/node.md](stacks/node.md)
- [stacks/frontend.md](stacks/frontend.md)
