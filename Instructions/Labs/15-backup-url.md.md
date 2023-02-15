# Backup to URL  <inject key="DeploymentID" enableCopy="false" />

**Estimated Time: 30 minutes**

As a DBA for AdventureWorks, you need to back up a database to a URL in Azure and restore it from Azure blob storage after a human error has occurred.

## Restore a database

1. Navigate to the Microsoft Edge browser window and download the database backup file located on **https://github.com/MicrosoftLearning/dp-300-database-administrator/blob/master/Instructions/Templates/AdventureWorks2017.bak** to **C:\LabFiles\HADR** path on the lab virtual machine (create the folder structure if it does not exist).

    ![Picture 03](../images/dp-300-module-15-lab-00.png)

1. Select the Windows Start button and type SSMS. Select **Microsoft SQL Server Management Studio 18** from the list.  

    ![Picture 01](../images/dp-300-module-01-lab-34.png)

1. When SSMS opens, notice that the **Connect to Server** dialog will be pre-populated with the default instance name with **sqlvm-<inject key="DeploymentID" enableCopy="false" />**. Select **Connect**.

    ![Picture 02](../images/dp-300-module-07-lab-01.png)

1. Select the **Databases** folder, and then **New Query**.

    ![Picture 03](../images/dp-300-module-07-lab-04.png)

1. In the new query window, copy and paste the below T-SQL into it. Execute the query to restore the database.

    ```sql
    RESTORE DATABASE AdventureWorks2017
    FROM DISK = 'C:\LabFiles\HADR\AdventureWorks2017.bak'
    WITH RECOVERY,
          MOVE 'AdventureWorks2017' 
            TO 'C:\LabFiles\HADR\AdventureWorks2017.mdf',
          MOVE 'AdventureWorks2017_log'
            TO 'C:\LabFiles\HADR\AdventureWorks2017_log.ldf';
    ```

    **Note:** The database backup file name and path should match with what you've downloaded on step 1, otherwise the command will fail.

1. You should see a successful message after the restore is complete.

    ![Picture 03](../images/dp-300-module-07-lab-05.png)

## Configure Backup to URL

1. From the lab virtual machine, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using the Azure **Username** and **Password** provided on the **Environment Details** tab for this lab virtual machine.

    ![Screenshot of Azure portal sign in page](../images/dp-300-module-01-lab-01.png)

1. Open a **Cloud Shell** prompt by selecting the icon shown below.

    ![Screenshot of cloud shell icon on Azure portal.](../images/dp-300-module-15-lab-01.png)

1. At the bottom half of the portal, you may see a message welcoming you to the Azure Cloud Shell, if you have not yet used a Cloud Shell. Select **Bash**.

    ![Screenshot of welcome page for cloud shell on Azure portal.](../images/dp-300-module-15-lab-02.png)

1. If you have not previously used a Cloud Shell, you must configure a storage. Select **Show advanced settings** (You may have a different subscription assigned).

    ![Screenshot of create storage for cloud shell on Azure portal.](../images/dp-300-module-15-lab-03.png)

1. Use the existing **Resource group** and specify new names for **Storage account** as **dp300storage<inject key="DeploymentID" enableCopy="false" /> ** and **File share** as **dp300fileshare**, as shown in the dialog below. Make a note of the **Resource group** name. It should start with *contoso-rg*. Then select **Create storage**.

    **Note:** Your storage account name must be unique and all lower case with no special characters. Please provide a unique name.

    ![Screenshot of the create storage account and file share on Azure portal.](../images/dp-300-module-15-lab-04.png)

1. Once complete, you will see a prompt similar to the one below. Verify that the upper left corner of the Cloud Shell screen shows **Bash**.

    ![Screenshot of the Cloud Shell prompt on Azure portal.](../images/dp-300-module-15-lab-05.png)

1. Create a new storage account from the CLI using by executing the following command in Cloud Shell. Use the name of the resource group starting with **contoso-rg** that you made note of above.

    > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and RESOURCE_GROUP_NAME with **contoso-rg-<inject key="DeploymentID" enableCopy="false" />**.

    ```bash
    az storage account create -n "BACKUP_STORAGE_NAME" -g "RESOURCE_GROUP_NAME" --kind StorageV2 -l eastus2
    ```

    ![Screenshot of the storage account creation prompt on Azure portal.](../images/dp-300-module-15-lab-16.png)

1. Next you will get the keys for your storage account, which you will use in subsequent steps. Execute the following code in Cloud Shell using the unique name of your storage account and resource group.
 
   > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and RESOURCE_GROUP_NAME with **contoso-rg-<inject key="DeploymentID" enableCopy="false" />**.
   
    ```bash
    az storage account keys list -g RESOURCE_GROUP_NAME -n BACKUP_STORAGE_NAME
    ```

    Your account key will be in the results of the above command. Copy the returned value for **key1** (without the double quotes) in a notepad as shown here:

    ![Screenshot of the storage account key on Azure portal.](../images/dp-300-module-15-lab-06.png)

1. Backing up a database in SQL Server to a URL uses container within a storage account. You will create a container specifically for backup storage in this step. To do this, execute the commands below.

   > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and STORAGE_KEY with the value of **key1** that you have copied in the notepad in the previous step.

    ```bash
    az storage container create --name "backups" --account-name "BACKUP_STORAGE_NAME" --account-key "STORAGE_KEY" --fail-on-exist
    ```

    The output should return **true**.

    ![Screenshot of the output for the container creation.](../images/dp-300-module-15-lab-07.png)

1. To verify if the container backups has been created properly, execute:

    ```bash
    az storage container list --account-name "BACKUP_STORAGE_NAME" --account-key "STORAGE_KEY"
    ```

   > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and STORAGE_KEY with the value of **key1** that you have copied in the notepad. The output should return something similar to below:

    ![Screenshot of the container list.](../images/dp-300-module-15-lab-08.png)

1. A shared access signature (SAS) at the container level is required for security. This can be done via Cloud Shell or PowerShell. Execute the following:

    ```bash
    az storage container generate-sas -n "backups" --account-name "BACKUP_STORAGE_NAME" --account-key "STORAGE_KEY" --permissions "rwdl" --expiry "2023-12-31T00:00Z" -o tsv
    ```

   > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and STORAGE_KEY with the value of **key1** that you have copied in the notepad.

   >  The output should return something similar to below. Copy the whole shared access signature and paste it in **Notepad**, it will be used in the next task.

    ![Screenshot of the shared access signature key.](../images/dp-300-module-15-lab-09.png)

## Create credential

Now that the functionality is configured, you can generate a backup file as a blob in Azure Storage Account.

1. Move back to **SQL Server Management Studio (SSMS)** and select **New Query**.

1. Create the credential that will be used to access storage in the cloud with the following Transact-SQL. Repalce the following values, then select **Execute**.

   > **NOTE:** Replace <storage_account_name> with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and <key_value> with the value of **SAS** that you have copied in the notepad.
   >  **<key_value>** is the value generated at the end of the previous task in this format:
       `'se=2023-12-31T00%3A00Z&sp=rwdl&sv=2018-11-09&sr=csig=rnoGlveGql7ILhziyKYUPBq5ltGc/pzqOCNX5rrLdRQ%3D'`


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

1. You can check if the credential was created successfully by navigating to **Security -> Credentials** on Object Explore.

    ![Screenshot of the credential on SSMS.](../images/dp-300-module-15-lab-17.png)

1. If you mistyped and need to recreate the credential, you can drop it with the following command, making sure to change the name of the storage account. (Only run this command if you need to go back and recreate the credential)

   > **Note:** Skip this step if you have already created the credentials correctly.

    ```sql
    DROP CREDENTIAL [https://<storage_account_name>.blob.core.windows.net/backups]  
    ```

## Backup to URL

1. Back up the database **AdventureWorks2017** to Azure with the following command in Transact-SQL:

    ```sql
    BACKUP DATABASE AdventureWorks2017   
    TO URL = 'https://<storage_account_name>.blob.core.windows.net/backups/AdventureWorks2017.bak';
    GO 
    ```

    > **Note:** Replace <storage_account_name> with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />**. The output should return something similar to below.

    ![Screenshot of the backup error.](../images/dp-300-module-15-lab-18.png)

    If something was configured incorrectly, you will see an error message similar to the following:

    ![Screenshot of the backup error.](../images/dp-300-module-15-lab-10.png)

    If an error occurs, check that you did not mistype anything during the credential creation, and that everything was created successfully.

## Validate the backup through Azure CLI

To see that the file is actually in Azure, you can use Storage Explorer (preview) or Azure Cloud Shell.

1. Navigate back to [https://portal.azure.com](https://portal.azure.com/). If not connected then connect to the Portal using the Azure **Username** and **Password** provided on the **Environment Details** tab for this lab virtual machine.

1. Re-open the bash shell window and run this Azure CLI command:

    ```bash
    az storage blob list -c "backups" --account-name "BACKUP_STORAGE_NAME" --account-key "KEY1" --output table
    ```

    > **NOTE:** Replace BACKUP_STORAGE_NAME with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />** and KEY1 with the value of **key1** that you have copied in the notepad.

    ![Screenshot of the backup in the container.](../images/dp-300-module-15-lab-19.png)

    We can confirm the backup file was generated successfully.

## Validate the backup through Storage Explorer

1. To use the Storage Explorer (preview), from the home page in the Azure portal select **Storage accounts**.

    ![Screenshot showing selecting a storage account.](../images/dp-300-module-15-lab-11.png)

1. Select the unique storage account name you created for the backups.

1. In the left navigation, select **Storage browser (preview)**. Expand **Blob containers**.

    ![Screenshot showing the backed up file in the storage account.](../images/dp-300-module-15-lab-12.png)

1. Select **backups**.

    ![Screenshot showing the backed up file in the storage account.](../images/dp-300-module-15-lab-13.png)

1. Note that the backup file is stored in the container.

    ![Screenshot showing the backup file on storage browser.](../images/dp-300-module-15-lab-14.png)

## Restore from URL

This task will show you how to restore a database from an Azure blob storage.

1. Navigate back to **SQL Server Management Studio (SSMS)**, select **New Query**, then paste and execute the following query.

    ```sql
    USE AdventureWorks2017;
    GO
    SELECT * FROM Person.Address WHERE AddressId = 1;
    GO
    ```

    ![Screenshot showing the customer name before the update was executed.](../images/dp-300-module-15-lab-21.png)

1. Run this command to change the name of that customer.

    ```sql
    UPDATE Person.Address
    SET AddressLine1 = 'This is a human error'
    WHERE AddressId = 1;
    GO
    ```

1. Re-run **Step 1** to verify that the address has been changed. Now imagine if someone had changed thousands or millions of rows without a WHERE clause – or the wrong WHERE clause. One of the solutions involves restoring the database from the last available backup.

    ![Screenshot showing the customer name after the update was executed.](../images/dp-300-module-15-lab-15.png)

1. To restore the database to get it back to where it was before the customer name was mistakenly changed, execute the following.

    **Note:** **SET SINGLE_USER WITH ROLLBACK IMMEDIATE** syntax the open transactions will all be rolled back. This can prevent the restore failing due to active connections.

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

    > **NOTE:** Replace <storage_account_name> with **dp300backupstorage<inject key="DeploymentID" enableCopy="false" />**.

    > The output should be similar to this:

    ![Screenshot showing the restore database from URL being executed.](../images/dp-300-module-15-lab-20.png)

1. Re-run **Step 1** to verify that the customer name has been restored.

    ![Screenshot showing the column with the correct value.](../images/dp-300-module-15-lab-21.png)

It is important to understand the components and the interaction to do a backup to or restore from the Azure Blob Storage service.

You have now seen that you can back up a database to a URL in Azure and, if necessary, restore it.
