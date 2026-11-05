-- Fail-back: N'sql1'
USE master;
GO
ALTER AVAILABILITY GROUP [ag1]
    MODIFY REPLICA ON N'sql2' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
GO
SELECT ar.replica_server_name, drs.synchronization_state_desc
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON ar.replica_id = drs.replica_id;
GO
IF NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states WHERE is_local = 0)
   OR EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states
              WHERE is_local = 0 AND synchronization_state_desc <> N'SYNCHRONIZED')
BEGIN
    ;THROW 50001, N'Secondary is not SYNCHRONIZED - failover stopped. The AG was not taken offline.', 1;
END;
ALTER AVAILABILITY GROUP [ag1] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 1);
ALTER AVAILABILITY GROUP [ag1] OFFLINE;
GO
