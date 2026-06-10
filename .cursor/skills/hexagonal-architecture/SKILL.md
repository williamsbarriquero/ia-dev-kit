---
name: hexagonal-architecture
description: Library of knowledge for Ports & Adapters (Hexagonal) architecture software design.
disable-model-invocation: true
---

# Hexagonal Architecture (Ports & Adapters)

## Core Principles

The Hexagonal Architecture, or Ports and Adapters architecture, aims to create loosely coupled application components that can be easily connected to their software environment. It makes components exchangeable at any level and facilitates test automation.

1. **Dependency Rule**: The core domain logic does not depend on anything outside of it. All dependencies point inward toward the domain.
2. **Separation of Concerns**: Keep business logic completely separate from external systems (databases, UI, APIs, message brokers).
3. **Ports**: Interfaces defined by the application core that define how it communicates with the outside world.
   - **Inbound/Driving/Primary Ports**: How outside actors interact with the application (e.g., Use Case interfaces).
   - **Outbound/Driven/Secondary Ports**: How the application interacts with outside actors (e.g., Repository interfaces).
4. **Adapters**: Implementations that interact with the external world and plug into the Ports.
   - **Primary Adapters**: Implement inbound ports (e.g., REST Controllers, CLI Commands, GraphQL Resolvers). They drive the application.
   - **Secondary Adapters**: Implement outbound ports (e.g., Database Repositories, HTTP Clients to external services, Event Publishers). They are driven by the application.

## Best Practices

- **Domain Isolation**: Ensure your domain entities and use cases have zero knowledge of frameworks, databases, or transport layers.
- **Dependency Injection**: Use DI to wire adapters to ports at the application entry point (e.g., main function or DI container configuration).
- **Testability**: The core application should be testable without any external dependencies by mocking or stubbing the outbound ports.
- **Mapping**: Avoid leaking domain entities to the outside. Map external DTOs to domain entities in primary adapters, and domain entities to database models or external payloads in secondary adapters.
