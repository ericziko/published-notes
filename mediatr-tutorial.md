# MediatR-tutorial

> give me a tutorial on mediatr in c#

# Assistant
MediatR is a tiny library that implements the **mediator pattern** for .NET. Instead of controllers/services calling each other directly, they send strongly-typed **requests** to a single **mediator**, which dispatches them to a **handler**. You get decoupling, testability, and nice choke-points for cross-cutting concerns (logging, validation, caching) via **pipeline behaviors**.

---

## 1) When you should (and shouldn't) use it

**Great for**
- CQRS-style apps where reads/writes are separate and each use case is a "message".
- Modularizing business logic away from controllers and UI.
- Adding cross-cutting concerns in one place (validation/logging/retries/metrics).

**Be cautious if**
- You only have a handful of endpoints and simple logic (plain services may be simpler).
- You start using it as a **global service locator** (anti-pattern).
- You cram multiple responsibilities into one handler (keep them narrow!).

---

## 2) Install & wire up

**Package**
```bash
dotnet add package MediatR
```

**ASP.NET Core registration (Program.cs)**
```csharp
using MediatR;

var builder = WebApplication.CreateBuilder(args);

// Registers handlers/pipeline behaviors found in the given assemblies
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly);
    // You can add behaviors here: cfg.AddOpenBehavior(typeof(LoggingBehavior<,>));
});

var app = builder.Build();
app.MapGet("/", () => "OK");
app.Run();
```

> Tip: if your handlers live in another project, pass that assembly's marker type to `RegisterServicesFromAssembly`.

---

## 3) Hello, IRequest + IRequestHandler

**Request (command)**
```csharp
using MediatR;

public record CreateUserCommand(string Email, string DisplayName) : IRequest<Guid>;
```

**Handler**
```csharp
using MediatR;

public class CreateUserHandler : IRequestHandler<CreateUserCommand, Guid>
{
    private readonly IUserRepository _repo;
    public CreateUserHandler(IUserRepository repo) => _repo = repo;

    public async Task<Guid> Handle(CreateUserCommand request, CancellationToken ct)
    {
        var userId = Guid.NewGuid();
        await _repo.CreateAsync(userId, request.Email, request.DisplayName, ct);
        return userId;
    }
}
```

**Controller (or Minimal API)**
```csharp
// Minimal API example inside Program.cs
app.MapPost("/users", async (CreateUserCommand cmd, IMediator mediator, CancellationToken ct)
    => Results.Ok(await mediator.Send(cmd, ct)));
```

- `IRequest<TResponse>` marks a message with a single response.
- `Send()` dispatches exactly one handler.

---

## 4) Queries vs Commands (CQRS-style)

Keep writes and reads separate for clarity and performance tuning.

**Query**
```csharp
public record GetUserByIdQuery(Guid Id) : IRequest<UserDto>;

public class GetUserByIdHandler : IRequestHandler<GetUserByIdQuery, UserDto>
{
    private readonly IDbConnection _db; // or EF DbContext
    public GetUserByIdHandler(IDbConnection db) => _db = db;

    public async Task<UserDto> Handle(GetUserByIdQuery q, CancellationToken ct)
    {
        // ...do read (Dapper/EF/whatever)
        return await LoadUser(q.Id, ct);
    }
}
```

Route:
```csharp
app.MapGet("/users/{id:guid}",
    async (Guid id, IMediator mediator, CancellationToken ct)
        => Results.Ok(await mediator.Send(new GetUserByIdQuery(id), ct)));
```

---

## 5) Notifications (publish/subscribe)

For "fan-out" events where **0..N** handlers may respond.

```csharp
public record UserCreated(Guid UserId) : INotification;

public class SendWelcomeEmail : INotificationHandler<UserCreated>
{
    public Task Handle(UserCreated n, CancellationToken ct)
    {
        // send email
        return Task.CompletedTask;
    }
}

public class WarmCache : INotificationHandler<UserCreated>
{
    public Task Handle(UserCreated n, CancellationToken ct)
    {
        // prime cache
        return Task.CompletedTask;
    }
}
```

Publish from a handler:
```csharp
await _mediator.Publish(new UserCreated(userId), ct);
```

---

## 6) Pipeline Behaviors (your superpower)

Behaviors wrap every `Send()` call, forming a chain. Perfect for **logging**, **validation**, **authorization**, **caching**, **metrics**, **retries**.

**Logging behavior**
```csharp
using MediatR;

public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest,TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest,TResponse>> _log;
    public LoggingBehavior(ILogger<LoggingBehavior<TRequest,TResponse>> log) => _log = log;

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken ct)
    {
        var name = typeof(TRequest).Name;
        _log.LogInformation("Handling {RequestName} {@Request}", name, request);
        var response = await next();
        _log.LogInformation("Handled {RequestName}", name);
        return response;
    }
}
```

**Register the behavior**
```csharp
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly);
    cfg.AddOpenBehavior(typeof(LoggingBehavior<,>));
});
```

**Validation with FluentValidation** (common pattern)
```bash
dotnet add package FluentValidation
dotnet add package FluentValidation.DependencyInjectionExtensions
```
```csharp
using FluentValidation;
using MediatR;

public record CreateOrderCommand(Guid UserId, decimal Amount) : IRequest<Guid>;

public class CreateOrderValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.Amount).GreaterThan(0);
    }
}

// Validation behavior (generic)
public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest,TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;
    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators) => _validators = validators;

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        if (_validators.Any())
        {
            var ctx = new FluentValidation.ValidationContext<TRequest>(request);
            var failures = (await Task.WhenAll(_validators.Select(v => v.ValidateAsync(ctx, ct))))
                           .SelectMany(r => r.Errors).Where(f => f != null).ToList();
            if (failures.Count != 0)
                throw new ValidationException(failures);
        }
        return await next();
    }
}
```

Register both:
```csharp
builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly);
    cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
    cfg.AddOpenBehavior(typeof(LoggingBehavior<,>));
});
```

> Behaviors run in the order registered.

---

## 7) EF Core example with transactions

Let's wire a command that updates two aggregates atomically.

```csharp
public record TransferMoney(Guid FromId, Guid ToId, decimal Amount) : IRequest;

public class TransferMoneyHandler : IRequestHandler<TransferMoney>
{
    private readonly BankingDbContext _db;
    private readonly IMediator _mediator;
    public TransferMoneyHandler(BankingDbContext db, IMediator mediator)
        => (_db, _mediator) = (db, mediator);

    public async Task<Unit> Handle(TransferMoney cmd, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var from = await _db.Accounts.FindAsync([cmd.FromId], ct)
                   ?? throw new KeyNotFoundException("From account not found");
        var to   = await _db.Accounts.FindAsync([cmd.ToId], ct)
                   ?? throw new KeyNotFoundException("To account not found");

        if (from.Balance < cmd.Amount) throw new InvalidOperationException("Insufficient funds");

        from.Balance -= cmd.Amount;
        to.Balance   += cmd.Amount;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        await _mediator.Publish(new MoneyTransferred(cmd.FromId, cmd.ToId, cmd.Amount), ct);
        return Unit.Value;
    }
}

public record MoneyTransferred(Guid From, Guid To, decimal Amount) : INotification;
```

> Whether you use explicit transactions or rely on `SaveChanges` semantics depends on your consistency needs. Keep handlers **idempotent** if they might be retried.

---

## 8) Streaming requests (for large/result sets)

MediatR supports **`IStreamRequest<T>`** for async streams:

```csharp
public record StreamUsers : IStreamRequest<UserDto>;

public class StreamUsersHandler : IStreamRequestHandler<StreamUsers, UserDto>
{
    private readonly AppDbContext _db;
    public StreamUsersHandler(AppDbContext db) => _db = db;

    public async IAsyncEnumerable<UserDto> Handle(StreamUsers request, CancellationToken ct)
    {
        await foreach (var u in _db.Users.AsAsyncEnumerable().WithCancellation(ct))
            yield return new UserDto(u.Id, u.Email);
    }
}
```

Usage:
```csharp
await foreach (var user in mediator.CreateStream(new StreamUsers(), ct))
{
    // process as they come in
}
```

---

## 9) Testing handlers cleanly

Because handlers are just classes, you can test them in isolation.

```csharp
[Fact]
public async Task CreateUser_Returns_Id_And_Persists()
{
    var fakeRepo = Substitute.For<IUserRepository>();
    var handler = new CreateUserHandler(fakeRepo);

    var id = await handler.Handle(new CreateUserCommand("e@x.com", "Eric"), default);

    await fakeRepo.Received(1).CreateAsync(id, "e@x.com", "Eric", Arg.Any<CancellationToken>());
    Assert.NotEqual(Guid.Empty, id);
}
```

You rarely need to mock `IMediator` except when a handler publishes notifications or sends sub-requests—prefer testing behavior, not implementation detail.

---

## 10) Cross-cutting patterns you'll actually use

- **Caching**: put a caching `IPipelineBehavior` in front of read queries (key by request + version). Bust on writes.
- **Authorization**: behavior that checks roles/claims against attributes on the request.
- **Metrics/Tracing**: time each request, add tags (request name, success/failure). Great with OpenTelemetry.
- **Idempotency**: behavior that checks a dedupe key and short-circuits duplicates.
- **Retries**: behavior that wraps `next()` in Polly policies.

---

## 11) Common pitfalls (and how to dodge them)

- **God-handlers**: keep handlers tiny. One use case per handler.
- **Anemic requests**: use records with meaningful data, not just IDs—push validation to the edge.
- **Leaky abstractions**: don't return EF entities to controllers; map to DTOs.
- **Mediator as a service locator**: don't `Send` from everywhere. Most composition should happen inside handlers, not controllers calling mediator 7 times.
- **Over-validation**: centralize with a validation behavior; avoid hand-rolled checks scattered around.

---

## 12) Minimal working sample (copy-paste starter)

**Create project**
```bash
dotnet new webapi -n MediatrDemo
cd MediatrDemo
dotnet add package MediatR
dotnet add package FluentValidation
dotnet add package FluentValidation.DependencyInjectionExtensions
```

**Program.cs**
```csharp
using FluentValidation;
using MediatR;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(Program).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);
builder.Services.AddSingleton<IUserRepository, InMemoryUsers>();

builder.Services.AddLogging();

var app = builder.Build();

app.MapPost("/users", async (CreateUserCommand cmd, IMediator mediator, CancellationToken ct)
    => Results.Ok(await mediator.Send(cmd, ct)));

app.MapGet("/users/{id:guid}", async (Guid id, IMediator mediator, CancellationToken ct)
    => Results.Ok(await mediator.Send(new GetUserQuery(id), ct)));

app.Run();

public record CreateUserCommand(string Email, string Name) : IRequest<Guid>;
public record GetUserQuery(Guid Id) : IRequest<UserDto>;
public record UserDto(Guid Id, string Email, string Name);

public class CreateUserValidator : AbstractValidator<CreateUserCommand>
{
    public CreateUserValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
    }
}

public class CreateUserHandler : IRequestHandler<CreateUserCommand, Guid>
{
    private readonly IUserRepository _repo;
    private readonly IMediator _mediator;
    public CreateUserHandler(IUserRepository repo, IMediator mediator)
        => (_repo, _mediator) = (repo, mediator);

    public async Task<Guid> Handle(CreateUserCommand cmd, CancellationToken ct)
    {
        var id = Guid.NewGuid();
        await _repo.SaveAsync(new(id, cmd.Email, cmd.Name), ct);
        await _mediator.Publish(new UserCreated(id), ct);
        return id;
    }
}

public class GetUserHandler : IRequestHandler<GetUserQuery, UserDto>
{
    private readonly IUserRepository _repo;
    public GetUserHandler(IUserRepository repo) => _repo = repo;

    public async Task<UserDto> Handle(GetUserQuery q, CancellationToken ct)
    {
        var user = await _repo.LoadAsync(q.Id, ct) ?? throw new KeyNotFoundException();
        return new(user.Id, user.Email, user.Name);
    }
}

public record UserCreated(Guid UserId) : INotification;

public class SendWelcomeEmail : INotificationHandler<UserCreated>
{
    private readonly ILogger<SendWelcomeEmail> _log;
    public SendWelcomeEmail(ILogger<SendWelcomeEmail> log) => _log = log;

    public Task Handle(UserCreated n, CancellationToken ct)
    {
        _log.LogInformation("Welcome email queued for {UserId}", n.UserId);
        return Task.CompletedTask;
    }
}

public interface IUserRepository
{
    Task SaveAsync(User user, CancellationToken ct);
    Task<User?> LoadAsync(Guid id, CancellationToken ct);
}

public record User(Guid Id, string Email, string Name);

public class InMemoryUsers : IUserRepository
{
    private readonly Dictionary<Guid, User> _store = new();
    public Task SaveAsync(User user, CancellationToken ct) { _store[user.Id] = user; return Task.CompletedTask; }
    public Task<User?> LoadAsync(Guid id, CancellationToken ct) => Task.FromResult(_store.TryGetValue(id, out var u) ? u : null);
}
```

Run it:
```bash
dotnet run
# POST /users with JSON: {"email":"eric@example.com","name":"Eric"}
# GET  /users/{id}
```

---

## 13) Folder structure that scales nicely

```
/Application
  /Users
    CreateUser
      CreateUserCommand.cs
      CreateUserHandler.cs
      CreateUserValidator.cs
    GetUser
      GetUserQuery.cs
      GetUserHandler.cs
  /Common
    Behaviors
      LoggingBehavior.cs
      ValidationBehavior.cs
/Domain
  User.cs
/Infrastructure
  Ef
    AppDbContext.cs
    UserRepository.cs
/Web (or Api)
  Program.cs
```

This keeps use cases discrete and discoverable.

---

## 14) Handy enhancements

- **AutoMapper**: map entities↔DTOs inside handlers.
- **Result types** (e.g., `OneOf`, `ErrorOr`, custom `Result`) to avoid throwing for expected failures.
- **OpenTelemetry**: instrument a behavior to add spans/tags for each request.
- **Publish strategies**: configure `IPublisher` for parallel vs. sequential notification handling if you need control.

---

If you want, I can adapt this to your stack—EF Core + SQL Server, your existing DI, custom result type, and a couple of real handlers from your domain—so it drops straight into your solution without a single yak to shave.

## User
It this pattern hard to refactor to?

## Assistant
Short answer: it's very refactor-able, and you don't have to "big-bang" it. You can migrate to MediatR in thin slices without breaking the world.

Here's a pragmatic path that keeps risk low and code readable the whole way:

## A sane, incremental strategy

1. **Start at the edges (controllers).**  
Pick one endpoint. Replace its direct service call with `mediator.Send(new SomeCommand(...))`. Keep the old service as-is and write a tiny handler that just calls that service.  
```csharp
// Before
public async Task<IActionResult> Create(UserDto dto) =>
    Ok(await _userService.CreateAsync(dto));

// After (controller)
public async Task<IActionResult> Create(UserDto dto, IMediator mediator) =>
    Ok(await mediator.Send(new CreateUserCommand(dto)));

// Handler (shim over the old service)
public sealed class CreateUserHandler : IRequestHandler<CreateUserCommand, Guid>
{
    private readonly IUserService _svc;
    public CreateUserHandler(IUserService svc) => _svc = svc;
    public Task<Guid> Handle(CreateUserCommand req, CancellationToken ct) =>
        _svc.CreateAsync(req.Dto, ct);
}
```
This flips the call site to the mediator with minimal churn.

2. **Strangler-fig the services.**  
Once a few endpoints call MediatR, start moving logic *from* services *into* handlers (or feature folders) one use-case at a time. Leave any shared domain logic where it belongs (entities/domain services).

3. **Introduce pipeline behaviors last.**  
After you have a handful of requests flowing through the mediator, add behaviors for logging/validation/authorization. This gives you quick wins (delete duplicated filters/middleware) without guessing.

4. **Split reads/writes when it's worth it.**  
You can adopt CQRS gradually: first keep "queries" calling the same repo/service; later swap in Dapper or projections for hot paths.

## Where refactors get sticky (and how to unstick them)

- **Transactional boundaries.**  
If your app relies on a "God service" that opens a transaction and calls several methods, create a *transaction behavior* so the boundary lives in one place:
```csharp
public sealed class EfTransactionBehavior<TReq,TRes> : IPipelineBehavior<TReq,TRes>
{
    private readonly DbContext _db;
    public EfTransactionBehavior(DbContext db) => _db = db;
    public async Task<TRes> Handle(TReq request, RequestHandlerDelegate<TRes> next, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var res = await next();
        await tx.CommitAsync(ct);
        return res;
    }
}
```
Register it for write commands only (e.g., by namespace or marker interface) to avoid wrapping reads.

- **Validation scattered everywhere.**  
Move rules into FluentValidation validators and a validation behavior. Delete controller/service duplication. You'll often shrink controllers by 30–70%.

- **Cross-service orchestration.**  
When one endpoint calls multiple services, create a *single command handler* that does the orchestration, and publish notifications for side effects (emails, cache warmers). This removes temporal coupling from controllers.

- **Unit tests tied to services.**  
Keep tests green by first pointing them at handlers that still call the old services. As you move logic into handlers, update tests to assert behavior, not private calls.

- **Multiple DbContexts.**  
Start simple: keep handlers using one context each. For the rare multi-context transaction, either:
  - consolidate to one context for that use case, or
  - wrap with an outbox pattern + eventual consistency (often cleaner than MSDTC).

## A lightweight checklist

- Pick 1–3 endpoints → route through `IMediator`.
- Add **feature folders** (e.g., `Users/CreateUser`) so code stays discoverable.
- Create **Command/Query records** that match your request models.
- Add **Logging** and **Validation** behaviors; remove duplicate filters.
- Move orchestration into handlers; keep domain logic in domain services/entities.
- For reads, introduce **query handlers**; keep EF or swap to Dapper later.
- Stabilize tests; prefer handler tests over controller tests.

## Effort ballpark (based on typical enterprise APIs)

- **Per endpoint** (simple CRUD): minutes to an hour to shim; a few more to extract validation and add tests.
- **Complex orchestrations**: half-day to a couple of days if you're also restructuring transactions and introducing domain events.
- **Cross-cutting** (logging, validation, metrics): a few behaviors can replace dozens of attributes/filters in an afternoon.

## Smarter refactor patterns

- **Anti-corruption shim**: initial handlers call existing services; swap internals later.
- **Publish domain notifications** from write handlers, let infra react (email, cache, search indexing).
- **Result types** (`OneOf`, `ErrorOr`, or your own) to normalize error handling across handlers.
- **OpenTelemetry behavior** for tracing; your logs suddenly have per-use-case spans.

## Red flags to avoid

- Turning the mediator into a **global service locator** (handlers should depend on real collaborators, not resolve everything via `IMediator`).
- **God handlers** that do five unrelated things—split by use case.
- Letting **controllers** retain business logic after adding MediatR—move it in or you've just added ceremony.

---

Bottom line: it's not hard if you slice it. Start by sending one request through MediatR, keep the service layer running as training wheels, then peel it away. If you want, I can sketch a step-by-step plan for one of your actual endpoints (EF + SQL Server, transaction + validation + caching) so you can see the before/after diff clearly.

## User
is it possible to switch handlers by config or at runtime

## Assistant
Yes, it's possible to swap handlers at runtime or based on config, but MediatR doesn't do it natively. By design it expects one handler per `IRequest<T>` (or many for `INotification`). That said, you've got a few escape hatches:

---

## 1. Multiple Handlers + Delegation
You can register multiple `IRequestHandler` implementations for the same request type and then use your own **wrapper handler** that delegates based on config.

```csharp
public class SwitchableHandler<TRequest,TResponse> : IRequestHandler<TRequest,TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IRequestHandler<TRequest,TResponse>> _handlers;
    private readonly IConfigProvider _config;
    public SwitchableHandler(IEnumerable<IRequestHandler<TRequest,TResponse>> handlers, IConfigProvider config)
    {
        _handlers = handlers;
        _config = config;
    }

    public Task<TResponse> Handle(TRequest request, CancellationToken ct)
    {
        var target = _config.UseNew ? _handlers.OfType<NewHandler<TRequest,TResponse>>().First()
                                    : _handlers.OfType<OldHandler<TRequest,TResponse>>().First();
        return target.Handle(request, ct);
    }
}
```

Here `SwitchableHandler` is the *one true handler* MediatR sees, and internally it chooses.

---

## 2. Configurable Pipeline Behavior
Instead of swapping handlers, put the "switch" into a pipeline behavior:

```csharp
public class RoutingBehavior<TRequest,TResponse> : IPipelineBehavior<TRequest,TResponse>
{
    private readonly OldHandler<TRequest,TResponse> _old;
    private readonly NewHandler<TRequest,TResponse> _new;
    private readonly IConfigProvider _config;

    public RoutingBehavior(OldHandler<TRequest,TResponse> old,
                           NewHandler<TRequest,TResponse> @new,
                           IConfigProvider config)
    {
        _old = old;
        _new = @new;
        _config = config;
    }

    public Task<TResponse> Handle(TRequest req, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        return _config.UseNew ? _new.Handle(req, ct) : _old.Handle(req, ct);
    }
}
```

This lets you flip routing logic without changing controller code.

---

## 3. Dependency Injection Profiles
If you're in ASP.NET Core, you can conditionally register one handler or another depending on environment/config:

```csharp
if (builder.Configuration.GetValue<bool>("Features:UseNewHandler"))
    services.AddTransient<IRequestHandler<MyCommand,MyResponse>, NewHandler>();
else
    services.AddTransient<IRequestHandler<MyCommand,MyResponse>, OldHandler>();
```

This approach is static per app instance (config at startup), not dynamic per-request.

---

## 4. Strategy Inside the Handler
Another pragmatic approach: just make one handler that internally decides which implementation path to take. This is often enough unless you're explicitly A/B testing.

---

## When to use which?

- **Startup-only config**: simplest, let DI register one handler or the other.  
- **Per-request runtime switching**: use a routing behavior or wrapper handler.  
- **Gradual migration**: wrapper handler lets you run old vs. new side by side, even "dual-run" for validation.  
- **Feature flags / A/B testing**: behaviors or wrapper handlers integrate nicely with feature-flag providers (LaunchDarkly, FF4J, etc.).

---

If you're thinking about **blue/green feature rollout** (old vs new logic for subsets of users), the behavior/wrapper approach works well: flip based on user claims, request headers, or feature flags.  

Do you want me to sketch a feature-flag-driven handler switch (say, LaunchDarkly or plain config key) so you can see the exact wiring in ASP.NET Core DI?
