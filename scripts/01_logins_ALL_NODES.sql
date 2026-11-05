USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'dbm_login')
    CREATE LOGIN dbm_login WITH PASSWORD = N'Dbm_Passw0rd!2026';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'dbm_user')
    CREATE USER dbm_user FOR LOGIN dbm_login;
GO
