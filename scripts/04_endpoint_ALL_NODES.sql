USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_mirroring_endpoints WHERE name = N'Hadr_endpoint')
    CREATE ENDPOINT [Hadr_endpoint]
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            ROLE = ALL,
            AUTHENTICATION = CERTIFICATE dbm_certificate,
            ENCRYPTION = REQUIRED ALGORITHM AES
        );
GO
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];
GO
ALTER EVENT SESSION AlwaysOn_health ON SERVER WITH (STARTUP_STATE = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = N'AlwaysOn_health')
    ALTER EVENT SESSION AlwaysOn_health ON SERVER STATE = START;
GO
SELECT @@SERVERNAME AS server_name, name, state_desc, role_desc
FROM sys.database_mirroring_endpoints;
GO
