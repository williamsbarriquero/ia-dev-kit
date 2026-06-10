---
name: design-patterns
description: Catalog of GoF design patterns and enterprise architectures.
disable-model-invocation: true
---

# Design Patterns

## Core Philosophy

Design patterns are typical solutions to common problems in software design. They are like pre-made blueprints that you can customize to solve a recurring design problem in your code.

**Crucial Warning**: Do not apply patterns unnecessarily. Overengineering is a common pitfall. Apply a pattern only if the problem it solves exists in your domain and the pattern simplifies the code or makes it significantly more maintainable.

## Creational Patterns
Deal with object creation mechanisms, trying to create objects in a manner suitable to the situation.
- **Singleton**: Ensure a class only has one instance, and provide a global point of access to it. (Use sparingly).
- **Factory Method**: Define an interface for creating an object, but let subclasses decide which class to instantiate.
- **Abstract Factory**: Provide an interface for creating families of related or dependent objects without specifying their concrete classes.
- **Builder**: Separate the construction of a complex object from its representation so that the same construction process can create different representations.
- **Prototype**: Specify the kinds of objects to create using a prototypical instance, and create new objects by copying this prototype.

## Structural Patterns
Deal with object composition or the way to realize relationships between entities.
- **Adapter**: Convert the interface of a class into another interface clients expect.
- **Bridge**: Decouple an abstraction from its implementation so that the two can vary independently.
- **Composite**: Compose objects into tree structures to represent part-whole hierarchies.
- **Decorator**: Attach additional responsibilities to an object dynamically.
- **Facade**: Provide a unified interface to a set of interfaces in a subsystem.
- **Proxy**: Provide a surrogate or placeholder for another object to control access to it.

## Behavioral Patterns
Deal with communication between objects.
- **Observer**: Define a one-to-many dependency between objects so that when one object changes state, all its dependents are notified and updated automatically.
- **Strategy**: Define a family of algorithms, encapsulate each one, and make them interchangeable.
- **Command**: Encapsulate a request as an object, thereby letting you parameterize clients with different requests, queue or log requests, and support undoable operations.
- **State**: Allow an object to alter its behavior when its internal state changes.
- **Chain of Responsibility**: Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request.
