---
name: node-mastery
description: Advanced Node.js ecosystem, event loop, and asynchronous patterns.
disable-model-invocation: true
---

# Node.js Mastery

## The Event Loop
- **Non-blocking I/O**: Node.js is single-threaded but uses asynchronous I/O primitives. Never block the event loop with heavy CPU-bound tasks (e.g., synchronous file reads, complex cryptography, large JSON parsing).
- **Worker Threads**: If you must perform CPU-intensive tasks, offload them to `worker_threads` or external services.
- **Microtasks vs Macrotasks**: Understand the difference. Promises (microtasks) resolve before `setTimeout` or `setImmediate` (macrotasks) in the same phase.

## Asynchronous Patterns
- **Async/Await**: Always prefer `async/await` over raw Promises or callbacks for readability.
- **Error Handling**: Always use `try/catch` within `async` functions. Unhandled promise rejections can crash the Node process in modern versions.
- **Concurrency**: Use `Promise.all` to run independent asynchronous operations concurrently. Be cautious with unbounded concurrency; use libraries like `p-limit` if you need to process thousands of items.

## Memory Management
- **Memory Leaks**: Node applications are long-running. Common leak sources include: global variables, unclosed database connections, lingering event listeners (e.g., `emitter.on` without `emitter.off`), and closures holding large scopes.
- **Streams**: Use Streams to process large amounts of data (files, network requests) to avoid buffering everything in memory.

## Architecture & Ecosystem
- **Modules**: Prefer ECMAScript Modules (ESM, `import`/`export`) over CommonJS (`require`) for new projects.
- **Typescript**: Use TypeScript heavily. Strictly type your interfaces and avoid `any`.
- **Frameworks**: Choose the right tool. Express/Fastify for APIs, NestJS for highly structured enterprise applications.
- **Security**: Never trust user input. Use tools to check dependencies (`npm audit`). Implement proper logging, but avoid logging sensitive data.
