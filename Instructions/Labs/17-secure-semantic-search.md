---
lab:
    title: 'Lab 17 – Case study: Secure a retail semantic-search workload on Azure SQL'
    module: Plan and secure Azure SQL for AI workloads
    description: "You'll work through a retail semantic-search case study to complete the five pre-production tasks a DBA owns for an AI-enabled database. By the end, you'll understand how to plan and secure Azure SQL for AI workloads."
    duration: 20  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: true # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2026-07-01' # Set to the future date when you expect an in-development lab to be released
---

# Case study: Secure a retail semantic-search workload on Azure SQL

**Estimated Time: 20 minutes**

A retail company wants to add semantic product search to its catalog. The catalog has 8 million SKUs. The initial embedding plan is 1,536 dimensions at single precision, refreshed nightly by an elastic job. Application traffic queries those embeddings during search.

Get these decisions wrong and the consequences are real: a leaked API key or an over-permissioned account is exactly the kind of gap that turns an AI feature into a data breach, and an undersized tier means an emergency migration weeks after go-live. This is why the pre-production design is a shared DBA responsibility with developers, not an afterthought.

In this exercise, you work through the five pre-production decisions every DBA owns for a workload like this. It's a design walkthrough, not a hands-on deployment: you reason about each decision and review the reference code it produces, but you don't run anything and don't need an Azure subscription. Adapt the placeholder names (`sql-retail-prod`, `<openai-resource>`, and so on) when you apply the pattern to a real workload.

The five decisions are: **size the vector workload**, **authenticate with a managed identity**, **define the external model objects**, **apply least-privilege roles**, and **enable audit and Defender**. Each section works through one.

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

Copilot returns the per-row size, the totals, and a tier recommendation with its reasoning. The result you get back will likely differ from the worked math below — that's the point. Most models size on the raw payload (about 48 GB) and miss SQL Server page allocation, so compare the two and notice whether Copilot accounted for the full per-page footprint. Treat the result as a starting point and validate the numbers against the worked math below.

> [!TIP]
> Always confirm Copilot's arithmetic and assumptions. Ask a follow-up such as "Show your calculation step by step" so you can check each figure, and "How would your tier recommendation change if the catalog grew to 50 million rows?" to pressure-test the design.

Understand the math to verify Copilot's estimate:

- **Total vector column:** A 1,536-dimension `float32` vector is about 6 KB of payload (1,536 × 4 bytes + an 8-byte header). But a SQL data page holds only 8,060 bytes, and a vector this large forces **one vector per page**, so each row consumes a full ~8 KB page. Real on-disk footprint ≈ 8,000,000 × 8 KB ≈ **64 GB**, not the 48 GB a raw payload calculation suggests.
- **Vector index overhead at roughly 50% of the column:** ≈ **32 GB**.
- **Total AI-related storage:** ≈ **96 GB**.
- **Recommended tier:** **General Purpose, 40-vCore** fits the storage footprint and the read-heavy query pattern for nightly refresh plus interactive search. Choose **Hyperscale** instead if the catalog is expected to grow past roughly 50 million SKUs within 12 months, because Hyperscale decouples storage growth from compute scaling.

> [!NOTE]
> Switching the column to half-precision (`float16`, 2 bytes per dimension) roughly halves both the column and index footprint and fits more vectors per page. It's worth considering for large catalogs because embeddings tolerate the small precision loss well.

The next decision is how the database proves its identity to Azure OpenAI without storing a secret.

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

> [!NOTE]
> `Cognitive Services OpenAI User` is the least-privilege role for an Azure SQL Database that only *calls* the embedding endpoint. If you instead run this pattern on SQL Server 2025 connected through Azure Arc, the documentation requires the broader `Cognitive Services OpenAI Contributor` role for the Arc-enabled managed identity.

With the identity in place, the next decision wires that identity into the database objects that actually call the model.

## Decision 3: Define the external model objects

Before any external model call works, the server needs two configuration options turned on: the external REST endpoint, and — because this design authenticates with a managed identity — server-scoped database credentials:

```sql
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;

EXECUTE sp_configure 'allow server scoped db credentials', 1;
RECONFIGURE WITH OVERRIDE;
```

Inside the database, three objects support the external model: the master key (if one doesn't already exist), the credential bound to the managed identity, and the external model object itself. The script that defines them looks like this:

```sql
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<strong-password>';

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

The model object exists, but right now any database user could call it. The next decision narrows that down to exactly the accounts that need it.

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

With permissions scoped, the final decision makes every external call observable so you can prove what happened and catch what shouldn't.

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

> [!NOTE]
> Recent Azure CLI versions express the Defender for SQL plan through Microsoft Defender for Cloud plan settings rather than a Standard/Free tier. Check `az security pricing` for your current CLI version, or enable the plan from the Defender for Cloud portal.

> [!TIP]
> When you apply this pattern for real, validate the end-to-end flow with a single embedding generation before declaring the security baseline complete. If `AI_GENERATE_EMBEDDINGS` returns successfully **and** the audit log captures the call from `embedding_refresh_svc`, the baseline works. If the audit row is missing, fix that before you let the nightly job run for real.

## Common mistakes to avoid

Each of these anti-patterns is something a real review would flag. Contrast the wrong approach with the design you just worked through:

| Anti-pattern (wrong) | What goes wrong | Do this instead (right) |
|---|---|---|
| Store the Azure OpenAI **API key in a connection string** or app config | The secret lives in source control, logs, and every developer's environment — one leak exposes the endpoint | Use a **system-assigned managed identity**; no secret exists to leak (Decision 2) |
| Grant the interactive **query user `EXECUTE` on the external model** | The search path can now trigger paid embedding calls and reach the external endpoint, widening the attack surface | Grant the query user only **`SELECT`** on the embeddings table; reserve model access for the refresh account (Decision 4) |
| **Skip the database master key** before creating the scoped credential | `CREATE DATABASE SCOPED CREDENTIAL` fails, or the credential can't be protected | Create the master key first, guarded by `IF NOT EXISTS` (Decision 3) |
| Forget to enable **`external rest endpoint enabled`** / `allow server scoped db credentials` | The external model call fails at runtime with a configuration error | Turn both options on with `sp_configure` before defining the model (Decision 3) |
| **Size only on raw payload** (1,536 × 4 bytes) and ignore page allocation | The database runs out of storage because each large vector consumes a full page | Size on real **per-page** footprint and add index overhead (Decision 1) |
| Ship without **auditing or Defender** | No record of who called the model and no threat alerts — a compliance and incident-response gap | Enable SQL Audit on the external model and Microsoft Defender for SQL (Decision 5) |

## Decision scorecard

Use this scorecard as a reusable summary of the design. For a real workload, swap in your own numbers and resource names.

| Decision | Recommended choice | Why |
|---|---|---|
| **Size the vector workload** | General Purpose, 40-vCore (~96 GB AI-related storage) | Fits the storage footprint and read-heavy nightly-refresh-plus-search pattern. Move to Hyperscale if the catalog grows past ~50 million SKUs within 12 months. |
| **Authenticate to Azure OpenAI** | System-assigned managed identity + `Cognitive Services OpenAI User` role | No secret to store, rotate, or leak; Azure Entra ID issues the credential and RBAC governs access. |
| **Define the external model** | Master key, database scoped credential, and external model object | Pins the database to one deployment and API version; callers reference a single model object. |
| **Scope permissions** | `embedding_refresh_svc` (refresh path) and `app_query_user` (read-only) | Least privilege — only the nightly job reaches the external endpoint; search reads stored vectors. |
| **Monitor operations** | SQL Audit on the external model + Microsoft Defender for SQL | Verifiable record of AI operations plus proactive threat alerts for compliance and incident response. |

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

General Purpose fits the current ~96 GB AI-related footprint and the read-heavy nightly-refresh-plus-search pattern. Hyperscale becomes the better choice when storage is expected to grow rapidly, because it lets storage scale independently of compute. Vector search alone doesn't require Hyperscale, and the design here stores embeddings rather than generating them on every query.

</details>
