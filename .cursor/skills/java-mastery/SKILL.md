---
name: java-mastery
description: Práticas modernas de engenharia Java e conhecimento do ecossistema.
disable-model-invocation: true
---

# Java Mastery

## Recursos Modernos do Java

- **Records**: Use `record` para data carriers imutáveis. Reduz drasticamente boilerplate (getters, `equals`, `hashCode`, `toString`).
- **Sealed Classes**: Use classes e interfaces `sealed` para restringir quais classes podem estendê-las ou implementá-las, permitindo pattern matching mais seguro.
- **Pattern Matching**: Use pattern matching para `instanceof` e em expressões `switch` para lógica mais limpa e expressiva.
- **Text Blocks**: Use `"""` para strings multilinha (JSON, SQL, HTML) e evitar concatenação e escape confusos.
- **Var**: Use inferência de tipo local (`var`) quando o tipo for óbvio pelo lado direito da atribuição, melhorando a legibilidade.

## JVM e Performance

- **Garbage Collection**: Entenda os algoritmos básicos de GC (G1GC é o padrão; ZGC/Shenandoah para baixa latência). Evite criação desnecessária de objetos em loops críticos.
- **Vazamentos de memória**: Cuidado ao manter referências em campos estáticos, coleções de longa duração ou recursos não fechados.
- **Streams API**: Use Streams para operações funcionais em coleções. Cuidado com parallel streams; só são benéficos para tarefas CPU-intensive em datasets grandes.

## Ecossistema e Frameworks

- **Spring Boot**: Padrão para Java enterprise. Use injeção por construtor em vez de `@Autowired` em campos. Mantenha controllers enxutos, delegando lógica de negócio a services.
- **Build Tools**: Use Maven ou Gradle. Mantenha gestão de dependências limpa e estruturada.
- **Testes**: Use JUnit 5 e AssertJ. Utilize Testcontainers para testes de integração contra bancos/serviços reais em vez de mocks in-memory como H2.

## Boas Práticas

- **Imutabilidade**: Prefira objetos imutáveis. Use `final` quando aplicável.
- **Optional**: Use `Optional` como tipo de retorno para indicar que um valor pode estar ausente. Evite `Optional` como tipo de campo ou parâmetro de método.
- **Exceções**: Use exceções unchecked (estendendo `RuntimeException`) para erros de lógica de negócio. Exceções checked devem ser reservadas para erros ambientais recuperáveis (embora seu uso esteja em declínio no Java moderno).
