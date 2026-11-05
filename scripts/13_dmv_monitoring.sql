-- Blocking
SELECT  r.session_id, r.blocking_session_id, r.status, r.command,
        r.wait_type, r.wait_time AS wait_ms, r.cpu_time, r.logical_reads,
        DB_NAME(r.database_id) AS database_name, s.login_name, s.host_name,
        t.text AS sql_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID AND s.is_user_process = 1
ORDER BY r.blocking_session_id DESC, r.wait_time DESC;

-- Waits
SELECT TOP (10) wait_type, waiting_tasks_count,
       wait_time_ms / 1000.0 AS wait_time_sec,
       CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS DECIMAL(5,2)) AS pct
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE N'SLEEP%' AND wait_type NOT LIKE N'%QUEUE%'
  AND wait_type NOT LIKE N'XE%' AND wait_type NOT LIKE N'BROKER%'
  AND wait_type NOT IN (N'CHECKPOINT_QUEUE', N'WAITFOR', N'DIRTY_PAGE_POLL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
                        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SP_SERVER_DIAGNOSTICS_SLEEP', N'HADR_WORK_QUEUE')
ORDER BY wait_time_ms DESC;

-- CPU
SELECT TOP (10)
       qs.execution_count,
       qs.total_worker_time / 1000 AS total_cpu_ms,
       qs.total_logical_reads,
       qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000 AS avg_duration_ms,
       SUBSTRING(t.text, qs.statement_start_offset / 2 + 1,
                 (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(t.text)
                       ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2 + 1) AS statement_text,
       p.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) p
ORDER BY qs.total_worker_time DESC;

-- Missing indexes
SELECT TOP (10)
       DB_NAME(d.database_id) AS database_name, d.statement AS table_name,
       d.equality_columns, d.inequality_columns, d.included_columns,
       s.user_seeks, s.avg_user_impact
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g        ON g.index_handle = d.index_handle
JOIN sys.dm_db_missing_index_group_stats s   ON s.group_handle = g.index_group_handle
ORDER BY s.user_seeks * s.avg_user_impact DESC;
GO

-- Query Store
-- ALTER DATABASE LabDB SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
-- USE LabDB;
-- SELECT TOP (10) q.query_id, qt.query_sql_text, rs.count_executions,
--        rs.avg_duration / 1000 AS avg_duration_ms, rs.avg_logical_io_reads
-- FROM sys.query_store_query q
-- JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
-- JOIN sys.query_store_plan p ON p.query_id = q.query_id
-- JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
-- ORDER BY rs.avg_duration DESC;
