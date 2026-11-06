# 2. Setup (about 30 minutes)

Names below are the defaults the scripts expect. If you change them, change them everywhere (see [05-customize.md](05-customize.md)).

## Step 1 — Workspace and lakehouses
1. Create a workspace, e.g. **CU Merger Demo**, and assign it to your Fabric capacity.
2. In the workspace create three **lakehouses** (leave *Lakehouse schemas* at its default):
   - `Contoso_CU`
   - `Fabrikam_CU`  *(skip this one if you'll use the optional SQL database source — Step 8)*
   - `Enterprise_Ref`

## Step 2 — Load the source data
1. **Workspace → Import → Notebook → From this computer** and select `fabric/notebooks/Load_Source_Data.ipynb`.
2. Open it and set the parameters in the first code cell:
   - `DATA_SOURCE = "github"` and `GITHUB_RAW_BASE` = the raw URL of this repo's `data` folder, e.g. `https://raw.githubusercontent.com/<org>/<repo>/main/data`
     **or** `DATA_SOURCE = "files"` and upload the repo's `data` folder to **Enterprise_Ref → Files → data** (keep the sub-folders `contoso_cu`, `fabrikam_cu`, `enterprise_ref`).
   - `TENANT_DOMAIN` = your tenant domain, e.g. `contoso.onmicrosoft.com` (fills in the persona UPNs for row-level security).
3. **Run all.** The last cell shows row counts for 13 tables.
4. Open each lakehouse's **SQL analytics endpoint** once. If a table is missing, select **Refresh** — metadata sync can take a minute.

## Step 3 — Combined warehouse
1. Create a **warehouse** named `Combined_Data` in the **same workspace**.
2. **New SQL query**, then paste and run, in order:
   1. `fabric/warehouse/01_create_objects.sql`
   2. `fabric/warehouse/02_usp_Load_Combined.sql`
   3. `EXEC combined.usp_Load_Combined;` — returns rows loaded per table (about 23 branches, 506 KPI rows, 3,036 driver rows)
3. Run `fabric/warehouse/03_validate.sql` and confirm:
   - two legacy organizations in query 1,
   - branch-code collisions in query 2,
   - the 60-day vs 30-day comparison in query 3,
   - Worcester deteriorating in query 4,
   - persona UPNs with **your** tenant domain in query 6.
4. Copy the warehouse's **SQL connection string**: warehouse **Settings → SQL endpoint** (or the *Copy SQL connection string* option).

## Step 4 — Semantic model and report
1. Open `powerbi/Monthly Member Intelligence Hub.pbip` in Power BI Desktop.
2. **Transform data → Edit parameters**:
   - `SqlEndpoint` = the SQL connection string from Step 3 (looks like `xxxx.datawarehouse.fabric.microsoft.com`)
   - `WarehouseName` = `Combined_Data`
3. Apply changes. Sign in with your **organizational account** when prompted, then **Refresh**.
4. Check the report: the **Source Credit Union** slicer shows *Contoso CU* and *Fabrikam CU*.
5. **Publish** to the demo workspace.

## Step 5 — Security and access
1. In the workspace open the semantic model **Settings → Data source credentials** and sign in with **OAuth2** (organizational account).
2. Semantic model **⋯ → Security**: add `north_director`, `south_director`, `east_director`, `west_director`, `retail_exec` and `mgmt_analyst` to the **Security Scope** role. Role membership is not stored in the PBIP files, so repeat this in every workspace you deploy to.
3. Use **Test as role** (or *View as* a specific user) to check that `west_director` sees only West branches.
4. Give the directors and `retail_exec` **Viewer** access — workspace Viewer role or an org app. **Admin, Member and Contributor bypass row-level security.** Give `mgmt_analyst` Contributor if they'll build in Act 2.

## Step 6 — Make it demo-ready
- **Endorse** the semantic model (Promoted, or Certified if your tenant allows certification).
- Optional: schedule a model refresh after the warehouse load.
- Optional: in Power BI Desktop use **Prep data for AI** to add AI instructions such as *"Delinquency always means the certified 30+ days past due definition."*

## Step 7 — Optional: Fabric data agent
1. **New item → Data agent**, add the `Monthly Member Intelligence Hub` semantic model as the data source.
2. Agent instructions (paste):
   > You answer questions about branch performance for a credit union formed by the merger of Contoso CU and Fabrikam CU. Use only the certified measures. "Delinquency" always means the certified 30+ days past due rate. Regions are North, South, East and West. When asked about a branch, include its legacy organization. Say when a question is ambiguous instead of guessing the period or measure.
3. Example questions: *Which branches in my region have the highest delinquency rate this quarter?* · *How is delinquency defined?* · *Compare NPS for Contoso CU and Fabrikam CU over the last six months.*
4. **Publish.** The agent runs as the signed-in user, so row-level security applies.

## Step 8 — Optional: Fabrikam as a live SQL database
Shows a change in a "source system" flowing into the report with no pipeline.
1. Create a **SQL database** named `Fabrikam_CU` in the workspace (instead of the lakehouse).
2. Run `optional/sql-database/01_fabrikam_schema_and_seed.sql` in it.
3. Run the load notebook with `LOAD_FABRIKAM = False`.
4. The warehouse procedure works unchanged — it reads `[Fabrikam_CU].[dbo].[...]` through the database's SQL analytics endpoint. Verify with `03_validate.sql`.
5. During the demo use `optional/sql-database/02_live_change.sql`.

## Step 9 — Optional: Git and deployment pipeline (Act 2)
- **Git:** Workspace settings → Git integration → connect to your repo/branch. The notebook, warehouse (as a SQL project), semantic model and report are tracked; **lakehouse tables are not** — rerun the load notebook in each new workspace.
- **Deployment pipeline:** create Dev → Test → Prod. On the semantic model add a **parameter rule** so `SqlEndpoint` points at each stage's own warehouse. Re-add role members in each stage.
- Stage a small, visible change in Dev (for example a measure description) so **Compare** shows a real difference.

## Step 10 — Optional: governance notebook (Act 7)
`fabric/notebooks/optional/Fabric_Governance.ipynb` builds an item inventory, finds stale content and orphaned workspaces, and (manually, off by default) archives items or takes over ownership. It needs a **Fabric administrator** and, for stale scoring, an activity-events table collected separately. Sections 1 and 3 run on their own.
