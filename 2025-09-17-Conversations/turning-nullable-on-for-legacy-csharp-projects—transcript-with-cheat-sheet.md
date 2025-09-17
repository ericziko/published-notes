---
created: 2025-09-17T15:23
updated: 2025-09-17T15:24
---
# turning-nullable-on-for-legacy-csharp-projects—transcript-with-cheat-sheet

*I flipped on nullable and my bugs disappeared—turns out they were just avoiding commitment.*

---

## Conversation

**User:**  
When turning nullabe on for legacy c# projects should I start from the top down or the bottom in my project dependency graph

**Assistant:**  
Think of turning nullable reference types on like flipping on the lights in an old basement—you’ll see cobwebs no matter where you start, but *where* you start matters for how the cleanup cascades.  

(...full explanation of bottom-up vs top-down, pragmatic approach, and analogy...)

**Assistant:**  
Do you want me to sketch out a step-by-step phased strategy (like a migration playbook) for enabling nullable across a multi-project solution?

**User:**  
Yes

**Assistant:**  
Sweet—here’s a pragmatic, bottom-up migration playbook you can actually run.

---

## Migration Playbook (Phased Strategy)

### Phase 0 — Prep & inventory (1–2 hours)
- Map the graph with project references.  
- Tag generated/interop/test code for special handling.  
- Capture baseline nullable warning counts.

```bash
dotnet build -nologo /clp:Summary /warnaserror- | tee build.log
rg -N "CS8(6|7)\d{2}" build.log | wc -l
```

### Phase 1 — Solution-wide guardrails
Centralize config with `Directory.Build.props`:

```xml
<Project>
  <PropertyGroup>
    <Nullable>disable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <AnalysisMode>AllEnabledByDefault</AnalysisMode>
    <WarningsAsErrors></WarningsAsErrors>
  </PropertyGroup>
</Project>
```

Configure `.editorconfig` severities:

```ini
dotnet_diagnostic.CS8600.severity = warning
dotnet_diagnostic.CS8602.severity = warning
dotnet_diagnostic.CS8603.severity = warning
dotnet_diagnostic.CS8618.severity = warning
dotnet_diagnostic.CS8625.severity = warning
dotnet_diagnostic.CS8774.severity = warning
```

Suppress noisy EF/interop issues in `GlobalSuppressions.cs`:

```csharp
[assembly: SuppressMessage("Nullable", "CS8618", Justification = "EF Core materializes these")]
```

### Phase 2 — Bottom-up migration loop
Enable nullable in a leaf project:

```xml
<PropertyGroup>
  <Nullable>enable</Nullable>
</PropertyGroup>
```

Annotate contracts, harden inputs/outputs, use attributes:

```csharp
public static bool TryFind(string key, [NotNullWhen(true)] out Item? item) { ... }
```

Fence off generated code:

```csharp
#nullable disable
// generated
#nullable restore
```

Enforce no regressions in CI:

```bash
dotnet build src/LeafProject/LeafProject.csproj /warnaserror:CS8600,CS8602,CS8603,CS8618,CS8625,CS8774
```

### Phase 3 — Integrate upward
Consume updated libs, replace `!` with checks, add null-edge tests.

### Phase 4 — Entry points
Flip UI/API projects last. Annotate DTOs, enforce `required` where needed.

### Phase 5 — Tighten & clean up
Promote warnings to errors globally:

```xml
<WarningsAsErrors>CS8600;CS8602;CS8603;CS8618;CS8625;CS8774</WarningsAsErrors>
```

Remove temporary disables, prune suppressions.

---

## Cheat Sheet

### Nullable Workflow
- Start **bottom-up** in the dependency graph.  
- Quarantine generated/interop code.  
- Annotate public APIs first, then internal.  
- Use attributes like `NotNullWhen`, `MaybeNull`, `MemberNotNull`.  
- Harden inputs with `ArgumentNullException.ThrowIfNull`.  
- Guard once at the boundary, then trust contracts.  
- Promote CS86xx/CS87xx warnings to errors gradually.  

### Handy Codes
- CS8600: convert null to non-nullable  
- CS8602: possible null dereference  
- CS8603: possible null return  
- CS8618: uninitialized non-nullable field  
- CS8625: cannot assign null to non-nullable  
- CS8774: member must have non-null value  

### Reusable Snippets
Normalize strings:
```csharp
public static string? NullIfWhiteSpace(string? s) =>
    string.IsNullOrWhiteSpace(s) ? null : s;
```

Argument guard:
```csharp
public static T NotNull<T>(T? value, string name) where T : class
{
    ArgumentNullException.ThrowIfNull(value, name);
    return value;
}
```

Option type:
```csharp
public readonly record struct Maybe<T>(T? Value)
{
    public bool HasValue => Value is not null;
    public static Maybe<T> None => new(default);
    public static implicit operator Maybe<T>(T value) => new(value);
}
```

---

## Clarifying Notes
- Transcript is labeled with **User** and **Assistant** for readability.  
- Full content preserved with added cheat sheet at the end.  
