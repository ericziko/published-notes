---
created: 2025-10-07T02:04
updated: 2025-10-07T02:11
---
# Replacing FluentAssertions with Shouldly 

In the world of .NET development, writing clear and maintainable unit tests is crucial. Two popular assertion libraries that enhance the readability and expressiveness of your tests are FluentAssertions and Shouldly. While both libraries serve similar purposes, you may need to switch from FluentAssertions to Shouldly. This article will guide you through the process and highlight the key differences.

### Why Replace FluentAssertions with Shouldly?

FluentAssertions and Shouldly both provide a fluent syntax for writing assertions, making your tests more readable and expressive. However, there are a few reasons you might consider switching to Shouldly:

1. **Readability**: Shouldly’s syntax is designed to be more human-readable, making it easier to understand test failures.
2. **Community and Support**: Shouldly has a strong community and active support, which can benefit long-term projects.
3. **Licensing**: Recent changes in FluentAssertions’[2] licensing might prompt some developers to look for alternatives[[1]](https://github.com/shouldly/shouldly/issues/1034).

### Getting Started with Shouldly

To start using Shouldly, you need to install the package via NuGet. You can do this using the following command:

```csharp
dotnet add package Shouldly
```

### Replacing Assertions

Let’s look at some common assertions and how to replace them with Shouldly.

#### Equality Assertions

With FluentAssertions:

```cs
result.Should().Be(5);
```

With Shouldly:

```cs
result.ShouldBe(5);
```

#### Exception Assertions

With FluentAssertions:

```cs
Action action = () => calculator.Divide(10, 0);  
action.Should().Throw<ArgumentException>();
```

With Shouldly:

```cs
var exception = Should.Throw<ArgumentException>(() => calculator.Divide(10, 0));
```

#### Collection Assertions

With FluentAssertions:

```csharp
collection.Should().Contain(item);
```

With Shouldly:

```csharp
collection.ShouldContain(item);
```

### Conclusion

Switching from FluentAssertions to Shouldly can be straightforward and beneficial, especially if you value readability and community support. Following the examples above, you can easily replace your assertions and take advantage of Shouldly’s expressive syntax.
