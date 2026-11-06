# Domínio

Sem framework. Tipos abaixo são a base; não reimplemente por agregado.

## Entity, agregado, identidade

```java
public abstract class ValueObject {}

public abstract class Identifier extends ValueObject {
    public abstract String getValue();
}

public abstract class Entity<ID extends Identifier> {
    protected final ID id;
    private final List<DomainEvent> domainEvents;

    protected Entity(final ID id, final List<DomainEvent> domainEvents) {
        this.id = Objects.requireNonNull(id, "'id' should not be null");
        this.domainEvents = new ArrayList<>(domainEvents == null ? List.of() : domainEvents);
    }

    public abstract void validate(ValidationHandler handler);

    public List<DomainEvent> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    public void registerEvent(final DomainEvent event) {
        if (event != null) this.domainEvents.add(event);
    }

    public void publishDomainEvents(final DomainEventPublisher publisher) {
        if (publisher == null) return;
        getDomainEvents().forEach(publisher::publishEvent);
        this.domainEvents.clear();
    }

    // equals e hashCode somente pelo id
}

public abstract class AggregateRoot<ID extends Identifier> extends Entity<ID> {
    protected AggregateRoot(final ID id) { super(id, List.of()); }
    protected AggregateRoot(final ID id, final List<DomainEvent> events) { super(id, events); }
}
```

`DomainEvent` é `Serializable` e expõe `Instant occurredOn()`. `DomainEventPublisher` é `@FunctionalInterface` com `publishEvent`.

## ID do agregado

Construtor privado. `unique()` gera; `from(String)` reconstitui. `equals` / `hashCode` pelo `value`.

```java
public final class CategoryID extends Identifier {
    private final String value;

    private CategoryID(final String value) {
        this.value = Objects.requireNonNull(value);
    }

    public static CategoryID unique() { return from(IdUtils.uuid()); }
    public static CategoryID from(final String anId) { return new CategoryID(anId); }

    @Override public String getValue() { return value; }
}
```

## Agregado

- Campos mutáveis só pelos métodos de negócio. `createdAt` não muda.
- `newCategory(name, description, isActive)` define id e timestamps. Se inativo, `deletedAt = now`; se ativo, `deletedAt = null`.
- `with(...)` completo para a JPA. `with(agregado)` copia.
- `activate` / `deactivate` / `update` alteram `updatedAt` e devolvem `this`.
- Invariante no construtor quando o objeto não pode existir inválido: `selfValidate()` monta `Notification`, chama `validate`, e lança `NotificationException` se `hasError()`.
- Adie a validação para o use case somente se **todo** o agregado usar `Either` e o construtor for chamado já com a checagem em seguida. Não deixe os dois caminhos no mesmo tipo.
- Associação: `List`/`Set` de IDs. `add` ignora null. Getter devolve coleção não modificável.

```java
@Override
public void validate(final ValidationHandler handler) {
    new CategoryValidator(this, handler).validate();
}

private void selfValidate() {
    final var notification = Notification.create();
    validate(notification);
    if (notification.hasError()) {
        throw new NotificationException("Failed to create Aggregate Genre", notification);
    }
}
```

## Validator

Estende `Validator`. Não lança. Acumula `Error` (record `message`).

```java
public class CategoryValidator extends Validator {
    private static final int NAME_MAX_LENGTH = 255;
    private static final int NAME_MIN_LENGTH = 3;

    public CategoryValidator(final Category category, final ValidationHandler handler) {
        super(handler);
        this.category = category;
    }

    @Override
    public void validate() {
        checkNameConstraints();
    }
}
```

Mensagens no formato `'name' should not be null`, `'name' should not be empty`, `'name' must be between 3 and 255 characters`.

`ValidationHandler`: `append(Error)`, `append(ValidationHandler)`, `<T> T validate(Validation<T>)`, `getErrors()`, `hasError()`.

- `Notification.create()` acumula. `validate` captura `DomainException` e segue.
- `ThrowsValidationHandler` converte `append` em `DomainException`.

## Gateway

Interface no pacote do agregado. Sem Spring.

```java
public interface CategoryGateway {
    Category create(Category aCategory);
    Category update(Category aCategory);
    void deleteById(CategoryID anId);
    Optional<Category> findById(CategoryID anId);
    Pagination<Category> findAll(SearchQuery aQuery);
    List<CategoryID> existsByIds(Iterable<CategoryID> ids);
}
```

`SearchQuery(page, perPage, terms, sort, direction)`. `Pagination<T>(currentPage, perPage, total, items)` com `map(Function)`.

Consulta que não devolve o agregado inteiro usa um tipo de leitura no domínio (`VideoPreview`), não a entidade JPA.

## Exceções

`NoStacktraceException` desliga o stacktrace (`super(message, cause, true, false)`). `DomainException` carrega `List<Error>`.

- `NotificationException(message, notification)` — validação agregada.
- `NotFoundException.with(Category.class, id)` — `"Category with ID %s was not found"`.
- `InternalErrorException` — falha técnica sem regra de negócio.

## Value object e enum

Construtor privado, factories `with`, todos os campos no `equals`. Transição de estado devolve instância nova (`media.processing()`, `media.completed(path)`), não altera o anterior.

Enum fechado para conjunto fixo (`ACTOR` / `DIRECTOR`, `Rating`, `MediaStatus`). Sem tabela lookup só para isso.
