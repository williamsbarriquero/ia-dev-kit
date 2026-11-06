---
name: audit-security
description: "Varredura de segurança (OWASP Top 10, segredos, dependências) no diff ou no escopo indicado."
argument-hint: "[arquivos, diretório ou branch]"
disable-model-invocation: true
context: fork
agent: rpe-security
---

# Auditoria de Segurança

Execute varredura de segurança no código modificado ou no escopo indicado.

## Passos

1. Ler diff do branch ou arquivos indicados.
2. Aplicar rule `safety-guardrails` e checklist OWASP Top 10:
   - Credenciais hardcoded (regex: password/secret/api_key/token)
   - SQL injection (queries sem parametrização)
   - XSS (output não sanitizado)
   - Dependências vulneráveis (`npm audit` se Node)
3. Verificar se o hook `rpe-secret-scan.ts` (roda no `git commit`) passaria nos arquivos analisados.
4. Para deep dive AppSec (SLSA, IaC, K8s), escalar ao subagent `rpe-security`.

## Output

Relatório com vulnerabilidades por severidade (Critical/Major/Minor) e correções sugeridas.
