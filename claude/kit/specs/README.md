# Especificações de features

Diretório **SSOT** para specs versionadas no Git. Criado pelo instalador do RPE Harness para Claude Code.

## Convenção de arquivos

Por feature, uma pasta com dois arquivos:

```text
docs/specs/<slug>/
├── feature.md      ← comportamentos, componentes, critérios de aceite (níveis 1–3)
└── technical.md    ← interfaces, DTOs, schemas, contratos (nível 4)
```

**Exemplo:** `docs/specs/forgot-password/feature.md` e `technical.md`.

## Templates

Instalados em `.claude/templates/`:

- `feature-spec.md`
- `technical-spec.md`
- `definition-of-done.md`

## Fluxo resumido

1. **Desenho** — `/plan-architecture <feature>`, de preferência em Plan Mode. Rascunho sem lista de tarefas.
2. **Aprovação da spec** — `aprovado` (ou aceitar o plano no `ExitPlanMode`) grava `feature.md` e `technical.md`.
3. **Plano de tarefas** — só se pedido, lido da pasta da feature. Não é a fonte da spec.
4. **TDD** — `/test-plan` (subagent `rpe-test-lead`) → subagent `rpe-tester` (RED) → subagent `rpe-developer` (GREEN e REFACTOR). Ou `/ultrawork <slug>` para o ciclo autônomo.
   **Sem TDD** — subagent `rpe-developer` conforme `technical.md` → subagent `rpe-tester` (testes que passam).
5. **Verificação** — `/validate-stack`.
6. **Revisão** — `/review-pr` (subagent `rpe-reviewer`), com a spec como referência.

**Regra:** testes e código seguem a spec. Se o código divergir, atualize a spec primeiro e regenere.

Publicação opcional no Confluence: subagent `rpe-atlassian` (espelho para o time).
