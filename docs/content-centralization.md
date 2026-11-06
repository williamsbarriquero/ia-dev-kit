# Centralização de Conteúdo — Rules, Skills e Commands

Este documento define como evitar duplicação entre `.cursor/rules/`, `.cursor/skills/` e `.cursor/commands/`.

## Problema

Artefatos com papéis diferentes acabavam carregando o **mesmo conteúdo técnico**:

| Antes (Java) | Linhas | Problema |
|--------------|--------|----------|
| `java-spring-cursor-rules.mdc` | ~94 | `alwaysApply: true` — injetava Spring em **toda** sessão |
| `java-standards.mdc` | ~25 | Repetia trechos da skill |
| `java-mastery/SKILL.md` | ~35 | Repetia Spring + JVM |

O mesmo padrão aparecia em Go/Node e, no frontend, em **4 rules** sobrepostas.

## Solução: hub de knowledge + camadas finas

```text
.cursor/knowledge/stacks/<stack>.md   ← SSOT (editar aqui)
        ↑
.cursor/skills/<stack>-mastery/       ← índice: quando usar + ponte
        ↑
.cursor/rules/<stack>-standards.mdc   ← glob + ponte + verificação
        ↑
.cursor/commands/*.md                 ← workflow; referencia stack-baseline
```

### O que cada camada faz

1. **Knowledge** (`.cursor/knowledge/stacks/`) — todo o conteúdo técnico da stack.
2. **Skill** — ativação sob demanda; instrui o agente a ler o knowledge.
3. **Rule contextual** — ativação automática por glob; não repete parágrafos.
4. **Rule global** — apenas harness (identidade, segurança, DoD). **Nunca** conteúdo de linguagem.
5. **Command** — passos de workflow; verificação aponta para `stack-baseline.mdc`.

## Checklist ao adicionar conteúdo

- [ ] É linguagem, runtime ou ecossistema de uma stack? → `knowledge/stacks/<stack>.md`
- [ ] É o modelo opt-in de Clean Architecture, o DDD tático ou a suíte desse modelo? → skills `clean-architecture`, `clean-architecture-ddd` e `java-test-layers` (não viram padrão de todo Java)
- [ ] Precisa ativar ao abrir arquivos? → rule contextual fina com `globs`
- [ ] Precisa ativar sob demanda / por agente? → skill fina com ponte ao knowledge
- [ ] É um fluxo repetível (validar, revisar PR)? → command que referencia, não duplica
- [ ] É universal (segurança, tom, DoD)? → rule `alwaysApply: true` em harness core

## Stacks consolidadas

| Stack | SSOT | Skill | Rule |
|-------|------|-------|------|
| Java (linguagem) | `knowledge/stacks/java.md` | `java-mastery` | `java-standards.mdc` |
| Java Clean Architecture (opt-in) | skill `clean-architecture` | `clean-architecture` | `java-standards.mdc` (só se o repo já usa ou o usuário pede) |
| Java DDD tático (opt-in) | skill `clean-architecture-ddd` | `clean-architecture-ddd` | `java-standards.mdc` (mesma condição) |
| Java testes desse modelo (opt-in) | skill `java-test-layers` | `java-test-layers` | `java-standards.mdc` (mesma condição) |

Skills de arquitetura (`hexagonal-architecture`, `clean-architecture`, `clean-architecture-ddd`, `java-test-layers`) guardam o próprio conteúdo. Não fundir em `knowledge/stacks/java.md`. O layout em camadas Spring fica nesse arquivo; Clean Architecture e DDD só entram quando o projeto usa os três módulos ou o usuário pede o modelo.
| Go | `knowledge/stacks/go.md` | `go-mastery` | `go-standards.mdc` |
| Node | `knowledge/stacks/node.md` | `node-mastery` | `node-standards.mdc` |
| Frontend | `knowledge/stacks/frontend.md` | `frontend-mastery` | `frontend-standards.mdc` + `typescript.mdc` (ponte) |

**Removidos:** `java-spring-cursor-rules.mdc`; `react-cursor-rules.mdc`, `front-end-cursor-rules.mdc`, `ultimate-frontend-development-guide.mdc` (conteúdo fundido em `frontend.md`).

## Fase 2 — Verificação (já centralizada)

`stack-baseline.mdc` + `AGENTS.md` são o SSOT de comandos de verificação. `@validate-stack.md` apenas orquestra — não duplica tabelas.

## Manutenção

Ao alterar um padrão Java:

1. Linguagem, Spring ou JVM: edite `.cursor/knowledge/stacks/java.md`
2. Modelo opt-in de módulos, use case e gateway: edite a skill `clean-architecture`
3. DDD tático (agregados, gateways, Notification/Either): edite a skill `clean-architecture-ddd`
4. Tags e bases desse modelo: edite a skill `java-test-layers`
5. Não copie esse mapa para rules globais nem o imponha em `java.md` como arquitetura única
