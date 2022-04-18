---
lab:
    title: 'Lab 10 – Isolate problem areas in poorly performing queries in a SQL Database'
    module: 'Optimize query performance in Azure SQL'
---

# Isolate problem areas in poorly performing queries in a SQL Database

**Estimated Time: 30 minutes**

You've been hired as a Senior Database Administrator to help with performance issues currently happening when users query the *AdventureWorks2017* database. Your job is to identify issues in query performance and remedy them using techniques learned in this module.

You'll run queries with suboptimal performance, examine the query plans, and attempt to make improvements within the database.

**Note:** These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Restore a database

1. Download the database backup file located on **https://github.com/MicrosoftLearning/dp-300-database-administrator/blob/master/Instructions/Templates/AdventureWorks2017.bak** to **C:\LabFiles\Monitor and optimize** path on the lab virtual machine (create the folder structure if it does not exist).

    ![Picture 03](../images/dp-300-module-07-lab-03.png)

1. Select the Windows Start button and type SSMS. Select **Microsoft SQL Server Management Studio 18** from the list.  

    ![Picture 01](../images/dp-300-module-01-lab-34.png)

1. When SSMS opens, notice that the **Connect to Server** dialog will be pre-populated with the default instance name. Select **Connect**.

    ![Picture 02](../images/dp-300-module-07-lab-01.png)

1. Select the **Databases** folder, and then **New Query**.

    ![Picture 03](../images/dp-300-module-07-lab-04.png)

1. In the new query window, copy and paste the below T-SQL into it. Execute the query to restore the database.

    ```sql
    RESTORE DATABASE AdventureWorks2017
    FROM DISK = 'C:\LabFiles\Monitor and optimize\AdventureWorks2017.bak'
    WITH RECOVERY,
          MOVE 'AdventureWorks2017' 
            TO 'C:\LabFiles\Monitor and optimize\AdventureWorks2017.mdf',
          MOVE 'AdventureWorks2017_log'
            TO 'C:\LabFiles\Monitor and optimize\AdventureWorks2017_log.ldf';
    ```

    **Note:** The database backup file name and path should match with what you've downloaded on step 1, otherwise the command will fail.

1. You should see a successful message after the restore is complete.

    ![Picture 03](../images/dp-300-module-07-lab-05.png)

## Run a query to generate actual execution plan

There are several ways to generate an execution plan in SQL Server Management Studio.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    **Note:** Use **SHOWPLAN_ALL** to see a text version of a query's execution plan in the results pane instead of graphically in a separate tab.

    ```sql
    USE AdventureWorks2017;
    GO

    SET SHOWPLAN_ALL ON;
    GO

    SELECT BusinessEntityID
    FROM HumanResources.Employee
    WHERE NationalIDNumber = '14417807';
    GO

    SET SHOWPLAN_ALL OFF;
    GO
    ```

    You'll see a text version of the execution plan, instead of the results of running the **SELECT** statement.

    ![Screenshot showing the text version of a query plan](../images/dp-3300-module-55-lab-06.png)

1. Examine the text in the second row's StmtText field:

    ```console
    |--Index Seek(OBJECT:([AdventureWorks2017].[HumanResources].[Employee].[AK_Employee_NationalIDNumber]), SEEK:([AdventureWorks2017].[HumanResources].[Employee].[NationalIDNumber]=CONVERT_IMPLICIT(nvarchar(4000),[@1],0)) ORDERED FORWARD)
    ```

    The above text explains that the execution plan use an **Index Seek** on the **AK_Employee_NationalIDNumber** key. It also shows that the execution plan needed to do a **CONVERT_IMPLICIT** step.

## Resolve a Performance Problem from an Execution Plan

1. Copy and paste the code below into a new query window.

    Select the **Include Actual Execution Plan** icon as shown below before running the query, or press <kbd>CTRL</kbd>+<kbd>M</kbd>. Execute the query by selecting **Execute** or press <kbd>F5</kbd>. Make note of the execution plan and the logical reads in the messages tab.

    ```sql
    SET STATISTICS IO, TIME ON;

    SELECT [SalesOrderID] ,[CarrierTrackingNumber] ,[OrderQty] ,[ProductID], [UnitPrice] ,[ModifiedDate]
    FROM [AdventureWorks2017].[Sales].[SalesOrderDetail]
    WHERE [ModifiedDate] > '2012/01/01' AND [ProductID] = 772;
    ```

    :::image type="content" source="../media/dp-3300-module-55-lab-07.png" alt-text="Screenshot showing the execution plan for the query":::

    When reviewing the execution plan you will note there is a key lookup. If you hover your mouse over the icon, you will see that the properties indicate it is performed for each row retrieved by the query. You can see the execution plan is performing a Key Lookup operation.

    :::image type="content" source="../media/dp-3300-module-55-lab-08.png" alt-text="Screenshot showing the output list of columns.":::

    Make a note of the columns in the Output list, as these fields need to be added to a covering index.

    To identify what index needs to be altered in order to remove the key lookup, you need to examine the index seek above it. Hover over the index seek operator with your mouse and the properties of the operator will appear.

    :::image type="content" source="../media/execution-plan-for-index.png" alt-text="Screenshot showing the NonClustered index.":::

1. Fix the Key Lookup and rerun the query to see the new plan.

    Key Lookups can be removed by adding a COVERING index that INCLUDES all fields being returned or searched in the query. In this example the index only uses the ProductID.

    ```sql
    CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail]
    (
    [ProductID] ASC
    )
    ```

    If we add the Output List fields to the index as Included Columns, then the Key Lookup will be removed. Since the index already exists you either have to DROP the index and recreate it or set the **DROP_EXISTING=ON** in order to add the columns. Note **ProductID** is already part of the index and does not need to be added as an included column. There is another performance improvement we can make to the index by adding the **ModifiedDate**.

    ```sql
    CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID]
    ON [Sales].[SalesOrderDetail] ([ProductID],[ModifiedDate])
    INCLUDE ([CarrierTrackingNumber],[OrderQty],[UnitPrice])
    WITH (DROP_EXISTING = on);
    GO
    ```

1. Rerun the query from step 1. Make note of the changes to the logical reads and execution plan changes. The plan now only needs to use the nonclustered index.

    :::image type="content" source="../media/improved-execution-plan.png" alt-text="Screenshot showing the improved execution plan":::

## Use Query Store (QS) to detect and handle regression in AdventureWorks2017

Next you'll run a workload to generate query statistics for QS, examine Top Resource Consuming Queries to identify poor performance, and see how to force a better execution plan.

## Run a workload to generate query stats for Query Store

1. Copy and paste the code below into a new query window and execute it by selecting **Execute**. This script will enable the Query Store for AdventureWorks2017 and sets the database to Compatibility Level 100.

    ```sql
    USE master;
    GO

    ALTER DATABASE AdventureWorks2017 SET QUERY_STORE = ON;
    GO

    ALTER DATABASE AdventureWorks2017 SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
    GO

    ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 100;
    GO
    ```

    Changing the compatibility level is like moving the database back in time. It restricts the features SQL server can use to those that were available in SQL Server 2008.

1. Select the **File** > **Open** > **File** menu in SQL Server Management Studio.

1. Navigate to the **D:\Labfiles\Query Performance\CreateRandomWorkloadGenerator.sql** file.

1. Select the file to load it into Management Studio and then select **Execute** or press <kbd>F5</kbd> to execute the query.

    :::image type="content" source="../media/dp-3300-module-55-lab-09.png" alt-text="Screenshot showing the Open File menu.":::

1. Select the **File** > **Open** > **File** menu in SQL Server Management Studio.

1. Navigate to the **D:\Labfiles\Query Performance\ExecuteRandomWorkload.sql** script and open it.

1. Select **Execute** or press <kbd>F5</kbd> to run the script.

    After execution completes, run the script a second time to create additional load on the server. Leave the query tab open for this query.

1. Copy and paste the code below into a new query window and execute it by selecting **Execute** or press <kbd>F5</kbd>. This script changes the database compatibility mode using the below script to SQL Server 2019 (**150**). Making all the database features and improvements since SQL Server 2008 available to the server.

    ```sql
    USE master;
    GO

    ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 150;
    GO
    ```

1. Navigate back to the query tab from step 6, and re-execute.

## Examine Top Resource Consuming Queries to identify poor performance

1. In order to view the Query Store node you will need to refresh the AdventureWorks2017 database in Management Studio. Right click on database name and choose select refresh. You will then see the Query Store node under the database.

    :::image type="content" source="../media/dp-3300-module-55-lab-10.png" alt-text="Expand Query Store":::

1. Expand the **Query Store** node to view all the available reports.

    :::image type="content" source="../media/dp-3300-module-55-lab-11.png" alt-text="Top Resource Consuming Queries Report":::

1. Select **Top Resource Consuming Queries Report**.

1. The report will open as shown below. On the right, select the menu dropdown, then select **Configure**.
    :::image type="content" source="../media/dp-3300-module-55-lab-12.png" alt-text="Select Configure":::

1. In the configuration screen, change the filter for the minimum number of query plans to 2. Then select **OK**.

    :::image type="content" source="../media/dp-3300-module-55-lab-13.png" alt-text="Set Minimum number of query plans":::

1. Choose the query with the longest duration by selecting the left most bar in the bar chart in the top left portion of the report.

    :::image type="content" source="../media/dp-3300-module-55-lab-14.png" alt-text="Query with longest duration":::

‎This will show you the query and plan summary for your longest duration query in your query store.

## Force a better execution plan

1. Navigate to the plan summary portion of the report as shown below. You will note there are two execution plans with widely different durations.

    :::image type="content" source="../media/dp-3300-module-55-lab-15.png" alt-text="Plan summary":::

1. Select the Plan ID with the lowest duration (this is indicated by a lower position on the Y-axis of the chart) in the top right window of the report. In the graphic above, it’s PlanID 43. Select the plan ID next to the Plan Summary chart (it should be highlighted like in the above screenshot).

1. Select **Force Plan** under the summary chart. A confirmation window will popup, choose Yes to force the plan.

    :::image type="content" source="../media/dp-3300-module-55-lab-16.png" alt-text="Screenshot showing the confirmation.":::

    Once forced you will see that the Forced Plan is now greyed out and the plan in the plan summary window now has a check mark indicating is it forced.

    :::image type="content" source="../media/dp-3300-module-55-lab-17.png" alt-text="Screenshot showing the forced check mark.":::

There can be times when the query optimizer can make a poor choice on which execution plan to use. When this happens you can force SQL server to use the plan you want when you know it performs better.

## Use query hints to impact performance in AdventureWorks2017

Next you'll run a workload, change the query to use a parameter, and apply query hint to the query to optimize for a value, and re-execute.

Before continuing with the exercise close all the current query windows by selecting the **Window** menu, then select **Close All Documents**. In the popup select **No**.

## Run a workload

Run the queries below, examine the Actual Execution Plan.

1. Select New Query and select on **Include Actual Execution Plan** icon before running the query or use <kbd>CTRL</kbd>+<kbd>M</kbd>.

    :::image type="content" source="../media/dp-3300-module-55-lab-18.png" alt-text="Include Actual Execution Plan":::

1. Execute the query below. Note that the execution plan shows an index seek operator.

    ```sql
    USE AdventureWorks2017;
    GO

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID=288;
    ```

    :::image type="content" source="../media/dp-3300-module-55-lab-19.png" alt-text="Screenshot showing the updated execution plan":::

1. Now run the next query.

    The only change this time is that the SalesPersonID value is set to 277. Note the Clustered Index Scan operation in the execution plan.

    ```sql
    USE AdventureWorks2017;
    GO

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID=277;
    ```

    :::image type="content" source="../media/dp-3300-module-55-lab-20.png" alt-text="Screenshot showing the sql statement.":::

Based on the index statistics the query optimizer has chosen a different execution plan because of the different values in the WHERE clause. Because this query uses a constant in its WHERE clause, the optimizer sees each of these queries as unique and generates a different execution plan each time.

## Change the query to use a variable and use a Query Hint

1. Change the query to use a variable value for SalesPersonID.

1. Use the T-SQL **DECLARE** statement to declare <strong>@SalesPersonID</strong> so you can pass in a value instead of hard-code the value in the **WHERE** clause. You should ensure that the data type of your variable matches the data type of the column in the target table.

    ```sql
    USE AdventureWorks2017;
    GO

    SET STATISTICS IO, TIME ON;

    DECLARE @SalesPersonID INT;

    SELECT @SalesPersonID = 288;

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID= @SalesPersonID;
    ```

    If you examine the execution plan, you will note is using an index scan to get the results. This is because SQL Server can't make good optimizations because it can't know the value of the local variable until runtime.

1. You can help the query optimizer make better choices by providing a query hint. Rerun the above query with an new option:

    ```sql
    USE AdventureWorks2017
    GO

    SET STATISTICS IO, TIME ON;

    DECLARE @SalesPersonID INT;

    SELECT @SalesPersonID = 288;

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID= @SalesPersonID
    OPTION (RECOMPILE);
    ```

    Note that the query optimizer has been able to choose a more efficient execution plan. The RECOMPILE option causes the query compiler to replace the variable with its value.

You can see in the message tab that the difference between logical reads is 68% (689 versus 409) more for the query without the query hint.

To finish this exercise select **Done** below.
