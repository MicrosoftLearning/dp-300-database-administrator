# Create a CPU status alert for a SQL Server on Azure

**Estimated Time: 30 minutes**

You have been hired as a Senior Data Engineer to help automate day to day operations of database administration. This automation is to help ensure that the databases for AdventureWorks continue to operate at peak performance as well as provide methods for alerting based on certain criteria.

## Create an alert when a CPU exceeds an average of 80 percent

Once the environment is provisioned, a virtual machine (JumpVM) and lab guide will get loaded in your browser. Use this virtual machine throughout the workshop to perform the lab. 

1.Login to Azure Portal
In the JumpVM, click on the Azure portal shortcut of the Microsoft Edge browser which is created on the desktop.

  ![Picture 2](../images/azureportal-lab12.png)
  
2.On the Sign in to Microsoft Azure tab you will see the login screen, in that enter the following email/username, and click on Next.

3.If you see the pop-up Stay Signed in?, click No.


4.If you see the pop-up You have free Azure Advisor recommendations!, close the window to continue the lab.


5.If a Welcome to Microsoft Azure popup window appears, click **Maybe Later** to skip the tour.

1. In the search bar at the top of the Azure portal, type **SQL**, and select **SQL databases**. Select the **AdventureWorksLT** database name listed.

    ![Screenshot of selecting a SQL database](../images/dp300-lab12-img1.png)

1. On the main blade for the **AdventureWorksLT** database, navigate down to the monitoring section. Select **Alerts**.

    ![Screenshot of selecting Alerts on the SQL database Overview page](../images/dp300-lab12-img2.png)

1. Select **Create alert rule**.

    ![Screenshot of selecting New alert rule](../images/dp300-lab12-img3.png)

1. In the **Select a signal** slide out, select **CPU percentage**.

    ![Screenshot of selecting CPU percentage](../images/dp300-lab12-img4.png)

1. In the **Configure signal** slide out, select **Static** for the **Threshold** property. Then check that the **Operator** property is **Greater than**, the **Aggregation** type is **Average**. Then in **Threshold value** enter a value of **80**. Select **Done**.

    ![Screenshot of entering 80 and selecting Done](../images/dp300-lab12-img5.png)

1. Select the **Actions** tab.

    ![Screenshot of selecting the Select action group link](../images/dp300-lab12-img6.png)

1. In the **Actions** tab, select **Create action group**.

    ![Screenshot of selecting the Create action group](../images/dp300-lab12-img7.png)

1. On the **Action Group** screen, type **emailgroup** in the **Action group name** field, and then select **Next: Notifications**.

    ![Screenshot of entering emailgroup and selecting Next: Notifications](../images/dp300-lab12-img8.png)

1. On the **Notifications** tab, enter the following information:

    - **Notification type:** Email/SMS message/Push/Voice
        - **Note:** When you select this option, a Email/SMS message/Push/Voice flyout will appear. Check the Email property and type the Azure username you signed in with.
    - **Name:** DemoLab

    ![Screenshot of the Create action group page with information added](../images/dp300-lab12-img9.png)
    
1. On the **Basic** tab, enter Alert rule name as **eamilrule**.
    
    ![Screenshot of entering emailgroup and selecting Next: Notifications](../images/altertrulename-lab12.png)

1. Select **Review + create**, then select **Create**.

    ![Screenshot of the Create alert rule page selecting the Create alert rule](../images/dp300-lab12-img10.png)

    **Note:** Before you select **Create**, you can also select **Test action group (preview)** to test the Alert.

1. An email like this is sent to the email address that you entered, once the rule is created.

    ![Screenshot of the confirmation email](../images/dp300-lab12-img11.png)

    With the alert in place, if the CPU usage on average exceeds 80%, an email like this is sent.

    ![Screenshot of the warning email](../images/dp300-lab12-img13.png)

Alerts can send you an email or call a web hook when some metric (for example database size or CPU usage) reaches a threshold you define. You've just seen how you can easily configure alerts for Azure SQL Databases.
