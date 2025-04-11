---
lab:
    title: 'Lab 13 – Deploy an automation runbook to automatically rebuild indexes'
    module: 'Automate database tasks for Azure SQL'
---

# Deploy an automation runbook to automatically rebuild indexes

**Estimated Time: 30 minutes**

You have been hired as a Senior Database Administrator to help automate day to day operations of database administration. This automation is to help ensure that the databases for AdventureWorks continue to operate at peak performance as well as provide methods for alerting based on certain criteria. AdventureWorks utilizes SQL Server in both Infrastructure as a Service (IaaS) and Platform as a Service (PaaS) offerings.

> &#128221; These exercises may ask you to copy and paste T-SQL code and makes use of existing SQL resources. Please verify that the code has been copied correctly, before executing the code.

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

## Create an Automation Account

1. From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. In the Azure portal in the search bar type *automation* and then select **Automation Accounts** from the search results, and then select **+ Create**.

1. On the **Create an Automation Account** page, enter the information below, and then select **Review + Create**.

    - **Resource Group:** &lt;Your resource group&gt;
    - **Automation account name:** autoAccount
    - **Region:** Use the default.

1. On the review page, select **Create**.

    > &#128221; Your automation account could take a few minutes to create.

## Connect to an existing Azure SQL Database

1. In the Azure portal, navigate to your database by searching for **sql databases**.

1. Select the SQL database **AdventureWorksLT**.

1. On the main section for your SQL Database page, select **Query editor (preview)**.

1. You will be prompted for credentials to sign in to your database using the database admin account and select **OK**.

    This will open a new tab in your browser. Select **Add client IP** and then select **Save**. Once saved, return to the previous tab and select **OK** again.

    > &#128221; You might receive the error message *Cannot open server 'your-sql-server-name' requested by the login. Client with IP address 'xxx.xxx.xxx.xxx' is not allowed to access the server.* If so, you will need to add your current Public IP address to the SQL server firewall rules.

    If you need to setup the firewall rules, follow these steps:

    1. select **Set server firewall** from the top menu bar of the database's **Overview** page.
    1. Select **Add your current IPv4 address (xxx.xxx.xxx.xxx)** and then select **Save**.
    1. Once saved, return to the **AdventureWorksLT** database page and select **Query editor (preview)** again.
    1. You will be prompted for credentials to sign in to your database using the database admin account and select **OK**.

1. In the **Query editor (preview)**, select **Open query**.

1. Select the browse *folder* icon and navigate to the **C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\Module13** folder. Select the **usp_AdaptiveIndexDefrag.sql** file and select **Open**, and then select **OK**.

1. Delete **USE msdb** and **GO** on lines 5 and 6 of the query, and then select **Run**.

1. Expand the **Stored Procedures** folder to see the newly created stored procedures.

## Configure Automation Account assets

The next steps consist of configuring the assets required in preparation for the runbook creation. Then select **Automation Accounts**.

1. On the Azure portal, in the top search box, type **automation** and select **Automation Accounts**.

1. Select the **autoAccount** automation account that you created.

1. Select **Modules** from the **Shared Resources** section of the Automation blade. Then select **Browse gallery**.

1. Search for **SqlServer** within the Gallery.

1. Select **SqlServer** which will direct to the next screen, and then select the **Select** button.

1. On the **Add a module** page, select the latest runtime version available, then select **Import**. This will import the PowerShell module into your Automation account.

1. You'll need to create a credential to securely sign in to your database. From the blade for the *Automation Account* navigate to the **Shared Resources** section and select **Credentials**.

1. Select **+ Add a Credential**, enter the information below, and then select **Create**.

    - Name: **SQLUser**
    - User name: **sqladmin**
    - Password: &lt;Enter a strong password, 12 characters long, and containing at least 1 uppercase letter, 1 lowercase letter, 1 number and 1 special character.&gt;
    - Confirm password: &lt;Re-enter the password you previously entered.&gt;

## Create a PowerShell runbook

1. In the Azure portal, navigate to your database by searching for **sql databases**.

1. Select the SQL database **AdventureWorksLT**.

1. On the **Overview** page copy the **Server name** of your Azure SQL Database (Your server name should start with *dp300-lab*). You'll paste this in later steps.

1. On the Azure portal, in the top search box, type **automation** and select **Automation Accounts**.

1. Select the **autoAccount** automation account.

1. Expand to the **Process Automation** section of the Automation account blade, select **Runbooks**.

1. Select **+ Create a runbook**.

    > &#128221; As we've learned, note that there are two existing runbooks created. These were automatically created during the automation account deployment.

1. Enter the runbook name as **IndexMaintenance** and a runbook type of **PowerShell**. Select the latest runtime version available, then select **Review + Create**.

1. On the **Create runbook** page, select **Create**.

1. Once the runbook has been created, copy and paste the Powershell code snippet below into your runbook editor. 

    > &#128221; Please verify that the code has been copied correctly, before saving the runbook.

    ```powershell
    $AzureSQLServerName = ''
    $DatabaseName = 'AdventureWorksLT'
    
    $Cred = Get-AutomationPSCredential -Name "SQLUser"
    $SQLOutput = $(Invoke-Sqlcmd -ServerInstance $AzureSQLServerName -UserName $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $DatabaseName -Query "EXEC dbo.usp_AdaptiveIndexDefrag" -Verbose) 4>&1

    Write-Output $SQLOutput
    ```

    > &#128221; Note that the code above is a PowerShell script that will execute the stored procedure **usp_AdaptiveIndexDefrag** on the **AdventureWorksLT** database. The script uses the **Invoke-Sqlcmd** cmdlet to connect to the SQL server and execute the stored procedure. The **Get-AutomationPSCredential** cmdlet is used to retrieve the credentials stored in the Automation account.

1. On the first line of the script paste in the server name you copied in the previous steps.

1. Select **Save**, and then select **Publish**.

1. Select **Yes** to confirm the publish action.

1. The *IndexMaintenance* runbook is now published.

## Create a schedule for a runbook

Next you will schedule the runbook to execute on a regular basis.

1. Under **Resources** in the left hand navigation of your **IndexMaintenance** runbook, select **Schedules**. 

1. Select **+ Add a schedule**.

1. Select **Link a schedule to your runbook**.

1. Select **+ Add a schedule**.

1. Enter the information below, and then select **Create**.

    - **Name:** DailyIndexDefrag
    - **Description:** Daily Index defrag for AdventureWorksLT database.
    - **Starts:** 4:00 AM (next day)
    - **Time zone:** &lt;Select the time zone that matches your location&gt;
    - **Recurrence:** Recurring
    - **Recur every:** 1 day
    - **Set expiration:** No

    > &#128221; Note that the start time is set to 4:00 AM the next day. The time zone is set to your local time zone. The recurrence is set to every 1 day. Never expires.

1. Select **Create**, and then select **OK**.

1. The schedule is now created and linked to the runbook. Select **OK**.

Azure Automation delivers a cloud-based automation, and configuration service that supports consistent management across your Azure and non-Azure environments.

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

By completing this exercise you've automated the defragging of indexes on a SQL server database to run every day, at 4am.
