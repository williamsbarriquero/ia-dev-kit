# Especificações de features

Diretório **SSOT** para specs versionadas no Git. Criado pelo `install.sh`.

## Convenção de arquivos

Por feature, uma pasta com dois arquivos:

```text
.cursor/docs/specs/<slug>/
├── feature.md      ← comportamentos, componentes, critérios de aceite (níveis 1–3)
└── technical.md    ← interfaces, DTOs, schemas, contratos (nível 4)
```

**Exemplo:** `.cursor/docs/specs/forgot-password/feature.md` e `technical.md`.

## Templates

Copiados para `.cursor/templates/` na instalação:

- `feature-spec.md`
- `technical-spec.md`

## Fluxo resumido

1. Desenho — `@rpe-architect.md`. Rascunho no chat, sem lista de tarefas.
2. Aprovação da spec — `aprovado` grava `feature.md` e `technical.md`.
3. Plano de tarefas — só se pedido, lido da pasta da feature. Não é a fonte da spec.
4. TDD — `@rpe-test-lead.md` → `@rpe-tester.md` (RED) → `@rpe-developer.md`, no mesmo chat.
   Sem TDD — `@rpe-developer.md` conforme `technical.md` → `@rpe-tester.md` (testes que passam).
5. Revisão — `@rpe-reviewer.md` + `@.cursor/docs/specs/<slug>/feature.md`.

**Regra:** testes e código seguem a spec. Se o código divergir, atualize a spec primeiro e regenere.

Publicação opcional no Confluence: `@rpe-atlassian.md` (espelho para o time).
