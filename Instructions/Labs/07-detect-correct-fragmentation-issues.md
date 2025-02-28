---
lab:
    title: 'Lab 7 – Detect and correct fragmentation issues'
    module: 'Monitor and optimize operational resources in Azure SQL'
---

# Detect and correct fragmentation issues

**Estimated Time: 20 minutes**

The students will take the information gained in the lessons to scope out the deliverables for a digital transformation project within AdventureWorks. Examining the Azure portal as well as other tools, students will determine how to utilize native tools to identify and resolve performance related issues. Finally, students will be able to identify fragmentation within the database as well as learn steps to resolve it appropriately.

You have been hired as a database administrator to identify performance related issues and provide viable solutions to resolve any issues found. AdventureWorks has been selling bicycles and bicycle parts directly to consumers and distributors for over a decade. Recently the company has noticed performance degradation in their products that are used to service customer requests. You need to use SQL tools to identify the performance issues and suggest methods to resolve them.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Setup environment

Download the lab files from GitHub.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the command palette (Ctrl+Shift+P) and type **Git: Clone**. Select the **Git: Clone** option.

1. Paste the following URL into the **Repository URL** field and select **Enter**.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

1. Save the repository to the **C:\LabFiles** folder on the lab virtual machine or your local machine if one wasn't provided (create the folder if it does not exist).

---

## Restore a database

If you already have the **AdventureWorks2017** database restored, you can skip this section.

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).

1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check to the **Trust server certificate** checkbox.

    > &#128221; Note that if you are using your own SQL Server instance, you will need to connect to it using the appropriate server instance name and credentials.

1. Select the **Databases** folder, and then **New Query**.

1. In the new query window, copy and paste the below T-SQL into it. Execute the query to restore the database.

    ```sql
    RESTORE DATABASE AdventureWorks2017
    FROM DISK = 'C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\Shared\AdventureWorks2017.bak'
    WITH RECOVERY,
          MOVE 'AdventureWorks2017' 
            TO 'C:\LabFiles\AdventureWorks2017.mdf',
          MOVE 'AdventureWorks2017_log'
            TO 'C:\LabFiles\AdventureWorks2017_log.ldf';
    ```

    > &#128221; You must have a folder named **C:\LabFiles**. If you don't have this folder, create it or specify another location for the database and backup files.

1. Under the **Messages** tab, you should see a message indicating that the database was restored successfully.

## Investigate index fragmentation

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE AdventureWorks2017

    GO
    
    SELECT i.name Index_Name
     , avg_fragmentation_in_percent
     , db_name(database_id)
     , i.object_id
     , i.index_id
     , index_type_desc
    FROM sys.dm_db_index_physical_stats(db_id('AdventureWorks2017'),object_id('person.address'),NULL,NULL,'DETAILED') ps
     INNER JOIN sys.indexes i ON ps.object_id = i.object_id 
     AND ps.index_id = i.index_id
    WHERE avg_fragmentation_in_percent > 50 -- find indexes where fragmentation is greater than 50%
    ```

    This query will report any indexes that have a fragmentation over **50%**. The query should not return any result.

1. Index fragmentation can be caused by a number of factors, including the following:

    - Frequent updates to the table or index.
    - Frequent inserts or deletes to the table or index.
    - Page splits.

    To increase the fragmentation level of the Person.Address table and its indexes, you will insert and delete a large number of records. To do this, you will run the following query.

    Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE AdventureWorks2017

    GO
    
    -- Insert 60000 records into the Address table    

    INSERT INTO [Person].[Address] 
        ([AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [SpatialLocation], [rowguid], [ModifiedDate])
    SELECT 
        'Split Avenue ' + CAST(v1.number AS VARCHAR(10)), 
        'Apt ' + CAST(v2.number AS VARCHAR(10)), 
        'PageSplitTown', 
        100 + (v1.number % 60),  -- 60 different StateProvinceIDs (100-159)
        '88' + RIGHT('000' + CAST(v2.number AS VARCHAR(3)), 3), -- Structured postal codes
        NULL, 
        NEWID(), -- Ensure unique rowguid
        GETDATE()
    FROM master.dbo.spt_values v1
    CROSS JOIN master.dbo.spt_values v2
    WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 300 
    AND v2.type = 'P' AND v2.number BETWEEN 1 AND 200;
    GO
    
    -- DELETE 25000 records from the Address table
    DELETE FROM [Person].[Address] WHERE AddressID BETWEEN 35001 AND 60000;

    GO

    -- Insert 40000 records into the Address table
    INSERT INTO [Person].[Address] 
        ([AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [SpatialLocation], [rowguid], [ModifiedDate])
    SELECT 
        'Fragmented Street ' + CAST(v1.number AS VARCHAR(10)), 
        'Suite ' + CAST(v2.number AS VARCHAR(10)), 
        'FragmentCity', 
        100 + (v1.number % 60),  -- 60 different StateProvinceIDs (100-159)
        '99' + RIGHT('000' + CAST(v2.number AS VARCHAR(3)), 3), -- Structured postal codes
        NULL, 
        NEWID(), -- Ensure a unique rowguid per row
        GETDATE()
    FROM master.dbo.spt_values v1
    CROSS JOIN master.dbo.spt_values v2
    WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 200 
    AND v2.type = 'P' AND v2.number BETWEEN 1 AND 200;

    GO
    ```

    This query will increase the fragmentation level of the Person.Address table and its indexes by adding and deleting a large number of records.

1. Execute the first query again. Now you should be able to see four highly fragmented indexes.

1. Select a **New Query** and copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    SET STATISTICS IO,TIME ON

    GO
        
    USE AdventureWorks2017

    GO
        
    SELECT DISTINCT (StateProvinceID)
        ,count(StateProvinceID) AS CustomerCount
    FROM person.Address
    GROUP BY StateProvinceID
    ORDER BY count(StateProvinceID) DESC;
        
    GO
    ```

    Select the **Messages** tab in the result pane of SQL Server Management Studio. Make note of the count of logical reads performed by the query on the **Address** table.

## Rebuild fragmented indexes

1. Select a **New Query** and copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE AdventureWorks2017

    GO
    
    ALTER INDEX [IX_Address_StateProvinceID] ON [Person].[Address] REBUILD PARTITION = ALL 
    WITH (PAD_INDEX = OFF, 
        STATISTICS_NORECOMPUTE = OFF, 
        SORT_IN_TEMPDB = OFF, 
        IGNORE_DUP_KEY = OFF, 
        ONLINE = OFF, 
        ALLOW_ROW_LOCKS = ON, 
        ALLOW_PAGE_LOCKS = ON)
    ```

1. Select a **New Query** and Execute the following query to confirm that the **IX_Address_StateProvinceID** index no longer has fragmentation greater than 50%.

    ```sql
    USE AdventureWorks2017

    GO
        
    SELECT DISTINCT i.name Index_Name
        , avg_fragmentation_in_percent
        , db_name(database_id)
        , i.object_id
        , i.index_id
        , index_type_desc
    FROM sys.dm_db_index_physical_stats(db_id('AdventureWorks2017'),object_id('person.address'),NULL,NULL,'DETAILED') ps
        INNER JOIN sys.indexes i ON (ps.object_id = i.object_id AND ps.index_id = i.index_id)
    WHERE i.name = 'IX_Address_StateProvinceID'
    ```

    Comparing the results we can see the **IX_Address_StateProvinceI** fragmentation dropped from 88% to 0.

1. Re-execute the select statement from the previous section. Make note of the logical reads in the **Messages** tab of the **Results** pane in Management Studio. *Was there a change from the number of logical reads encountered before you rebuilt the index for the address table*?

    ```sql
    SET STATISTICS IO,TIME ON

    GO
        
    USE AdventureWorks2017

    GO
        
    SELECT DISTINCT (StateProvinceID)
        ,count(StateProvinceID) AS CustomerCount
    FROM person.Address
    GROUP BY StateProvinceID
    ORDER BY count(StateProvinceID) DESC;
        
    GO
    ```

Because the index has been rebuilt, it will now be as efficient as possible and the logical reads should reduce. You have now seen that index maintenance can have an effect on query performance.

---

## Cleanup

If you are not using the Database or the lab files for any other purpose, you can clean up the objects you created in this lab.

### Delete the C:\LabFiles folder

1. From the lab virtual machine or your local machine if one wasn't provided, open **File Explorer**.
1. Navigate to **C:\\** .
1. Delete the **C:\LabFiles** folder.

## Delete the AdventureWorks2017 database

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).
1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check to the **Trust server certificate** checkbox.
1. In **Object Explorer**, expand the **Databases** folder.
1. Right-click on the **AdventureWorks2017** database and select **Delete**.
1. In the **Delete Object** dialog, check the **Close existing connections** checkbox.
1. Select **OK**.

---

You have successfully completed this lab.

In this exercise, you've learned how to rebuild index and analyze logical reads to increase query performance.
