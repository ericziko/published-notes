---
created: 2025-09-15T14:38
updated: 2025-09-15T14:42
title: session-level-unique-identifier-to-sql-server-transcript
date created: Monday, September 15th 2025, 9:38:48 pm
date modified: Monday, September 15th 2025, 9:42:02 pm
---

# session-level-unique-identifier-to-sql-server-transcript

**User:**  
Is there a way to pass a session level unique identifier such as a guid generated c# to sql server and be able to read that value from the tsql?

**Assistant:**  
Yes. Use a per-connection "session context." You've got two solid options in SQL Server:

## 1) Modern + flexible (SQL Server 2016+): `sp_set_session_context` / `SESSION_CONTEXT()`
Set a key/value on the current session from C#, then read it anywhere in T-SQL during that connection's lifetime.

### C#
```csharp
using System.Data;
using Microsoft.Data.SqlClient; // or System.Data.SqlClient

var guid = Guid.NewGuid();

using var conn = new SqlConnection(connectionString);
await conn.OpenAsync();

using (var cmd = new SqlCommand(
    "EXEC sys.sp_set_session_context @key, @val, @read_only = 1;", conn))
{
    cmd.Parameters.Add(new SqlParameter("@key", SqlDbType.NVarChar, 128) { Value = "TraceId" });
    cmd.Parameters.Add(new SqlParameter("@val", SqlDbType.UniqueIdentifier) { Value = guid });
    cmd.Parameters.Add(new SqlParameter("@read_only", SqlDbType.Bit) { Value = true });
    await cmd.ExecuteNonQueryAsync();
}

// … run whatever commands; they can read the value in T-SQL via SESSION_CONTEXT
```

### T-SQL
```sql
SELECT CAST(SESSION_CONTEXT(N'TraceId') AS uniqueidentifier) AS TraceId;
```

Notes:
- Values are per **session/connection**, not per transaction.
- `@read_only = 1` prevents accidental overwrites later in the request pipeline.
- Works with any `sql_variant`-compatible type, including `uniqueidentifier`, `nvarchar`, `int`, etc.

## 2) Legacy (older versions): `SET CONTEXT_INFO` / `CONTEXT_INFO()`
Stores up to 128 bytes of `varbinary` on the session.

### C#
```csharp
var guid = Guid.NewGuid();
var bytes = guid.ToByteArray(); // 16 bytes

using var conn = new SqlConnection(connectionString);
await conn.OpenAsync();

using (var cmd = new SqlCommand("SET CONTEXT_INFO @b;", conn))
{
    cmd.Parameters.Add(new SqlParameter("@b", SqlDbType.VarBinary, 128) { Value = bytes });
    await cmd.ExecuteNonQueryAsync();
}
```

### T-SQL
```sql
SELECT CAST(CONTEXT_INFO() AS uniqueidentifier) AS TraceId;
-- If needed: SELECT CONVERT(uniqueidentifier, CONTEXT_INFO());
```

---

## Important gotchas (the gremlins in the plumbing)
- **Connection pooling:** ADO.NET reuses connections. Always set the session context **immediately after opening** a connection (or via an EF/ADO interceptor) so you don't inherit someone else's context.
- **MARS / multiple DbContexts:** Each physical connection has its own context. If you multiplex, ensure each connection you open sets the context you expect.
- **Scope:** Session context is visible to all modules called on that session (procs, triggers, functions), but it's not automatically "passed" to other servers via linked servers.
- **Clearing:** You can overwrite or clear a key: `EXEC sp_set_session_context @key='TraceId', @value=NULL;`

---

## EF Core one-liner (nice for pipelines)
Add a connection interceptor that sets the context on open:

```csharp
public sealed class SessionContextInterceptor : DbConnectionInterceptor
{
    public override async Task ConnectionOpenedAsync(
        DbConnection connection, ConnectionEndEventData eventData, CancellationToken ct = default)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = "EXEC sys.sp_set_session_context @key, @val, @read_only = 1;";
        var traceId = Guid.NewGuid(); // or pull from your logger/request context
        var p1 = cmd.CreateParameter(); p1.ParameterName="@key"; p1.Value="TraceId";
        var p2 = cmd.CreateParameter(); p2.ParameterName="@val"; p2.Value=traceId;
        var p3 = cmd.CreateParameter(); p3.ParameterName="@read_only"; p3.Value=true;
        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);
        await cmd.ExecuteNonQueryAsync(ct);
    }
}
```

Register it in `DbContextOptionsBuilder`:
```csharp
options.AddInterceptors(new SessionContextInterceptor());
```

Then inside stored procs, triggers, or ad-hoc T-SQL:
```sql
DECLARE @TraceId uniqueidentifier =
    TRY_CAST(SESSION_CONTEXT(N'TraceId') AS uniqueidentifier);
```

That's the whole trick: stamp the connection once, read it anywhere in T-SQL for auditing, multi-tenant scoping, or correlating to app logs. If you want, we can wire this into your existing EF setup and push the TraceId into every proc call and log line for end-to-end tracing.
