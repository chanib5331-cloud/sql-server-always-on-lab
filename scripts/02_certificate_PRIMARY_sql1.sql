USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'MasterKey_Passw0rd!2026';
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'dbm_certificate')
    CREATE CERTIFICATE dbm_certificate WITH SUBJECT = N'Always On endpoint certificate';
GO
BACKUP CERTIFICATE dbm_certificate
    TO FILE = N'/var/opt/mssql/data/dbm_certificate.cer'
    WITH PRIVATE KEY (
        FILE = N'/var/opt/mssql/data/dbm_certificate.pvk',
        ENCRYPTION BY PASSWORD = N'Cert_Passw0rd!2026'
    );
GO
