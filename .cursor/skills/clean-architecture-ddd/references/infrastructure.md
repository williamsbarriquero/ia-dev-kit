# Infraestrutura

Único módulo com Spring. Adapta o que `domain` e `application` já definiram. Não coloque invariante aqui.

## Gateway de persistência

`@Component`. Implementa o gateway do domínio. O repository Spring Data fica em `persistence` e não vaza.

```java
@Component
public class CategoryPostgreSQLGateway implements CategoryGateway {
    private final CategoryRepository repository;

    public CategoryPostgreSQLGateway(final CategoryRepository repository) {
        this.repository = repository;
    }

    @Override
    public Category create(final Category aCategory) { return save(aCategory); }

    @Override
    public Optional<Category> findById(final CategoryID anId) {
        return this.repository.findById(anId.getValue()).map(CategoryJpaEntity::toAggregate);
    }

    private Category save(final Category aCategory) {
        return this.repository.save(CategoryJpaEntity.from(aCategory)).toAggregate();
    }
}
```

`deleteById`: se `existsById`, apaga. Não lance `NotFoundException` no delete.

`findAll`: traduza `SearchQuery` para `PageRequest` + `Sort`. Termo em branco não vira filtro. Devolva `Pagination` de domínio, nunca `Page` do Spring, para fora do gateway.

`existsByIds`: receba IDs de domínio, consulte valores `String`, mapeie de volta com `AgregadoID.from`.

## Entidade JPA

Classe à parte do agregado. Sem lógica. `from(agregado)` e `toAggregate()` via `Agregado.with(...)`.

```java
@Entity(name = "Category")
@Table(name = "categories")
public class CategoryJpaEntity {
    @Id
    private String id;

    public static CategoryJpaEntity from(final Category aCategory) {
        return new CategoryJpaEntity(
                aCategory.getId().getValue(),
                aCategory.getName(),
                aCategory.getDescription(),
                aCategory.isActive(),
                aCategory.getCreatedAt(),
                aCategory.getUpdatedAt(),
                aCategory.getDeletedAt());
    }

    public Category toAggregate() {
        return Category.with(
                CategoryID.from(getId()),
                getName(),
                getDescription(),
                isActive(),
                getCreatedAt(),
                getUpdatedAt(),
                getDeletedAt());
    }
}
```

Id é `String` atribuído pelo domínio. Flyway cria a tabela; não dependa de `ddl-auto=create` fora de teste.

## Use cases no contexto Spring

A classe `Default*` não é `@Service`. Uma `@Configuration` por agregado recebe os gateways e expõe o tipo abstrato.

```java
@Configuration
public class CategoryUseCaseConfig {
    private final CategoryGateway categoryGateway;

    public CategoryUseCaseConfig(final CategoryGateway categoryGateway) {
        this.categoryGateway = categoryGateway;
    }

    @Bean
    public CreateCategoryUseCase createCategoryUseCase() {
        return new DefaultCreateCategoryUseCase(categoryGateway);
    }
}
```

## HTTP

Contrato da API numa interface (`CategoryAPI`) com anotações MVC. Controller `@RestController implements CategoryAPI`.

1. Request record → `Command.with(...)`.
2. `useCase.execute`.
3. Presenter ou `ResponseEntity` a partir do output.

Estilo `Either`:

```java
final Function<Notification, ResponseEntity<?>> onError =
        notification -> ResponseEntity.unprocessableEntity().body(notification);
final Function<CreateCategoryOutput, ResponseEntity<?>> onSuccess =
        output -> ResponseEntity.created(URI.create("/categories/" + output.id())).body(output);

return this.createCategoryUseCase.execute(aCommand).fold(onError, onSuccess);
```

List: `pagination.map(CategoryApiPresenter::present)`. Get: presenter no output. Campo `active` ausente no request cai no default do comando (no catálogo, `true`).

Presenter é interface com métodos `static`. Converte output → response. `id` de domínio vira `getValue()` aqui, não no use case de leitura.

`@RestControllerAdvice`:

| Exceção | Status |
|---------|--------|
| `NotFoundException` | 404 |
| `DomainException` (inclui `NotificationException`) | 422 |
| Bean Validation do request | 400, handler à parte |

Corpo: `message` + `List<Error>`. Não exponha stacktrace.

## Eventos

O gateway de vídeo, depois do `save`, chama `aVideo.publishDomainEvents(this.eventService::send)`.

`EventService` é porta da infraestrutura (não do domínio). Implementações: Rabbit e in-memory. Escolha por profile / `@ConditionalOnMissingBean`. O agregado só registra `VideoMediaCreated` quando a mídia entra em encode pendente; quem envia é a infraestrutura.

## O que revisar no adapter

- Controller sem `new` de agregado e sem `if` de regra de nome, tamanho ou vínculo.
- `*JpaEntity` sem `validate`.
- Nenhum import de `infrastructure` em `application` ou `domain`.
- Use case mockável em teste de API sem subir PostgreSQL.
- Gateway testado com Testcontainers, não com H2, quando a query usa recurso do Postgres.
