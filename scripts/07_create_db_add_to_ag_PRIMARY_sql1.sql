USE master;
GO
IF DB_ID(N'LabDB') IS NULL
    CREATE DATABASE LabDB;
GO
ALTER DATABASE LabDB SET RECOVERY FULL;
GO
USE LabDB;
GO
IF OBJECT_ID(N'dbo.Orders') IS NULL
BEGIN
    CREATE TABLE dbo.Orders (
        OrderID    INT IDENTITY(1,1) CONSTRAINT PK_Orders PRIMARY KEY,
        CustomerID INT           NOT NULL,
        OrderDate  DATETIME2(0)  NOT NULL,
        Amount     DECIMAL(10,2) NOT NULL,
        Status     VARCHAR(20)   NOT NULL
    );

    ;WITH n AS (
        SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    )
    INSERT dbo.Orders (CustomerID, OrderDate, Amount, Status)
    SELECT  i % 5000 + 1,
            DATEADD(MINUTE, -i, SYSDATETIME()),
            CAST((i % 1000) + 0.99 AS DECIMAL(10,2)),
            CASE i % 4 WHEN 0 THEN 'New' WHEN 1 THEN 'Paid' WHEN 2 THEN 'Shipped' ELSE 'Closed' END
    FROM n;
END
GO
USE master;
GO
BACKUP DATABASE LabDB TO DISK = N'/var/opt/mssql/data/LabDB_initial.bak' WITH INIT, COMPRESSION;
GO
IF NOT EXISTS (SELECT 1 FROM sys.availability_databases_cluster WHERE database_name = N'LabDB')
    ALTER AVAILABILITY GROUP [ag1] ADD DATABASE LabDB;
GO
