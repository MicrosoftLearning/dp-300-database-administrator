---
lab:
    title: 'Lab 17 – Design a machine learning solution case study'
    module: Design a machine learning training solution
    description: "You'll work through a Contoso Retail case study to design a machine learning training solution for a product recommendation system, making decisions about data strategy, service selection, compute resources, and deployment. By the end, you'll understand how to make informed machine learning design choices that balance cost, performance, complexity, and team skills."
    duration: 15  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: no # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2099-01-01' # Set to the future date when you expect an in-development lab to be released
---

# Design a machine learning solution - Case study

**Estimated Time: 15 minutes**

> [!NOTE]
> To complete this exercise, read the case study carefully. Apply the design principles you've learned throughout this module to make informed decisions. At the end, you'll test your understanding by answering knowledge check questions.

Welcome to Contoso Retail! You've been hired as the **lead data scientist** to help us design a machine learning training solution.

## Understand the problem

At Contoso Retail, we operate both physical stores and an e-commerce platform. We want to build a **product recommendation system** that suggests items to customers based on their browsing and purchase history.

Our goal is to increase customer engagement and sales by showing personalized product recommendations:

- In our **mobile app**, customers should see recommendations immediately when they view a product.
- For our **weekly email campaign**, we want to include the top 5 recommended products for each of our 2 million customers.

Our data engineering team has been collecting customer interaction data for the past two years, including:

- Browsing history (products viewed, time spent)
- Purchase history (items bought, purchase dates, amounts)
- Customer demographics (age, location, preferences)
- Product catalog (categories, prices, descriptions, images)

The data is currently stored in multiple systems:

- Transactional data in Azure SQL Database (updated in real time)
- Clickstream data from our website stored as JSON files in Azure Blob Storage (logged every hour)
- Product images stored in Azure Blob Storage
- Customer profiles in our CRM system (Dynamics 365)

We need your help deciding **how to design the machine learning training solution** to build this recommendation system.

## Consider the requirements

As you design the solution, think about these key areas.

### Data ingestion and preparation

- **Consider the data sources**: We have data in Azure SQL Database, Blob Storage (JSON files), Blob Storage (images), and Dynamics 365. How should we consolidate this data?
- **Consider the data format**: The data is in different formats (structured, semi-structured, and unstructured). What format should we use for training?
- **Consider the data pipeline**: Should we build a data ingestion pipeline? If so, how often should it run?

### Machine learning task and service

- **Consider the machine learning task**: What type of machine learning task is this? Classification, regression, recommendation, or something else?
- **Consider the service**: Should we use Azure Machine Learning, Azure Databricks, Microsoft Fabric, or Microsoft Foundry? What factors influence this choice?
- **Consider existing skills**: Our team has strong Python experience but limited Spark knowledge. How does this affect our choice?

### Compute resources

- **Consider the data size**: We have 2 million customers and millions of product interactions. What compute type is appropriate?
- **Consider the model complexity**: Recommendation systems can be simple (collaborative filtering) or complex (deep learning). How does this affect compute needs?
- **Consider cost**: We have a limited budget for this initial phase. Should we start with CPU or GPU? General purpose or memory optimized?

### Deployment requirements

- **Consider the deployment types**: We need both real-time recommendations (mobile app) and batch predictions (email campaign). How should we handle these different needs?
- **Consider the frequency**: Mobile app recommendations need to be instant. Email campaigns are sent weekly. Should we use different endpoints?
- **Consider the scale**: Our app has 100,000 active daily users. Our email campaign targets 2 million customers. How does scale affect our deployment decisions?

## Your task

Based on these requirements, you need to make design decisions about:

1. **Data strategy**: How will you ingest, transform, and store the data for training?
2. **Service selection**: Which Azure service(s) will you use for training, and why?
3. **Compute strategy**: What compute resources will you provision for training?
4. **Deployment approach**: How will you handle both real-time and batch prediction requirements?

Think through each decision carefully, considering trade-offs between cost, performance, complexity, and team capabilities. The knowledge check questions test your ability to make informed design choices based on this scenario.

## Knowledge check

Answer the following questions based on the Contoso Retail case study. Select an answer for each question, then expand **Show answer** to check your reasoning.

**1. Based on the Contoso Retail case study, what data ingestion strategy would be most appropriate for consolidating data from Azure SQL Database, Blob Storage (JSON), and Dynamics 365?**

- Manually export data from each source and combine in Excel before training.
- Create an ETL pipeline using Azure Synapse Analytics to extract, transform, and load data into a unified storage layer like Azure Data Lake Storage.
- Keep data in separate sources and connect directly to each during model training.

<details>
<summary>Show answer</summary>

**Create an ETL pipeline using Azure Synapse Analytics to extract, transform, and load data into a unified storage layer like Azure Data Lake Storage.**

The data is spread across structured, semi-structured, and unstructured sources that update on different schedules. An automated ETL pipeline consolidates these sources into a single, training-ready layer. Manual export doesn't scale to millions of interactions, and connecting directly to each source during training adds latency and complexity.

</details>

**2. For the Contoso Retail recommendation system, which Azure service would be most suitable given the team's Python experience and the need to train on large-scale customer interaction data?**

- Microsoft Foundry, because it provides pre-built recommendation models.
- Azure Machine Learning, because it supports the Python SDK, handles large datasets, and provides comprehensive tools for custom model training.
- Azure Databricks, because it's required for any large-scale machine learning.

<details>
<summary>Show answer</summary>

**Azure Machine Learning, because it supports the Python SDK, handles large datasets, and provides comprehensive tools for custom model training.**

The team has strong Python skills but limited Spark knowledge, which makes Azure Machine Learning a better fit than Azure Databricks. Azure Databricks is Spark-based and isn't required for all large-scale machine learning. Microsoft Foundry focuses on generative AI rather than custom recommendation training.

</details>

**3. Considering Contoso Retail needs both real-time recommendations (mobile app) and batch predictions (weekly email campaign), what deployment strategy should they implement?**

- Deploy two separate models: a real-time endpoint for the mobile app and a batch endpoint for the email campaign.
- Deploy only a real-time endpoint and call it 2 million times for the email campaign.
- Deploy only a batch endpoint and accept 5-10 minute delays for mobile app recommendations.

<details>
<summary>Show answer</summary>

**Deploy two separate models: a real-time endpoint for the mobile app and a batch endpoint for the email campaign.**

The two scenarios have different latency and throughput needs. A real-time (online) endpoint delivers instant recommendations in the mobile app, while a batch endpoint efficiently scores 2 million customers for the weekly email. Forcing one endpoint type to handle both leads to either excessive cost or unacceptable latency.

</details>

**4. What compute resource would be most appropriate for training the initial Contoso Retail recommendation model, given the 2 million customer dataset and budget constraints?**

- Start with CPU general-purpose compute, monitor performance, and scale to memory-optimized or GPU if needed.
- Immediately provision the largest GPU memory-optimized compute to ensure fast training.
- Use only local development machines to minimize Azure costs.

<details>
<summary>Show answer</summary>

**Start with CPU general-purpose compute, monitor performance, and scale to memory-optimized or GPU if needed.**

With a limited initial budget, start with cost-effective CPU general-purpose compute and scale up only when the model complexity or training time justifies it. Provisioning the largest GPU upfront wastes budget, and local machines can't handle the scale of 2 million customers and millions of interactions.

</details>
