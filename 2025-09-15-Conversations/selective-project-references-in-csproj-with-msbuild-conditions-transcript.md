---
created: 2025-09-15T14:38
updated: 2025-09-15T14:41
title: selective-project-references-in-csproj-with-msbuild-conditions-transcript
date created: Monday, September 15th 2025, 9:38:14 pm
date modified: Monday, September 15th 2025, 9:41:44 pm
---

# selective-project-references-in-csproj-with-msbuild-conditions-transcript

**User:**  
Is there a way to selectively include or exclude reference csharp projects in csproj files with compiler directives 

**Assistant:**  
Short answer: you can't use C# `#if` / "compiler directives" inside a `.csproj`. Those live in source files. But you *can* do the equivalent with **MSBuild conditions** in the project file: turn features on/off via properties, then conditionally include/exclude `<ProjectReference>` (or whole `<ItemGroup>`s).

Here are solid patterns.

## 1) Flip references with a custom property
Define a property (from CLI, environment, or inside the project), and gate the reference.

```xml
<!-- MyApp.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <!-- Default off; can override with /p:IncludeFoo=true -->
    <IncludeFoo>false</IncludeFoo>
  </PropertyGroup>

  <ItemGroup Condition="'$(IncludeFoo)' == 'true'">
    <ProjectReference Include="..\Foo\Foo.csproj" />
  </ItemGroup>
</Project>
```

Builds:
```bash
dotnet build MyApp.csproj /p:IncludeFoo=true
```

## 2) Condition directly on common built-ins
You can key off `$(Configuration)`, `$(Platform)`, or `$(TargetFramework)` / `$(TargetFrameworks)`.

```xml
<ItemGroup Condition="'$(Configuration)' == 'Debug'">
  <ProjectReference Include="..\DebugOnly\DebugOnly.csproj" />
</ItemGroup>

<ProjectReference Include="..\Net8Only\Net8Only.csproj"
                 Condition="'$(TargetFramework)' == 'net8.0'" />
```

With multi-targeting:

```xml
<PropertyGroup>
  <TargetFrameworks>net8.0;net9.0</TargetFrameworks>
</PropertyGroup>

<ItemGroup Condition="'$(TargetFramework)' == 'net9.0'">
  <ProjectReference Include="..\VNext\VNext.csproj" />
</ItemGroup>
```

## 3) Use `Choose/When/Otherwise` if you prefer branching blocks
Handy when the logic is mutually exclusive.

```xml
<Choose>
  <When Condition="'$(UseImpl)' == 'A'">
    <ItemGroup>
      <ProjectReference Include="..\ImplA\ImplA.csproj" />
    </ItemGroup>
  </When>
  <When Condition="'$(UseImpl)' == 'B'">
    <ItemGroup>
      <ProjectReference Include="..\ImplB\ImplB.csproj" />
    </ItemGroup>
  </When>
  <Otherwise>
    <!-- no reference or a default -->
  </Otherwise>
</Choose>
```

Invoke with:
```bash
dotnet build /p:UseImpl=A
```

## 4) If you *must* mirror `DefineConstants`
You can read the `DefineConstants` MSBuild property and condition on it. It's a plain string, so use an MSBuild property function to "contains"-check.

```xml
<PropertyGroup>
  <DefineConstants>$(DefineConstants);FEATURE_FOO</DefineConstants>
</PropertyGroup>

<ProjectReference Include="..\Foo\Foo.csproj"
  Condition="$([System.String]::Copy('$(DefineConstants)')).Contains('FEATURE_FOO')" />
```

This works, but it's brittle (string matching). Prefer a dedicated property like `IncludeFoo`.

## 5) Centralize the switches (team-friendly)
Drop them in `Directory.Build.props` so every project can share the same feature flag:

```xml
<!-- Directory.Build.props at the repo root -->
<Project>
  <PropertyGroup>
    <IncludeFoo>false</IncludeFoo>
  </PropertyGroup>
</Project>
```

Then in any project:

```xml
<ItemGroup Condition="'$(IncludeFoo)' == 'true'">
  <ProjectReference Include="..\Foo\Foo.csproj" />
</ItemGroup>
```

## 6) Visual Studio & design-time behavior
- SDK-style projects respect these conditions in solution view for the *active* configuration/TFM. Switch config/TFM to see different references.
- Design-time build follows the same rules; IntelliSense resolves accordingly.
- CI builds can pass `/p:` flags to pin the topology for a given pipeline stage.

---

If your goal is "compile without this transitive code for certain builds," this is the right approach. If your goal is "always reference it, but don't include its outputs," that's a different lever (targets/props phases or, for packages, `ExcludeAssets`).  

Next step ideas: wire a small feature-matrix (props file) to toggle whole stacks, or set up multi-TFM with per-TFM references for clean compat fences.
