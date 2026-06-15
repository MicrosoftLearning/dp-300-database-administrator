---
lab:
    title: 'Lab 16 – Diagnose a slow query with Copilot'
    module: Optimize query performance in Azure SQL
    description: "You'll use Microsoft Copilot in the Azure portal and GitHub Copilot in SSMS to investigate a regressed stored procedure, generate an index recommendation, validate it against a performance baseline, and apply the fix. By the end, you'll understand how to use Copilot to diagnose and resolve slow queries while following a validation gate."
    duration: 30  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: true # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2026-07-01' # Set to the future date when you expect an in-development lab to be released
---

# Diagnose a slow query with Copilot

**Estimated Time: 30 minutes**

You're the DBA for the **ContosoOps** database. The operations team reports that `dbo.usp_GetOpenWorkOrdersByTechnician` has been running slow for the last two days. Response times that used to average 150 ms are now averaging 3.2 seconds. Your job: use Copilot to investigate, generate a fix, validate it, and apply it — following the validation gate from the previous unit.

## Prerequisites

- Access to an Azure SQL Database instance in the Azure portal
- SSMS installed with the **AI Assistance** workload (added via Visual Studio Installer)
- An active GitHub Copilot subscription
- The **ContosoOps** database with the `WorkOrders` and `Technicians` tables (or any equivalent database where you can identify a slow query from Query Store)

> [!NOTE]
> If you don't have a ContosoOps database, you can follow along with any Azure SQL Database that has Query Store enabled and contains a stored procedure you can observe in performance data. The steps and validation patterns are identical regardless of the schema.

---

## Use Copilot in the portal to identify the problem

1. In the [Azure portal](https://portal.azure.com), navigate to your Azure SQL Database resource.

1. On the resource page, open the **Microsoft Copilot** pane from the portal's top toolbar. The Copilot pane opens on the right side of the portal.

1. In the Copilot chat, ask:

   > "What queries have regressed in performance in the last 24 hours?"

1. Review the response. Copilot queries the integrated Query Store signals and returns a ranked list of queries with increased average duration. Confirm that `dbo.usp_GetOpenWorkOrdersByTechnician` appears as a top contributor. Note the **query ID** that Copilot references — you use it in the next task.

> [!TIP]
> If Copilot returns multiple queries, ask a follow-up: "Show me the execution trend for query ID *\<id\>* over the last 48 hours." Copilot can surface duration and logical reads over time using the same Query Store data that **Query Performance Insight** exposes.

---

## Open the slow query in SSMS and analyze with GitHub Copilot

1. Open SSMS and connect to the ContosoOps database.

1. Open a new query window and run the following script to retrieve the stored procedure's query text and recent execution statistics from Query Store:

   ```sql
   -- Find the stored procedure's query text and current execution plan
   SELECT TOP 5
       qt.query_sql_text,
       rs.avg_duration / 1000.0 AS avg_duration_ms,
       p.plan_id
   FROM sys.query_store_query_text AS qt
   JOIN sys.query_store_query       AS q  ON qt.query_text_id = q.query_text_id
   JOIN sys.query_store_plan        AS p  ON q.query_id       = p.query_id
   JOIN sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
   WHERE qt.query_sql_text LIKE '%GetOpenWorkOrdersByTechnician%'
   ORDER BY rs.avg_duration DESC;
   ```

1. In the results, copy the `query_sql_text` value for the slow procedure. Select the query text directly in the editor.

1. Right-click the selected text and choose **Explain with Copilot**. GitHub Copilot opens a chat panel and describes the query. In the explanation, Copilot identifies a table scan on `WorkOrders` caused by a filter predicate on `TechnicianID` and `Status` with no supporting index.

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

Before you create the index, apply the validation gate from the previous unit.

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

1. Capture a pre-index baseline by running the stored procedure in non-production with I/O and time statistics enabled:

    ```sql
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;
    GO

    EXEC dbo.usp_GetOpenWorkOrdersByTechnician @TechnicianID = 42;
    GO

    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
    ```

    Note the **logical reads** and **elapsed time** from the Messages tab. This is your baseline.

1. Enable **Include Actual Execution Plan** in SSMS (or press **Ctrl+M**), run the stored procedure again, and inspect the plan. Confirm that the table scan on `WorkOrders` appears in the current plan. This validates what Copilot identified.

---

## Apply and verify

1. Create the Copilot-suggested index in your non-production environment:

    ```sql
    CREATE NONCLUSTERED INDEX IX_WorkOrders_TechnicianID_Status
    ON dbo.WorkOrders (TechnicianID, Status)
    INCLUDE (WorkOrderID, OpenedDate, Description);
    ```

1. Run the stored procedure again with `SET STATISTICS IO ON; SET STATISTICS TIME ON;` and compare the new logical reads and elapsed time against the baseline you captured in step 13. Confirm that logical reads decreased and elapsed time dropped toward the historical 150 ms baseline.

1. Inspect the actual execution plan again. Confirm that the plan now shows an **Index Seek** on `IX_WorkOrders_TechnicianID_Status` rather than the table scan.

1. After validating in non-production, schedule the index creation for production during a maintenance window. After the maintenance window, check Query Store the following day to confirm that the average duration for `dbo.usp_GetOpenWorkOrdersByTechnician` has returned to its historical baseline.

---

## Expected outcome

A targeted nonclustered index eliminates the table scan on `WorkOrders`. Average duration for `dbo.usp_GetOpenWorkOrdersByTechnician` returns to approximately 150 ms. You followed the full validation gate: you checked for redundant indexes, captured a performance baseline, inspected the execution plan, validated in non-production, and scheduled production deployment through a maintenance window.

> [!IMPORTANT]
> The index creation itself causes a brief table lock in standard editions. For large tables in production, use the `ONLINE = ON` option if your service tier supports it, and schedule the operation during low-traffic hours.
