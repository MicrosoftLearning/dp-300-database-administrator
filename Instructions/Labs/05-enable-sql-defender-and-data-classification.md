---
lab:
    title: 'Lab 5 – Enable Microsoft Defender for SQL and Data classification'
    module: 'Implement a Secure Environment for a Database Service'
---

# Enable Microsoft Defender for SQL and Data Classification

**Estimated Time: 30 minutes**

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the AdventureWorks database.

You have been hired as a Senior Database Administrator help ensure the security of the database environment. These tasks will focus on Azure SQL Database.

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

## Enable Microsoft Defender for SQL

1. From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. From the Azure Portal, search for *SQL servers* in the search box at the top, then select **SQL servers** from the list of options.

1. Select the SQL server **dp300-lab-xxxxxxxx**, where *xxxxxxxx* is a random numeric string.

    > &#128221; Note, if you are using your own Azure SQL server not created by this lab, select the name of that SQL server.

1. In the *Overview* blade, select **Not configured** next to *Microsoft Defender for SQL*.

1. Select the **X** at the upper right to close the *Microsoft Defender for Cloud* Overview pane.

1. Select **Enable** under *Microsoft Defender for SQL*.

1. In a production environment, there should be multiple recommendations listed. You would want to select **View all recommendations in Defender for Cloud** and review all the *Microsoft Defender* recommendations listed for your Azure SQL Server and implement them as appropriate.

## Vulnerability Assessment

1. From the main blade of your Azure SQL server, navigate to the **Settings** section, and select **SQL databases**, and then select the database named **AdventureWorksLT**.

1. Select the **Microsoft Defender for Cloud** setting under **Security**.

1. Select the **X** at the upper right to close the *Microsoft Defender for Cloud* Overview pane and view the **Microsoft Defender for Cloud** dashboard for your `AdventureWorksLT` database.

1. To begin reviewing the Vulnerability Assessment capabilities, under **Vulnerability assessment findings**, select **View additional findings in Vulnerability Assessment**.  

1. Select **Scan** to get the most current Vulnerability Assessment results. This process takes a few moments while Vulnerability Assessment scans the database.

1. Every security risk has a risk level (high, medium, or low) and additional information. The rules in place are based on benchmarks that are provided by the [Center for Internet Security](https://www.cisecurity.org/benchmark/microsoft_sql_server/?azure-portal=true). In the **Findings** tab, select a vulnerability. Take note of the vulnerability's **ID**, for example **VA1143** (if listed).

1. Depending on the security check, there will be alternate views and recommendations. Review the information that's provided. For this security check, you can select the **Add all results as baseline** button and then select **Yes** to set the baseline. Now that a baseline is in place, this security check will fail in any future scans where the results are different from the baseline. Select the **X** at the top-right to close the pane for the specific rule.  

1. Let's run **Scan** again confirm that the selected vulnerability is now showing up as a *Passed* security check.

    If you select the preceding passed security check, you should be able to see the baseline you configured. If anything changes in the future, Vulnerability Assessment scans will pick it up and the security check will fail.  

## Advanced Threat Protection

1. Select the **X** at the upper right to close the Vulnerability Assessment pane and return to the **Microsoft Defender for Cloud** dashboard for your database. Under **Security incidents and alerts**, you shouldn't see any items. This means **Advanced Threat Protection** hasn't detected any issues. Advanced Threat Protection detects anomalous activities that indicate unusual and potentially harmful attempts to access or exploit databases.  

    > &#128221; You aren't expected to see any security alerts at this stage. In the next step, you'll run a test that will trigger an alert so that you can review the results in Advanced Threat Protection.  

    You can use Advanced Threat Protection to identify threats and alert you when it suspects that any of the following events are occurring:  

    - SQL injection
    - SQL injection vulnerability
    - Data exfiltration
    - Unsafe action
    - Brute force
    - Anomalous client login

    In this section, you'll learn how a SQL Injection alert can be triggered through SSMS. SQL Injection alerts are intended for custom-written applications, not for standard tools such as SSMS. Therefore, to trigger an alert through SSMS as a test for a SQL Injection, you need to "set" the **Application Name**, which is a connection property for clients that connect to SQL Server or Azure SQL.

1. From the lab virtual machine or your local machine if one wasn't provided, open SQL Server Management Studio (SSMS). On the Connect to Server dialog box, paste in the name of your Azure SQL Database server, and login with the following credentials:

    - **Server name:** &lt;_paste your Azure SQL Database server name here_&gt;
    - **Authentication:** SQL Server Authentication
    - **Server admin login:** Your Azure SQL Database server admin login
    - **Password:** Your Azure SQL Database server admin password

1. Select **Connect**.

1. In SSMS, select **File** > **New** > **Database Engine Query** to create a query by using a new connection.  

1. In the main login window, log in to the **AdventureWorksLT** database as you usually would, with SQL authentication and your Azure SQL Server name and administrator credentials. Before you connect, select **Options >>** > **Connection Properties**. Type in **AdventureWorksLT** for the option **Connect to database**.  

1. Select the **Additional Connection Parameters** tab, and then insert the following connection string in the text box:  

    ```sql
    Application Name=webappname
    ```

1. Select **Connect**.  

1. In the new query window, paste the following query, then select **Execute**:  

    ```sql
    SELECT * FROM sys.databases WHERE database_id like '' or 1 = 1 --' and family = 'test1';
    ```

1. In the Azure portal, go to your **AdventureWorksLT** database. On the left pane, under **Security**, select **Microsoft Defender for Cloud**.

1. Under **Security incidents and alerts**, select **Check for alerts on this resources in Microsoft Defender for Cloud**.  

1. You can now see the overall security alerts.  

1. Select **Potential SQL injection** to display more specific alerts and receive investigation steps.

1. Select **View full details** to display the details of the alert.

1. Under the **Alert details** tab, note that the *Vulnerable statement* is shown. This is the SQL statement that was executed to
trigger the alert. This was also the SQL statement that was executed in SSMS. Additionally, note that teh **Client application** is shown as **webappname**. This is the name that you specified in the connection string in SSMS.

1. As a clean-up step, consider closing all your query editors in SSMS and removing all connections so that you don't accidentally trigger additional alerts in the next exercises.

## Enable Data Classification

1. From the main blade of your Azure SQL server, navigate to the **Settings** section, and select **SQL databases**, and then select the database named **AdventureWorksLT**.

1. On the main blade for the **AdventureWorksLT** database, navigate to the **Security** section, and then select **Data Discovery & Classification**.

1. On the **Data Discovery & Classification** page, you will see an informational message that reads: **Currently using SQL Information Protection policy. We have found 15 columns with classification recommendations**. Select this link.

1. On the next **Data Discovery & Classification** screen select the check box next to **Select all**, select **Accepted selected recommendations**, and then select **Save** to save the classifications into the database.

1. Back to the **Data Discovery & Classification** screen, notice that fifteen columns were successfully classified across five different tables. Review the *Information type* and *Sensitivity label* for each of the columns.

## Configure data classification and masking

1. In the Azure portal, go to your **AdventureWorksLT** Azure SQL Database instance (not your logical server).

1. On the left pane, under **Security**, select **Data Discovery & Classification**.  

1. In the SalesLT Customer table, *Data Discovery & Classification* identified `FirstName` and `LastName` to be classified, but not `MiddleName`. Use the drop-down lists to add it now. Select **Name** for the *Information type* and **Confidential - GDPR** for the *Sensitivity label* and then select **Add classification**.  

1. Select **Save**.

1. Confirm that the classification was successfully added by viewing the **Overview** tab, and confirm that `MiddleName` is now displayed in the list of classified columns under the SalesLT schema.

1. On the left pane, select **Overview** to go back to the overview of your database.  

   Dynamic Data Masking (DDM) is available in both Azure SQL and SQL Server. DDM limits data exposure by masking sensitive data to non-privileged users at the SQL Server level instead of at the application level where you have to code those types of rules. Azure SQL recommends items for you to mask, or you can add masks manually.

   In the next steps, you'll mask the `FirstName`, `MiddleName`, and `LastName` columns, which you reviewed in the previous step.  

1. In the Azure portal, go to your Azure SQL Database. On the left pane, under **Security**, select **Dynamic Data Masking**, then select **Add mask**.  

1. In the dropdown lists, select the **SalesLT** schema, **Customer** table, and **FirstName** column. You can review the options for masking, but the default option is good for this scenario. Select **Add** to add the masking rule.  

1. Repeat the previous steps for both **MiddleName** and **LastName** in that table.  

    You now have three masking rules.  

1. Select **Save**.

    > &#128221; Note if your Azure SQL Server name is not made up of only lower case letters, numbers and dashes, this step will fail and you wont be able to continue with the data masking sections.

1. On the left pane, select **Overview** to go back to the overview of your database.

## Retrieve data that is classified and masked

Next, you'll simulate someone querying the classified columns and explore Dynamic Data Masking in action.

1. Go to SQL Server Management Studio (SSMS), connect to your Azure SQL server, and open a new query window.

1. Right-click the database **AdventureWorksLT** database and select **New Query**.  

1. Run the following query to return the classified data and, in some cases, columns marked for masked data. Select **Execute** to run the query.

    ```sql
    SELECT TOP 10 FirstName, MiddleName, LastName
    FROM SalesLT.Customer;
    ```

    Your result should display the first 10 names, with no masking applied. Why? Because you're the admin for this Azure SQL Database logical server.  

1. In the following query, you'll create a new user and run the preceding query as that user. You'll also use `EXECUTE AS` to impersonate `Bob`. When an `EXECUTE AS` statement is run, the session's execution context is switched to the login or user. This means that the permissions are checked against the login or user instead of the person executing the `EXECUTE AS` command (in this case, you). `REVERT` is then used to stop impersonating the login or user.  

    You might recognize the first few parts of the commands that follow, because they're a repeat from a previous exercise. Create a new query with the following commands, then select **Execute** to run the query and observe the results.

    ```sql
    -- Create a new SQL user and give them a password
    CREATE USER Bob WITH PASSWORD = 'c0mpl3xPassword!';

    -- Until you run the following two lines, Bob has no access to read or write data
    ALTER ROLE db_datareader ADD MEMBER Bob;
    ALTER ROLE db_datawriter ADD MEMBER Bob;

    -- Execute as our new, low-privilege user, Bob
    EXECUTE AS USER = 'Bob';
    SELECT TOP 10 FirstName, MiddleName, LastName
    FROM SalesLT.Customer;
    REVERT;
    ```

    The result should now display the first 10 names, but with masking applied. Bob hasn't been granted access to the unmasked form of this data.  

    What if, for some reason, Bob needs access to the names and gets permission to have it?  

    You can update excluded users from masking in the Azure portal by going to the **Dynamic Data Masking** pane, under **Security**, but you can also do it by using T-SQL.

1. Right-click the **AdventureWorksLT** database and select **New Query**, then enter the following query to allow Bob to query the names results without masking. Select **Execute** to run the query.

    ```sql
    GRANT UNMASK TO Bob;  
    EXECUTE AS USER = 'Bob';
    SELECT TOP 10 FirstName, MiddleName, LastName
    FROM SalesLT.Customer;
    REVERT;  
    ```

    Your results should include the names in full.  

1. You can also take away a user's unmasking privileges and confirm that action by running the following T-SQL commands in a new query:  

    ```sql
    -- Remove unmasking privilege
    REVOKE UNMASK TO Bob;  

    -- Execute as Bob
    EXECUTE AS USER = 'Bob';
    SELECT TOP 10 FirstName, MiddleName, LastName
    FROM SalesLT.Customer;
    REVERT;  
    ```

    Your results should include the masked names.  

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

In this exercise, you've enhanced the security of an Azure SQL Database by enabling Microsoft Defender for SQL. You've also created classified columns based on Azure portal recommendations.
