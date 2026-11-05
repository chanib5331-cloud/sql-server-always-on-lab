USE master;
GO
IF EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states
           WHERE is_local = 1 AND database_id = DB_ID(N'LabDB') AND is_suspended = 1)
    ALTER DATABASE [LabDB] SET HADR RESUME;
GO
-- Primary
IF EXISTS (SELECT 1 FROM sys.dm_hadr_availability_replica_states
           WHERE is_local = 1 AND role_desc = N'PRIMARY')
    ALTER AVAILABILITY GROUP [ag1] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);
GO
