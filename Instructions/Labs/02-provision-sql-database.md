---
lab:
    title: 'Lab 2 - Provision an Azure SQL Database'
    module: 'Plan and Implement Data Platform Resources'
---

# Provision an Azure SQL Database

**Estimated Time: 40 minutes**

Students will configure basic resources needed to deploy an Azure SQL Database with a Virtual Network Endpoint. Connectivity to the SQL Database will be validated using Azure Data Studio from the lab VM.

As a database administrator for AdventureWorks, you will set up a new SQL Database, including a Virtual Network Endpoint to increase and simplify the security of the deployment. Azure Data Studio will be used to evaluate the use of a SQL Notebook for data querying and results retention.

## Navigate on Azure portal

1. From the lab virtual machine, start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/). Connect to the Portal using the Azure **Username** and **Password** provided on the **Resources** tab for this lab virtual machine.

    ![Picture 1](../images/dp-300-module-01-lab-01.png)

1. From the Azure portal, search for “resource groups” in the search box at the top, then select **Resource groups** from the list of options.

    ![Picture 1](../images/dp-300-module-02-lab-45.png)

1. On the **Resource group** page, check the resource group listed (it should start with *contoso-rg*), make note of the **Location** assigned to your resource group, as you will use it in the next exercise.

    **Note:** You may have a different location assigned.

    ![Picture 1](../images/dp-300-module-02-lab-46.png)

## Create a Virtual Network

1. In the Azure portal home page, select the left hand menu.  

    ![Picture 2](../images/dp-300-module-02-lab-01_1.png)

1. In the left navigation pane, click **Virtual Networks**  

1. Click **+ Create** to open the **Create Virtual Network** page. On the **Basics** tab, complete the following information:

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *contoso-rg*
    - **Name:** lab02-vnet
    - **Region:** Select the same region where your resource group was created

1. Click **Review + Create**, review the settings for the new virtual network, and then click **Create**.

1. Configure the virtual network’s IP range for the Azure SQL database endpoint by navigating to the virtual network created, and on the **Settings** pane, click **Subnets**.

1. Click on the **default** subnet link. Note that the **Subnet address range** you see might be different.

1. In the **Edit subnet** pane on the right, expand the **Services** drop-down, and select **Microsoft.Sql**. Select **Save**.

## Provision an Azure SQL Database

1. From the Azure Portal, search for “SQL databases” in the search box at the top, then click **SQL databases** from the list of options.

    ![Picture 5](../images/dp-300-module-02-lab-10.png)

1. On the **SQL databases** blade, select **+ Create**.

    ![Picture 6](../images/dp-300-module-02-lab-10_1.png)

1. On the **Create SQL Database** page, select the following options on the **Basics** tab and then click **Next: Networking**.

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *contoso-rg*
    - **Database Name:** AdventureWorksLT
    - **Server:** click on **Create new** link. The **Create SQL Database Server** page will open. Provide the server details as follow:
        - **Server name:** dp300-lab-&lt;your initials (lower case)&gt; (server name must be globally unique)
        - **Location:** &lt;your local region, same as the selected region for your resource group, otherwise it may fail&gt;
        - **Authentication method:** Use SQL authentication
        - **Server admin login:** dp300admin
        - **Password:** dp300P@ssword!
        - **Confirm password:** dp300P@ssword!

        Your **Create SQL Database Server** page should look similar to the one below. Then click **OK**.

        ![Picture 7](../images/dp-300-module-02-lab-11.png)

    -  Back to the **Create SQL Database** page, make sure **Want to use Elastic Pool?** is set to **No**.
    -  On the **Compute + Storage** option, click on **Configure database** link. On the **Configure** page, for **Service tier** dropdown, select **Basic**, and then **Apply**.

    **Note:** Make note of this server name, and your login information. You will use it in subsequent labs.

1. For the **Backup storage redundancy** option, keep the default value: **Geo-redundant backup storage**.

1. Then click **Next: Networking**.

1. On the **Networking** tab, for **Network Connectivity** option, click the **Private endpoint** radio button.

    ![Picture 8](../images/dp-300-module-02-lab-14.png)

1. Then click the **+ Add private endpoint** link under the **Private endpoints** option.

	![Picture 9](../images/dp-300-module-02-lab-15.png)

1. Complete the **Create private endpoint** right pane as follows:

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *contoso-rg*
    - **Location:** &lt;your local region, same as the selected region for your resource group, otherwise it may fail&gt;
    - **Name:** DP-300-SQL-Endpoint
    - **Target sub-resource:** SqlServer
    - **Virtual network:** lab02-vnet
    - **Subnet:** lab02-vnet/default (10.x.0.0/24)
    - **Integrate with private DNS zone:** Yes
    - **Private DNS zone:** keep the default value
    - Review settings, and then click **OK**  

    ![Picture 10](../images/dp-300-module-02-lab-16.png)

1. The new endpoint will appear on the **Private endpoints** list.

    ![Picture 11](../images/dp-300-module-02-lab-17.png)

1. Click **Next: Security**, and then **Next: Additional settings**.  

1. On the **Additional settings** page, select **Sample** on the **Use existing data** option. Select **OK** if a pop-up message is displayed for the sample database.

    ![Picture 12](../images/dp-300-module-02-lab-18.png)

1. Click **Review + Create**.

1. Review the settings before clicking **Create**.

1. Once the deployment is complete, click **Go to resource**.

## Enable access to an Azure SQL Database

1. From the **SQL database** page, select the **Overview** section, and then select the link for the server name in the top section:

    ![Picture 13](../images/dp-300-module-02-lab-19.png)

1. On the SQL servers navigation blade, select **Networking** under the **Security** section.

    ![Picture 14](../images/dp-300-module-02-lab-20.png)

1. On the **Public access** tab, select **Selected networks**, and then check the **Allow Azure services and resources to access this server** property. Click **Save**.

    ![Picture 15](../images/dp-300-module-02-lab-21.png)

## Connect to an Azure SQL Database in Azure Data Studio

1. Launch Azure Data Studio from the lab virtual machine.

    - You may see this pop-up at initial launch of Azure Data Studio. If you receive it, click **Yes (recommended)**  

        ![Picture 16](../images/dp-300-module-02-lab-22.png)

1. When Azure Data Studio opens, click the **Connections** button in top left corner, and then **Add Connection**.

    ![Picture 17](../images/dp-300-module-02-lab-25.png)

1. In the **Connection** sidebar, fill out the **Connection Details** section with connection information to connect to the SQL database created previously.

    - Connection Type: **Microsoft SQL Server**
    - Server: Enter the name of the SQL Server created previously. For example: **dp300-lab-xxxxxxxx.database.windows.net** (Where ‘xxxxxxxx’ is a ramdom number)
    - Authentication Type: **SQL Login**
    - User name: **dp300admin**
    - Password: **dp300P@ssword!**
    - Expand the Database drop-down to select **AdventureWorksLT.** 
        - **NOTE:** You may be asked to add a firewall rule that allows your client IP access to this server. If you are asked to add a firewall rule, click on **Add account** and login to your Azure account. On **Create new firewall rule** screen, click **OK**.

        ![Picture 18](../images/dp-300-module-02-lab-26.png)

        Alternatively, you can manually create a firewall rule for your SQL server on Azure portal by navigating to your SQL server, selecting **Networking**, and then selecting **+ Add your client IPv4 address (your IP address)**

        ![Picture 18](../images/dp-300-module-02-lab-47.png)

    Back on the Connection sidebar, continue filling out the connection details:  

    - Server group will remain on **&lt;default&gt;**
    - Name (optional) can be populated with a friendly name of the database, if desired
    - Review settings and click **Connect**  

    ![Picture 19](../images/dp-300-module-02-lab-27.png)

1. Azure Data Studio will connect to the database, and show some basic information about the database, plus a partial list of objects.

    ![Picture 20](../images/dp-300-module-02-lab-28.png)

## Query an Azure SQL Database with a SQL Notebook

1. In Azure Data Studio, connected to this lab’s AdventureWorksLT database, click the **New Notebook** button.

    ![Picture 21](../images/dp-300-module-02-lab-29.png)

1. Click the **+Text** link to add a new text box in the notebook  

    ![Picture 22](../images/dp-300-module-02-lab-30.png)

**Note:** Within the notebook you can embed plain text to explain queries or result sets.

1. Enter the text **Top Ten Customers by Order SubTotal**, making it Bold if desired.

    ![A screenshot of a cell phone Description automatically generated](../images/dp-300-module-02-lab-31.png)

1. Click the **+ Cell** button, then **Code cell** to add a new code cell at the end of the notebook.  

    ![Picture 23](../images/dp-300-module-02-lab-32.png)

5. Paste the following SQL statement into the new cell:

```sql
SELECT TOP 10 cust.[CustomerID], 
    cust.[CompanyName], 
    SUM(sohead.[SubTotal]) as OverallOrderSubTotal
FROM [SalesLT].[Customer] cust
    INNER JOIN [SalesLT].[SalesOrderHeader] sohead
         ON sohead.[CustomerID] = cust.[CustomerID]
GROUP BY cust.[CustomerID], cust.[CompanyName]
ORDER BY [OverallOrderSubTotal] DESC
   ```

1. Click on the blue circle with the arrow to execute the query. Note how the results are included within the cell with the query.

1. Click the **+ Text** button to add a new text cell.

1. Enter the text **Top Ten Ordered Product Categories**, making it Bold if desired.

1. Click the **+ Code** button again to add a new cell, and paste the following SQL statement into the cell:

```sql
SELECT TOP 10 cat.[Name] AS ProductCategory, 
    SUM(detail.[OrderQty]) AS OrderedQuantity
FROM salesLT.[ProductCategory] cat
   INNER JOIN [SalesLT].[Product] prod
      ON prod.[ProductCategoryID] = cat.[ProductCategoryID]
   INNER JOIN [SalesLT].[SalesOrderDetail] detail
      ON detail.[ProductID] = prod.[ProductID]
GROUP BY cat.[name]
ORDER BY [OrderedQuantity] DESC
```

1. Click on the blue circle with the arrow to execute the query.

1. To run all cells in the notebook and present results, click the **Run all** button in the toolbar.

	![Picture 17](../images/dp-300-module-02-lab-33.png)

1. Within Azure Data Studio save the notebook from File menu (either Save or Save As) to the **C:\Labfiles\Deploy Azure SQL Database** path (create the folder structure if it does not exist). Make sure the file extension is **.ipynb**

1. Close the tab for the Notebook from inside of Azure Data Studio. From the File Menu, select Open File, and open the notebook you just saved. Observe that query results were saved along with the queries in the notebook.

In this exercise, you've seen how you deploy a Azure SQL Database with a Virtual Network Endpoint. You were also able to connect to the SQL Database you've created using SQL Server Management Studio.
