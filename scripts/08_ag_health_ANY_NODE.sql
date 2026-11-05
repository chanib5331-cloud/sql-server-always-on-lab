SELECT  ag.name                         AS ag_name,
        ar.replica_server_name,
        ars.role_desc,
        ars.connected_state_desc,
        ars.synchronization_health_desc,
        ar.availability_mode_desc,
        ar.failover_mode_desc
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar        ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states ars ON ars.replica_id = ar.replica_id
ORDER BY ar.replica_server_name;

SELECT  ar.replica_server_name,
        DB_NAME(drs.database_id)        AS database_name,
        drs.is_local,
        drs.is_primary_replica,
        drs.synchronization_state_desc,
        drs.synchronization_health_desc,
        drs.is_suspended,
        drs.log_send_queue_size         AS log_send_queue_kb,
        drs.redo_queue_size             AS redo_queue_kb,
        drs.last_commit_time
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON ar.replica_id = drs.replica_id
ORDER BY ar.replica_server_name;

-- Seeding
SELECT TOP (10) s.start_time, s.completion_time, db.database_name, s.current_state, s.failure_state_desc
FROM sys.dm_hadr_automatic_seeding s
LEFT JOIN sys.availability_databases_cluster db ON db.group_database_id = s.ag_db_id
ORDER BY s.start_time DESC;
