---
lab:
    title: 'Lab 1 - Provision SQL Server on an Azure Virtual Machine'
    module: 'Plan and Implement Data Platform Resources'
---

# Provision a SQL Server on an Azure Virtual Machine

**Estimated Time: 30 minutes**

Students will explore the Azure Portal and use it to create an Azure VM with SQL Server 2022 installed. Then they will connect to the virtual machine through Remote Desktop Protocol.

You are a database administrator for AdventureWorks. You need to create a test environment for use in a proof of concept. The proof of concept will use SQL Server on an Azure Virtual Machine and a backup of the AdventureWorksDW database. You need to set up the Virtual Machine, restore the database, and query it to ensure it is available.

## Deploy a SQL Server on an Azure Virtual Machine

1. Start a browser session and navigate to [https://portal.azure.com](https://portal.azure.com/), and sign in using the Microsoft account associated with your Azure subscription.

1. Locate the search bar at the top of the page. Search for **Azure SQL**. Select the search result for **Azure SQL** that appears in the results under **Services**.

1. On the **Azure SQL** blade, select **Create**.

1. On the **Select SQL deployment option** blade, click on the drop-down box under **SQL virtual machines**. Select the option labeled **Free SQL Server License: SQL Server 2022 Developer on Windows Server 2022**. Then select **Create**.

1. On the **Create a virtual machine** page, enter the following information, *leave all other options as the default values*:

    - **Subscription:** &lt;Your subscription&gt;
    - **Resource group:** &lt;Your resource group&gt;
    - **Virtual machine name:**  AzureSQLServerVM
    - **Region:** &lt;Choose your local region, same as the selected region for your resource group.&gt;
    - **Availability Options:** No infrastructure redundancy required
    - **Image:** Free SQL Server License: SQL Server 2022 Developer on Windows Server 2022 - Gen2
    - **Run with Azure spot discount:** No (unchecked)
    - **Size:** Standard *D2s_v5* (2 vCPUs, 8 GiB memory). *You may need to select the "See all sizes" link to see this option.*
    - **Administrator account username:** &lt;Choose a name for your administrator account.&gt;
    - **Administrator account password:** &lt;Choose a strong password.&gt;
    - **Select inbound ports:** RDP (3389)
    - **Would you like to use an existing Windows Server license?:** No (unchecked)

    > &#128221; Make note of the username and password for later use.

1. Navigate to the **Disks** tab and review the configuration.

1. Navigate to the **Networking** tab and review the configuration.

1. Navigate to the **Management** tab and review the configuration.

    Verify that **Enable auto_shutdown** is unchecked.

1. Navigate to the **Advanced** tab and review the configuration.

1. Navigate to the **SQL Server settings** tab and review the configuration.

    > &#128221; Note that you can also configure the storage for your SQL Server VM on this screen. By default, the SQL Server Azure VM templates create one premium disk with read caching for data, one premium disk without caching for transaction log, and uses the local SSD (D:\ on Windows) for tempdb.

1. Select the **Review + create** button. Then select **Create**.

1. On the deployment blade, wait until the deployment is complete. The VM will take approximate 5-10 minutes to deploy. After the deployment is complete, select  **Go to resource**.

    > &#128221; Note that your deployment may take several minutes to complete.

1. On the **Overview** page for the virtual machine, explore the menu options for this resource to review what is available.

---

## Connect to SQL Server on an Azure Virtual Machine

1. On the **Overview** page for the virtual machine, select the **Connect** pulldown and select **Connect**.

1. On the Connect pane, select the **Download RDP File** button.

    > &#128221; If see the error **Port prerequisite not met**. Make sure to select the link to add an inbound network security group rule with the destination port mentioned in the *Port number* field.

1. Open the RDP file that was just downloaded. When a dialog appears asking if you want to connect, select **Connect**.

1. Enter the username and password selected during the virtual machine provisioning process. Then select **OK**.

1. When the **Remote Desktop Connection** dialog appears asking if you want to connect, select **Yes**.

1. Select the search bar besides the Windows Start button and type SSMS. Select **Microsoft SQL Server Management Studio** from the list.  

1. When SSMS opens, notice that the **Connect to Server** dialog will be pre-populated with the default instance name. Check the option **Trust server certificate** and then select **Connect**.

1. Close SSMS by selecting the **X** in the upper right corner.

1. You can now disconnect from the virtual machine to close the RDP session.

The Azure portal gives you powerful tools to manage a SQL Server hosted in a virtual machine. These tools include control over automated patching, automated backups, and giving you an easy way to setup high availability.

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

1. Select all the resources prefixed with the virtual machine name you previously specified in the lab.

1. Select **Delete** from the top menu.

1. In the **Delete resources** dialog, type **delete** and select **Delete**.

1. Select **Delete** again to confirm the deletion of the resources.

1. Wait for the resources to be deleted.

1. Close the Azure portal.

---

You have successfully completed this lab.
