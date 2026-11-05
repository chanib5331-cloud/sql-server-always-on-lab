USE master;
GO
IF DB_ID(N'DBAdmin') IS NULL CREATE DATABASE DBAdmin;
GO
USE DBAdmin;
GO
IF OBJECT_ID(N'dbo.AgHealthLog') IS NULL
    CREATE TABLE dbo.AgHealthLog (
        LogID          INT IDENTITY PRIMARY KEY,
        CheckTime      DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        ServerName     SYSNAME      NOT NULL,
        ReplicaName    SYSNAME      NULL,
        DatabaseName   SYSNAME      NULL,
        RoleDesc       NVARCHAR(60) NULL,
        ConnectedState NVARCHAR(60) NULL,
        SyncState      NVARCHAR(60) NULL,
        SyncHealth     NVARCHAR(60) NULL,
        LogSendQueueKB BIGINT       NULL,
        RedoQueueKB    BIGINT       NULL
    );
GO
USE msdb;
GO
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA - AG Health Check')
    EXEC msdb.dbo.sp_delete_job @job_name = N'DBA - AG Health Check';
GO
EXEC msdb.dbo.sp_add_job @job_name = N'DBA - AG Health Check', @enabled = 1,
     @description = N'Logs the Always On state of every replica visible from this server, every 5 minutes';
EXEC msdb.dbo.sp_add_jobstep @job_name = N'DBA - AG Health Check',
     @step_name = N'Log AG state', @subsystem = N'TSQL', @database_name = N'DBAdmin',
     @command = N'
INSERT dbo.AgHealthLog (ServerName, ReplicaName, DatabaseName, RoleDesc, ConnectedState, SyncState, SyncHealth, LogSendQueueKB, RedoQueueKB)
SELECT @@SERVERNAME, ar.replica_server_name, DB_NAME(drs.database_id), ars.role_desc, ars.connected_state_desc,
       drs.synchronization_state_desc, drs.synchronization_health_desc,
       drs.log_send_queue_size, drs.redo_queue_size
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON ar.replica_id = drs.replica_id
LEFT JOIN sys.dm_hadr_availability_replica_states ars ON ars.replica_id = drs.replica_id;

DECLARE @server SYSNAME = @@SERVERNAME;
IF EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states
           WHERE synchronization_health_desc <> N''HEALTHY'')
   OR EXISTS (SELECT 1 FROM sys.dm_hadr_availability_replica_states
              WHERE connected_state_desc <> N''CONNECTED'')
    RAISERROR(N''AG health problem detected on %s'', 16, 1, @server) WITH LOG;';
EXEC msdb.dbo.sp_add_schedule @schedule_name = N'Every 5 minutes',
     @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 5;
EXEC msdb.dbo.sp_attach_schedule @job_name = N'DBA - AG Health Check', @schedule_name = N'Every 5 minutes';
EXEC msdb.dbo.sp_add_jobserver @job_name = N'DBA - AG Health Check', @server_name = N'(local)';
GO
-- Test
EXEC msdb.dbo.sp_start_job @job_name = N'DBA - AG Health Check';
WAITFOR DELAY '00:00:05';
SELECT TOP (20) * FROM DBAdmin.dbo.AgHealthLog ORDER BY LogID DESC;
GO
