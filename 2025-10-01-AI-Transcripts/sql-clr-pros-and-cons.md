---
transcription_date_utc: 2025-10-01T20:03:57Z
title: Pros and cons of running .NET inside SQL Server (SQL CLR)
summary: >
  A concise exchange covering SQL CLR integration—what it is, key advantages like
  leveraging the .NET Base Class Library and streaming TVFs, the tradeoffs around
  operational complexity, security, runtime coupling, observability, when it’s a
  good idea vs when to avoid it, safer usage patterns, and a quick decision
  cheat-sheet.
joke: "I asked SQL Server to host my web API; it replied, 'I'm a database, not your app server—stop trying to CLR up our relationship.'"
document-type: chat-gpt-transcription
ai-model: GPT-5 Thinking (snapshot 2025-10-01)
tags:
  - -para/fleeting-thought
  - -para/resources/ai-transcript
---

# sql-clr-pros-and-cons

*I asked SQL Server to host my web API; it replied, 'I'm a database, not your app server—stop trying to CLR up our relationship.'*

## Transcript

### User
what are the pros and cons of running .net inside sql server

### Assistant
Running .NET **inside** SQL Server = “SQL CLR integration.” You load a compiled .NET assembly into the database and expose methods as stored procs, scalar/table-valued functions, triggers, or aggregates.

Here’s the pragmatic rundown.

## Pros
- **Leverage the full .NET BCL**  
  Regex, complex string parsing, date/time gymnastics, binary manipulation, compression, crypto, custom math—things that are awkward or slow in T-SQL become straightforward.
- **Streaming table-valued functions**  
  CLR TVFs can stream rows as they’re produced (no big intermediate tables), which can beat multi-statement TVFs for complex transforms.
- **Custom aggregates**  
  Build domain-specific aggregations (e.g., percentile variants, geodesic accumulators) that T-SQL doesn’t natively offer.
- **Atomic deployment & permissions**  
  Assemblies live in the database; you can secure them via SQL permissions and replicate them with the database (e.g., with AGs).
- **Pre-2019 scalar performance win**  
  Historically, CLR scalar UDFs were much faster than T-SQL scalars (which forced row-by-row execution). SQL Server 2019’s scalar UDF inlining narrowed this advantage, but for some workloads CLR still wins—especially for CPU-heavy text/binary work.

## Cons
- **Operational complexity**  
  You’re now hosting two runtimes in one process. CLR memory and GC run under SQLOS; bad code (busy loops, large allocations) can pressure SQL Server’s memory and schedulers.
- **Security hoops**  
  CLR increases attack surface. Since SQL Server 2017, *CLR strict security* treats most assemblies as UNSAFE unless signed or whitelisted. Managing `SAFE` vs `EXTERNAL_ACCESS` vs `UNSAFE`, certificates, and `TRUSTWORTHY` gets… spicy.
- **Version/runtime coupling**  
  Your code is tied to the CLR that SQL Server hosts. You don’t control the .NET version or GC settings, and you can’t use NuGet freely like an app—only what you embed and what’s allowed.
- **Troubleshooting & observability**  
  Debugging is harder than app-tier .NET. Profiling CLR execution inside SQL needs careful DMV/perf counter spelunking (`sys.dm_clr_*`, `sys.assemblies`, wait stats).
- **Parallelism & threading limits**  
  SAFE code can’t spin threads or do arbitrary I/O. Even in UNSAFE, it’s a very bad idea—SQL expects cooperative scheduling. Blocking or long CPU bursts can starve other queries.
- **Networking / external I/O pain**  
  Anything outside the database (files, web, queues) demands `EXTERNAL_ACCESS`/`UNSAFE`, extra security config, and careful failure handling. Usually better in the app tier.
- **Upgrades & portability**  
  Migrating servers means migrating signed assemblies and security config. Cross-platform quirks (Windows/Linux) can surprise you.

## When it’s a good idea
- **Tiny, hot, pure functions** that are compute-heavy and called in-set (e.g., parsing, hashing, specialized math), especially when T-SQL is ugly or slow.
- **Custom aggregates** that would otherwise require awkward cursor logic.
- **Streaming TVFs** generating rows algorithmically (parsers, tokenizers) without staging tables.

## When to avoid it
- **Business logic, workflows, or I/O** (HTTP calls, file access, queues, cloud SDKs). Put that in the app tier, a service, or an external compute layer.
- **Anything long-running or blocking** (ML inference, report rendering, big XML/JSON shredding that belongs upstream).
- **Things T-SQL now does well** (JSON, window functions, STRING_SPLIT with ordinal, built-in crypto types, geospatial, 2019+ scalar UDF inlining).

## Safer patterns if you must use SQL CLR
- Prefer **`SAFE` permission** assemblies. Avoid `EXTERNAL_ACCESS`/`UNSAFE` unless you’ve exhausted alternatives.
- Keep functions **pure and deterministic**; avoid I/O, global state, and randomness unless you mark determinism appropriately.
- **Stream results** (IEnumerable) for TVFs; don’t slurp huge arrays into memory.
- **Sign assemblies** and use **CLR strict security** properly (certs/asymmetric keys, no `TRUSTWORTHY ON` if you can help it).
- Watch memory/schedulers with **DMVs** and **Query Store**; regression-test like you would a new index.
- Package a **fallback T-SQL** option for emergencies and document the assembly lifecycle (build → sign → `CREATE ASSEMBLY` → `CREATE FUNCTION/PROC`).

## Quick decision cheat-sheet
- “I need regex/exotic parsing inside a query.” → CLR **can** be worth it (SAFE, small, pure).
- “I need to call a web API from SQL.” → **No.** Use app code or external services (e.g., ETL, Azure Functions, Service Broker + worker).
- “This scalar UDF is killing us.” → First try **SQL Server 2019+** with scalar UDF inlining; only then consider CLR.
- “I need a custom aggregate (e.g., t-digest).” → CLR aggregate is a strong candidate.

If you want, I can sketch a minimal example (a SAFE, deterministic CLR scalar UDF with `CREATE ASSEMBLY`/`CREATE FUNCTION`) and a deployment checklist tuned for your CI/CD setup.
