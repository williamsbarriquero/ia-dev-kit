# Java & Spring Boot — SSOT RPE

Conteúdo canônico para implementação e revisão Java. Referenciado por `java-mastery` e `java-standards.mdc`.

## Recursos modernos do Java

- **Records**: data carriers imutáveis (getters, `equals`, `hashCode`, `toString` gerados).
- **Sealed classes**: restringir hierarquias para pattern matching seguro.
- **Pattern matching**: `instanceof` e `switch` expressivos.
- **Text blocks**: `"""` para JSON, SQL, HTML multilinha.
- **Var**: inferência local quando o tipo é óbvio pelo RHS.

## Estilo e nomenclatura

- Classes: `PascalCase` (ex.: `UserController`, `OrderService`).
- Métodos/variáveis: `camelCase`.
- Constantes: `ALL_CAPS`.
- Código limpo, documentado; controllers enxutos delegando lógica a services.

## Spring Boot

### Estrutura

`controllers` → `services` → `repositories` → `models` / `configurations`.

### Anotações e IoC

- `@SpringBootApplication`, `@RestController`, `@Service`, auto-configuration.
- **Injeção por construtor** — evitar `@Autowired` em campos.
- `@ControllerAdvice` + `@ExceptionHandler` para erros.

### Configuração

- `application.properties` ou `application.yml`.
- Profiles por ambiente (`dev`, `test`, `prod`).
- `@ConfigurationProperties` para config tipada.

### API REST

- HTTP methods e status codes corretos.
- Bean Validation (`@Valid`, validadores customizados).
- Springdoc OpenAPI para documentação.

### Dados

- Spring Data JPA; relacionamentos e cascade adequados.
- Migrações: Flyway ou Liquibase.

### Performance e async

- Spring Cache quando aplicável.
- `@Async` para operações não bloqueantes.
- Indexação e otimização de queries.

### Segurança

- Spring Security; BCrypt para senhas.
- CORS configurado por ambiente.

### Observabilidade

- SLF4J + Logback (ERROR, WARN, INFO, DEBUG).
- Spring Boot Actuator para métricas.

### Build e deploy

- Maven ou Gradle; profiles por ambiente.
- Docker quando aplicável.
- Java 17+; Spring Boot 3.x.

## JVM e performance

- GC: G1 padrão; ZGC/Shenandoah para baixa latência.
- Evitar alocação excessiva em loops críticos.
- Streams para coleções; parallel streams só em CPU-bound com datasets grandes.
- Cuidado com vazamentos: referências estáticas, coleções long-lived, recursos não fechados.

## Boas práticas

- **Imutabilidade**: `final` quando aplicável.
- **Optional**: tipo de retorno para ausência; evitar em campos/parâmetros.
- **Exceções**: unchecked para regras de negócio; tipadas — nunca `catch` genérico sem tratamento.
- **SOLID**: alta coesão, baixo acoplamento.
- Microservices e WebFlux quando o contexto exigir reatividade.

## Testes

- JUnit 5 + AssertJ; Spring Boot Test.
- MockMvc para camada web.
- `@SpringBootTest` integração; `@DataJpaTest` para repositories.
- **Testcontainers** para banco/serviços reais — preferir a H2 in-memory.

## Verificação

- `./gradlew spotlessApply` ou `./mvnw spotless:apply`
- `./gradlew test` ou `./mvnw test`
