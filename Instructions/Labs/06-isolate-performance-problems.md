---
lab:
    title: 'Lab 6 – Isolate performance problems through monitoring'
    module: 'Monitor and optimize operational resources in Azure SQL'
---

# Isolate performance problems through monitoring

**Estimated Time: 30 minutes**

The students will take the information gained in the lessons to scope out the deliverables for a digital transformation project within AdventureWorksLT. Examining the Azure portal as well as other tools, students will determine how to utilize tools to identify and resolve performance related issues.

You have been hired as a database administrator to identify performance related issues and provide viable solutions to resolve any issues found. You need to use the Azure portal to identify the performance issues and suggest methods to resolve them.

> &#128221; These exercises ask you to copy and paste T-SQL code and makes use of existing SQL resources. Please verify that the code has been copied correctly, before executing the code.

## Setup environment

If your lab virtual machine has been provided and pre-configured, you should find the lab files ready in the **C:\LabFiles** folder. *Take a moment to check, if the files are already there, skip this section*. However, if you're using your own machine or the lab files are missing, you'll need to clone them from *GitHub* to proceed.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the command palette (Ctrl+Shift+P) and type **Git: Clone**. Select the **Git: Clone** option.

1. Paste the following URL into the **Repository URL** field and select **Enter**.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

1. Save the repository to the **C:\LabFiles** folder on the lab virtual machine or your local machine if one wasn't provided (create the folder if it does not exist).

## Setup your SQL Server in Azure

Log in to Azure and check if you have an existing Azure SQL Server instance running in Azure. *Skip this section if you already have a SQL Server instance running in Azure*.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session and navigate to the cloned repository from the previous section.

1. Right-click on the **/Allfiles/Labs** folder and select **Open in Integrated Terminal**.

1. Let's connect to Azure using the Azure CLI. Type the following command and select **Enter**.

    ```bash
    az login
    ```

    > &#128221; Note that a browser window will open. Use your Azure credentials to log in.

1. Once you are logged in to Azure, it's time to create a resource group if it doesn't already exist, and create a SQL server and database under that resource group. Type the following command and select **Enter**. *The script will take a few minutes to complete*.

    ```bash
    cd ./Setup
    ./deploy-sql-database.ps1
    ```

    > &#128221; Note that by default this script will create or a resource group called **contoso-rg**, or use a resource whose name start with *contoso-rg* if it exists. By default it will also create all resources on the **West US 2** region (westus2). Finally it will generate a random 12 character password for the **SQL admin password**. You can change these values by using one or more of the parameters **-rgName**, **-location** and **-sqlAdminPw** with your own values. The password will have to meet the Azure SQL password complexity requirements, at least 12 characters long, and contain at least 1 uppercase letter, 1 lowercase letter, 1 number and 1 special character.

    > &#128221; Note that the script will add your current Public IP address to the SQL server firewall rules.

1. Once the script has completed, it will return the resource group name, SQL server name and database name, and admin user name and password. *Take note of these values as you will need them later in the lab*.

---

## Review CPU utilization in Azure portal

1. From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. From the Azure Portal, search for *SQL servers*”* in the search box at the top, then select **SQL servers** from the list of options.

1. Select the SQL server **dp300-lab-xxxxxxxx**, where *xxxxxxxx* is a random numeric string.

    > &#128221; Note, if you are using your own Azure SQL server not created by this lab, select the name of that SQL server.

1. On the Azure SQL server main page, under **Security**, select **Networking**.

1. On the **Networking** page, verify if your current public IP is already added to the **Firewall rules** list, if not, select **+ Add your client IPv4 address (your IP address)** to add it and then select **Save**.

1. From the main blade of your Azure SQL server, navigate to the **Settings** section, and select **SQL databases**, and then select the **AdventureWorksLT** database.

1. In the left navigation, select **Query editor (preview)**.

    **Note:** This feature is in preview.

1. Select the SQL Server admin user name and enter the password or your Microsoft Entra credentials if assigned to connect to the database.

1. In **Query 1**, type the following query, and select **Run**:

    ```sql
    DECLARE @Counter INT 
    SET @Counter=1
    WHILE ( @Counter <= 10000)
    BEGIN
        SELECT 
             RTRIM(a.Firstname) + ' ' + RTRIM(a.LastName)
            , b.AddressLine1
            , b.AddressLine2
            , RTRIM(b.City) + ', ' + RTRIM(b.StateProvince) + '  ' + RTRIM(b.PostalCode)
            , CountryRegion
            FROM SalesLT.Customer a
            INNER JOIN SalesLT.CustomerAddress c 
                ON a.CustomerID = c.CustomerID
            RIGHT OUTER JOIN SalesLT.Address b
                ON b.AddressID = c.AddressID
        ORDER BY a.LastName ASC
        SET @Counter  = @Counter  + 1
    END
    ```

1. Wait for the query to complete.

1. Re-run the query *two* more times to generate some CPU load on the database.

1. On the blade for the **AdventureWorksLT** database, select the **Metrics** icon on the **Monitoring** section.

    If the message *Your unsaved changes will be discarded* pops-up, select **OK**.

1. Change the **Metric** menu option to reflect **CPU Percentage**, then select an **Aggregation** of **Avg**. This will display the average CPU Percentage for the given time frame.

1. Observe the the CPU average across time. You should note a spike in CPU utilization at end of the graph when the query was running.

## Identify high CPU queries

1. Locate the **Query Performance Insight** icon on the **Intelligent Performance** section of the blade for the **AdventureWorksLT** database.

1. Select **Reset settings**.

1. Select the query in the grid below the graph. If you don't see the query we previously ran several times, wait for up 2 to 5 minutes and select **Refresh**.

    > &#128221; If there is more than one query listed, select each one to observe the results. Note the rich amount of information available for each query.

1. For the query you ran earlier, note that the total duration was over a minute and that it ran around thirty thousands times.

1. Reviewing the SQL text on the **Query details** page against the query you ran, you will note that the **Query details** only includes the **SELECT** statement and not the **WHILE** loop or other statement. This happens because **Query Performance Insight** relies on data from the **Query Store**, which only tracks Data Manipulation Language (DML) statements such as **SELECT, INSERT, UPDATE, DELETE, MERGE,** and **BULK INSERT** while ignoring Data Definition Language (DDL) statements.

Not all performance issues are related to a high CPU utilization by one single query execution. In this case, the query was executed thousands of times, which can also result in high CPU utilization.

---

## Cleanup Resources

If you are not using the Azure SQL Server for any other purpose, you can clean up the resources you created in this lab.

### Delete the Resource Group

If you created a new resource group for this lab, you can delete the resource group to remove all resources created in this lab.

1. In the Azure portal, select **Resource groups** from the left navigation pane or search for **Resource groups** in the search bar and select it from the results.

1. Go into the resource group that you created for this lab. The resource group will contain the Azure SQL Server and other resources created in this lab.

1. Select **Delete resource group** from the top menu.

1. In the **Delete resource group** dialog, type the name of the resource group to confirm and select **Delete**.

1. Wait for the resource group to be deleted.

1. Close the Azure portal.

### Delete the Lab resources only

If you didn't create a new resource group for this lab, and want to leave the resource group and its previous resources intact, you can still delete the resources created in this lab.

1. In the Azure portal, select **Resource groups** from the left navigation pane or search for **Resource groups** in the search bar and select it from the results.

1. Go into the resource group that you created for this lab. The resource group will contain the Azure SQL Server and other resources created in this lab.

1. Select all the resources prefixed with the SQL Server name you previously specified in the lab.

1. Select **Delete** from the top menu.

1. In the **Delete resources** dialog, type **delete** and select **Delete**.

1. Select **Delete** again to confirm the deletion of the resources.

1. Wait for the resources to be deleted.

1. Close the Azure portal.

### Delete the LabFiles folder

If you created a new LabFiles folder for this lab, and no longer need it, you can delete the LabFiles folder to remove all files created in this lab.

1. From the lab virtual machine or your local machine if one wasn't provided, open file explorer and navigate to the **C:\\** drive.
1. Right-click on the **LabFiles** folder and select **Delete**.
1. Select **Yes** to confirm the deletion of the folder.

---

You have successfully completed this lab.

In this exercise, you've learned how to explore server resources for an Azure SQL Database and identify potential query performance issues through Query Performance Insight.
