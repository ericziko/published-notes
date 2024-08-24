---
created: 2024-08-23T18:14
updated: 2024-08-23T18:25
---
# How to use ILogger in Xunit


**From:** [How to get ASP.NET Core logs in the output of xUnit tests - Meziantou's blog](https://www.meziantou.net/how-to-get-asp-net-core-logs-in-the-output-of-xunit-tests.htm)


```csharp
internal class XUnitLogger : ILogger
{
    private readonly ITestOutputHelper _testOutputHelper;
    private readonly string _categoryName;
    private readonly LoggerExternalScopeProvider _scopeProvider;

    public static ILogger CreateLogger(ITestOutputHelper testOutputHelper) => new XUnitLogger(testOutputHelper, new LoggerExternalScopeProvider(), "");
    public static ILogger<T> CreateLogger<T>(ITestOutputHelper testOutputHelper) => new XUnitLogger<T>(testOutputHelper, new LoggerExternalScopeProvider());

    public XUnitLogger(ITestOutputHelper testOutputHelper, LoggerExternalScopeProvider scopeProvider, string categoryName)
    {
        _testOutputHelper = testOutputHelper;
        _scopeProvider = scopeProvider;
        _categoryName = categoryName;
    }

    public bool IsEnabled(LogLevel logLevel) => logLevel != LogLevel.None;

    public IDisposable BeginScope<TState>(TState state) => _scopeProvider.Push(state);

    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception exception, Func<TState, Exception, string> formatter)
    {
        var sb = new StringBuilder();
        sb.Append(GetLogLevelString(logLevel))
          .Append(" [").Append(_categoryName).Append("] ")
          .Append(formatter(state, exception));

        if (exception != null)
        {
            sb.Append('\n').Append(exception);
        }

        // Append scopes
        _scopeProvider.ForEachScope((scope, state) =>
        {
            state.Append("\n => ");
            state.Append(scope);
        }, sb);

        _testOutputHelper.WriteLine(sb.ToString());
    }

    private static string GetLogLevelString(LogLevel logLevel)
    {
        return logLevel switch
        {
            LogLevel.Trace =>       "trce",
            LogLevel.Debug =>       "dbug",
            LogLevel.Information => "info",
            LogLevel.Warning =>     "warn",
            LogLevel.Error =>       "fail",
            LogLevel.Critical =>    "crit",
            _ => throw new ArgumentOutOfRangeException(nameof(logLevel))
        };
    }
}

internal sealed class XUnitLogger<T> : XUnitLogger, ILogger<T>
{
    public XUnitLogger(ITestOutputHelper testOutputHelper, LoggerExternalScopeProvider scopeProvider)
        : base(testOutputHelper, scopeProvider, typeof(T).FullName)
    {
    }
}

internal sealed class XUnitLoggerProvider : ILoggerProvider
{
    private readonly ITestOutputHelper _testOutputHelper;
    private readonly LoggerExternalScopeProvider _scopeProvider = new LoggerExternalScopeProvider();

    public XUnitLoggerProvider(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    public ILogger CreateLogger(string categoryName)
    {
        return new XUnitLogger(_testOutputHelper, _scopeProvider, categoryName);
    }

    public void Dispose()
    {
    }
}

```
## How to create an instance of ILogger

You can create an instance of `ILogger` when needed in unit tests:

```csharp
public class DemoTests
{
    private readonly ITestOutputHelper _testOutputHelper;

    public DemoTests(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    [Fact]
    public async Task Test(string url)
    {
        // Arrange
        var logger = XUnitLogger.CreateLogger<Sample>(_testOutputHelper);
        var sut = new Sample(logger);

        // Act
        var response = await sut.Execute();

        // Assert
        response.EnsureSuccessStatusCode();
    }
}
```
## How to use the logger in ASP.NET Core integration tests

If you write integration tests, you should use `WebApplicationFactory<T>`. This type allows us to easily test an ASP.NET Core application using an in-memory test server. It is possible to integrate the `XUnitLoggerProvider` provider into the factory, so all loggers will output text to xUnit.

```csharp
public class CustomWebApplicationFactory<TStartup> : WebApplicationFactory<TStartup>
    where TStartup : class
{
    private readonly ITestOutputHelper _testOutputHelper;

    public CustomWebApplicationFactory(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Register the xUnit logger
        builder.ConfigureLogging(loggingBuilder =>
        {
            loggingBuilder.Services.AddSingleton<ILoggerProvider>(serviceProvider => new XUnitLoggerProvider(_testOutputHelper));
        });
    }
}
```

```csharp

public class BasicTests
{
    private readonly ITestOutputHelper _testOutputHelper;

    public BasicTests(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    [Theory]
    [InlineData("/weatherforecast")]
    public async Task Get_EndpointsReturnSuccessAndCorrectContentType(string url)
    {
        using var factory = new CustomWebApplicationFactory<Startup>(_testOutputHelper);

        // Arrange
        var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync(url);

        // Assert
        response.EnsureSuccessStatusCode();
    }
}
```





