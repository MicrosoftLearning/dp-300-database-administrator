---
lab:
    title: 'Lab 15 – Backup to URL and Restore from URL'
    module: 'Plan and implement a high availability and disaster recovery solution'
---

# Backup to URL

**Estimated Time: 30 minutes**

As a DBA for AdventureWorks, you need to back up a database to a URL in Azure and restore it from Azure blob storage after a human error has occurred.

## Setup environment

If your lab virtual machine has been provided and pre-configured, you should find the lab files ready in the **C:\LabFiles** folder. *Take a moment to check, if the files are already there, skip this section*. However, if you're using your own machine or the lab files are missing, you'll need to clone them from *GitHub* to proceed.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the command palette (Ctrl+Shift+P) and type **Git: Clone**. Select the **Git: Clone** option.

1. Paste the following URL into the **Repository URL** field and select **Enter**.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

1. Save the repository to the **C:\LabFiles** folder on the lab virtual machine or your local machine if one wasn't provided (create the folder if it does not exist).

## Restore the database

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

## Configure Backup to URL

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the cloned repo at **C:\LabFiles\dp-300-database-administrator**.

1. Right-click on the **Allfles** folder and select **Open in Integrated Terminal**. This will open a terminal window at the correct location.

1. In the terminal, type the following and press **Enter**.

    ```bash
    az login
    ```

1. You will be prompted to open a browser and enter a code. Follow the instructions to log in to your Azure account.

1. *Skip this step if you have a resource group already*. If you don't have a resource group, create one by executing the following command in the terminal. Replace *contoso-rgXXX######* with a unique name for your resource group. The name must be unique across Azure. Replace your location (-l) with the location of your resource group.

    ```bash
    az group create -n "contoso-rglod#######" -l eastus2
    ```

    Replace **######** for some random characters.

1. In the terminal, type the following and press **Enter** to create a storage account. Make sure to use a unique name for the storage account. *The name must be between 3 and 24 characters in length and can contain numbers and lowercase letters only*. Replace *########* for 8 random numeric characters. The name must be unique across Azure. Replace contoso-rgXXX###### with the name of your resource group. Finally replace your location (-l) with the location of your resource group.

    ```bash
    az storage account create -n "dp300bckupstrg########" -g "contoso-rgXXX########" --kind StorageV2 -l eastus2
    ```

1. Next you will get the keys for your storage account, which you will use in subsequent steps. Execute the following code in the terminal using the unique name of your storage account and resource group.

    ```bash
    az storage account keys list -g contoso-rgXXX######## -n dp300bckupstrg########
    ```

    Your account key will be in the results of the above command. Make sure you use the same name (after the **-n**) and resource group (after the **-g**) that you used in the previous command. Copy the returned value for **key1** (without the double quotes).

1. Backing up a database in SQL Server to a URL uses container within a storage account. You will create a container specifically for backup storage in this step. To do this, execute the commands below.

    ```bash
    az storage container create --name "backups" --account-name "dp300bckupstrg########" --account-key "storage_key" --fail-on-exist
    ```

    Where **dp300bckupstrg########** is the unique storage account name used when creating the storage account, and **storage_key** is the key previously generated. The output should return **true**.

1. To verify if the container backups has been created properly, execute:

    ```bash
    az storage container list --account-name "dp300bckupstrg########" --account-key "storage_key"
    ```

    Where **dp300bckupstrg########** is the unique storage account name used when creating the storage account, and **storage_key** is the key generated.

1. A shared access signature (SAS) at the container level is required for security. Execute the following command on the terminal:

    ```bash
    az storage container generate-sas -n "backups" --account-name "dp300bckupstrg########" --account-key "storage_key" --permissions "rwdl" --expiry "date_in_the_future" -o tsv
    ```

    Where **dp300bckupstrg########** is the unique storage account name used when creating the storage account, **storage_key** is the key generated, and **date_in_the_future** is a time later than now. **date_in_the_future** must be in UTC. An example is **2025-12-31T00:00Z** which translates to expiring at Dec 31, 2025 at midnight.

    The output should return something similar to the following. Copy the whole shared access signature and paste it in **Notepad**, it will be used in the next task.

    *se=2020-12-31T00%3A00Z&sp=rwdl&sv=2018-11-09&sr=c&sig=rnoGlveGql7ILhziyKYUPBq5ltGc/pzqOCNX5rrLdRQ%3D*

## Create credential

Now that the functionality is configured, you can generate a backup file as a blob in Azure Storage Account.

1. Start **SQL Server Management Studio (SSMS)**.

1. You will be prompted to connect to  SQL Server. Ensure that **Windows Authentication** is selected, and select **Connect**.

1. Select **New Query**.

1. Create the credential that will be used to access storage in the cloud with the following Transact-SQL. Fill in the appropriate values, then select **Execute**.

    ```sql
    IF NOT EXISTS  
    (SELECT * 
        FROM sys.credentials  
        WHERE name = 'https://<storage_account_name>.blob.core.windows.net/backups')  
    BEGIN
        CREATE CREDENTIAL [https://<storage_account_name>.blob.core.windows.net/backups]
        WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
        SECRET = '<key_value>'
    END;
    GO  
    ```

    Where both occurrences of **<storage_account_name>** are the unique storage account name created, and **<key_value>** is the value generated at the end of the previous task similar to the following:

    *se=2020-12-31T00%3A00Z&sp=rwdl&sv=2018-11-09&sr=c&sig=rnoGlveGql7ILhziyKYUPBq5ltGc/pzqOCNX5rrLdRQ%3D*

1. You can check if the credential was created successfully by navigating to **Security -> Credentials** on Object Explore in SSMS.

1. If you mistyped and need to recreate the credential, you can drop it with the following command, making sure to change the name of the storage account:

    ```sql
    -- Only run this command if you need to go back and recreate the credential! 
    DROP CREDENTIAL [https://<storage_account_name>.blob.core.windows.net/backups]  
    ```

## Backup database to URL

1. Using SSMS, back up the database **AdventureWorks2017** to Azure with the following command in Transact-SQL:

    ```sql
    BACKUP DATABASE AdventureWorks2017   
    TO URL = 'https://<storage_account_name>.blob.core.windows.net/backups/AdventureWorks2017.bak';
    GO 
    ```

    Where **<storage_account_name>** is the unique storage account name used created. 

    If an error occurs, check that you did not mistype anything during the credential creation, and that everything was created successfully.

## Validate the backup through Azure CLI

To see that the file is actually in Azure, you can use Storage Explorer (preview) or Azure Cloud Shell.

1. Back on the Visual Studio code terminal, run this Azure CLI command:

    ```bash
    az storage blob list -c "backups" --account-name "dp300backupstorage1234" --account-key "storage_key" --output table
    ```

    Make sure you use the same unique storage account name (after the **--account-name**) and account key (after the **--account-key**) that you used in the previous commands.

    We can confirm the backup file was generated successfully.

## Validate the backup through Storage Browser

1. In a browser windows, go to the Azure portal and search and select **Storage accounts**.

1. Select the unique storage account name you created for the backups.

1. In the left navigation, select **Storage browser**. Expand **Blob containers**.

1. Select **backups**.

1. Note that the backup file is stored in the container.

## Restore from URL

This task will show you how to restore a database from an Azure blob storage.

1. From **SQL Server Management Studio (SSMS)**, select **New Query**, then paste and execute the following query.

    ```sql
    USE AdventureWorks2017;
    GO
    SELECT * FROM Person.Address WHERE AddressId = 1;
    GO
    ```

1. Run this command to change the name of that customer.

    ```sql
    UPDATE Person.Address
    SET AddressLine1 = 'This is a human error'
    WHERE AddressId = 1;
    GO
    ```

1. Re-run **Step 1** to verify that the address has been changed. Now imagine if someone had changed thousands or millions of rows without a WHERE clause – or the wrong WHERE clause. One of the solutions involves restoring the database from the last available backup.

1. To restore the database to get it back to where it was before the customer name was mistakenly changed, execute the following.

    > &#128221; **SET SINGLE_USER WITH ROLLBACK IMMEDIATE** syntax the open transactions will all be rolled back. This can prevent the restore failing due to active connections.

    ```sql
    USE [master]
    GO

    ALTER DATABASE AdventureWorks2017 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    GO

    RESTORE DATABASE AdventureWorks2017 
    FROM URL = 'https://<storage_account_name>.blob.core.windows.net/backups/AdventureWorks2017.bak'
    GO

    ALTER DATABASE AdventureWorks2017 SET MULTI_USER
    GO
    ```

    Where **<storage_account_name>** is the unique storage account name you created.

1. Re-run **Step 1** to verify that the customer name has been restored.

It is important to understand the components and the interaction to do a backup to or restore from the Azure Blob Storage service.

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

You have now seen that you can back up a database to a URL in Azure and, if necessary, restore it.
