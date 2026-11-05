-- Primary
USE LabDB;
INSERT dbo.Orders (CustomerID, OrderDate, Amount, Status)
VALUES (999999, SYSDATETIME(), 123.45, 'SyncTest');
SELECT COUNT(*) AS total_rows FROM dbo.Orders;

-- Secondary
-- USE LabDB;
-- SELECT * FROM dbo.Orders WHERE CustomerID = 999999;
-- SELECT COUNT(*) AS total_rows FROM dbo.Orders;
-- Fails
-- INSERT dbo.Orders (CustomerID, OrderDate, Amount, Status) VALUES (1, SYSDATETIME(), 1, 'Fail');
