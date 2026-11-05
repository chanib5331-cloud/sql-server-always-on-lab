# SQL Server Always On Lab

A hands-on lab that builds a two-node **SQL Server 2022 Always On Availability Group** in Docker, then practices the everyday work of an infrastructure DBA: failover, monitoring, index tuning, scheduled health checks, and backup & restore.

## Architecture

```
            Docker network "aglab"
 ┌──────────────────────┐      ┌──────────────────────┐
 │ sql1  (PRIMARY)      │ 5022 │ sql2  (SECONDARY)    │
 │ SQL Server 2022      │─────▶│ SQL Server 2022      │
 │ localhost,14331      │ log  │ localhost,14332      │
 │ LabDB (read/write)   │      │ LabDB (read-only)    │
 └──────────────────────┘      └──────────────────────┘
   Availability Group "ag1" – synchronous commit, automatic seeding,
   certificate-authenticated endpoints, manual failover
```

## What the lab covers

| Area | Scripts |
|---|---|
| Installation & configuration of SQL Server instances (Developer edition, HADR, SQL Agent) | `docker-compose.yml` |
| Always On: logins, certificates, mirroring endpoints, AG creation, join, automatic seeding | `01`–`07` |
| AG health monitoring with DMVs | `08` |
| Data synchronization test, readable secondary | `09` |
| Planned manual failover and fail-back | `10a`–`10d` |
| Monitoring with Extended Events (blocked process report, slow statements) | `11`, `12` |
| DMV monitoring: active requests & blocking, wait stats, top CPU queries, missing indexes, Query Store | `13` |
| Index tuning with Execution Plans and STATISTICS IO/TIME, fragmentation & FILLFACTOR | `14` |
| SQL Server Agent job that logs AG health every 5 minutes | `15` |
| Full + log backups, RESTORE VERIFYONLY, restore test | `16` |

## Results

Measured in this lab, on a sample table of 200,000 rows.

**Index tuning.** The same query, before and after a covering index, returned the same 1,250 rows. The final plan uses an Index Seek on the new index.

| Metric | Before | After |
|---|---|---|
| Logical reads | 1,021 | 60 |
| CPU time | 24 ms | 4 ms |
| Elapsed time | 25 ms | 4 ms |

**Synchronization.** A row written on `sql1` appeared on `sql2`, and a write on the secondary was rejected with error 3906 (read-only database).

**Failover.** A planned manual failover moved the primary role to `sql2` and back to `sql1`. After each move, DMVs showed both replicas connected and `LabDB` as `SYNCHRONIZED` and `HEALTHY`.

**Blocking.** A deliberate 30-second lock was identified with `sys.dm_exec_requests` (`LCK_M_S`) and captured by `blocked_process_report`. The blocked `SELECT` took about 27 seconds but used only about 2 ms of CPU and 6 logical reads, so the delay was lock waiting and not query cost.

**Health monitoring.** With `sql2` stopped, the Agent job on `sql1` logged it as `DISCONNECTED` and `NOT_HEALTHY` and wrote an alert to the error log. The local row for `sql1` stayed `HEALTHY` during the outage, so the job reads the secondary's row as well. After `sql2` restarted, `LabDB` returned to `SYNCHRONIZED` with no manual action.

**Backup and restore.** Full and log backups were restored to a separate database, and both databases had 200,001 rows.

## Run

Requirements: Docker Desktop (WSL 2), ~8 GB RAM, ~10 GB free disk, SSMS.

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1   # builds the AG (steps 01-08)
# continue with scripts 09-16 in SSMS
powershell -ExecutionPolicy Bypass -File .\teardown.ps1  # removes everything
```

To build the AG manually instead of using `setup.ps1`, run `docker compose up -d`, then run scripts `01`-`08` on the servers named in their file names. Run `copy-certificate.ps1` between scripts `02` and `03`.

## Notes

- `CLUSTER_TYPE = NONE` (read-scale AG) is used because containers have no Windows Server Failover Cluster. In production on Windows, the AG sits on a WSFC, which adds automatic failover and a listener.
- Passwords in this repo are lab-only.
