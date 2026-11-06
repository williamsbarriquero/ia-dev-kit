---
paths:
  - "**/*.{ts,tsx,js,go,java}"
  - "**/handlers/**"
  - "**/services/**"
  - "**/middleware/**"
---

# Observabilidade RPE

## Contexto

Regras para logging, tracing e métricas. Complementa `/audit-logs-otel`.

## Instruções

- **Níveis**: debug/info/warn/error com contexto estruturado (requestId, userId, traceId).
- **PII**: Nunca logar senhas, tokens, CPF, cartões ou dados sensíveis em plain text.
- **Trace context**: Propagar `traceparent`/`tracestate` em chamadas HTTP e mensageria.
- **Correlação**: Incluir `correlationId` em logs de fluxos distribuídos.
- **Severidade**: error para falhas recuperáveis com retry; fatal apenas para indisponibilidade total.

## Verificação

- `/audit-logs-otel` para auditoria de PII e trace context
- Revisar que logs de erro não expõem stack traces com dados sensíveis em produção
