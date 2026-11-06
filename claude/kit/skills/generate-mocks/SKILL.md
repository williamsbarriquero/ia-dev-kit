---
name: generate-mocks
description: "Gera mocks de API (MSW, WireMock, mocks Go) a partir de OpenAPI, Swagger ou payload JSON."
argument-hint: "[schema ou payload]"
disable-model-invocation: true
context: fork
agent: rpe-sdet
---

# Geração de Mocks de API

Execute as seguintes ações para gerar dublês de teste a partir do schema OpenAPI, Swagger ou payload JSON enviado:

1. Identifique a estrutura de campos, tipos e payloads de requisição/resposta.
2. Use o framework de teste pedido (ex: MSW no TypeScript, WireMock no Java, Go mocks nativos). Se o pedido não especificar, use o que o projeto já usa ou o padrão mais comum da linguagem, e declare a escolha no relatório.
3. Produza o código de mock completo e configurável, incluindo respostas de sucesso (200/201) e simulações de erro comuns (400, 401, 500).
