USE LabDB;
GO
SET STATISTICS IO, TIME ON;
-- Before (Ctrl+M)
SELECT CustomerID, SUM(Amount) AS total_amount, COUNT(*) AS orders
FROM dbo.Orders
WHERE OrderDate >= DATEADD(DAY, -30, SYSDATETIME()) AND Status = 'Paid'
GROUP BY CustomerID;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_Status_OrderDate')
    CREATE NONCLUSTERED INDEX IX_Orders_Status_OrderDate
        ON dbo.Orders (Status, OrderDate)
        INCLUDE (CustomerID, Amount)
        WITH (FILLFACTOR = 90);
GO
-- After
SELECT CustomerID, SUM(Amount) AS total_amount, COUNT(*) AS orders
FROM dbo.Orders
WHERE OrderDate >= DATEADD(DAY, -30, SYSDATETIME()) AND Status = 'Paid'
GROUP BY CustomerID;
GO
SET STATISTICS IO, TIME OFF;
GO
-- Fragmentation
SELECT  OBJECT_NAME(ips.object_id) AS table_name, i.name AS index_name,
        ips.avg_fragmentation_in_percent, ips.page_count,
        CASE WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
             WHEN ips.avg_fragmentation_in_percent > 5  THEN 'REORGANIZE'
             ELSE 'OK' END AS recommended_action
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 100;
GO
