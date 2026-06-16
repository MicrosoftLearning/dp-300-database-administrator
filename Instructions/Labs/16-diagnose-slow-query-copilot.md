---
lab:
    title: 'Lab 16 – Diagnose a slow query with Copilot'
    module: Optimize query performance in Azure SQL
    description: "You'll use GitHub Copilot in SSMS to investigate a slow stored procedure, generate an index recommendation, validate it against a performance baseline, and apply the fix. By the end, you'll understand how to use Copilot to diagnose and resolve slow queries while following a validation gate."
    duration: 20  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: true # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2026-07-01' # Set to the future date when you expect an in-development lab to be released
---

# Diagnose a slow query with Copilot

**Estimated Time: 20 minutes**

You're the DBA for the **ContosoOps** database. The operations team reports that `dbo.usp_GetOpenWorkOrdersByTechnician` runs slowly — a query that should return in milliseconds takes several seconds. Your job: use GitHub Copilot in SSMS to investigate, generate a fix, validate it, and apply it — following the validation gate from the previous unit.

## Prerequisites

- SSMS installed with the **AI Assistance** workload (added via Visual Studio Installer)
- An active GitHub Copilot subscription
- A SQL Server instance or Azure SQL Database where you can create the **ContosoOps** database

> [!NOTE]
> You can also follow along with any database that contains a stored procedure with a slow, scan-heavy query. The steps and validation patterns are identical regardless of the schema.

---

## Setup environment

The setup script creates and seeds the **ContosoOps** database used throughout this lab. If your lab files are already in the **C:\LabFiles** folder, you can skip cloning; otherwise, clone this repository to **C:\LabFiles** first.

1. Open SSMS and connect to your SQL Server instance or Azure SQL Database.

1. Open the file **C:\LabFiles\dp-300-database-administrator\Instructions\Templates\01-ContosoOps-Setup.sql** and select **Execute**. This script:

    - Creates the **ContosoOps** database, the `Technicians` and `WorkOrders` tables, and the `dbo.usp_GetOpenWorkOrdersByTechnician` stored procedure.
    - Seeds approximately 2 million `WorkOrders` rows with no supporting index, so the stored procedure scans the table and runs slowly.

    > &#128221; The seed step inserts about 2 million rows and takes a couple of minutes to complete. Wait for the **setup complete** message before continuing.

---

## Open the slow query in SSMS and analyze with GitHub Copilot

1. In SSMS, open a new query window against the **ContosoOps** database.

1. Enable **Include Actual Execution Plan** (or press **Ctrl+M**), then run the stored procedure with I/O and time statistics enabled to confirm it's slow:

   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   GO

   EXEC dbo.usp_GetOpenWorkOrdersByTechnician @TechnicianID = 42;
   GO

   SET STATISTICS IO OFF;
   SET STATISTICS TIME OFF;
   ```

   Note the **logical reads** and **elapsed time** from the Messages tab — this is your baseline. In the execution plan, confirm a **table scan** (clustered index scan) on `WorkOrders`.

1. Open the stored procedure definition. In **Object Explorer**, expand **ContosoOps** > **Programmability** > **Stored Procedures**, right-click `dbo.usp_GetOpenWorkOrdersByTechnician`, and select **Modify** to view its query text.

1. Select the `SELECT` statement inside the procedure, right-click the selection, and choose **Explain with Copilot**. GitHub Copilot opens a chat panel and describes the query. In the explanation, Copilot identifies a table scan on `WorkOrders` caused by a filter predicate on `TechnicianID` and `Status` with no supporting index.

---

## Ask Copilot for an index recommendation

1. In the Copilot chat, type:

   > "This query has a table scan on WorkOrders filtered by TechnicianID and Status. What index would you recommend?"

1. Copilot responds with an index recommendation similar to the following:

    ```sql
    -- Copilot-suggested index
    CREATE NONCLUSTERED INDEX IX_WorkOrders_TechnicianID_Status
    ON dbo.WorkOrders (TechnicianID, Status)
    INCLUDE (WorkOrderID, OpenedDate, Description);
    ```

1. Read the explanation Copilot provides alongside the index. It should describe the key column order — `TechnicianID` first as the equality predicate, `Status` second as a range or equality predicate — and explain why the `INCLUDE` columns avoid a key lookup.

> [!NOTE]
> The `INCLUDE` columns Copilot suggests depend on the columns it can infer from the query text. If your stored procedure selects additional columns not in Copilot's context, add them to the `INCLUDE` list before creating the index.

---

## Validate the recommendation

Before you create the index, apply the validation gate we learned.

1. Check whether a similar index already exists to avoid redundant indexes:

    ```sql
    -- Check for existing indexes on WorkOrders
    SELECT
        i.name             AS index_name,
        i.type_desc,
        c.name             AS column_name,
        ic.is_included_column,
        ic.key_ordinal
    FROM sys.indexes AS i
    JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    JOIN sys.columns       AS c  ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE i.object_id = OBJECT_ID('dbo.WorkOrders')
    ORDER BY i.index_id, ic.key_ordinal;
    ```

    If an index on `TechnicianID` already exists, check whether it includes `Status` and the `INCLUDE` columns. If it does, you don't need the new index — ask Copilot to refine the recommendation based on the existing index.

> [!NOTE]
> You already captured a baseline (logical reads, elapsed time, and the table scan in the execution plan) when you confirmed the procedure was slow. Keep those numbers handy — you compare against them after creating the index.

---

## Apply and verify

1. Create the Copilot-suggested index:

    ```sql
    CREATE NONCLUSTERED INDEX IX_WorkOrders_TechnicianID_Status
    ON dbo.WorkOrders (TechnicianID, Status)
    INCLUDE (WorkOrderID, OpenedDate, Description);
    ```

1. Run the stored procedure again with `SET STATISTICS IO ON; SET STATISTICS TIME ON;` and compare the new logical reads and elapsed time against the baseline you captured earlier. Confirm that logical reads dropped sharply and elapsed time fell to subsecond.

1. Inspect the actual execution plan again. Confirm that the plan now shows an **Index Seek** on `IX_WorkOrders_TechnicianID_Status` rather than the table scan.

1. In a real environment, validate the change in non-production first, then schedule the index creation for production during a maintenance window.

---

## Expected outcome

A targeted nonclustered index eliminates the table scan on `WorkOrders`, and the stored procedure returns in subsecond time instead of several seconds. You followed the full validation gate: you confirmed the slow query and captured a baseline, checked for redundant indexes, applied the Copilot-recommended index, and verified the improvement with statistics and the execution plan.

> [!IMPORTANT]
> The index creation itself causes a brief table lock in standard editions. For large tables in production, use the `ONLINE = ON` option if your service tier supports it, and schedule the operation during low-traffic hours.
