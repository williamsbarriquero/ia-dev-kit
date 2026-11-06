# Knowledge Hub — SSOT de Conteúdo por Stack

Este diretório centraliza o **conteúdo técnico** que antes estava duplicado entre rules, skills e commands.

## Camadas (responsabilidade única)

| Camada | Pasta | Papel | Tamanho típico |
|--------|-------|-------|----------------|
| **Knowledge** | `.claude/knowledge/stacks/` | SSOT — padrões, convenções, ecossistema | Completo |
| **Skill** | `.claude/skills/` | `*-mastery` índice; `clean-architecture` e `java-test-layers` são o modelo Java opt-in | Curto a médio |
| **Rule contextual** | `.claude/rules/*-standards.md` (`paths:`) | Globs + ponte para skill/knowledge + verificação | Curto (~25 linhas) |
| **Rule global** | `.claude/rules/*.md` (sem `paths`) | Harness (identidade, segurança, DoD) — **nunca** conteúdo de stack | Médio |
| **Workflow** | `.claude/skills/<comando>/SKILL.md` | Skill `/comando` acionável — referencia rules/skills, não duplica conteúdo | Curto |

## Fluxo de ativação

```text
Arquivo lido ou editado (*.java)
    → rule java-standards (paths)
        → skill java-mastery → knowledge/stacks/java.md
        → clean-architecture e java-test-layers
          só se o repo já usa o modelo ou o usuário pediu
```

## Regras de manutenção

1. **Edite o knowledge** quando mudar linguagem, runtime ou ecossistema da stack.
2. **Edite `clean-architecture` e `java-test-layers`** quando mudar o modelo opt-in. Elas não são o padrão de todo projeto Java.
3. **Não duplique** conteúdo técnico em rules sem `paths` (carregam em toda sessão) — isso polui todas as sessões.
4. Skills `*-mastery` e rules contextuais **apontam** para o knowledge; não copiam parágrafos. As skills de arquitetura e de camadas de teste guardam o modelo operacional.
5. Commands referenciam rule `stack-baseline` para verificação — não repetem tabelas de comandos.

## Stacks disponíveis

- [stacks/java.md](stacks/java.md)
- [stacks/go.md](stacks/go.md)
- [stacks/node.md](stacks/node.md)
- [stacks/frontend.md](stacks/frontend.md)
