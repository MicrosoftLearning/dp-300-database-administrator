---
lab:
    title: 'Lab 3 – Implement a Secure Environment'
    module: 'Implement a Secure Environment'
---

# Lab 3 – Implement a Secure Environment
 

**Estimated Time**: 60 minutes

**Prerequisites**: An Azure SQL server you created in the lab for Module 2. Azure Active Directory access in the subscription.  

**Lab files**: The files for this lab are in the D:\Labfiles\Secure Environment folder.

# Lab overview

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the AdventureWorks database. 

# Lab objectives

After completing this lab, you will be able to:

1. Configure an Azure SQL Database Firewall

2. Authorize Access to Azure SQL Database with Azure Active Directory

3. Enable Microsoft Defender for SQL for Azure SQL Database

4. Configure Data Classification for Azure SQL Database

5. Manage access to database objects

# Scenario

You have been hired as a Senior Database Administrator help ensure the security of the database environment. These tasks will focus on Azure SQL Database. 

**Note:** The exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, with the proper line breaks, before executing the code. 

## Exercise 1: Configure an Azure SQL Database Firewall and connect to a new database

1. From the lab virtual machine, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Provide appropriate credentials. 

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-01.png)

2. In the search bar at the top of the Azure Portal, type SQL. The SQL servers icon will appear. Click on SQL servers. Click on the server name to be taken to the detail page for the server you created in Lab 2

	![A screenshot of a social media post Description automatically generated](../images/dp-3300-module-33-lab-02.png)

3. In the detail screen for your SQL server, move your mouse to the right of the server name, and click copy to clipboard button as shown below.

	![Picture 2](../images/dp-3300-module-33-lab-03.png)

4. Click on Show firewall settings (above the server name that you just copied). Click on **+ Add client IP** as highlighted below and then click Save.

    ![Picture 3](../images/dp-3300-module-33-lab-04.png)

	This will allow you to connect to your Azure SQL Database server using SQL Server Management Studio or any other client tools. **Important:** Make note of your client IP address, you will use it later in this task.

5. Open SQL Server Management Studio on the lab VM. Paste in the name of your Azure SQL database server and login with the credentials you created in Lab 2:

	- Server name: **&lt;_paste your Azure SQL database server name here_&gt;** 
         
	 - Authentication: **SQL Server Authentication**  
	
	- Server admin login: **dp300admin**

	- Password: **dp300P@ssword!**

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-05.png)

	Click **Connect**.

6. In Object Explorer expand the server node, and right click on databases. Click Import a Data-tier Application.

	![A screenshot of a social media post Description automatically generated](../images/dp-3300-module-33-lab-06.png)

7. In the Import Data Tier Application dialog, click Next on the first screen. 

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-07.png)

8. In the Import Settings screen, click Browse and navigate to D:\Labfiles\Secure Environment folder and click on the AdventureWorks.bacpac file and click open. Then in the Import Data-tier application screen click **Next**.

	![Picture 996777398](../images/dp-3300-module-33-lab-08.png)

	![A screenshot of a social media post Description automatically generated](../images/dp-3300-module-33-lab-09.png)

9. On the database settings screen, change the edition of Azure SQL Database to General Purpose. Change the Service Objective to **GP_Gen5_2** and click **Next**. 

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-10.png)

10.  On the Summary screen click **Finish**. When your import completes you will see the results below. Then click **Close**
	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-11.png)

11. In Object Explorer, expand the Databases folder. Then right-click on AdventureWorks and click on new query. 

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-12.png)

12. Execute the following T-SQL query by pasting the text into your query window. **Important:** Replace 192.168.1.1. with your client IP address from Step 4. Click execute or press F5.

	```sql
	EXECUTE sp_set_database_firewall_rule @name = N'ContosoFirewallRule',

	@start_ip_address = '192.168.1.1', @end_ip_address = '192.168.1.1'
	```

13. Next you will create a contained user in the AdventureWorks database. Click New Query and execute the following T-SQL. Ensure that you are still using the AdventureWorks database. If you see master in the database name box below, you can pull down and switch to AdventureWorks.

	```sql
	CREATE USER containeddemo WITH PASSWORD = 'P@ssw0rd!'
	```
    ![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-13.png)
    
    Click **Execute** to run this command. This command creates a contained user within the AdventureWorks database. You will login using the username and password in the next step.
    
14. Navigate to the Object Explorer. Click on **Connect** and then **Database Engine**.

	![Picture 1960831949](../images/dp-3300-module-33-lab-14.png)

15. Attempt to connect with the credentials you created in step 13. 
    You will need to use the following information:  
	-  **Login:** containeddemo   
	-  **Password:**  P@ssw0rd! 
	 
     Click **Connect**.
	 
     You will see the following error.

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-15.png)

	This error is generated because the connection attempted to login to the master database and not AdventureWorks where the user was created. Change the connection context by clicking **OK** to exit the error message and then clicking on **Options >>** in the Connect to Server dialog box as shown below.

	![Picture 9](../images/dp-3300-module-33-lab-16.png)

16. On the connection options tab, type the database name AdventureWorks. Click **Connect**.

	![A screenshot of a social media post Description automatically generated](../images/dp-3300-module-33-lab-17.png)

17. Another database should appear in the Object Explorer. 

    ![Picture 10](../images/dp-3300-module-33-lab-18.png)

    Make sure the selection stays on the newly added database. Then click **Connect** from the Object Explorer and **Database Engine**. 
    Enter the following again: 
    - **Login:** containeddemo   
	- **Password:**  P@ssw0rd! 

    Click **Connect**.

    This time the connection bypasses the master database and logs you directly into AdventureWorks, which is the only database to which the newly created user has access.

## Exercise 2: Authorize Access to Azure SQL Database with Azure Active Directory

1. Navigate to the Azure Portal, and click on your user name in the top right corner of the screen.

	![A picture containing bottle, black, photo, orange Description automatically generated](../images/dp-3300-module-33-lab-19.png)

	Make note of the user name. 
	
	**Important:** A Microsoft account (a user account from Outlook, Gmail, Hotmail or Yahoo, for example) is **not supported** for the Azure Active Directory administrator for Azure SQL Database. As a workaround, you can create an Azure Active Directory group named DBA and add your user account to it. Alternatively, you can skip Exercise 2.

2. In the Azure Portal navigate to your Azure SQL Database server **dp300-lab-xx** and click on **Not Configured** next to Active Directory Admin.

	![Picture 11](../images/dp-3300-module-33-lab-20.png)

	On the next screen, click **Set admin**.

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-21.png)

3. In the Set admin screen, search for your username. When you have found it, click on it to highlight the username, and then click **Select**. You will be returned to the above Active Directory Admin screen. Click **Save** to complete the process. This will make your username the Azure Active Directory admin for the server as shown below

	![Picture 12](../images/dp-3300-module-33-lab-22.png)

4. Open SQL Server Management Studio and click **Connect**, then **Database Engine**. In the server name enter the name of your server. Change the authentication type to Azure Active Directory Universal with MFA.

	![A screenshot of a cell phone Description automatically generated](../images/dp-3300-module-33-lab-23.png)

	You will be prompted to enter your Azure Active Directory password, and will you click **Connect**, you'll be logged in to your database. 

## Exercise 3: Enable Microsoft Defender for SQL and Data Classification

1. From the main blade of your Azure SQL server, navigate to the **Security** section, and select **Microsoft Defender for Cloud**.

    ![Screenshot of selecting the Microsoft Defender for Cloud option](../images/dp-3300-module-33-lab-24.png)

    On the **Microsoft Defender for Cloud** page, select **Enable Microsoft Defender for SQL** in case this option is not enabled.

2. After Azure Defender for SQL is successfully enabled, select **Configure** option. You may need to refresh the page to see this option.

    ![Screenshot of selecting the Configure option](../images/dp-3300-module-33-lab-25_2.png)

3. On the **Server Settings** page, make sure the toggle switch under **MICROSOFT DEFENDER FOR SQL** is set to **ON**, and that the **Storage account** name is provided. Enter the Azure account email in the **Send scan reports to**, and select **Save**.

    ![Screenshot of Server settings page](../images/dp-3300-module-33-lab-25_3.png)

4. Navigate to the **AdventureWorksLT** database in the Azure portal by scrolling down in the overview screen for Azure SQL server and select the database name.

    ![Screenshot showing selecting the AdventureWOrksLT database](../images/dp-3300-module-33-lab-27.png)

5. Navigate to the Security section of the main blade for your Azure SQL Database and select **Data Discovery & Classification**.

    ![Screenshot showing the Data Discovery & Classification](../images/dp-3300-module-33-lab-28.png)

6. On the **Data Discovery & Classification** screen you will see an informational message that reads **We have found 15 columns with classification recommendations**. Select that link.

    ![Screenshot showing the Classification Recommendations](../images/dp-3300-module-33-lab-29.png)

7. On the next **Data Discovery & Classification** screen select the check box next to **Select all**, select **Accepted selected recommendations**, and then select **Save** to save the classifications into the database.

    ![Screenshot showing the Accept selected recommendations](../images/dp-3300-module-33-lab-30.png)

## Exercise 4: Manage access to database objects

1. In this exercise, you will manage access to the database and its objects. Navigate back to SQL Server Management Studio. The first thing you will do is create two users in the AdventureWorks database. 

    In the Object Explorer, right click on the AdventureWorks database and select **New Query**. In the new query window, copy and paste the following T-SQL into it. Verify that the code has been copied correctly. 

```sql
CREATE USER [DP300User1] WITH PASSWORD = 'Azur3Pa$$'

GO

CREATE USER [DP300User2] WITH PASSWORD = 'Azur3Pa$$'

GO
```

You will note these users are created in the scope of the database. So if you were to try to login with one of these users, you would need to specify the AdventureWorks database in your connection string.

2. Next you will create a custom role and add the users to it. Add the following T-SQL in the same query window as in step 1. Click **Execute** to run. 

```sql
CREATE ROLE [SalesReader]

GO

ALTER ROLE [SalesReader] ADD MEMBER [DP300User1]

GO

ALTER ROLE [SalesReader] ADD MEMBER [DP300User2]

GO
```

3. Next you will grant permissions to the role. In this case you are assigning SELECT and EXECUTE on the Sales schema. Clear the window of the previous query. Then in the same window, click **Execute** to run the below T-SQL to grant the permissions to the role.

```sql
GRANT SELECT, EXECUTE ON SCHEMA::Sales TO [SalesReader]

GO
```
 

4. Next you will create a new stored procedure in the Sales schema. You will note this procedure access a table in the Product schema. Clear the window of the previous query. Execute the below T-SQL in your query window.

```sql
CREATE OR ALTER PROCEDURE Sales.DemoProc

AS

SELECT P.Name, Sum(SOD.LineTotal) as TotalSales ,SOH.OrderDate 

FROM Production.Product P

INNER JOIN Sales.SalesOrderDetail SOD on SOD.ProductID = P.ProductID

INNER JOIN Sales.SalesOrderHeader SOH on SOH.SalesOrderID = SOD.SalesOrderID

GROUP BY P.Name, SOH.OrderDate

ORDER BY TotalSales DESC

GO
```
 

5. Next you will use the EXECUTE AS USER command to test out the security you just created. This allows the database engine to execute a query in the context of your user. Clear the window of the previous query. Execute the below query in your query window.

```sql
EXECUTE AS USER = 'DP300User1'


SELECT P.Name, Sum(SOD.LineTotal) as TotalSales ,SOH.OrderDate 

FROM Production.Product P

INNER JOIN Sales.SalesOrderDetail SOD on SOD.ProductID = P.ProductID

INNER JOIN Sales.SalesOrderHeader SOH on SOH.SalesOrderID = SOD.SalesOrderID

GROUP BY P.Name, SOH.OrderDate

ORDER BY TotalSales DESC
```
 

This query will fail, with an error message saying the SELECT permission was denied on the Production.Product table. The role that user DP300User1 is a member of has SELECT permission in the Sales schema, but not in the Production schema. 

However, if you execute the stored procedure in that same context, the query will complete. Clear the query that gave an error message. Then execute the following T-SQL.

```sql
EXECUTE AS USER = 'DP300User1'

EXECUTE Sales.DemoProc
```

This happens because stored procedures take advantage a feature called ownership chaining to provide data access to users who do not have direct permissions to access database objects. For all objects that have the same owner, the database engine only checks the EXECUTE permission on the procedure and not the underlying objects. 

**Do not remove any of the resources created in this lab as they will be used in subsequent lab exercises.**
