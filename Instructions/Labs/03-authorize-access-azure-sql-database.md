---
lab:
    title: 'Lab 3 – Authorize access to Azure SQL Database with Azure Active Directory'
    module: 'Implement a Secure Environment for a Database Service'
---

# Configure database authentication and authorization

**Estimated Time: 25 minutes**

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the *AdventureWorksLT* database.

You've been hired as a Senior Database Administrator to help ensure the security of the database environment.

> &#128221; These exercises ask you to copy and paste T-SQL code and makes use of existing SQL resources. Please verify that the code has been copied correctly, before executing the code.

## Setup environment

Download the lab files from GitHub.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the command palette (Ctrl+Shift+P) and type **Git: Clone**. Select the **Git: Clone** option.

1. Paste the following URL into the **Repository URL** field and select **Enter**.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

1. Save the repository to the **C:\LabFiles** folder on the lab virtual machine or your local machine if one wasn't provided (create the folder if it does not exist).

## Setup your SQL Server in Azure

Skip this section if you already have a SQL Server instance running in Azure.

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

    > &#128221; Note that by default this script will create or a resource group called **dp300**, or use a resource whose name start with *dp300* if it exists. By default it will also create all resources on the **West US 2** region (westus2). Finally it will generate a random 12 character password for the **SQL admin password**. You can change these values by using one or more of the parameters **-rgName**, **-location** and **-sqlAdminPw** with your own values. The password will have to meet the Azure SQL password complexity requirements, at least 12 characters long, and contain at least 1 uppercase letter, 1 lowercase letter, 1 number and 1 special character.

    > &#128221; Note that the script will add your current Public IP address to the SQL server firewall rules.

1. Once the script has completed, it will return the resource group name, SQL server name and database name, and admin user name and password. Take note of these values as you will need them later in the lab.

---

## Authorize access to Azure SQL Database with Microsoft Entra

You can create logins from Microsoft Entra accounts as a contained database user using the `CREATE USER [anna@contoso.com] FROM EXTERNAL PROVIDER` T-SQL syntax. A contained database user maps to an identity in the Microsoft Entra directory associated with the database and has no login in the `master` database.

With the introduction of Microsoft Entra server logins in Azure SQL Database, you can create logins from Microsoft Entra principals in the virtual `master` database of a SQL Database. You can create Microsoft Entra logins from Microsoft Entra *users, groups, and service principals*. For more information, see [Microsoft Entra server principals](/azure/azure-sql/database/authentication-azure-ad-logins)

Additionally, you can use the Azure portal only to create administrators, and Azure role-based access control roles don't propagate to Azure SQL Database logical servers. You must grant additional server and database permissions by using Transact-SQL (T-SQL). Let's create a Microsoft Entra admin for the SQL server.

1. From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. On the Azure portal home page search for **SQL servers** and select it.

1. Select the SQL server **dp300-xxxxxx-xxxx-lab**, where **xxxxxxx-xxxx** is a random string.

    > &#128221; Note, if you are using your own Azure SQL server not created by this lab, select the name of that SQL server.

1. In the *Overview* blade, select **Not configured** next to *Microsoft Entra admin*.

1. On the next screen, select **Set admin**.

1. In the **Azure Active Directory** sidebar, search for the Azure username you logged into the Azure portal with, then click on **Select**.

1. Select **Save** to complete the process. This will make your username the Azure Active Directory admin for the server.

1. On the left select **Overview**, then copy the **Server name**.

1. Open SQL Server Management Studio (SSMS) and select **Connect** > **Database Engine**. In the **Server name** paste the name of your server. Change the authentication type to **Azure Active Directory Universal with MFA**.

1. Select **Connect**.

> &#128221; When you first try to sign in to an Azure SQL database your client IP address needs to be added to the firewall rules. SQL Server Management Studio can do this for you. Use your Azure portal credentials and select **Connect**. You will be prompted to add your current Public IP address to the SQL server firewall rules.

## Manage access to database objects

In this task you will manage access to the database and its objects. The first thing you will do is create two users in the *AdventureWorksLT* database.

1. From the lab virtual machine or your local machine if one wasn't provided, in SSMS, login to the *AdventureWorksLT* database using the Azure Server admin account or the Azure Active Directory admin account.

1. Use the **Object Explorer** and expand **Databases**.

1. Right-click on **AdventureWorksLT**, and select **New Query**.

1. In the new query window, copy and paste the below T-SQL into it. Execute the query to create the two users.

    ```sql
    CREATE USER [DP300User1] WITH PASSWORD = 'Azur3Pa$$';
    GO

    CREATE USER [DP300User2] WITH PASSWORD = 'Azur3Pa$$';
    GO
    ```

    **Note:** These users are created in the scope of the AdventureWorksLT database. Next you will create a custom role and add the users to it.

1. Execute the following T-SQL in the same query window.

    ```sql
    CREATE ROLE [SalesReader];
    GO

    ALTER ROLE [SalesReader] ADD MEMBER [DP300User1];
    GO

    ALTER ROLE [SalesReader] ADD MEMBER [DP300User2];
    GO
    ```

    Next create a new stored procedure in the **SalesLT** schema.

1. Execute the below T-SQL in your query window.

    ```sql
    CREATE OR ALTER PROCEDURE SalesLT.DemoProc
    AS
    SELECT P.Name, Sum(SOD.LineTotal) as TotalSales ,SOH.OrderDate
    FROM SalesLT.Product P
    INNER JOIN SalesLT.SalesOrderDetail SOD on SOD.ProductID = P.ProductID
    INNER JOIN SalesLT.SalesOrderHeader SOH on SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY P.Name, SOH.OrderDate
    ORDER BY TotalSales DESC
    GO
    ```

    Next use the `EXECUTE AS USER` syntax to test out the security. This allows the database engine to execute a query in the context of your user.

1. Execute the following T-SQL.

    ```sql
    EXECUTE AS USER = 'DP300User1'
    EXECUTE SalesLT.DemoProc
    ```

    This will fail with the message:

    <span style="color:red">Msg 229, Level 14, State 5, Procedure SalesLT.DemoProc, Line 1 [Batch Start Line 0]
    The EXECUTE permission was denied on the object 'DemoProc', database 'AdventureWorksLT', schema 'SalesLT'.</span>

1. Next grant permissions to the role to allow it to execute the store procedure. Execute the below T-SQL.

    ```sql
    REVERT;
    GRANT EXECUTE ON SCHEMA::SalesLT TO [SalesReader];
    GO
    ```

    The first command reverts the execution context back to the database owner.

1. Rerun the previous T-SQL.

    ```sql
    EXECUTE AS USER = 'DP300User1'
    EXECUTE SalesLT.DemoProc
    ```

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

---

You have successfully completed this lab.

In this exercise, you've seen how you can use Azure Active Directory to grant Azure credentials access to a SQL Server hosted in Azure. You've also used T-SQL statement to create new database users and granted them permissions to run stored procedures.
