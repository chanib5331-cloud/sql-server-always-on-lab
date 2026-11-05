USE master;
GO
EXEC sp_configure 'show advanced options', 1;  RECONFIGURE;
EXEC sp_configure 'blocked process threshold (s)', 5;  RECONFIGURE;
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'Lab_Monitoring')
    DROP EVENT SESSION Lab_Monitoring ON SERVER;
GO
CREATE EVENT SESSION Lab_Monitoring ON SERVER
    ADD EVENT sqlserver.blocked_process_report,
    ADD EVENT sqlserver.sql_statement_completed (
        ACTION (sqlserver.database_name, sqlserver.client_app_name, sqlserver.sql_text)
        WHERE duration > 1000000
    )
    ADD TARGET package0.event_file (
        SET filename = N'/var/opt/mssql/log/Lab_Monitoring.xel', max_file_size = 20, max_rollover_files = 3
    )
    WITH (STARTUP_STATE = ON, MAX_DISPATCH_LATENCY = 5 SECONDS);
GO
ALTER EVENT SESSION Lab_Monitoring ON SERVER STATE = START;
GO
-- Events
SELECT  x.e.value('(@name)[1]', 'varchar(60)')        AS event_name,
        x.e.value('(@timestamp)[1]', 'datetimeoffset') AS event_time_utc,
        x.e.value('(data[@name="duration"]/value)[1]', 'bigint') / 1000 AS duration_ms,
        x.e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text,
        x.e.query('.')                                 AS full_event_xml
FROM (
    SELECT CAST(event_data AS XML) AS event_xml
    FROM sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log/Lab_Monitoring*.xel', NULL, NULL, NULL)
) t
CROSS APPLY t.event_xml.nodes('/event') AS x(e)
ORDER BY event_time_utc DESC;
GO
