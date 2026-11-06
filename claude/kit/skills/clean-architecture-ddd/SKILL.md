---
name: clean-architecture-ddd
description: >-
  Implementa e revisa Java em Clean Architecture com DDD tático: módulos
  domain, application e infrastructure, agregados, value objects, gateways,
  use cases, Notification/Either e adapters Spring. Use ao criar ou alterar
  agregados, use cases, gateways, entidades JPA ou controllers neste estilo,
  ou quando o usuário mencionar Clean Architecture, DDD, domínio, agregado,
  use case ou gateway em Java.
disable-model-invocation: true
---

# Clean Architecture + DDD (Java)

Padrão de três módulos Gradle. O domínio não conhece framework. A aplicação orquestra casos de uso. A infraestrutura adapta HTTP, banco, filas e storage.

`java-mastery` continua valendo para linguagem, testes, segurança e observabilidade. O layout `controllers → services → repositories` de `knowledge/stacks/java.md` não se aplica enquanto esta skill estiver ativa. Ports e adapters em geral: skill `hexagonal-architecture`. Aqui o port de saída se chama **gateway**.

## Regra de dependência

```text
infrastructure → application → domain
```

| Módulo | Pode depender de | Proibido |
|--------|------------------|----------|
| `domain` | JDK | Spring, JPA, Jackson, Vavr, HTTP |
| `application` | `domain`, Vavr | Spring, JPA, anotações de framework |
| `infrastructure` | `domain`, `application`, Spring | Regra de negócio |

Identidade nasce no domínio (`IdUtils.uuid()`: UUID minúsculo, sem hífen). Relógio do domínio passa por `InstantUtils.now()` (truncado a microssegundos). Não use `@GeneratedValue` nem `Instant.now()` espalhado no agregado.

## Onde cada tipo vive

| Tipo | Pacote |
|------|--------|
| Agregado, ID, validator, gateway | `{base}.domain.{agregado}` |
| `Entity`, `AggregateRoot`, `Identifier`, `ValueObject` | `{base}.domain` |
| `ValidationHandler`, `Validator`, `Error` | `{base}.domain.validation` |
| `Notification`, `ThrowsValidationHandler` | `{base}.domain.validation.handler` |
| Exceções de domínio | `{base}.domain.exceptions` |
| `Pagination`, `SearchQuery` | `{base}.domain.pagination` |
| Use case, `Command`, `Output` | `{base}.application.{agregado}.{operacao}` |
| Gateway JPA | `{base}.infrastructure.{agregado}` |
| `{Agregado}JpaEntity`, repository | `{base}.infrastructure.{agregado}.persistence` |
| Request/response HTTP | `{base}.infrastructure.{agregado}.models` |
| Presenter | `{base}.infrastructure.{agregado}.presenters` |
| API + controller | `{base}.infrastructure.api` |
| Beans dos use cases | `{base}.infrastructure.configuration.usecases` |

Operações e pacotes: `create`, `update`, `delete`, `retrieve.get`, `retrieve.list`. Um use case por operação.

Nomes: `{Agregado}`, `{Agregado}ID`, `{Agregado}Gateway`, `{Agregado}Validator`, `{Verbo}{Agregado}UseCase`, `Default{Verbo}{Agregado}UseCase`, `{Verbo}{Agregado}Command`, `{Verbo}{Agregado}Output`.

## Fluxo de um agregado novo

1. Domínio: ID, agregado, validator, gateway. Testes de unidade sem Spring.
2. Aplicação: use case abstrato, `Default*`, command e output. Testes com gateway em memória ou mock.
3. Infraestrutura: JPA (`from` / `toAggregate`), gateway `@Component`, Flyway, `{Agregado}UseCaseConfig`, API, controller, presenter.
4. Controller só traduz HTTP ↔ command/output. Não instancia agregado.

Leia o reference só da camada que for alterar:

- Domínio: [references/domain.md](references/domain.md)
- Aplicação: [references/application.md](references/application.md)
- Infraestrutura: [references/infrastructure.md](references/infrastructure.md)

## Modelo tático

- **Agregado** estende `AggregateRoot<ID>`. Construtor privado ou protegido. `new{Agregado}(...)` cria; `with(...)` reconstitui (persistência e cópia). Métodos de negócio devolvem `this`.
- **Referência entre agregados** é só o ID (`Genre` guarda `CategoryID`, nunca `Category`).
- **Invariante do agregado** fica no `{Agregado}Validator`. O use case valida o que cruza agregados (`existsByIds`) antes de persistir.
- **Gateway** é interface no domínio. Fala tipos de domínio: `create`, `update`, `deleteById`, `findById` → `Optional`, `findAll` → `Pagination`, `existsByIds`.
- **Use case** recebe gateways no construtor (`Objects.requireNonNull`). Sem `@Service`. O `@Bean` fica na infraestrutura e instancia `Default*`.
- **Command** entra com primitivos e `String`. **Output** de escrita expõe `String id`. **Output** de leitura pode carregar tipos do domínio; o presenter converte para o model HTTP.
- **Evento** (`DomainEvent` com `occurredOn()`) é registrado no agregado (`registerEvent`). O gateway publica **depois** do `save` (`publishDomainEvents`) e a lista é esvaziada. O agregado não fala com fila nem HTTP.

## Erros — um estilo por agregado

Não misture os dois no mesmo agregado.

| Estilo | Quando | Contrato do use case | HTTP |
|--------|--------|----------------------|------|
| `Either<Notification, Output>` (Vavr) | Só regras do próprio agregado (create/update simples) | `UseCase<Command, Either<Notification, Output>>` | Controller faz `fold`: esquerda → 422, direita → 201/200 |
| `NotificationException` | Regras do agregado **e** checagem de outros agregados | `execute` devolve `Output` e lança | `@RestControllerAdvice` mapeia `DomainException` → 422 |

`Notification` acumula `Error`. `ThrowsValidationHandler` falha no primeiro erro. `Get*` lança `NotFoundException.with(Agregado.class, id)` → 404. `Delete*` estende `UnitUseCase<String>` e não devolve corpo.

Falha inesperada do gateway no estilo `Either`: `Try(...).toEither().bimap(Notification::create, Output::from)`.

## Testes

| Camada | Onde | Como |
|--------|------|------|
| Domínio | `domain/src/test` | JUnit, sem Spring. Invariantes, factories, activate/deactivate |
| Aplicação | `application/src/test` | Gateway falso. Sem contexto Spring |
| Gateway | `infrastructure` | Testcontainers PostgreSQL |
| API | `infrastructure` | Controller com use case mockado |
| E2E | `infrastructure` | Spring + Testcontainers |

## Proibições

- `@Entity`, `@Table` ou anotação Spring no agregado.
- Repository Spring Data injetado em use case.
- Regra de negócio em controller, presenter ou `*JpaEntity`.
- Setter público como API do agregado. Mutação por método de intenção (`activate`, `update`, `addCategory`).
- Coleção interna exposta mutável. Entrada: cópia. Saída: `unmodifiable`.
- Agregado inválido persistido. Valide antes de `gateway.create` / `update`.
- Publicar evento antes do `save` ou engolir falha de publicação sem decisão explícita.
