---
lab:
    title: 'Convert an Oracle schema to Azure Database for PostgreSQL'
    module: Migrate Oracle workloads to Azure Database for PostgreSQL flexible server
    description: "You'll run an end-to-end Oracle-to-Azure Database for PostgreSQL schema conversion in your own environment — creating a migration project, running the conversion pipeline, interpreting the conversion report, resolving a mandatory review task with GitHub Copilot agent mode, and locating the generated deploy.sql. By the end, you'll understand how to run and validate an AI-assisted schema conversion."
    duration: 30  # duration in minutes
    level: 300 # 100 basic concepts, 200 foundations, 300 practical usage, 400 advanced scenarios, 500 expert design
    islab: true # if this is not a lab that should be listed in the catalog, set to false
    status: 'in-development' # in-development or released
    targetDate: '2099-01-01' # Set to the future date when you expect an in-development lab to be released
---

# Convert an Oracle schema to Azure Database for PostgreSQL

**Estimated Time: 30 minutes**

Throughout this module, you followed Contoso Retail's move from Oracle to Azure Database for PostgreSQL flexible server. In this exercise, you run the same end-to-end workflow yourself: you create a migration project, run the conversion pipeline, interpret the conversion report, resolve a Mandatory review task with GitHub Copilot agent mode, and locate the generated `deploy.sql`.

You run this exercise against your own environment rather than a prebuilt sandbox, because the tool reads schema metadata directly from a live Oracle data dictionary and validates the converted objects against a real Azure Database for PostgreSQL flexible server.

> [!NOTE]
> This exercise uses the environment you prepared in the previous units. Before you start, confirm that you have:
>
> - The **PostgreSQL** extension for Visual Studio Code installed and signed in.
> - A source Oracle database you can reach, with a migration user that holds `SELECT_CATALOG_ROLE` and read access to `SYS.ARGUMENT$`.
> - An Azure Database for PostgreSQL flexible server to use as the scratch database, with the extensions your schema needs allowlisted and installed.
> - A Microsoft Foundry deployment of `gpt-5.2` with enough tokens-per-minute (TPM) capacity for your schema.
>
> If you haven't set up an environment yet, complete the steps in the earlier units first.

## Create the migration project

The Migration Wizard collects everything the conversion needs across four steps: a project name, the Oracle source, the scratch database, and the Microsoft Foundry model.

1. In the PostgreSQL extension, open the **Migrations (preview)** view and select **Create Migration Project**.
1. On **Project Setup**, enter a project name, then select **Next**.
1. On **Connect to Oracle**, enter your Oracle host, port, and service name, along with the migration user credentials. Select **Load Schemas**, choose the schema you want to convert, then select **Next**.
1. On the scratch database step, select your Azure Database for PostgreSQL connection and target database, select **Verify Extensions**, then select **Next**.
1. On the Microsoft Foundry step, enter your endpoint and the deployment name for `gpt-5.2`, and select **Microsoft Entra ID** for authentication.
1. Select **Test Connection**. After the check succeeds, select **Create Migration Project**.

The tool selects thin or thick client mode automatically based on your Oracle network configuration, so the connection succeeds without extra steps unless native network encryption requires the Oracle Instant Client.

## Run the schema conversion

The wizard opens the main conversion panel with a **Schema Migration** card that tracks the run.

1. On the **Schema Migration** card, select **Migrate** to start the conversion.
1. Watch the pipeline move through its stages: *Extracting* reads the Oracle data dictionary, and *Converting* transforms the batched DDL with the Microsoft Foundry model and validates it in scratch schemas.
1. Wait for the **Migration Complete** message. The tool creates and drops scratch schemas named with the `_mig_scratch_` prefix automatically during validation.
1. Select **View Migration Report** to open the generated reports.

The run takes anywhere from a few minutes to over an hour, depending on your schema size, its PL/SQL complexity, and your Microsoft Foundry TPM capacity. The tool processes objects in dependency-aware batches, so types convert before the tables that use them, and functions convert before the triggers that call them.

## Interpret the conversion report

Open `reports/customer_summary.md` first. It gives you the overall readiness decision before you look at any individual object.

The summary reports the overall conversion status, the success percentage, and the count of objects flagged for review by criticality: Mandatory, Recommended, and Optional. Note your success percentage and your number of Mandatory tasks. The **Next actions** section directs you to resolve the Mandatory tasks before deployment.

> [!NOTE]
> The success percentage reflects automated conversion coverage, not deployment readiness. Objects that convert automatically still need your validation, and the review tasks represent the work remaining before the schema is production-ready.

For a per-object breakdown with DDL snippets, open `reports/technical_conversion_report.md`. Treat `reports/review_tasks.md` as an offline reference only, and resolve tasks from the **Schema Review** pane instead.

## Triage the review tasks

Open the **Schema Review** pane to work through the flagged objects. Start in the **Grouped** view to see the tasks organized by behavioral category, such as Numeric Semantics and Empty String / NULL, then switch to the **Tasks** view to filter and resolve them one by one.

1. In the **Tasks** view, set the **Status** filter to **Pending** and the **Priority** filter to **Mandatory**.
1. Select a Mandatory task to open its details, including the source DDL, the generated PostgreSQL DDL, and the task evidence.

A task is Mandatory when the object isn't ready for production until you address it. A common example is an Oracle function that returns an unqualified `NUMBER`, which maps ambiguously to PostgreSQL `numeric`, `integer`, or `bigint`. When the value feeds a calculation, an integer mapping would truncate fractional results, so you choose the correct type before deployment.

## Resolve a Mandatory task with GitHub Copilot agent mode

Resolve the task with guided help, then validate the result yourself.

1. With the task open, select **Run Task** to open GitHub Copilot agent mode with the source DDL, the generated PostgreSQL DDL, and the task evidence loaded as context.
1. Review the proposed fix. Copilot suggests a change based on the evidence, such as mapping an ambiguous `NUMBER` to `numeric` with an explicit precision and scale.
1. Apply the fix to the generated `.sql` file under `postgres_ddl/<schema>/<object_type>/`.
1. Connect to the scratch database and run the updated `.sql` file to confirm it compiles.
1. Select **Resolve** to mark the task complete, then move to the next Mandatory task.

> [!IMPORTANT]
> The same AI that converts a schema object can also assist with reviewing it, and AI systems can occasionally confirm their own mistakes. Independently validate every AI-assisted resolution before you deploy. Run the converted object with representative test data and confirm the result matches the Oracle source.

Resolving a task updates the `.sql` file in `postgres_ddl/`, but the change isn't applied to the scratch database automatically. Run the updated file yourself to validate the fix before you mark the task resolved.

## Locate the deployment output

Each run writes its output to a session folder under `artifacts/oracle/_migration/convert/sessions/<session-id>/`. Two locations matter most for deployment:

- `postgres_ddl/<schema>/<object_type>/` contains one `.sql` file per converted object, grouped by type. These are the files you edit and revalidate when you resolve tasks.
- `deploy.sql` is the consolidated script that creates the target schema and applies every object in dependency order. This is the file you run against the production target after independent validation.

> [!IMPORTANT]
> A fix you run directly against the scratch database doesn't propagate to `deploy.sql`. After you address the root cause of a task, rerun the conversion so the tool regenerates `deploy.sql` with the improved output, then compare the new report against the previous one to confirm the change had the intended effect.

With `deploy.sql` generated and your Mandatory tasks resolved, the converted schema is ready for the independent validation and production deployment that follow the conversion.

## What you accomplished

You ran an end-to-end schema conversion — creating the migration project, running the pipeline, interpreting the customer summary, resolving a Mandatory review task with GitHub Copilot agent mode, and locating `deploy.sql`. You also confirmed the two habits that keep an AI-assisted migration trustworthy: validate every resolution independently, and rerun the conversion instead of hand-patching the scratch database.
