# [FEATURE-XXX] Título da feature (documento consolidado — opcional)

> **Preferência do harness:** use o modelo em **dois arquivos** em `.cursor/docs/specs/`:
> - `<slug>.md` — [feature-spec.md](./feature-spec.md) (níveis 1–3)
> - `<slug>-technical.md` — [technical-spec.md](./technical-spec.md) (nível 4)
>
> Este template serve apenas se o time quiser um único documento ou espelho no Confluence.

| Campo | Valor |
|-------|-------|
| **Ticket Jira** | FEATURE-XXX |
| **Autor** | |
| **Status** | rascunho \| em revisão \| aprovado \| implementado |
| **Última atualização** | YYYY-MM-DD |

---

## 1. Contexto e objetivo

- Problema de negócio:
- Objetivo da entrega:
- Fora de escopo:

## 2. Capacidades (nível 1 — comportamento)

Liste comportamentos do ponto de vista do usuário/sistema, em linguagem natural.

1.
2.

## 3. Componentes e impacto (nível 2–3)

| Módulo / camada | Ação (criar / alterar / remover) | Notas |
|-----------------|----------------------------------|-------|
| | | |

### Fluxo principal

```text
[ator] → [componente A] → [componente B] → [resultado]
```

## 4. Contratos (nível 4)

### APIs / eventos

| Método / tópico | Entrada | Saída | Erros |
|-----------------|---------|-------|-------|
| | | | |

### Modelos / DTOs

```text
// Esboço de tipos, schemas ou tabelas — detalhar na implementação
```

## 5. Critérios de aceite (BDD)

```gherkin
Cenário: caminho feliz
  Dado ...
  Quando ...
  Então ...

Cenário: exceção relevante
  Dado ...
  Quando ...
  Então ...
```

## 6. Plano TDD (handoff para @test-plan.md)

| Prioridade | Teste | Tipo | Arquivo previsto |
|------------|-------|------|------------------|
| P0 | | unitário / integração / E2E | |

## 7. Riscos e decisões

| Decisão | Alternativas consideradas | Motivo |
|---------|---------------------------|--------|
| | | |

## 8. Verificação e DoD

- [ ] Spec aprovada (Três Amigos ou equivalente)
- [ ] Testes RED escritos conforme plano
- [ ] Implementação GREEN
- [ ] `@validate-stack.md` com exit 0
- [ ] `@review-pr.md` executado
- [ ] Spec atualizada se houver drift arquitetural

---

## Histórico de alterações

| Data | Autor | Alteração |
|------|-------|-----------|
| | | Versão inicial |
