---
transcription_date_utc: 2025-10-01T20:02:16Z
title: SSIS on Linux: caveats, migration paths, and C# ETL tooling
summary: >
  We discussed whether SSIS packages can run on Linux (short answer: not natively),
  the practical caveats and hybrid options (Scale Out, containers, ADF/SSIS IR),
  a step-by-step migration playbook to Linux-native tooling (Airflow + dbt + Python/SQL),
  and a full C# alternative stack for Linux using Worker Services, TPL Dataflow, SqlBulkCopy,
  Quartz/Hangfire, Polly, Serilog, and OpenTelemetry. The conversation includes
  concrete mapping of SSIS tasks to open tools and multiple code examples (Airflow DAG,
  C#, SQL MERGE, Quartz, Polly) to serve as a starting template for modernization.
joke: "Our ETL ran away to Linux, but SSIS insisted on a Windows layover—so we booked it a C# connecting flight."
document-type: chat-gpt-transcription
ai-model:
  name: GPT-5 Thinking
  version: 2025-10-01
tags:
  - -para/fleeting-thought
  - -para/resources/ai-transcript
---
## ssis-on-linux-migration-and-csharp-etl-tooling

*Our ETL ran away to Linux, but SSIS insisted on a Windows layover—so we booked it a C# connecting flight.*

### Transcript

**User:** can sql server ssis packages be run on linux and what are the cavearts

**Assistant:** SQL Server Integration Services (SSIS) is historically a Windows-only technology, but there’s some nuance:

### Official Support
- **SQL Server Data Tools (SSDT) and the SSIS runtime itself are Windows-only.** You can’t natively design or run SSIS packages directly on Linux in the same way you can on Windows.
- However, **SQL Server on Linux** *can run SSIS packages indirectly* through the **SSIS Scale Out feature**. The Scale Out Master still needs to run on Windows, but Linux SQL Server instances can participate as execution targets.

### Workarounds / Options
1. **dtexec / SSIS Runtime:**  
   The `dtexec` utility (the command-line runner for SSIS packages) isn’t available on Linux. So you can’t simply copy over `.dtsx` packages and run them like you would on Windows.

2. **SSIS Scale Out (Hybrid):**  
   You can host your packages in SQL Server (Windows) or in Azure Data Factory (ADF) SSIS Integration Runtime, then orchestrate their execution from Linux clients.  
   This means the heavy lifting (the SSIS runtime) still happens on Windows, but Linux can trigger and coordinate.

3. **Containers:**  
   Microsoft provides **Docker containers with SSIS installed** (based on Windows containers). If you run Docker on Linux with Windows containers enabled (usually requires Windows host), you can host SSIS this way. Pure Linux containers won’t work since SSIS is tied to Windows APIs.

4. **Migration Path:**  
   Microsoft has been nudging people toward **Azure Data Factory (ADF)** or **SQL Server Integration Runtime in Azure** if you want cloud or cross-platform ETL. On Linux, folks often switch to **Apache NiFi**, **Airflow**, or just plain **Python + SQL** for ETL jobs instead of sticking with SSIS.

### Caveats
- **No native execution on Linux**: You’ll always need a Windows runtime somewhere in the loop.  
- **Maintenance overhead**: If you try to containerize SSIS, you’re really just wrapping Windows inside Docker/VM. That’s more moving parts.  
- **Limited ecosystem support**: Tooling like Visual Studio/SSDT and SSISDB catalog are Windows-centric. You’ll likely be managing packages from a Windows environment even if SQL Server itself is on Linux.  
- **Portability**: If you’re looking for true cross-platform ETL, SSIS is not the best fit. It locks you into Windows runtimes.

---

In short: you can **control and orchestrate** SSIS from Linux, but you cannot **natively run** SSIS packages on Linux. If you’re already invested in SSIS, you’ll need at least one Windows node in your setup. If you’re starting fresh and want Linux-friendly ETL, better to evaluate Airflow, NiFi, or Azure Data Factory.  

Would you like me to sketch a migration path from SSIS packages into a Linux-native pipeline (like Airflow or ADF), so you can see what “modernization” might look like?

**User:** yes

**Assistant:** Sweet. Here’s a practical, low-drama roadmap to move SSIS workloads to a Linux-friendly stack—plus a “Rosetta Stone” mapping of common SSIS components to open tooling.

# ssis-on-linux-migration-and-csharp-etl-tooling

**Option A — Airflow + dbt + Python/SQL (self-hosted, Linux-native)**
- **Orchestrator:** Apache Airflow
- **Transformations:** dbt (SQL-first) for warehouses (Postgres/SQL Server/Snowflake/BigQuery), or Pandas/PySpark for row-by-row logic
- **Connectivity:** `pyodbc`/`odbc` + drivers for SQL Server; S3/Azure Blob/FTP libs for files
- **Observability:** Airflow logs + OpenTelemetry exporters (optional)
- **Secrets:** Env vars/HashiCorp Vault/Airflow Connections

**Option B — Azure Data Factory + Azure-SSIS IR (managed)**
- Not Linux-native, but fully managed and minimal code. If you want off Windows servers fast with least re-write, this is often the fastest bridge. You can then gradually refactor pipelines into ADF/Mapping Data Flows or Synapse/Fabric later.

If the mandate is “pure Linux,” choose **Option A**.

---

# 2) Inventory & Classify SSIS Packages

Make a quick spreadsheet with columns:
- Package / Path in SSISDB
- Schedule / Trigger
- Sources → Destinations
- Control-flow tasks used (Execute SQL, File System, FTP/SFTP, ForEach, etc.)
- Data-flow components used (Lookups, Merge Join, Conditional Split, Derived Column, SCD)
- Script Task/Component languages
- Error paths & retry logic
- Runtime (min/max/avg), SLA, failure rate

This tells you where the real work is (hint: SCDs, Lookups, custom scripts).

---

# 3) SSIS → Linux “Rosetta Stone”

| SSIS thing | Purpose | Linux-friendly target |
|---|---|---|
| **SQL Agent schedule** | Orchestration | Airflow DAG + `CronTrigger` (or ADF trigger if using ADF) |
| **Execute SQL Task** | Run SQL | Airflow `MsSqlOperator`/`SqlOperator`, or dbt model |
| **Data Flow: OLE DB Source/Dest** | Move data | Python task using `pyodbc`/bulk insert; dbt seed/model for set-based |
| **Lookup / Merge Join** | Enrich/Join | SQL joins in dbt; Pandas/PySpark join for row logic |
| **Conditional Split** | Branch rows | SQL `CASE`/filters; Pandas dataframe filters |
| **Derived Column** | Compute fields | SQL expressions in dbt; Pandas column ops |
| **Slowly Changing Dimension** | SCD Type 1/2 | dbt `snapshots` (Type 2) or handcrafted MERGE; PySpark Delta; Pandas + MERGE |
| **Script Task/Component** | Custom code | Python task/function; or .NET 8 worker (Linux-friendly) |
| **ForEach Loop (files/rows)** | Iterate | Airflow dynamic task mapping; Python loops; dbt set-based preferred |
| **File System Task** | Move/copy files | Python `pathlib`/`shutil`; BashOperator |
| **FTP/SFTP Task** | File transfer | Python `paramiko`/`pysftp`; Airflow `SFTPHook` |
| **SSIS Parameters/Environments** | Config | Airflow Variables/Connections; `.env` + Vault |
| **Event Handlers / OnError** | Error paths | Airflow retries, `on_failure_callback`, task dependencies |
| **Logging to SSISDB** | Audit | Airflow logs + warehouse audit tables; OpenTelemetry traces/metrics (optional) |

---

# 4) Migration Patterns (do these first)

**A. Pure ELT (set-based SQL) → dbt**
- If your SSIS pipelines mostly do SELECT-INSERT/UPDATE/MERGE with lightweight derivations, port to **dbt models** + **snapshots**.
- You get versioned SQL, tests, docs, environments, and easy CI/CD.

**B. Row-by-row transforms / branching → Python**
- Where SSIS used Script Components, replicate in **Python** (Pandas) or **PySpark** if volumes are large or you need distributed compute.
- Keep IO at the edges (ingest → transform in memory → bulk load).

**C. Orchestration & dependencies → Airflow**
- Each former SSIS package becomes an **Airflow DAG**.
- SSIS Precedence Constraints map to task dependencies (`task_a >> task_b`).
- Retries, SLAs, alerts handled in operator/task args.

---

# 5) Example: one SSIS package as an Airflow DAG

```python
# dags/customer_dim.py
from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
import pandas as pd
import pyodbc
import os

def load_stage_from_source():
    cn = pyodbc.connect(os.environ["SRC_ODBC"])
    df = pd.read_sql("SELECT * FROM dbo.CustomerSrc WHERE UpdatedAt >= DATEADD(day,-1,GETUTCDATE())", cn)
    # write to staging (use fast_executemany for speed)
    tgt = pyodbc.connect(os.environ["DW_ODBC"])
    cur = tgt.cursor()
    cur.fast_executemany = True
    rows = [tuple(r) for r in df.to_numpy()]
    cur.executemany("INSERT INTO stage.CustomerSrc (...) VALUES (...)", rows)
    tgt.commit()

default_args = {"retries": 2}

with DAG(
    dag_id="customer_dim",
    start_date=datetime(2024,1,1),
    schedule="0 * * * *",
    catchup=False,
    default_args=default_args,
) as dag:

    stage = PythonOperator(
        task_id="stage_source",
        python_callable=load_stage_from_source,
    )

    # Type 2 SCD via MERGE (dbt snapshot is often cleaner)
    merge_dim = MsSqlOperator(
        task_id="merge_customer_dim",
        mssql_conn_id="dw_mssql",
        sql="""
        MERGE dw.DimCustomer AS T
        USING stage.CustomerSrc AS S ON T.BusinessKey = S.BusinessKey
        WHEN MATCHED AND (T.HashDiff <> S.HashDiff) THEN
          UPDATE SET T.EndDate = SYSUTCDATETIME(), T.IsCurrent = 0
        WHEN NOT MATCHED BY TARGET THEN
          INSERT (BusinessKey, ..., StartDate, EndDate, IsCurrent)
          VALUES (S.BusinessKey, ..., SYSUTCDATETIME(), '9999-12-31', 1);
        """,
    )

    stage >> merge_dim
```

If you lean ELT, replace the Python staging with a **dbt model** and use **dbt snapshots** for SCD2.

---

# 6) Data movement at scale (SQL Server specifics)

- Use **ODBC 18** drivers on Linux and `pyodbc` with `fast_executemany=True` for bulkiness.
- Prefer **set-based** `INSERT…SELECT`/`MERGE` executed server-side (dbt/SQL operator) over row loops.
- For files: land in **object storage** (S3/Azure Blob) then load with bulk/PolyBase/OPENROWSET if available.

---

# 7) Config, Secrets, and Environments

- Airflow **Connections** for DSNs, S3/Blob keys, SFTP.
- Parameterize per-env via Airflow Variables or `.env` + Docker/K8s Secrets.
- Mirror SSIS “Environments” by separate Airflow deploys or per-env variables with the same DAG code.

---

# 8) Testing, QA, and Cutover

1. **Golden-set tests:** For each package, pick N representative runs. Persist inputs and expected outputs.
2. **Unit tests:** dbt tests (not null, unique, referential) + Python unit tests for transform functions.
3. **Row-count & hash checks:** Pre/post counts and checksum columns to prove parity.
4. **Dry-run windows:** Run Airflow and SSIS in parallel, compare deltas.
5. **Backfill strategy:** Use Airflow backfills or dbt `--full-refresh` for historical rebuilds.

---

# 9) Observability & Ops

- Airflow has retry/alerting; wire email/Slack, or export logs/metrics to Prometheus/Splunk/OpenTelemetry.
- Add **data quality sentinels**: row counts, schema drift checks, freshness checks (dbt’s `freshness` is handy).

---

# 10) Common snags & how to dodge them

- **SCD components:** SSIS’s SCD wizard hides complexity. Recreate explicitly using dbt snapshots or MERGE patterns.
- **Implicit type casts:** SSIS often casts silently; make types explicit in SQL/Python to avoid Linux driver surprises.
- **File encodings & locales:** Normalize to UTF-8; specify `encoding=` when reading/writing.
- **Network auth:** Kerberos/AD from Linux can require extra config. If painful, use service principals or SQL auth per environment.
- **Long-running monolith packages:** Split into smaller DAG tasks to get better retries and checkpointing.

---

# 11) Minimal-rewrite bridge (if you must)

- Stand up **ADF + SSIS IR** to execute existing packages quickly (no server maintenance, still Windows under the hood).
- Then, carve out the biggest cost/complexity packages into **dbt/Airflow** iteratively until SSIS IR is empty.

---

# 12) A crisp migration plan (4–8 weeks for a medium estate)

1. **Week 1:** Inventory, pick target patterns, set up Airflow/dbt skeleton repo, CI, and one environment (dev).
2. **Week 2:** Migrate 2–3 representative packages (one simple ELT, one with SCD, one with files).
3. **Week 3–4:** Migrate the bulk (parallelize by domain), add data quality tests, backfills.
4. **Week 5:** Parallel runs vs SSIS, fix deltas, tighten SLAs/alerts.
5. **Week 6+:** Cutover per domain; decommission Windows runners or move remaining stragglers to ADF IR temporarily.

---

Want me to turn one of your actual SSIS packages into a concrete Airflow + dbt blueprint—operators, SQL, and a dbt snapshot—so you can see an end-to-end slice with your objects and edge cases (lookups, error handling, etc.)?

**User:** what if i want to rewrite in c# rather then python what libraries do you recommend

**Assistant:** Totally doable in C# on Linux. Think of it as “SSIS, but code”: a Worker Service hosts your pipelines; TPL Dataflow (or Channels) does the flow; `SqlBulkCopy` (plus helpers) moves data fast; Quartz/Hangfire schedules; Polly keeps it alive; Serilog/OpenTelemetry tells you what happened.

Here’s a battle-tested toolbox to cover the usual SSIS-y tasks:

## Orchestration & Scheduling
- **Quartz.NET** – cron-like scheduling in-process; great for K8s or systemd services.
- **Hangfire** – background jobs with a dashboard + retries & queues (uses a DB backend).
- **Azure Functions** or **K8s CronJobs** – if you prefer external scheduling.

## Pipeline Building Blocks
- **TPL Dataflow** (`System.Threading.Tasks.Dataflow`) – easy DAGs with backpressure, bounded concurrency, retry hooks.
- **System.Threading.Channels** – lighter, great for producer/consumer.
- **Reactive Extensions (Rx.NET)** – if you like streaming/evented semantics.

## Database IO (SQL Server & friends)
- **Microsoft.Data.SqlClient** – cross-platform SQL Server driver.
- **Dapper** – micro-ORM for fast reads/writes (parameterized SQL).
- **Entity Framework Core** – when you want change tracking/linq, but…
- **Fast bulk ops**:
  - **`SqlBulkCopy`** (BCL) – screaming fast inserts.
  - **EFCore.BulkExtensions** (OSS) or **Z.BulkOperations** (paid) – bulk insert/update/merge convenience.
- Other DBs: **Npgsql** (Postgres), **MySqlConnector** (MySQL), **Oracle.ManagedDataAccess.Core** (Oracle).

## Files & Formats
- **CsvHelper** – robust CSV read/write (schemas, culture, quoting).
- **ExcelDataReader** (read) / **EPPlus** or **ClosedXML** (write Excel).
- **Parquet**: **Parquet.Net** or **ParquetSharp**; **Apache.Arrow** for columnar in-memory.
- **Avro**: **Chr.Avro** or **Apache.Avro**.
- **JSON/XML**: `System.Text.Json`, `Newtonsoft.Json`, `System.Xml` (XmlReader for streaming).
- **Compression**: `System.IO.Compression` (GZip/Zip) – stream friendly.

## Cloud & Storage
- **Azure.Storage.Blobs**, **AWSSDK.S3**, **Google.Cloud.Storage.V1** – all solid on Linux.
- **SFTP/FTP**: **SSH.NET**.

## Message Buses (for decoupling & scale)
- **Confluent.Kafka** (Kafka), **RabbitMQ.Client**, **Azure.Messaging.ServiceBus**, **AWSSDK.SQS**.
- Higher level: **MassTransit**, **NServiceBus**, **CAP**.

## Reliability, Config, Observability
- **Polly** – retries, circuit breakers, bulkheads (wrap DB & network calls).
- **Microsoft.Extensions.Hosting / Options** – Worker Service template; env-based config.
- **Vault/Secrets**: **Azure.Identity** + Key Vault; **AWS Secrets Manager**; **VaultSharp** (HashiCorp).
- **Serilog** – sinks to Seq, Splunk HEC, Elasticsearch, console JSON.
- **OpenTelemetry .NET** – traces/metrics/logs you can ship anywhere.

## Useful patterns that map 1:1 from SSIS

### 1) Dataflow with backpressure (TPL Dataflow)
```csharp
using System.Threading.Tasks.Dataflow;

// 1) Read → 2) Transform → 3) Bulk Load
var readBlock = new TransformBlock<int, DataTable>(async _ => await ReadBatchAsync(...),
    new ExecutionDataflowBlockOptions { MaxDegreeOfParallelism = 4, BoundedCapacity = 2 });

var transformBlock = new TransformBlock<DataTable, DataTable>(dt => DeriveColumns(dt),
    new ExecutionDataflowBlockOptions { MaxDegreeOfParallelism = 4, BoundedCapacity = 2 });

var loadBlock = new ActionBlock<DataTable>(async dt => await BulkInsertAsync(dt),
    new ExecutionDataflowBlockOptions { MaxDegreeOfParallelism = 2, BoundedCapacity = 1 });

readBlock.LinkTo(transformBlock, new DataflowLinkOptions { PropagateCompletion = true });
transformBlock.LinkTo(loadBlock, new DataflowLinkOptions { PropagateCompletion = true });

// seed N batches
for (var i = 0; i < 100; i++) readBlock.Post(i);
readBlock.Complete();
await loadBlock.Completion;
```

### 2) Fast loads (`SqlBulkCopy`) with EF/Dapper on the side
```csharp
using var bulk = new SqlBulkCopy(conn, SqlBulkCopyOptions.TableLock, null) {
    DestinationTableName = "stage.Customer"
};
bulk.BatchSize = 10_000;
bulk.BulkCopyTimeout = 0; // no timeout
await bulk.WriteToServerAsync(dataTable);
```

### 3) Scheduling (Quartz)
```csharp
IJobDetail job = JobBuilder.Create<ImportJob>().WithIdentity("import").Build();
ITrigger trig = TriggerBuilder.Create()
    .WithCronSchedule("0 0/15 * * * ?") // every 15 minutes
    .StartNow()
    .Build();
await scheduler.ScheduleJob(job, trig);
```

### 4) Resilience (Polly)
```csharp
var retry = Policy
    .Handle<SqlException>()
    .Or<TimeoutException>()
    .WaitAndRetryAsync(5, i => TimeSpan.FromSeconds(Math.Pow(2, i)));

await retry.ExecuteAsync(() => BulkInsertAsync(dt));
```

### 5) SCD Type 2 (MERGE)
```sql
MERGE dw.DimCustomer AS T
USING stage.Customer AS S
ON T.BusinessKey = S.BusinessKey
WHEN MATCHED AND T.HashDiff <> S.HashDiff THEN
  UPDATE SET T.EndDate = SYSUTCDATETIME(), T.IsCurrent = 0
WHEN NOT MATCHED BY TARGET THEN
  INSERT (BusinessKey, ..., StartDate, EndDate, IsCurrent)
  VALUES (S.BusinessKey, ..., SYSUTCDATETIME(), '9999-12-31', 1);
```
Use Dapper/SqlClient to execute; compute `HashDiff` in C# or SQL.

## Linux-friendly hosting & deploy
- **.NET 8 Worker Service** → containerize; run as **systemd** service or in **Kubernetes**.
- Keep state external (DB/queue/Blob); instances become stateless & horizontally scalable.
- Metrics/logs to your existing stack (Prometheus, Seq, Splunk, ELK).

## Design tips (so you don’t re-invent SSIS’s footguns)
- Prefer **set-based** SQL (server-side) over row-by-row where possible.
- Use **bounded** blocks/buffers for predictable memory.
- Standardize **schemas** (DTOs/DataTables) at stage boundaries; validate with **FluentValidation**.
- Version your transforms; keep **idempotency** & **watermarks** (last successful key/timestamp) per task.
- Wrap every external call in **Polly**; log structured events with correlation IDs.
- For CDC: consume from **Debezium/Kafka** in C# or query SQL Server CDC tables with watermarks.

---

If you give me one representative SSIS package (sources, transforms, targets), I’ll sketch a C# Worker project layout with:
- a Quartz job,
- a TPL Dataflow pipeline,
- Dapper read + `SqlBulkCopy` load,
- Polly policies,
- Serilog/Otel wiring,
- and a config model that mirrors your SSIS parameters/environments.
