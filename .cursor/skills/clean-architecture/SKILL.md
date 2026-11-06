---
name: clean-architecture
description: >-
  Aplica Clean Architecture e DDD em Java com módulos domain, application e
  infrastructure. Use somente quando o repositório já tem esses módulos (ou use
  case abstrato e gateway no domínio) ou quando o usuário pede explicitamente
  para adotar esse modelo. Não aplique em projetos Java de outra arquitetura.
disable-model-invocation: true
---

# Clean Architecture (Java)

## Quando aplicar

Aplique esta skill só em um destes casos:

1. O repositório já segue o modelo: módulos `domain`, `application` e `infrastructure`, ou o equivalente com use case abstrato e gateway no domínio.
2. O usuário pediu explicitamente para adotar Clean Architecture.

Fora isso, implemente na arquitetura que o projeto já tem. Não crie esses módulos, não troque `service` por use case e não mova regra para um domínio novo.

Quando a skill se aplica, o serviço tem três módulos Gradle, domínio rico e use cases isolados de framework. Spring, JPA, HTTP e mensageria existem só em `infrastructure`.

Leia também `hexagonal-architecture` para o vocabulário de ports e adapters. Esta skill é a forma concreta de implementá-los.

## Módulos

`settings.gradle.kts` inclui `domain`, `application`, `infrastructure`.

| Módulo | Depende de | Contém | Não contém |
|--------|------------|--------|------------|
| `domain` | nada interno | agregados, value objects, gateways, validação, eventos, paginação | Spring, JPA, web, anotações de framework |
| `application` | `domain` | use cases, commands, outputs | repositório, entidade JPA, DTO HTTP |
| `infrastructure` | `domain` + `application` | gateway concreto, JPA, API, controller, presenter, config de beans, Flyway | regra de negócio |

`domain` e `application` são `java-library`. Só `infrastructure` aplica Spring Boot. A regra de dependência não se inverte.

Pacote raiz `<root>` (ex.: `tech.willeei.admin.catalogo`):

```text
domain/        <root>.domain.<agregado>
application/   <root>.application.<agregado>.<operação>
infrastructure/<root>.infrastructure.<agregado>
               <root>.infrastructure.api
               <root>.infrastructure.configuration.usecases
```

Operações de aplicação: `create`, `update`, `delete`, `retrieve/get`, `retrieve/list`. Uma pasta por operação.

## Domínio

Tipos base em `<root>.domain`:

- `Identifier` — value object com `getValue()`. ID do agregado: `unique()` e `from(String)`, construtor privado.
- `ValueObject`, `Entity<ID>`, `AggregateRoot<ID>`.
- Igualdade de entidade pelo `id`. Sem setters públicos.
- `new<Agregado>(...)` cria. `with(...)` reconstitui (persistência e cópia). Construtor real é privado.
- `validate(ValidationHandler)` delega a `<Agregado>Validator`.
- Comportamento de negócio mora no agregado (`activate`, `deactivate`, `update`) e devolve `this`.

Gateway é a porta de saída, no mesmo pacote do agregado, sem tecnologia no nome:

```java
public interface CategoryGateway {
    Category create(Category aCategory);
    Optional<Category> findById(CategoryID anId);
    Category update(Category aCategory);
    void deleteById(CategoryID anId);
    Pagination<Category> findAll(SearchQuery aQuery);
}
```

Validação:

- `Validator` acumula `Error` no `ValidationHandler`.
- `Notification` coleta erros. `ThrowsValidationHandler` lança `DomainException`.
- Use case de escrita que valida devolve `Either<Notification, Output>` (Vavr). Não lança na primeira falha de input.
- Ausência de agregado: `NotFoundException`.

`Entity` guarda `DomainEvent` e publica via `DomainEventPublisher`. `Pagination` e `SearchQuery` ficam em `domain.pagination`.

## Aplicação

Três bases, um método `execute`:

| Base | Assinatura | Uso |
|------|------------|-----|
| `UseCase<IN, OUT>` | `OUT execute(IN)` | cria, atualiza, consulta |
| `UnitUseCase<IN>` | `void execute(IN)` | delete |
| `NullaryUseCase<OUT>` | `OUT execute()` | sem entrada |

Por operação, no mesmo pacote:

- `<Ação><Agregado>UseCase` — abstrato, estende uma das bases. É o tipo injetado.
- `Default<Ação><Agregado>UseCase` — implementação. Construtor recebe só gateways (`Objects.requireNonNull`).
- `<Ação><Agregado>Command` — `record` + `with(...)`. Consulta por id pode receber `String`.
- `<Ação><Agregado>Output` — `record` + `from(agregado)` / `from(id)`.

O `Default*` cria o agregado pela factory, chama `validate(notification)` e só então o gateway. `Left` se houver erro. Falha do gateway vira `Notification` com `Try(...).toEither().bimap(...)`. Sem `@Service` e sem `@Transactional` na aplicação.

## Infrastructure

Por agregado:

| Peça | Papel |
|------|--------|
| `<Agregado>PostgreSQLGateway` | `@Component`, implementa o gateway, traduz agregado ↔ JPA |
| `persistence/<Agregado>JpaEntity` | `@Entity` com `from(agregado)` e `toAggregate()` |
| `persistence/<Agregado>Repository` | Spring Data, usado só pelo gateway |
| `models/` | records de request e response HTTP |
| `presenters/<Agregado>ApiPresenter` | `Output` → response. Estáticos, sem estado |
| `api/<Agregado>API` | interface `@RequestMapping` com contrato OpenAPI |
| `api/controllers/<Agregado>Controller` | implementa a API, monta command, faz `fold` do `Either` |
| `configuration/usecases/<Agregado>UseCaseConfig` | `@Bean` do tipo abstrato (`CreateXUseCase`), instancia o `Default*` |

O controller não conhece repositório nem agregado persistido. `201` com `Location` na criação, `422` no `Left` ou em `DomainException`, `404` em `NotFoundException`, `204` no delete. `GlobalExceptionHandler` traduz `NotFoundException` e `DomainException`.

Schema relacional: Flyway em `infrastructure/src/main/resources/db/migration`. `ddl-auto: none` fora de teste.

## Ordem ao adicionar uma operação

1. Teste de domínio e agregado (skill `java-test-layers`).
2. Gateway no domínio, se a operação precisar de persistência nova.
3. Teste do use case com gateway mockado, depois `Default*`, command e output.
4. Teste do gateway, depois JPA entity, repository e `<Agregado>PostgreSQLGateway`.
5. Teste de controller com use cases mockados, depois API, controller, models e presenter.
6. `@Bean` em `<Agregado>UseCaseConfig`.
7. E2E da API no perfil `test-e2e`.

## Proibido

- Importar Spring, Jakarta Persistence ou HTTP em `domain` ou `application`.
- Colocar regra de negócio no controller, presenter ou entidade JPA.
- Injetar `Repository` ou o `Default*` no controller. O controller depende do use case abstrato.
- Expor `JpaEntity` ou entidade de domínio no JSON.
- Criar camada `service` entre controller e use case.
- Anotar use case com `@Service` em vez do `@Bean` na config.
