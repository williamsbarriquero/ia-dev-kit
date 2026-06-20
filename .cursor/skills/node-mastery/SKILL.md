---
name: node-mastery
description: Ecossistema Node.js avançado, event loop e padrões assíncronos.
disable-model-invocation: true
---

# Node.js Mastery

## Event Loop

- **I/O não bloqueante**: Node.js é single-threaded, mas usa primitivas de I/O assíncrono. Nunca bloqueie o event loop com tarefas CPU-bound pesadas (ex.: leituras síncronas de arquivo, criptografia complexa, parsing de JSON grande).
- **Worker Threads**: Se precisar executar tarefas intensivas em CPU, delegue-as a `worker_threads` ou serviços externos.
- **Microtasks vs Macrotasks**: Entenda a diferença. Promises (microtasks) resolvem antes de `setTimeout` ou `setImmediate` (macrotasks) na mesma fase.

## Padrões Assíncronos

- **Async/Await**: Sempre prefira `async/await` a Promises cruas ou callbacks por legibilidade.
- **Tratamento de erros**: Sempre use `try/catch` dentro de funções `async`. Rejeições de promise não tratadas podem derrubar o processo Node em versões modernas.
- **Concorrência**: Use `Promise.all` para executar operações assíncronas independentes em paralelo. Cuidado com concorrência ilimitada; use bibliotecas como `p-limit` se precisar processar milhares de itens.

## Gerenciamento de Memória

- **Vazamentos de memória**: Aplicações Node são de longa duração. Fontes comuns incluem: variáveis globais, conexões de banco não fechadas, event listeners persistentes (ex.: `emitter.on` sem `emitter.off`) e closures retendo escopos grandes.
- **Streams**: Use Streams para processar grandes volumes de dados (arquivos, requisições de rede) e evitar bufferizar tudo na memória.

## Arquitetura e Ecossistema

- **Módulos**: Prefira ECMAScript Modules (ESM, `import`/`export`) a CommonJS (`require`) em projetos novos.
- **TypeScript**: Use TypeScript extensivamente. Tipagem estrita em interfaces e evite `any`.
- **Frameworks**: Escolha a ferramenta certa. Express/Fastify para APIs, NestJS para aplicações enterprise altamente estruturadas.
- **Segurança**: Nunca confie em input do usuário. Use ferramentas para verificar dependências (`npm audit`). Implemente logging adequado, mas evite registrar dados sensíveis.
