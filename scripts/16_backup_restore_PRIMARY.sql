USE master;
GO
BACKUP DATABASE LabDB TO DISK = N'/var/opt/mssql/data/LabDB_full.bak'
    WITH INIT, COMPRESSION, CHECKSUM, STATS = 25;
GO
BACKUP LOG LabDB TO DISK = N'/var/opt/mssql/data/LabDB_log.trn'
    WITH INIT, COMPRESSION, CHECKSUM;
GO
RESTORE VERIFYONLY FROM DISK = N'/var/opt/mssql/data/LabDB_full.bak' WITH CHECKSUM;
GO
-- Restore
IF DB_ID(N'LabDB_RestoreTest') IS NOT NULL DROP DATABASE LabDB_RestoreTest;
GO
RESTORE DATABASE LabDB_RestoreTest FROM DISK = N'/var/opt/mssql/data/LabDB_full.bak'
    WITH MOVE N'LabDB'     TO N'/var/opt/mssql/data/LabDB_RestoreTest.mdf',
         MOVE N'LabDB_log' TO N'/var/opt/mssql/data/LabDB_RestoreTest_log.ldf',
         NORECOVERY, STATS = 25;
RESTORE LOG LabDB_RestoreTest FROM DISK = N'/var/opt/mssql/data/LabDB_log.trn' WITH RECOVERY;
GO
SELECT (SELECT COUNT(*) FROM LabDB.dbo.Orders)             AS rows_in_source,
       (SELECT COUNT(*) FROM LabDB_RestoreTest.dbo.Orders) AS rows_in_restore;
GO
-- History
SELECT TOP (10) database_name, type AS backup_type, backup_start_date, backup_finish_date,
       compressed_backup_size / 1024 / 1024 AS size_mb
FROM msdb.dbo.backupset ORDER BY backup_finish_date DESC;
GO
-- Cleanup
DROP DATABASE LabDB_RestoreTest;
GO
