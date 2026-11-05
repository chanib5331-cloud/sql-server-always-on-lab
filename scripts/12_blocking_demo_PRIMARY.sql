-- Window 1
USE LabDB;
BEGIN TRAN;
    UPDATE dbo.Orders SET Status = 'Locked' WHERE OrderID = 1;
    WAITFOR DELAY '00:00:30';
ROLLBACK;

-- Window 2
-- USE LabDB;
-- SELECT * FROM dbo.Orders WHERE OrderID = 1;
