# Enable Microsoft Defender for SQL and Data Classification

The students will take the information gained in the lessons to configure and subsequently implement security in the Azure Portal and within the AdventureWorks database.

You have been hired as a Senior Database Administrator help ensure the security of the database environment. These tasks will focus on Azure SQL Database.

## Enable Microsoft Defender for SQL

1. From the Azure Portal, search for “SQL servers” in the search box at the top, then click on **SQL servers** from the list of options.

    ![Picture 1](../images/upd-dp-300-module-04-lab-1.png)

1. Select the server name **dp300-lab- <inject key="Deployment-id"></inject>** to be taken to the detail page (you may have a different location assigned for your SQL server).

    ![A screenshot of a social media post Description automatically generated](../images/upd-dp-300-module-04-lab-2.png)

1. From the main blade of your Azure SQL server, navigate to the **Security** section, and select **Microsoft Defender for Cloud (1)**.

    ![Screenshot of selecting the Microsoft Defender for Cloud option](../images/upd-dp-300-module-05-lab-01.png)

    On the **Microsoft Defender for Cloud** page, select **Enable Microsoft Defender for SQL (2)**.

1. The following notification message will show up after Azure Defender for SQL is successfully enabled.

    ![Screenshot of selecting the Configure option](../images/upd-dp-300-module-05-lab-02_1.png)

1. On the **Microsoft Defender for Cloud** page, select the **Configure** link (You may need to refresh the page to see this option)

    ![Screenshot of selecting the Configure option](../images/defenderconfigure.png)

1. On the **Server settings** page, notice that toggle switch under **MICROSOFT DEFENDER FOR SQL** is set to **ON (1)**, and then select **Save (2)**.

    ![Screenshot of Server settings page](../images/upd-dp-300-module-05-lab-03.png)

## Enable Data Classification

> **Note:** 
> - Microsoft Defender for Cloud can take upto 24-48 hours to surface post the completion of a scan.
> - At this point of the workshop, no data visualisations may be populated. (So the result in the screenshot below may vary)

1. From the main blade of your Azure SQL server, navigate to the **Settings** section, and select **SQL databases (1)**, and then select the database name **(2)**.

    ![Screenshot showing selecting the AdventureWOrksLT database](../images/upd-dp-300-module-05-lab-04.png)

1. On the main blade for the **AdventureWorksLT** database, navigate to the **Security** section, and then select **Data Discovery & Classification**.

    ![Screenshot showing the Data Discovery & Classification](../images/upd-dp-300-module-05-lab-05.png)

1. On the **Data Discovery & Classification** screen, you can find the recommended classifications.

   > **Note:** The screenshot and information below, has been provided so that you can conceptualise the type of graphs and output that can be gleaned from a fully populated environment.

    ![Screenshot showing the Accept selected recommendations](../images/upd-dp-300-module-05-lab-08.png)

In this exercise, you've enhanced the security of an Azure SQL Database by enabling Microsoft Defender for SQL. You've also created classified columns based on Azure portal recommendations.
