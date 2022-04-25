---
lab:
    title: 'Lab 11 – Create a CPU status alert for a SQL Server'
    module: 'Automate database tasks for Azure SQL'
---

# Create a CPU status alert for a SQL Server on Azure

**Estimated Time: 30 minutes**

You have been hired as a Senior Data Engineer to help automate day to day operations of database administration. This automation is to help ensure that the databases for AdventureWorks continue to operate at peak performance as well as provide methods for alerting based on certain criteria.

## Create an alert when a CPU exceeds an average of 80 percent

1. In the search bar at the top of the Azure portal, type **SQL**, and select **SQL databases**. Select the **AdventureWorksLT** database name listed.

    ![Screenshot of selecting a SQL database](../images/dp-300-module-12-lab-01.png)

1. On the main blade for the **AdventureWorksLT** database, navigate down to the monitoring section. Select **Alerts**.

    ![Screenshot of selecting Alerts on the SQL database Overview page](../images/dp-300-module-12-lab-02.png)

1. Select **Create alert rule**.

    ![Screenshot of selecting New alert rule](../images/dp-300-module-12-lab-03.png)

1. In the **Select a signal** slide out, select **CPU percentage**.

    ![Screenshot of selecting CPU percentage](../images/dp-300-module-12-lab-04.png)

1. In the **Configure signal** slide out, select **Static** for the **Threshold** property. Then check that the **Operator** property is **Greater than**, the **Aggregation** type is **Average**. Then in **Threshold value** enter a value of **80**. Select **Done**.

    ![Screenshot of entering 80 and selecting Done](../images/dp-300-module-12-lab-05.png)

1. Select the **Actions** tab, and then **Select action group** link.

    ![Screenshot of selecting the Select action group link](../images/dp-300-module-12-lab-06.png)

1. In the fly out for Action Group, select **Create action group**.

    ![Screenshot of selecting the Create action group](../images/dp-300-module-12-lab-07.png)

    On the **Action Group** screen, type **emailgroup** in the **Action group name** field, and then select **Next: Notifications**.

    ![Screenshot of entering emailgroup and selecting Next: Notifications](../images/dp-300-module-12-lab-08.png)

1. On the **Notifications** tab, enter the following information:

    - **Notification type:** Email/SMS message/Push/Voice
        - **Note:** When you select this option, a Email/SMS message/Push/Voice flyout will appear. Check the Email property and type the Azure username you signed in with.
    - **Name:** DemoLab

    ![Screenshot of the Create action group page with information added](../images/dp-300-module-12-lab-09.png)

1. Select **Review + create**, then select **Create**.

    ![Screenshot of the Create alert rule page selecting the Create alert rule](../images/dp-300-module-12-lab-10.png)

    **Note:** Before you select **Create**, you can also select **Test action group (preview)** to test the Alert.

1. An email like this is sent to the email address that you entered, once the rule is created.

    ![Screenshot of the confirmation email](../images/dp-300-module-12-lab-11.png)

    With the alert in place, if the CPU usage on average exceeds 80%, an email like this is sent.

    ![Screenshot of the warning email](../images/dp-300-module-12-lab-12.png)

Alerts can send you an email or call a web hook when some metric (for example database size or CPU usage) reaches a threshold you define. You've just seen how you can easily configure Alerts for Azure SQL Databases.
