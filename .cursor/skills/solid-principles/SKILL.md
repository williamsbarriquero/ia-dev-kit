---
name: solid-principles
description: Practical fundamentals of SOLID object-oriented design.
disable-model-invocation: true
---

# SOLID Principles

## Overview
SOLID is an acronym for five design principles intended to make software designs more understandable, flexible, and maintainable.

## 1. Single Responsibility Principle (SRP)
*A class should have one, and only one, reason to change.*
- **Definition**: Every module or class should have responsibility over a single part of the functionality provided by the software.
- **Heuristic**: If you can think of more than one motive for changing a class, then that class has more than one responsibility.
- **Violation Example**: A class that handles both formatting a report and printing it to an output stream.

## 2. Open/Closed Principle (OCP)
*Software entities should be open for extension, but closed for modification.*
- **Definition**: You should be able to extend a class's behavior without modifying it.
- **Heuristic**: Use polymorphism. Instead of writing `if/switch` statements based on object types, create an abstraction and implement it differently.
- **Violation Example**: A class calculating shipping costs that needs to be modified every time a new courier service is added.

## 3. Liskov Substitution Principle (LSP)
*Objects in a program should be replaceable with instances of their subtypes without altering the correctness of that program.*
- **Definition**: Subclasses must be substitutable for their base classes.
- **Heuristic**: If an override method does nothing or throws an exception just because it's a subclass, you are probably violating LSP.
- **Violation Example**: A `Square` class inheriting from `Rectangle` where setting the width also modifies the height, breaking the expectations of code working with `Rectangle`.

## 4. Interface Segregation Principle (ISP)
*Many client-specific interfaces are better than one general-purpose interface.*
- **Definition**: Clients should not be forced to depend upon interfaces that they do not use.
- **Heuristic**: Fat interfaces should be broken down into smaller, highly cohesive interfaces.
- **Violation Example**: A monolithic `Worker` interface with `work()`, `eat()`, and `sleep()` methods implemented by a `Robot` class (robots don't eat or sleep).

## 5. Dependency Inversion Principle (DIP)
*Depend upon abstractions, not concretions.*
- **Definition**: High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions.
- **Heuristic**: Inject dependencies via constructors rather than instantiating concrete classes inside high-level modules.
- **Violation Example**: A `PaymentService` class directly instantiating a `StripeClient` class.
