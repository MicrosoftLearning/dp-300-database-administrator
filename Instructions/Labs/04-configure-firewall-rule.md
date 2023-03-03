# Implement a Secure Environment

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the AdventureWorks database.

You have been hired as a Senior Database Administrator to help ensure the security of the database environment. These tasks will focus on Azure SQL Database.

>**Note:** These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Configure Azure SQL Database firewall rules

1. In the lab virtual machine, double click on the Azure portal shortcut on the desktop [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using the Azure **Username** <inject key="AzureAdUserEmail"></inject> and **Password** <inject key="AzureAdUserPassword"></inject>

    ![Picture 1](../images/dp300-lab4-img1.png)

1. From the Azure Portal, search for **SQL servers (1)** in the search box at the top, then click **SQL servers (2)** from the list of options.

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img2.png)

1. Select the server name **dp300-lab-<inject key="Deployment-id" enableCopy="false" />** to be taken to the detail page (you may have a different resource group and location assigned for your SQL server).

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img3.png)

1. Select **Show networking settings**.

    ![Picture 2](../images/dp300-lab4-img5.png)

1. On the **Networking** page, click on **+ Add your client IPv4 address (your IP address)**, and then click **Save**.

    ![Picture 3](../images/dp300-lab4-img6.png)

    >**Note:** Your client IP address was automatically entered for you. Adding your client IP address to the list will allow you to connect to your Azure SQL Database using SQL Server Management Studio or any other client tools. **Make note of your client IP address, you will use it later.**

1. Open SQL Server Management Studio in the labvm. On the Connect to Server dialog box, paste in the name of your Azure SQL Database server, and login with the credentials below:

    - **Server name:** <inject key="sqlServerFqdn"></inject> 
    - **Authentication:** SQL Server Authentication
    - **Server admin login:** sqladmin
    - **Password:** P@ssw0rd01

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img7.png)

1. Click **Connect**.

1. In Object Explorer expand the server node, and right click on **Databases**. Click **Import Data-tier Application**.

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img8.png)

1. In the **Import Data Tier Application** dialog, click **Next** on the first screen.
     
1. In the **Import Settings** screen, click **Browse** and navigate to **C:\LabFiles\SecureEnvironment** folder, click on the **AdventureWorksLT.bacpac** file, and then click **Open**. Back to the **Import Data-tier Application** screen click **Next**.

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img9.png)

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img10.png)

1. On the **Database Settings** screen, make the changes as below:

    - **Database name:** AdventureWorksFromBacpac
    - **Edition of Microsoft Azure SQL Database**: Basic

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img11.png)

1. Click **Next**.

1. On the **Summary** screen click **Finish**. When your import completes you will see the results below. Then click **Close**.

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img12.png)
     
     >**Note:** Please wait untill Operation complete successfully it might take sometime.

1. Back to SQL Server Management Studio, in **Object Explorer**, expand the **Databases** folder. Then right-click on **AdventureWorksFromBacpac** database, and then **New Query**.

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img13.png)

1. Execute the following T-SQL query by pasting the text into your query window.
    1. **Important:** Replace **000.000.000.00** with your client IP address. Click **Execute** or press **F5**.

    ```sql
    EXECUTE sp_set_database_firewall_rule 
            @name = N'AWFirewallRule',
            @start_ip_address = '000.000.000.00', 
            @end_ip_address = '000.000.000.00'
    ```

1. Next you will create a contained user in the **AdventureWorksFromBacpac** database. Click **New Query** and execute the following T-SQL.

    ```sql
    USE [AdventureWorksFromBacpac]
    GO
    CREATE USER ContainedDemo WITH PASSWORD = 'P@ssw0rd01'
    ```

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img14.png)

    >**Note:** This command creates a contained user within the **AdventureWorksFromBacpac** database. We will test this credential in the next step.

1. Navigate to the **Object Explorer**. Click on **Connect**, and then **Database Engine**.

    ![Picture 1960831949](../images/dp300-lab4-img15.png)

1. Attempt to connect with the credentials you created in the previous step. You will need to use the following information:

    - **Login:** ContainedDemo
    - **Password:** P@ssw0rd01

     Click **Connect**.

     You will receive the following error.

    ![A screenshot of a cell phone Description automatically generated](../images/dp300-lab4-img16.png)

    >**Note:** This error is generated because the connection attempted to login to the *master* database and not **AdventureWorksFromBacpac** where the user was created. Change the connection context by clicking **OK** to exit the error message, and then clicking on **Options >>** in the **Connect to Server** dialog box as shown below.

    ![Picture 9](../images/dp300-lab4-img17.png)

1. On the **Connection Properties** tab, type the database name **AdventureWorksFromBacpac**, and then click **Connect**.

    ![A screenshot of a social media post Description automatically generated](../images/dp300-lab4-img18.png)

1. Notice that you were able to successfully authenticate using the **ContainedDemo** user. This time you were directly logged into **AdventureWorksFromBacpac**, which is the only database to which the newly created user has access to.

    ![Picture 10](../images/dp300-lab4-img19.png)

In this exercise, you've configured server and database firewall rules to access a database hosted on Azure SQL Database. You've also used T-SQL statements to create a contained user, and used SQL Server Management Studio to check the access.
