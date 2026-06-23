# Node.js — SSOT RPE

Conteúdo canônico para implementação e revisão Node.js/TypeScript backend. Referenciado por `node-mastery`.

## Event loop

- I/O não bloqueante — nunca bloquear o loop com CPU-bound pesado.
- `worker_threads` ou serviços externos para CPU intensivo.
- Microtasks (Promises) antes de macrotasks (`setTimeout`, `setImmediate`) na mesma fase.

## Assíncrono

- Preferir `async/await` a callbacks ou Promises encadeadas.
- `try/catch` em funções `async` — rejeições não tratadas derrubam o processo.
- `Promise.all` para paralelismo; `p-limit` para concorrência controlada em lotes grandes.

## Memória

- Vazamentos: globais, conexões abertas, listeners sem `off`, closures grandes.
- Streams para volumes grandes — evitar bufferizar tudo na RAM.

## Ecossistema

- ESM (`import`/`export`) em projetos novos.
- TypeScript com strict; evitar `any`.
- Express/Fastify para APIs; NestJS para enterprise estruturado.
- `npm audit`; nunca confiar em input; não logar dados sensíveis.

## Verificação

Ver `stack-baseline.mdc` → seção Node.js / TypeScript.
