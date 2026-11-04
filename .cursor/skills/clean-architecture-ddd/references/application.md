# Aplicação

Depende só de `domain` e Vavr. Classes concretas não levam anotação Spring.

## Bases

```java
public abstract class UseCase<IN, OUT> {
    public abstract OUT execute(IN anIn);
}

public abstract class UnitUseCase<IN> {
    public abstract void execute(IN anIn);
}

public abstract class NullaryUseCase<OUT> {
    public abstract OUT execute();
}
```

| Operação | Base | Entrada | Saída |
|----------|------|---------|-------|
| create / update com `Either` | `UseCase` | `Command` | `Either<Notification, Output>` |
| create / update com exceção | `UseCase` | `Command` | `Output` |
| get by id | `UseCase` | `String` | `Output` |
| list | `UseCase` | `SearchQuery` | `Pagination<Output>` |
| delete | `UnitUseCase` | `String` | `void` |

O tipo abstrato `{Verbo}{Agregado}UseCase` fica vazio e só fixa o contrato. A implementação é `Default*`. Controller e testes dependem do abstrato.

## Command e output

Records no pacote da operação. Factory `with` no command; `from` no output.

```java
public record CreateCategoryCommand(String name, String description, boolean isActive) {
    public static CreateCategoryCommand with(final String name, final String description, final boolean isActive) {
        return new CreateCategoryCommand(name, description, isActive);
    }
}

public record CreateCategoryOutput(String id) {
    public static CreateCategoryOutput from(final Category category) {
        return new CreateCategoryOutput(category.getId().getValue());
    }
}
```

Query output pode guardar `CategoryID` e timestamps. Não devolver a entidade de persistência. Não devolver o agregado se o caller for HTTP — o output é o contrato da aplicação.

## Create simples (`Either`)

Gateway obrigatório no construtor. Valida com `Notification`. Só persiste sem erro. Falha do gateway vira `Left`.

```java
public class DefaultCreateCategoryUseCase extends CreateCategoryUseCase {
    private final CategoryGateway categoryGateway;

    public DefaultCreateCategoryUseCase(final CategoryGateway categoryGateway) {
        this.categoryGateway = Objects.requireNonNull(categoryGateway);
    }

    @Override
    public Either<Notification, CreateCategoryOutput> execute(final CreateCategoryCommand aCommand) {
        final var notification = Notification.create();
        final var aCategory = Category.newCategory(aCommand.name(), aCommand.description(), aCommand.isActive());
        aCategory.validate(notification);

        return notification.hasError() ? Left(notification) : create(aCategory);
    }

    private Either<Notification, CreateCategoryOutput> create(final Category aCategory) {
        return Try(() -> this.categoryGateway.create(aCategory))
                .toEither()
                .bimap(Notification::create, CreateCategoryOutput::from);
    }
}
```

O construtor do agregado **não** pode lançar `NotificationException` neste estilo: a validação fica no `validate(notification)`.

## Create com outros agregados (exceção)

Conferência de IDs no use case. O agregado só conhece os próprios campos. IDs ausentes entram na mesma `Notification` que a factory.

```java
@Override
public CreateGenreOutput execute(final CreateGenreCommand aCommand) {
    final var categories = aCommand.categories().stream().map(CategoryID::from).toList();
    final var notification = Notification.create();
    notification.append(validateCategories(categories));

    final var aGenre = notification.validate(() -> Genre.newGenre(aCommand.name(), aCommand.isActive()));
    if (notification.hasError()) {
        throw new NotificationException("Could not create Aggregate Genre", notification);
    }

    aGenre.addCategories(categories);
    return CreateGenreOutput.from(this.genreGateway.create(aGenre));
}
```

`validateCategories`: `categoryGateway.existsByIds`. Se o tamanho divergir, monte a mensagem `Some categories could not be found: %s` com os IDs ausentes. Lista vazia não é erro, salvo regra explícita do agregado.

`Genre.newGenre` já chama `selfValidate`. `notification.validate` captura `DomainException` e devolve null — por isso o `hasError()` vem **antes** de usar o agregado.

## Get, list, delete

```java
@Override
public CategoryOutput execute(final String anIn) {
    final var anId = CategoryID.from(anIn);
    return this.categoryGateway.findById(anId)
            .map(CategoryOutput::from)
            .orElseThrow(() -> NotFoundException.with(Category.class, anId));
}
```

List mapeia `Pagination<Agregado>` para `Pagination<ListOutput>` com `page.map(ListOutput::from)`. Delete chama `deleteById(AgregadoID.from(anIn))`. Idempotência do delete (ignorar id ausente) fica no gateway.

## O que não entra no use case

- Status HTTP, `ResponseEntity`, records de request.
- `JpaRepository`, `Specification`, SQL.
- Montar SQL ou critério de paginação além de repassar `SearchQuery`.
- Publicar em Rabbit/Kafka. Isso é o gateway, depois do save.
