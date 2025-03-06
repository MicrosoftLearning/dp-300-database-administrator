---
lab:
    title: 'Lab 14 – Configure geo-replication for Azure SQL Database'
    module: 'Plan and implement a high availability and disaster recovery solution'
---

# Configure geo replication for Azure SQL Database

**Estimated Time: 30 minutes**

As a DBA within AdventureWorks, you need to enable geo-replication for Azure SQL Database, and ensure it is working properly. Additionally, you will manually fail it over to another region using the portal.

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

## Enable geo-replication

1.  From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. In the Azure portal, navigate to your database by searching for **sql databases**.

1. Select the SQL database **AdventureWorksLT**.

1. On the blade for the database, in **Data management** section, select **Replicas**.

1. Select **+ Create replica**.

1. On the **Create SQL Database - Geo Replica** page notice that the **Project details** and **Primary database** sections are already filled in with the subscription, resource group and database name.

1. For the **Replica Configuration** section, select **Geo replica** for the *Replica type*.

1. For the **Geo-secondary database details** fill in the following values:

    - **Subscription**: &lt;Your subscription name&gt; (the same as the primary database).
    - **Resource group**: &lt;Select the same resource group as the primary database.&gt; 
    - **Database name**: The database name will be grayed out and will be the same as the primary database name.
    - **Server**: Select **Create new**.
    - On the **Create SQL Database Server** page, fill in the following values:

        - **Server name**: Enter a unique name for the secondary server. The name must be unique across all Azure SQL Database servers.
        - **Location**: Select a different region from the primary database. Note that your subscription may not have all regions available.
        - Check the **Allow Azure services to access server** checkbox. Note that in a production environment, you may want to restrict access to the server.
        - For authentication, select **SQL authentication**. Note that in a production environment, you may want to use **Use Microsoft Entra-only** authentication. Enter **sqladmin* for the admin login name and a secure password. The password must meet the Azure SQL password complexity requirements, at least 12 characters long, and contain at least 1 uppercase letter, 1 lowercase letter, 1 number and 1 special character.
        - Select **OK** to create the server.

    - **Want to use elastic pool?**: No.
    - **Compute + storage**: General Purpose, Gen 5, 2 vCores, 32 GB storage.
    - **Backup storage redundancy**: Locally redundant storage (LRS). Note that in a production environment, you may want to use **Geo-redundant storage (GRS)**.

1. Select **Review + Create**.

1. Select **Create**. It will take a few minutes to create the secondary server and database. Once it completes, the progress will change from **Deployment in progress** to **Your deployment is complete**.

1. Select **Go to resource** to navigate to the secondary server's database for the next step.

## Failover SQL Database to a secondary region

Now that the Azure SQL Database replica is created, you will perform a failover.

1. If not already on the secondary server's database, search for **sql databases** in the Azure portal and select the SQL database **AdventureWorksLT** on the secondary server.

1. On the SQL database main blade, in **Data management** section, select **Replicas**.

1. Note that the geo replication link is now established. The *Replica state* value of the primary database is **Online** and the *Replica state* value of the geo replicas is **Readable**.

1. Select the **...** menu for the secondary geo replica server, and select **Forced Failover**.

    > &#128221; Forced failover will switch the secondary database to the primary role. All sessions are disconnected during this operation.

1. When prompted by the warning message, click **Yes**.

1. The status of the primary replica will switch to **Pending** and the secondary to **Failover**. 

     > &#128221; Note that since the database is small, the failover will be quick. In a production environment, this process can take a few minutes.

1. When complete, the roles will switch with the secondary becoming the new primary, and the old primary the secondary. You might need to refresh the page to see the new status.

We've seen the readable secondary database may be in the same Azure region as the primary, or, more commonly, in a different region. This kind of readable secondary databases are also known as geo-secondaries, or geo-replicas.

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

You have now seen how to enable geo-replicas for Azure SQL Database, and manually fail it over to another region using the portal.
