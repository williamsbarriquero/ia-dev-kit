---
name: api-contract-testing
description: Testes de API funcionais, validações de contrato e mockagem avançada.
disable-model-invocation: true
---
# Testes de API e de Contrato

## Testes de Contrato
- **Princípio**: Garantir que o Provedor (Producer) e o Consumidor (Consumer) de uma API concordem sobre os formatos de payload sem precisar rodar testes de integração E2E pesados.
- **Pact & JSON Schema**: Utilize validação de JSON Schema para verificar a estrutura dos payloads em todas as respostas de API.

## Mockagem Inteligente
- Utilize ferramentas modernas como **MSW (Mock Service Worker)** para interceptação de rede no frontend ou **WireMock** para backend.
- Mocks devem ser dinâmicos e simular comportamentos reais de timeout, erros 500, e payloads inválidos.
