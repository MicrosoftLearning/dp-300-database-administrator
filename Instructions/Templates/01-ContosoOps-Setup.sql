/*
    Lab 16 – Diagnose a slow query with Copilot
    Setup script: Create and seed the ContosoOps database

    Run this script once before starting the lab. It:
      1. Creates the ContosoOps database (drops it first if it exists).
      2. Creates the Technicians and WorkOrders tables.
      3. Creates the dbo.usp_GetOpenWorkOrdersByTechnician stored procedure.
      4. Seeds ~2 million WorkOrders rows so a table scan is measurably slow.

    There is intentionally NO index on (TechnicianID, Status), so the stored
    procedure scans the clustered index and runs slowly. You create the
    supporting index later in the lab with help from GitHub Copilot.

    Estimated run time: 1-3 minutes depending on hardware.
*/

----------------------------------------------------------------------
-- 1. Create the database
----------------------------------------------------------------------
IF DB_ID('ContosoOps') IS NOT NULL
BEGIN
    ALTER DATABASE ContosoOps SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ContosoOps;
END
GO

CREATE DATABASE ContosoOps;
GO

USE ContosoOps;
GO

----------------------------------------------------------------------
-- 2. Create the tables
----------------------------------------------------------------------
CREATE TABLE dbo.Technicians (
    TechnicianID  INT           IDENTITY(1,1) NOT NULL,
    FirstName     NVARCHAR(50)  NOT NULL,
    LastName      NVARCHAR(50)  NOT NULL,
    Region        NVARCHAR(50)  NOT NULL,
    IsActive      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_Technicians PRIMARY KEY CLUSTERED (TechnicianID)
);
GO

CREATE TABLE dbo.WorkOrders (
    WorkOrderID   INT            IDENTITY(1,1) NOT NULL,
    TechnicianID  INT            NOT NULL,
    Status        VARCHAR(20)    NOT NULL,   -- 'Open','InProgress','Closed','Cancelled'
    OpenedDate    DATETIME2(0)   NOT NULL,
    ClosedDate    DATETIME2(0)   NULL,
    Priority      TINYINT        NOT NULL DEFAULT 3,
    Description   NVARCHAR(200)  NOT NULL,
    CONSTRAINT PK_WorkOrders PRIMARY KEY CLUSTERED (WorkOrderID),
    CONSTRAINT FK_WorkOrders_Technicians
        FOREIGN KEY (TechnicianID) REFERENCES dbo.Technicians (TechnicianID),
    CONSTRAINT CK_WorkOrders_Status
        CHECK (Status IN ('Open','InProgress','Closed','Cancelled'))
);
GO

----------------------------------------------------------------------
-- 3. Create the stored procedure the lab investigates
----------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetOpenWorkOrdersByTechnician
    @TechnicianID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT WorkOrderID, OpenedDate, Description
    FROM dbo.WorkOrders
    WHERE TechnicianID = @TechnicianID
      AND Status = 'Open';
END;
GO

----------------------------------------------------------------------
-- 4. Seed data
----------------------------------------------------------------------
-- 200 technicians
INSERT dbo.Technicians (FirstName, LastName, Region)
SELECT TOP (200)
       'Tech',
       CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(10)),
       'Region-' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 10 AS NVARCHAR(2))
FROM sys.all_objects;
GO

-- ~2 million work orders. Only ~20% are 'Open' so the predicate is selective,
-- but the table is large enough that a scan is clearly slow without an index.
;WITH nums AS (
    SELECT TOP (2000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.WorkOrders (TechnicianID, Status, OpenedDate, Description)
SELECT (n % 200) + 1,
       CASE WHEN n % 10 < 2 THEN 'Open'
            WHEN n % 10 < 4 THEN 'InProgress'
            WHEN n % 10 < 9 THEN 'Closed'
            ELSE 'Cancelled' END,
       DATEADD(MINUTE, -n, SYSUTCDATETIME()),
       'Work order ' + CAST(n AS NVARCHAR(12))
FROM nums;
GO

PRINT 'ContosoOps setup complete. The stored procedure is intentionally slow (no supporting index). You can now start the lab in SSMS.';
GO
