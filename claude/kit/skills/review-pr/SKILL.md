---
name: review-pr
description: "Revisa o PR ou a branch atual contra o checklist RPE e gera relatório para colar no PR."
argument-hint: "[branch de destino]"
disable-model-invocation: true
context: fork
agent: rpe-reviewer
---

# Revisão de PR

Execute os passos a seguir para revisar o Pull Request:

1. Ler o diff do branch atual em relação ao destino.
2. Aplicar o checklist de revisão definido em `.claude/skills/code-review/SKILL.md`.
3. Gerar relatório formatado para ser copiado e colado no PR.
