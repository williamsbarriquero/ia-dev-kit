---
name: java-test-layers
description: >-
  Organiza testes Java em unitTest, integrationTest e e2eTest com classes base,
  tags JUnit e tasks Gradle. Use somente em serviço que já segue a skill
  clean-architecture, ou quando o usuário pede explicitamente esse modelo de
  testes. Não substitua a suíte de um projeto Java em outra arquitetura.
disable-model-invocation: true
---

# Camadas de teste Java

## Quando aplicar

Mesma condição da skill `clean-architecture`: o repositório já tem esse modelo, ou o usuário pediu para adotá-lo. Nos outros projetos Java, use o runner, os nomes e as bases de teste que já existem. Não introduza `UnitTest`, `@E2ETest` nem as tasks `unitTests` / `integrationTests` / `e2eTests`.

Quando a skill se aplica, a suíte acompanha os módulos de `clean-architecture`. Cada teste estende ou usa uma base já tagueada. Não crie outro `@SpringBootTest` solto.

## Tags e tasks

Convenção Gradle (`useJUnitPlatform` + tags):

| Tag | Task | O que roda |
|-----|------|------------|
| `unitTest` | `./gradlew unitTests` | domínio e use cases, sem Spring e sem banco |
| `integrationTest` | `./gradlew integrationTests` | controller slice, gateway JPA, Jackson, AMQP |
| `e2eTest` | `./gradlew e2eTests` | API sob o contexto inteiro, PostgreSQL via Testcontainers |

`./gradlew test` executa as três. Infra de teste que compartilha banco usa `maxParallelForks = 1`.

Perfil `test-integration`: H2 em memória (`MODE=PostgreSQL`), Flyway desligado, `ddl-auto: create-drop`.
Perfil `test-e2e`: PostgreSQL real. A porta vem de `E2EPostgreSQLExtension.mappedPort()` via `@DynamicPropertySource` (`postgres.port`). Se o Docker não estiver disponível, o teste é ignorado (`assumeTrue`), não marcado como sucesso falso.

## Onde cada teste mora

| Camada | Módulo | Classe base | Dependências |
|--------|--------|-------------|--------------|
| Domínio | `domain` | `UnitTest` (`@Tag("unitTest")`) | nenhuma. `ThrowsValidationHandler` para inválidos |
| Use case | `application` | `UseCaseTest` | `@Mock` do gateway, `@InjectMocks` do `Default*` |
| Controller | `infrastructure` | `@ControllerTest(controllers = X.class)` | `@MockitoBean` nos use cases, `MockMvc` |
| Gateway | `infrastructure` | `@PostgreSQLGatewayTest` | gateway e repository reais, H2 |
| E2E de API | `infrastructure` … `e2e.<agregado>` | `@E2ETest` | `MockMvc` + repository, banco limpo a cada teste |
| JSON de model | `infrastructure` | `@JacksonTest` | contrato do payload, sem web |
| Mensageria | `infrastructure` | `@AmqpTest` | broker de teste, sem regra de domínio |

`domain` publica o jar de teste (`configuration testClasses`). `application` e `infrastructure` dependem dele para reutilizar `Fixture`.

## Nomes

Teste de unidade e integração, um comportamento por método:

```text
givenAValidCommand_whenCallsCreateCategory_shouldReturnCategoryId
givenAnInvalidNullName_whenCallNewCategoryAndValidate_thenShouldReceiveError
```

E2E, frase do ator:

```text
asACatalogAdminIShouldBeAbleToCreateANewCategoryWithValidValues
```

Arrange com `expected*` explícito. Assert nos campos e, no use case, `verify` de que o gateway foi ou não chamado.

## Domínio (`extends UnitTest`)

Cubra a factory feliz, cada restrição do validator (null, vazio, tamanho) e os métodos de comportamento (`activate`, `deactivate`, `update`). Estado inválido passa por `validate(new ThrowsValidationHandler())` e espera `DomainException` com a mensagem e a quantidade de erros. Não mockar o agregado.

## Use case (`extends UseCaseTest`)

`UseCaseTest` aplica `MockitoExtension`, tag `unitTest`, e zera os mocks em `beforeEach`. O teste implementa `getMocks()` com os gateways.

Mínimo por operação de escrita:

1. caminho feliz — gateway devolve o agregado (`returnsFirstArg`) e o output expõe o id;
2. propriedade inválida — `getLeft()` tem o erro e o gateway **não** é chamado;
3. estado de borda relevante (ex.: inativo, `deletedAt` preenchido);
4. exceção do gateway vira `Notification`, sem estourar cru.

Consulta: encontrado e `NotFoundException`. Delete: id existente chama o gateway uma vez.

## Controller (`@ControllerTest`)

Meta-anotação: `@WebMvcTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test-integration")` + `@Tag("integrationTest")` + `@Import` do `ObjectMapper` do projeto. Atributo `controllers` limita o slice.

O teste implementa `ApiTest` e envia o JWT do papel (`ADMIN_JWT`, ou o papel do recurso). Mockar só os use cases abstratos. Casos: 201/200, 422 quando o use case devolve `Left`, 404 quando lança `NotFoundException`, 204 no delete. Não subir banco.

## Gateway (`@PostgreSQLGatewayTest`)

Meta-anotação: `@DataJpaTest` + `@ActiveProfiles("test-integration")` + `@Tag("integrationTest")` + `ComponentScan` só de classes `*PostgreSQLGateway` + `DatabaseCleanUpExtension`.

`DatabaseCleanUpExtension` dá `deleteAll` nos repositories antes de cada teste, na ordem que respeita FK (filhos antes dos pais).

Assert: `repository.count()`, agregado devolvido e entidade relida do banco. Cobrir create, update, find, delete idempotente e `findAll` com `SearchQuery` (página, ordenação, termo).

## E2E (`@E2ETest`)

Meta-anotação: `@SpringBootTest` na config do servidor + `@AutoConfigureMockMvc` + `@ActiveProfiles("test-e2e")` + `@Tag("e2eTest")` + `E2EPostgreSQLExtension` + `DatabaseCleanUpExtension`.

`E2EPostgreSQLExtension` sobe um PostgreSQL compartilhado (`postgres:16`) no store raiz do JUnit e encerra no fim da suíte. O teste registra a porta mapeada e confirma `isRunning()` e `count() == 0` no início.

Fluxo pelo HTTP (`MockDsl`: `givenACategory`, `listCategories`, …), depois conferência no repository. Não mockar use case nem gateway. Não usar `Thread.sleep`.

Playwright e Cypress não cobrem este E2E. A skill `e2e-testing` vale para UI.

## O que não fazer

- Testar use case com `@SpringBootTest`.
- Apontar gateway ou E2E para um Postgres manual sem a extension.
- Compartilhar linha entre testes. Cada método assume banco vazio.
- Desligar segurança para o teste passar.
- Marcar `ALL_TESTS_PASSED` sem exit code `0` da task da camada alterada (`tdd-grinder`).
