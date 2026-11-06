# Java & Spring Boot — SSOT RPE

Conteúdo canônico de linguagem, runtime e stack. Referenciado por `java-mastery` e rule `java-standards`.

A arquitetura do serviço é a que o repositório já usa. Camadas `controller → service → repository`, hexágono, módulos Maven próprios e outros layouts são válidos. Não reestruture o projeto para outro modelo durante uma tarefa de funcionalidade.

## Clean Architecture (opt-in)

Skills `clean-architecture` e `java-test-layers` valem só quando:

1. O repositório já tem os módulos `domain`, `application` e `infrastructure`, ou use case abstrato com gateway no domínio.
2. O usuário pediu explicitamente para adotar esse modelo.

Fora desses casos, não crie esses módulos e não troque a estrutura existente.

## Recursos modernos do Java

- **Records**: data carriers imutáveis.
- **Sealed classes**: restringir hierarquias para pattern matching seguro.
- **Pattern matching**: `instanceof` e `switch` expressivos.
- **Text blocks**: `"""` para JSON, SQL, HTML multilinha.
- **Var**: inferência local quando o tipo é óbvio pelo RHS (`final var`).

## Estilo e nomenclatura

- Classes: `PascalCase`. Métodos e variáveis: `camelCase`. Constantes: `ALL_CAPS`.
- Siga os nomes que o pacote vizinho já usa (service, use case, repository, gateway).
- Injeção por construtor. Sem `@Autowired` em campo.

## Spring Boot

### Estrutura

Layout em camadas (`controllers` → `services` → `repositories` → `models` / `configurations`) quando o projeto já o usa.

Projeto com módulos `domain`, `application` e `infrastructure`, ou pedido explícito de Clean Architecture: siga `clean-architecture`, `clean-architecture-ddd` e `java-test-layers`. Esse layout em camadas não se aplica.

### Anotações e IoC

- `@SpringBootApplication`, `@RestController`, `@Service` quando o projeto já organiza a regra em services.
- `@ControllerAdvice` + `@ExceptionHandler` para erros.
- `application.yml` com profiles por ambiente. `@ConfigurationProperties` para config tipada.
- HTTP com status coerente. Bean Validation (`@Valid`) quando o projeto valida na borda.
- Springdoc para o contrato HTTP quando a API já o usa.
- Spring Data JPA e migrações com Flyway ou Liquibase, conforme o repositório.
- Spring Security e CORS no padrão já configurado. Não desligar segurança para teste passar.
- SLF4J. Actuator quando o serviço já expõe métricas.
- Java 17+. Spring Boot 3.x ou 4.x, conforme o projeto. Gradle ou Maven.

## JVM e performance

- GC: G1 padrão; ZGC/Shenandoah para baixa latência.
- Evitar alocação excessiva em loops críticos.
- Streams para coleções; parallel streams só em CPU-bound com datasets grandes.
- Cuidado com vazamentos: referências estáticas, coleções long-lived, recursos não fechados.

## Boas práticas

- **Imutabilidade**: `final` quando aplicável.
- **Optional**: tipo de retorno para ausência. Evitar em campo ou parâmetro.
- **Exceções**: tipadas. Sem `catch` genérico vazio.
- **SOLID**: skill `solid-principles`, sem impor um formato de pasta.

## Testes

JUnit 5 no layout que o projeto já tem (`@SpringBootTest`, `@DataJpaTest`, MockMvc, Testcontainers, testes puros). Não introduza tags `unitTest` / `integrationTest` / `e2eTest` nem as bases `UnitTest`, `UseCaseTest`, `@ControllerTest`, `@PostgreSQLGatewayTest` e `@E2ETest` se elas não existirem. Essas bases estão na skill `java-test-layers`, no mesmo critério opt-in da Clean Architecture.

## Verificação

- Formatação: `./gradlew spotlessApply` ou `./mvnw spotless:apply` quando o plugin existir.
- Testes: a task que o build já expõe. Se existirem `unitTests`, `integrationTests` ou `e2eTests`, use a da camada alterada. Senão `./gradlew test` ou `./mvnw test`.
- `ALL_TESTS_PASSED: true` só com exit code `0`.
