---
lab:
    title: 'Lab 15 – Configure geo replication for Azure SQL Database'
    module: 'Plan and implement a high availability and disaster recovery solution'
---

# Deploy an automation runbook to automatically rebuild indexes

**Estimated Time: 30 minutes**

As a DBA for Wide World Importers, you need to back up a database to a URL in Azure and restore it after a human error has
occurred.

## Connect to the lab environment

1. When the VM lab environment opens, use the password on the **Resources** tab above for the **Student** account to sign in to Windows.

1. Select the Microsoft Edge browser from the toolbar and navigate to [https://portal.azure.com](https://portal.azure.com/). This should be the home page of the browser.

> [!NOTE]
> To complete this exercise, you will need a Microsoft Azure subscription. If you don't already have one, you can sign up for a free trial at [https://azure.microsoft.com/free](https://azure.microsoft.com/free?portal=true).

## Configure Backup to URL

1. Open a **Cloud Shell** prompt by selecting the icon shown below.

    :::image type="content" source="../media/cloud-shell.png" alt-text="Cloud Shell":::

1. At the bottom half of the portal, you may see a message welcoming you to the Azure Cloud Shell, if you have not yet used a Cloud Shell. Select **Bash**.

    :::image type="content" source="../media/welcome-to-cloud-shell.png" alt-text="Welcome to Azure Cloud Shell":::

1. If you have not previously used a Cloud Shell, you must give it storage. Click **Show advanced settings** in the dialog below:

    :::image type="content" source="../media/create-storage.png" alt-text="Create storage":::

1. Use the existing **Resource group** and specify new names for **Storage account** and **File share**, as shown in the dialog below. Make a note of the **Resource group** name. It should start with **DP-300-HADR**.The Storage account and File share names should use lower case letters and no special characters. Then click **Create storage**.

    :::image type="content" source="../media/create-storage-account.png" alt-text="Create storage account and file share":::

1. Verify that the upper left corner of the Cloud Shell screen shows **Bash**.

    Once complete, you will see a prompt similar to the one below.

    :::image type="content" source="../media/cloud-shell-prompt.png" alt-text="Cloud Shell prompt":::

1. Create a new storage account from the CLI using by executing the following command in Cloud Shell. Your storage account name must be unique and all lower case with no special characters. You should change dp300storage in the example to a unique name such as **dp300storagemsl123**. Use the name of the resource group starting with **DP-300-HADR** that you made note of above. 

    > [!NOTE]
    > You can copy these Azure CLI commands from the **D:\LabFiles\High Availability\High Availability Bash scripts.sh** file and edit them as needed.

    ```bash
    az storage account create -n dp300storage -g DP-300-HADR --kind StorageV2 -l eastus2
    ```

    Next you will get the account keys for your account, which you will use in subsequent steps. Execute the following code in Cloud Shell using the unique name of your storage account:

    ```bash
    az storage account keys list -g DP-300-HADR -n dp300storage
    ```

    Your account key will be in the results of the above command. Make sure you use the same name (after the **-n**) and resource group (after the **-g**) that you used in the previous command. Copy the returned value for **key1** (without the double quotes) as shown here:

    :::image type="content" source="../media/storage-account-keys.png" alt-text="Key1":::

1. Backing up a database in SQL Server to a URL uses a storage account and a container within it. You will create a container specifically for backup storage in this step. To do this, execute:

    ```bash
    az storage container create --name "backups" --account-name "dp300storage" --account-key "storage_key" --fail-on-exist
    ```

    where **dp300storage** is the storage account name used when creating the storage account and **storage_key** is the key generated above. The output should return **true**.

1. To further verify the container backups has been created, execute:

    ```bash
    az storage container list --account-name "dp300storage" --account-key "storage_key"
    ```

    where **dp300storage** is the storage account name used you created and storage_key is the key you generated above. The output should return something similar to below:

    :::image type="content" source="../media/storage-list.png" alt-text="Container list":::

1. A shared access signature (SAS) at the container level is required for security. This can be done via Cloud Shell or PowerShell. Execute the following:

    ```bash
    az storage container generate-sas -n "backups" --account-name "dp300storage" --account-key "storage_key" --permissions "rwdl" --expiry "date_in_the_future" -o tsv
    ```

    where **dp300storage** is the storage account name you created above, **storage_key** is the key generated above, and **date_in_the_future** is a time later than now. **date_in_the_future** must be in UTC. An example is **2021-12-31T00:00Z** which translates to expiring at Dec 31, 2020 at midnight.

    The output should return something similar to below. Copy the whole shared access signature and paste it in **Notepad**, because it will be used in the next task:

    :::image type="content" source="../media/storage-key.png" alt-text="Shared access signature":::

## Back Up WideWorldImporters

Now that the functionality is configured, you can generate a backup file as a blob in Azure.

1. Start **SQL Server Management Studio (SSMS)**.

1. You will be prompted to connect to  SQL Server. Ensure that **Windows Authentication** is selected, and click **Connect**.

1. Click **New Query**.

1. Create the credential that will be used to access storage in the cloud with the following Transact-SQL. Fill in the appropriate values:

    > [!NOTE]
    > You can copy these SQL statements from the **D:\LabFiles\High Availability\High Availability Bash scripts.sql** file.

    ```sql
    IF NOT EXISTS  
    (SELECT * FROM sys.credentials  
    WHERE name = 'https://dp300storage.blob.core.windows.net/backups')  
    BEGIN
    CREATE CREDENTIAL [https://dp300storage.blob.core.windows.net/backups]
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
    SECRET = 'sas_token'
    END;
    GO  
    ```

    Where both occurrences  of **dp300storage** are the storage account name created above and **sas_token** is the value generated at the end of the previous task.

    The **sas_token** line should be in this format:

    ```sql
    SECRET = 'se=2020-12-31T00%3A00Z&sp=rwdl&sv=2018-11-09&sr=c&sig=rnoGlveGql7ILhziyKYUPBq5ltGc/pzqOCNX5rrLdRQ%3D'   
    ```

1. Click **Execute**. This should be successful. If you mistyped and need to recreate the credential, you can drop it with the following command, making sure to change the name of the storage account:
    ```sql
    -- Only run this command if you need to go back and recreate the credential! 
    DROP CREDENTIAL [https://dp300storage.blob.core.windows.net/backups]  
    ```

1. Back up the database WideWorldImporters to Azure with the following command in Transact-SQL:

    ```sql
    BACKUP DATABASE WideWorldImporters   
    TO URL = 'https://dp300storage.blob.core.windows.net/backups/WideWorldImporters.bak';
    GO 
    ```

    where **dp300storage** is the storage account name used in **Task 1**.

    If something is configured incorrectly, you will see an error message similar to the following:

    :::image type="content" source="../media/backup-error.png" alt-text="Backup error":::

    If an error occurs, check that you did not mistype anything and that everything was created successfully.

## Validate the backup

To see that the file is actually in Azure, you can use Storage Explorer (preview) or Azure Cloud Shell.

1. Select the Microsoft Edge browser from the toolbar and navigate to [https://portal.azure.com](https://portal.azure.com/).

1. Use the Azure Cloud Shell to run this Azure CLI command:

    ```bash
    az storage blob list -c "backups" --account-name "dp300storage" --account-key "storage_key"
    ```

    Where **dp300storage** is the storage account name you created above and **storage_key** is the key used there as well.

1. To use the Storage Explorer (preview), from the home page in the Azure portal select **Storage accounts**.

    :::image type="content" source="../media/selecting-storage-account.png" alt-text="Screenshot showing selecting a storage account.":::

1. Select the storage account starting with **dp300storage**.

1. In the left navigation, select **Storage Explorer (preview)**. Expand **BLOB CONTAINERS**, then select **backups**.

    :::image type="content" source="../media/storage-explorer.png" alt-text="Screenshot showing the backed up file in the storage account.":::

## Restore WideWorldImporters
This task will show you how to restore a database.

1. In a query window, execute the following query:

    ```sql
    USE WideWorldImporters;
    GO
    ```

1. Now execute the statement below to return the very first row of the Customers table which has a CustomerID of 1. Note the name of the customer:

    ```sql
    SELECT TOP 1 * FROM Sales.Customers;
    GO
    ```

1. Run this command to change the name of that customer.

    ```sql
    UPDATE Sales.Customers
    SET CustomerName = 'This is a human error'
    WHERE CustomerID = 1;
    GO
    ```

1. Re-run **Step 2** to verify that the name has been changed. Now imagine if someone had changed thousands or millions of rows without a WHERE clause – or the wrong WHERE clause.

1. To restore the database to get it back to where it was before the change you made in **Step 3**, execute the following. (First, make sure there are no connections to the WideWorldImporters database.)

    ```sql
    USE master;
    GO

    RESTORE DATABASE WideWorldImporters 
    FROM URL = 'https://dp300storage.blob.core.windows.net/backups/WideWorldImporters.bak';
    GO
    ```

    Where **dp300storage** is the storage account name used above.

    The output should be similar to this:

    :::image type="content" source="../media/restore-database.png" alt-text="Restore database":::

1. Re-run **Step 2** to verify that the data has been restored.

You have now seen that you can back up a database to a URL in Azure and, if necessary, restore it.

To finish this exercise select **Done** below.
