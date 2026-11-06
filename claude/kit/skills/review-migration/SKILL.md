---
name: review-migration
description: "Revisa migração de banco contra o checklist RPE (rollback, expand-and-contract, índices, locks)."
argument-hint: "[arquivo de migração]"
disable-model-invocation: true
context: fork
agent: rpe-dba
---

# Revisão de Migração

Revise a migração de banco de dados solicitada contra as boas práticas RPE.

## Checklist

Aplicar rule `database-migrations`:

- [ ] Possui script de rollback explícito
- [ ] Usa expand-and-contract para alterações breaking
- [ ] Foreign keys possuem índice
- [ ] Evita locks longos (sem ALTER bloqueante em tabelas grandes sem estratégia)
- [ ] Nomes descritivos e versionados
- [ ] Testada em ambiente de staging

## Passos

1. Ler arquivos de migração no diff ou path indicado.
2. Avaliar impacto em dados existentes e downtime.
3. Gerar relatório com status Aprovado/Alterações/Rejeitado.
4. Sugerir correções se necessário.

## Output

Relatório seguindo rule `interaction-standards`.
