---
lab:
    title: 'Lab 4 – Configure Azure SQL Database firewall rules'
    module: 'Implement a Secure Environment for a Database Service'
---

# Implement a Secure Environment

**Estimated Time: 30 minutes**

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the *AdventureWorksLT* database.

You have been hired as a Senior Database Administrator to help ensure the security of the database environment. These tasks will focus on Azure SQL Database.

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

## Configure Azure SQL Database firewall rules

1. From the lab virtual machine or your local machine if one wasn't provided, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using your Azure credentials.

1. From the Azure Portal, search for *SQL servers* in the search box at the top, then select **SQL servers** from the list of options.

1. Select the SQL server **dp300-lab-xxxxxxxx**, where *xxxxxxxx* is a random numeric string.

    > &#128221; Note, if you are using your own Azure SQL server not created by this lab, select the name of that SQL server.

1. In the *Overview* screen for your SQL server, to the right of the server name, select the **Copy to clipboard** button.

1. Select **Show networking settings**.

1. On the **Networking** page, under **Firewall rules**, review the list and make sure that your client IP address is listed. If it isn't listed, select on **+ Add your client IPv4 address (your IP address)**, and then select **Save**.

    > &#128221; Note that your client IP address was automatically entered for you. Adding your client IP address to the list will allow you to connect to your Azure SQL Database using SQL Server Management Studio (SSMS) or any other client tools. **Make note of your client IP address, you will use it later.**

1. Open SQL Server Management Studio. On the Connect to Server dialog box, paste in the name of your Azure SQL Database server, and login with the following credentials:

    - **Server name:** &lt;_paste your Azure SQL Database server name here_&gt;
    - **Authentication:** SQL Server Authentication
    - **Server admin login:** Your Azure SQL Database server admin login
    - **Password:** Your Azure SQL Database server admin password

1. Select **Connect**.

1. In Object Explorer expand the server node, and right click on **Databases**. Select **Import a Data-tier Application**.

1. In the **Import Data Tier Application** dialog, click **Next** on the first screen.

1. In the **Import Settings** screen, click **Browse** and navigate to **C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\04** folder, click on the **AdventureWorksLT.bacpac** file, and then click **Open**. Back to the **Import Data-tier Application** screen select **Next**.

1. On the **Database Settings** screen, make the changes as below:

    - **Database name:** AdventureWorksFromBacpac
    - **Edition of Microsoft Azure SQL Database**: Basic

1. Select **Next**.

1. On the **Summary** screen select **Finish**. This could take a few minutes. When your import completes you will see the results below. Then select **Close**.

1. Back to SQL Server Management Studio, in **Object Explorer**, expand the **Databases** folder. Then right-click on **AdventureWorksFromBacpac** database, and then **New Query**.

1. Execute the following T-SQL query by pasting the text into your query window.
    1. **Important:** Replace **000.000.000.000** with your client IP address. Select **Execute**.

    ```sql
    EXECUTE sp_set_database_firewall_rule 
            @name = N'AWFirewallRule',
            @start_ip_address = '000.000.000.000', 
            @end_ip_address = '000.000.000.000'
    ```

1. Next you will create a contained user in the **AdventureWorksFromBacpac** database. Select **New Query** and execute the following T-SQL.

    ```sql
    USE [AdventureWorksFromBacpac]
    GO
    CREATE USER ContainedDemo WITH PASSWORD = 'P@ssw0rd01'
    ```

    > &#128221; This command creates a contained user within the **AdventureWorksFromBacpac** database. We will test this credential in the next step.

1. Navigate to the **Object Explorer**. Click on **Connect**, and then **Database Engine**.

1. Attempt to connect with the credentials you created in the previous step. You will need to use the following information:

    - **Login:** ContainedDemo
    - **Password:** P@ssw0rd01

     Click **Connect**.

     You will receive the following error.

    <span style="color:red">Login failed for user 'ContainedDemo'. (Microsoft SQL Server, Error: 18456)</span>

    > &#128221; This error is generated because the connection attempted to login to the *master* database and not **AdventureWorksFromBacpac** where the user was created. Change the connection context by selecting **OK** to exit the error message, and then selecting on **Options >>** in the **Connect to Server**.

1. On the **Connection Properties** tab, type the database name **AdventureWorksFromBacpac**, and then select **Connect**.

1. Notice that you were able to successfully authenticate using the **ContainedDemo** user. This time you were directly logged into **AdventureWorksFromBacpac**, which is the only database to which the newly created user has access to.

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

In this exercise, you've configured server and database firewall rules to access a database hosted on Azure SQL Database. You've also used T-SQL statements to create a contained user, and used SQL Server Management Studio to check the access.
