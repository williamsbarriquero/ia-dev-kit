---
name: java-mastery
description: Modern Java engineering practices and ecosystem knowledge.
disable-model-invocation: true
---

# Java Mastery

## Modern Java Features
- **Records**: Use `record` for immutable data carriers. It drastically reduces boilerplate (getters, `equals`, `hashCode`, `toString`).
- **Sealed Classes**: Use `sealed` classes and interfaces to restrict which classes may extend or implement them, enabling safer pattern matching.
- **Pattern Matching**: Use pattern matching for `instanceof` and in `switch` expressions to write cleaner, more expressive logic.
- **Text Blocks**: Use `"""` for multi-line strings (JSON, SQL, HTML) to avoid messy concatenation and escaping.
- **Var**: Use local variable type inference (`var`) when the type is obvious from the right-hand side, improving readability.

## JVM & Performance
- **Garbage Collection**: Understand the basic GC algorithms (G1GC is default, ZGC/Shenandoah for low-latency). Avoid unnecessary object creation in hot loops.
- **Memory Leaks**: Beware of keeping object references in static fields, long-lived collections, or unclosed resources.
- **Streams API**: Use Streams for functional-style operations on collections. Be careful with parallel streams; they are only beneficial for CPU-intensive tasks on large datasets.

## Ecosystem & Frameworks
- **Spring Boot**: The standard for enterprise Java. Use constructor injection instead of `@Autowired` on fields. Keep controllers lean, delegating business logic to services.
- **Build Tools**: Use Maven or Gradle. Keep dependency management clean and structured.
- **Testing**: Use JUnit 5 and AssertJ. Utilize Testcontainers for integration testing against real databases/services instead of in-memory mocks like H2.

## Best Practices
- **Immutability**: Prefer immutable objects. Use `final` where applicable.
- **Optional**: Use `Optional` as a return type to indicate that a value might be missing. Avoid using `Optional` as field types or method parameters.
- **Exceptions**: Use unchecked exceptions (extending `RuntimeException`) for business logic errors. Checked exceptions should be reserved for recoverable environmental errors (though their usage is generally declining in modern Java).
