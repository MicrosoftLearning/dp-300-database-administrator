---
lab:
    title: 'Lab 17 – Case study: Secure a retail semantic-search workload on Azure SQL'
    module: Plan and Secure Azure SQL for AI Workloads
    description: "You'll work through a retail semantic-search case study to complete the five pre-production tasks a DBA owns for an AI-enabled database. By the end, you'll understand how to plan and secure Azure SQL for AI workloads."
    duration: 20  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: true # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2026-07-01' # Set to the future date when you expect an in-development lab to be released
---

# Plan and secure Azure SQL for AI workloads

**Estimated Time: 20 minutes**

A retail company wants to add semantic product search to its catalog. The catalog has 8 million SKUs. The initial embedding plan is 1,536 dimensions at single precision, refreshed nightly by an elastic job. Application traffic queries those embeddings during search. 

In this exercise, you work through the five pre-production decisions every DBA owns for a workload like this: a sizing worksheet, managed identity setup, external model creation, role assignment, and audit configuration. This is a design walkthrough, not a hands-on deployment — you reason about each decision and review the code it produces, but you don't need an Azure subscription or a running database to complete it.

> [!NOTE]
> The Transact-SQL and Azure CLI snippets in this exercise are **reference examples** that show what each decision looks like in practice. You don't run them. Read each one to confirm it matches the decision you'd make, then adapt the placeholder names (`sql-retail-prod`, `<openai-resource>`, and so on) when you apply the pattern to a real workload.

| Decision | Why it matters |
|---|---|
| **Size the vector workload** | Vector columns and their indexes consume far more storage than typical relational data. Estimating the footprint up front lets you pick the right service tier and avoid costly resizing or throttling after go-live. |
| **Enable system-assigned managed identity** | Authenticating with a managed identity means no API key is stored, rotated, or leaked. Azure Entra ID issues the credential and RBAC governs access, removing the most common secret-handling risk. |
| **Create the external model** | The external model object pins the database to a specific Azure OpenAI deployment and API version. Callers reference one model object, so you update the endpoint in a single place instead of in every query. |
| **Apply least-privilege roles** | Granting each principal only what it needs keeps the interactive query path away from the external endpoint. This blocks unauthorized access routes and caps unexpected cost from runaway embedding calls. |
| **Enable audit and Defender** | Auditing external model calls and turning on Microsoft Defender for SQL give you a verifiable record of AI operations and proactive threat alerts, which are essential for compliance and incident response. |

## Decision 1: Size the vector workload

Fill in this worksheet for the scenario:

| Input | Value |
|---|---|
| Rows | 8,000,000 |
| Dimensions | 1,536 |
| Precision | float32 |
| Per-row vector size | 6 KB |
| Total vector column storage | **?** |
| Estimated vector index overhead (~50%) | **?** |
| Total AI-related storage | **?** |
| Recommended tier | **?** |

### Ask Copilot to estimate the sizing

Rather than work the math by hand, you can ask GitHub Copilot in SSMS (or Copilot in the Azure portal) to do it. In the Copilot chat, paste a prompt that includes the known inputs:

> "I'm planning a vector column in Azure SQL. I have 8,000,000 rows, each storing a 1,536-dimension embedding at float32 (4 bytes per dimension). Estimate the per-row vector size, the total vector column storage, vector index overhead at about 50%, and the total AI-related storage. Then recommend an Azure SQL service tier for a read-heavy nightly-refresh-plus-search workload."

Copilot returns the per-row size, the totals, and a tier recommendation with its reasoning. Treat the result as a starting point and validate the numbers against the worked math below.

> [!TIP]
> Always confirm Copilot's arithmetic and assumptions. Ask a follow-up such as "Show your calculation step by step" so you can check each figure, and "How would your tier recommendation change if the catalog grew to 50 million rows?" to pressure-test the design.

Work the math to verify Copilot's estimate:

- **Total vector column:** 8,000,000 × 6 KB ≈ **48 GB**.
- **Vector index overhead at roughly 50% of the column:** ≈ **24 GB**.
- **Total AI-related storage:** ≈ **72 GB**.
- **Recommended tier:** **General Purpose, 40-vCore** fits the storage footprint and the read-heavy query pattern for nightly refresh plus interactive search. Choose **Hyperscale** instead if the catalog is expected to grow past roughly 50 million SKUs within 12 months, because Hyperscale decouples storage growth from compute scaling.

## Decision 2: Authenticate with a managed identity

The logical server needs an identity Azure OpenAI accepts. The design turns on the system-assigned managed identity and grants it the right RBAC role on the Azure OpenAI resource. The configuration looks like this:

```bash
az sql server update \
  --name sql-retail-prod \
  --resource-group rg-retail \
  --identity-type SystemAssigned
```

```bash
SQL_MI_ID=$(az sql server show \
  --name sql-retail-prod \
  --resource-group rg-retail \
  --query identity.principalId -o tsv)

az role assignment create \
  --assignee $SQL_MI_ID \
  --role "Cognitive Services OpenAI User" \
  --scope <azure-openai-resource-id>
```

With this configuration, no secret has been created and no API key exists. The server identity is the entire authentication path to Azure OpenAI.

## Decision 3: Define the external model objects

Inside the database, three objects support the external model: the master key (if one doesn't already exist), the credential bound to the managed identity, and the external model object itself. The script that defines them looks like this:

```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<strong-password>';

-- The credential name must be the protocol + FQDN of the endpoint the model calls.
CREATE DATABASE SCOPED CREDENTIAL [https://<openai-resource>.openai.azure.com]
WITH IDENTITY = 'Managed Identity',
     SECRET = '{"resourceid": "https://cognitiveservices.azure.com"}';

CREATE EXTERNAL MODEL Ada2Embeddings
WITH (
    LOCATION = 'https://<openai-resource>.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'text-embedding-ada-002',
    CREDENTIAL = [https://<openai-resource>.openai.azure.com]
);
```

The `LOCATION` value pins the model to a specific deployment and API version. If you change the deployment, you update the model object, not every caller's code.

## Decision 4: Apply least-privilege role grants

The role design calls for two principals, each granted exactly what it needs and no more. The grants look like this:

```sql
-- Refresh service account
CREATE USER [embedding_refresh_svc] WITHOUT LOGIN;
GRANT EXECUTE ON EXTERNAL MODEL::Ada2Embeddings TO [embedding_refresh_svc];
GRANT REFERENCES ON DATABASE SCOPED CREDENTIAL::[https://<openai-resource>.openai.azure.com] TO [embedding_refresh_svc];
GRANT INSERT, UPDATE ON dbo.ProductEmbeddings TO [embedding_refresh_svc];

-- Query user: NO external endpoint permissions
CREATE USER [app_query_user] WITHOUT LOGIN;
GRANT SELECT ON dbo.ProductEmbeddings TO [app_query_user];
```

The query user has no path to Azure OpenAI. Search queries read the stored vectors directly. Only the nightly refresh job touches the external endpoint.

## Decision 5: Enable audit and Defender

The final decision turns on SQL Audit for the external model and enables Microsoft Defender for SQL on the server:

```sql
CREATE SERVER AUDIT [AuditAIOperations]
TO URL (PATH = 'https://<staudit>.blob.core.windows.net/<container>');

ALTER SERVER AUDIT [AuditAIOperations] WITH (STATE = ON);

CREATE DATABASE AUDIT SPECIFICATION [AIDatabaseAudit]
FOR SERVER AUDIT [AuditAIOperations]
ADD (EXECUTE ON EXTERNAL MODEL::[Ada2Embeddings] BY [public])
WITH (STATE = ON);
```

```bash
az security pricing create --name SqlServers --tier Standard
```

> [!TIP]
> When you apply this pattern for real, validate the end-to-end flow with a single embedding generation before declaring the security baseline complete. If `AI_GENERATE_EMBEDDINGS` returns successfully **and** the audit log captures the call from `embedding_refresh_svc`, the baseline works. If the audit row is missing, fix that before you let the nightly job run for real.

You've now worked through all five pre-production decisions — sizing the workload, configuring the identity path, defining the external model, scoping permissions, and turning on auditing — that every DBA owns for an AI-enabled database.

## Validate the design decisions

Answer the following questions based on the retail semantic-search case study. Select an answer for each question, then expand **Show answer** to check your reasoning.

**1. The logical server authenticates to Azure OpenAI using a system-assigned managed identity. Why is this preferred over storing an API key in the database?**

- **A.** Managed identities make the embedding queries run faster.
- **B.** There's no secret to store, rotate, or leak — Azure Entra ID issues and rotates the credential automatically, and access is governed by RBAC.
- **C.** API keys aren't supported by Azure SQL Database.

<details markdown="1">
<summary>Show answer</summary>

✅ **Correct answer: B.** There's no secret to store, rotate, or leak — Azure Entra ID issues and rotates the credential automatically, and access is governed by RBAC.

With a managed identity, no API key exists anywhere in the database or application. The server identity is the entire authentication path, so there's nothing to leak in source control or a connection string, and you grant or revoke access by changing an RBAC role assignment. Managed identities don't change query performance, and API keys are technically supported — they're just a weaker security posture.

</details>

**2. In the role design, the `app_query_user` that serves interactive search is granted `SELECT` on `dbo.ProductEmbeddings` but no permission on the external model or credential. Why?**

- **A.** Search queries read the stored vectors directly, so the query user never needs to call the external endpoint — only the nightly refresh job does.
- **B.** Granting `SELECT` automatically includes external model access.
- **C.** The query user can't be granted external model permissions in Azure SQL.

<details markdown="1">
<summary>Show answer</summary>

✅ **Correct answer: A.** Search queries read the stored vectors directly, so the query user never needs to call the external endpoint — only the nightly refresh job does.

This is least privilege in action. Embeddings are generated once per night by `embedding_refresh_svc` and stored in the table. Interactive search compares against those stored vectors with a simple `SELECT`, so the query user has no path to Azure OpenAI. Limiting external-endpoint permission to the single refresh account shrinks the attack surface and the potential cost exposure.

</details>

**3. The database scoped credential is named `[https://<openai-resource>.openai.azure.com]`. What rule does this naming follow?**

- **A.** The name can be any descriptive string the DBA chooses.
- **B.** The name must be the protocol plus the fully qualified domain name (FQDN) of the endpoint the model calls.
- **C.** The name must match the Azure OpenAI deployment name.

<details markdown="1">
<summary>Show answer</summary>

✅ **Correct answer: B.** The name must be the protocol plus the fully qualified domain name (FQDN) of the endpoint the model calls.

Azure SQL matches the credential to an outbound call by URL, so the credential name has to be the protocol and FQDN of the target endpoint (for example, `https://<openai-resource>.openai.azure.com`). The specific deployment and API version are pinned in the external model's `LOCATION`, not in the credential name.

</details>

**4. The catalog is 8 million SKUs today, sized comfortably on a General Purpose 40-vCore tier. Under what condition does the case study recommend Hyperscale instead?**

- **A.** Whenever the database uses vector search at all.
- **B.** Only if the workload needs real-time embedding generation on every query.
- **C.** If the catalog is expected to grow past roughly 50 million SKUs within 12 months, because Hyperscale decouples storage growth from compute scaling.

<details markdown="1">
<summary>Show answer</summary>

✅ **Correct answer: C.** If the catalog is expected to grow past roughly 50 million SKUs within 12 months, because Hyperscale decouples storage growth from compute scaling.

General Purpose fits the current ~72 GB AI-related footprint and the read-heavy nightly-refresh-plus-search pattern. Hyperscale becomes the better choice when storage is expected to grow rapidly, because it lets storage scale independently of compute. Vector search alone doesn't require Hyperscale, and the design here stores embeddings rather than generating them on every query.

</details>
