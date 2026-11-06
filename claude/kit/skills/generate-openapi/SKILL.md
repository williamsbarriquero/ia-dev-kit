---
name: generate-openapi
description: "Gera ou atualiza a especificação OpenAPI 3.x das rotas indicadas."
argument-hint: "[rotas ou controllers]"
disable-model-invocation: true
context: fork
agent: rpe-tech-writer
---

# Gerar OpenAPI

Gere ou atualize a especificação OpenAPI/Swagger para as rotas solicitadas.

## Passos

1. Ler controllers/handlers e modelos de request/response.
2. Identificar rotas, métodos HTTP, parâmetros, headers e códigos de status.
3. Gerar spec OpenAPI 3.x com exemplos de request/response.
4. Incluir descrições claras e schemas reutilizáveis.
5. Validar consistência com implementação existente.

## Output

- Arquivo YAML/JSON OpenAPI pronto para uso
- Resumo das rotas documentadas e gaps encontrados

## Referência

Seguir boas práticas de subagent `rpe-tech-writer` e Google Developer Documentation Style Guide.
