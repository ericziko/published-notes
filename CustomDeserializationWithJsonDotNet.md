# Transcript: Custom Deserialization with System.Text.Json

**User:** Tell me bout custom deserialization with System.Text.JSON (or
whichever json library is built into .Net)

**Assistant:**\
`System.Text.Json` is the JSON library that ships with .NET Core 3.0+
and .NET 5+. It's built for speed and low allocations, but it's also
stricter and less magical than `Newtonsoft.Json`. By default, it handles
most POCO (plain old C# object) serialization/deserialization just fine,
but when you need **custom deserialization**, you typically write a
`JsonConverter`.

Here's how it works in practice:

------------------------------------------------------------------------

### The `JsonConverter<T>`

A `JsonConverter<T>` lets you hook into how a specific type is
deserialized (and serialized). Think of it as a translator for when the
built-in parser doesn't know how to handle a type or when you want more
control.

Example: Suppose your JSON has a date stored as `"2025-08-25T10:30Z"`
but you want to parse it into a `DateOnly` (which `System.Text.Json`
doesn't natively handle before .NET 8).

``` csharp
using System;
using System.Text.Json;
using System.Text.Json.Serialization;

public class DateOnlyConverter : JsonConverter<DateOnly>
{
    private const string Format = "yyyy-MM-dd";

    public override DateOnly Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        var value = reader.GetString();
        return DateOnly.ParseExact(value!, Format);
    }

    public override void Write(
        Utf8JsonWriter writer,
        DateOnly value,
        JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToString(Format));
    }
}
```

Then register it:

``` csharp
var options = new JsonSerializerOptions
{
    Converters = { new DateOnlyConverter() }
};

var obj = JsonSerializer.Deserialize<MyRecord>(json, options);
```

------------------------------------------------------------------------

### Inline "manual" deserialization

Sometimes you don't need a converter for every use, just a quick
hand-rolled parse. You can use `JsonDocument` to walk the DOM-like
structure:

``` csharp
using var doc = JsonDocument.Parse(json);
var root = doc.RootElement;
string name = root.GetProperty("user").GetProperty("name").GetString();
int age = root.GetProperty("user").GetProperty("age").GetInt32();
```

This is handy for small tweaks without changing model classes.

------------------------------------------------------------------------

### Polymorphic Deserialization

One big pain point: `System.Text.Json` doesn't automatically handle
polymorphic types (e.g. base class `Animal` with subclasses `Cat` and
`Dog`). You need a custom converter that inspects the JSON and decides
which concrete type to instantiate:

``` csharp
public class AnimalConverter : JsonConverter<Animal>
{
    public override Animal Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        using var doc = JsonDocument.ParseValue(ref reader);
        var type = doc.RootElement.GetProperty("type").GetString();

        return type switch
        {
            "cat" => JsonSerializer.Deserialize<Cat>(doc.RootElement.GetRawText(), options)!,
            "dog" => JsonSerializer.Deserialize<Dog>(doc.RootElement.GetRawText(), options)!,
            _ => throw new JsonException("Unknown animal type")
        };
    }

    public override void Write(
        Utf8JsonWriter writer,
        Animal value,
        JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, (object)value, options);
    }
}
```

------------------------------------------------------------------------

### Key takeaways

-   **For special types**: Write a `JsonConverter<T>`.
-   **For occasional tweaks**: Use `JsonDocument` to walk the JSON
    yourself.
-   **For polymorphic hierarchies**: A custom converter is almost always
    needed.

`System.Text.Json` has caught up in features compared to Newtonsoft, but
it's still less forgiving. If you want everything to "just work" with
exotic JSON, Newtonsoft is easier. If you want speed and native support,
stick with `System.Text.Json`.

------------------------------------------------------------------------

**Assistant:** Would you like me to show you a **complete working demo**
of custom deserialization (e.g., JSON with nested arrays into C#
objects), or more of a **cheat sheet of patterns** for different tricky
scenarios (dates, enums, polymorphism, etc.)?

**User:** Please create a transcript of this entire conversation in a
markdown document called CustomDeserializationWithJsonDotNet.md for me
to download
