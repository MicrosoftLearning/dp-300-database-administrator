---
lab:
    title: 'Lab 2 - Provision an Azure SQL Database'
    module: 'Plan and Implement Data Platform Resources'
---

# Provision an Azure SQL Database

**Estimated Time: 40 minutes**

Students will configure basic resources needed to deploy an Azure SQL Database with a Virtual Network Endpoint. Connectivity to the SQL Database will be validated using SQL Server Management Studio from the lab VM if available or from your local machine setup.

As a database administrator for AdventureWorks, you will set up a new SQL Database, including a Virtual Network Endpoint to increase and simplify the security of the deployment. SQL Server Management Studio will be used to evaluate the use of a SQL Notebook for data querying and results retention.

## Navigate on Azure portal

1. On the lab virtual machine if provided, otherwise on your local machine, open a browser window.

1. Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com/). Log in to the Azure portal using your Azure account or provided credentials if available.

1. From the Azure portal, search for *resource groups* in the search box at the top, then select **Resource groups** from the list of options.

1. On the **Resource group** page, if provided, select the resource group starting with *contoso-rg*. If this resource group doesn't exist, either create a new resource group named with *contoso-rg* in your local region, or use an existing resource group and take note of the region its in.

## Create a Virtual Network

1. In the Azure portal home page, select the left hand menu.  

1. In the left navigation pane, select **Virtual Networks**  

1. Select **+ Create** to open the **Create Virtual Network** page. On the **Basics** tab, complete the following information:

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *DP300* or the resource group you previously selected
    - **Name:** lab02-vnet
    - **Region:** Select the same region where your resource group was created

1. Select **Review + Create**, review the settings for the new virtual network, and then select **Create**.

## Provision an Azure SQL Database in the Azure portal

1. From the Azure Portal, search for *SQL databases* in the search box at the top, then select **SQL databases** from the list of options.

1. On the **SQL databases** blade, select **+ Create**.

1. On the **Create SQL Database** page, select the following options on the **Basics** tab and then select **Next: Networking**.

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *DP300* or the resource group you previously selected
    - **Database Name:** AdventureWorksLT
    - **Server:** select on **Create new** link. The **Create SQL Database Server** page will open. Provide the server details as follow:
        - **Server name:** dp300-lab-&lt;your initials (lower case)&gt; and if needed a random 5 digit number (server name must be globally unique)
        - **Location:** &lt;your local region, same as the selected region for your resource group, otherwise it may fail&gt;
        - **Authentication method:** Use SQL authentication
        - **Server admin login:** dp300admin
        - **Password:** select a complex password and take note of it
        - **Confirm password:** select the same previously selected password
    - Select **OK** to to return to the **Create SQL Database** page.
    - **Want to use Elastic Pool?** set to **No**.
    - **Workload environment:** Development
    - On the **Compute + Storage** option, select on **Configure database** link. On the **Configure** page, for **Service tier** dropdown, select **Basic**, and then **Apply**.

1. For the **Backup storage redundancy** option, keep the default value: **Local-redundant backup storage**.

1. Then select **Next: Networking**.

1. On the **Networking** tab, for **Network Connectivity** option, select the **Private endpoint** radio button.

1. Then select the **+ Add private endpoint** link under the **Private endpoints** option.

1. Complete the **Create private endpoint** right pane as follows:

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** starting with *DP300* or the resource group you previously selected
    - **Location:** &lt;your local region, same as the selected region for your resource group, otherwise it may fail&gt;
    - **Name:** DP-300-SQL-Endpoint
    - **Target sub-resource:** SqlServer
    - **Virtual network:** lab02-vnet
    - **Subnet:** lab02-vnet/default (10.x.0.0/24)
    - **Integrate with private DNS zone:** Yes
    - **Private DNS zone:** keep the default value
    - Review settings, and then select **OK**  

1. The new endpoint will appear on the **Private endpoints** list.

1. Select **Next: Security**, and then **Next: Additional settings**.  

1. On the **Additional settings** page, select **Sample** on the **Use existing data** option. Select **OK** if a pop-up message is displayed for the sample database.

1. Select **Review + Create**.

1. Review the settings before selecting **Create**.

1. Once the deployment is complete, select **Go to resource**.

## Enable access to an Azure SQL Database

1. From the **SQL database** page, select the **Overview** section, and then select the link for the server name in the top section.

1. On the SQL servers navigation blade, select **Networking** under the **Security** section.

1. On the **Public access** tab, select **Selected networks**.

1. Select **+ Add your client IPv4 address**. This will add a firewall rule to allow your current IP address to access the SQL server.

1. Check the **Allow Azure services and resources to access this server** property.

1. Select **Save**.

---

## Connect to an Azure SQL Database in SQL Server Management Studio

1. On the Azure portal, select the **SQL databases** in the left navigation pane. And then select the **AdventureWorksLT** database.

1. Copy the **Server name** value from the **Overview** page.

1. Launch SQL Server Management Studio from the lab virtual machine if provided or your local machine if not.

1. In the **Connect to Server** dialog, paste the **Server name** value copied from the Azure portal.

1. In the **Authentication** dropdown, select **SQL Server Authentication**.

1. In the **Login** field, enter **dp300admin**.

1. In the **Password** field, enter the password selected during the SQL server creation.

1. Select **Connect**.

1. SQL Server Management Studio will connect to your Azure SQL Database server. You can expand the server and then the **Databases** node to see the *AdventureWorksLT* database.

## Query an Azure SQL Database with SQL Server Management Studio

1. In SQL Server Management Studio, right-click on the *AdventureWorksLT* database and select **New Query**.

1. Paste the following SQL statement into the query window:

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

1. Select on the **Execute** button in the toolbar to execute the query.

1. In the **Results** pane, review the results of the query.

1. Right-click on the *AdventureWorksLT* database and select **New Query**.

1. Paste the following SQL statement into the query window:

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

1. Select on the **Execute** button in the toolbar to execute the query.

1. In the **Results** pane, review the results of the query.

1. Close SQL Server Management Studio. Select **No** when prompted to save changes.

---

## Cleanup Resources

If you are not using the virtual machine for any other purpose, you can clean up the resources you created in this lab.

### Delete the Resource Group

If you created a new resource group for this lab, you can delete the resource group to remove all resources created in this lab.

1. In the Azure portal, select **Resource groups** from the left navigation pane or search for **Resource groups** in the search bar and select it from the results.

1. Go into the resource group that you created for this lab. The resource group will contain the virtual machine and other resources created in this lab.

1. Select **Delete resource group** from the top menu.

1. In the **Delete resource group** dialog, type the name of the resource group to confirm and select **Delete**.

1. Wait for the resource group to be deleted.

1. Close the Azure portal.

### Delete the Lab resources only

If you didn't create a new resource group for this lab, and want to leave the resource group and its previous resources intact, you can still delete the resources created in this lab.

1. In the Azure portal, select **Resource groups** from the left navigation pane or search for **Resource groups** in the search bar and select it from the results.

1. Go into the resource group that you created for this lab. The resource group will contain the virtual machine and other resources created in this lab.

1. Select all the resources prefixed with the SQL Server name you previously specified in the lab. Additionally, select the virtual network and the private DNS zone you created.

1. Select **Delete** from the top menu.

1. In the **Delete resources** dialog, type **delete** and select **Delete**.

1. Select **Delete** again to confirm the deletion of the resources.

1. Wait for the resources to be deleted.

1. Close the Azure portal.

---

You have successfully completed this lab.

In this exercise, you've seen how you deploy a Azure SQL Database with a Virtual Network Endpoint. You were also able to connect to the SQL Database you've created using SQL Server Management Studio.
