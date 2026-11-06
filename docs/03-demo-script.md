# 3. Demo script — "One organization, one version of the truth"

**Length:** about 90 minutes in full; Acts 1–5 alone run 45–60 minutes.
**North Star:** one governed source of truth, with trusted KPIs that mean the same thing across the merged organization, that any employee can question in natural language, with governance that fits a regulated institution.

## Before you start
- One browser profile per persona, already signed in: `mgmt_analyst`, `west_director`, `east_director`, `retail_exec`, admin.
- Warehouse loaded (`EXEC combined.usp_Load_Combined;`) and semantic model refreshed.
- Directors and `retail_exec` are **Viewers** and members of the **Security Scope** role.
- Rehearse the exact Copilot prompts — wording of AI answers varies between runs. Record a backup video of each act.
- Optional for Act 7: one deliberately slow visual, and a staged refresh failure.

## Run of show

| Time | Act | Persona | Proves |
|---|---|---|---|
| 0:00 | Welcome | — | |
| 0:05 | 1. The problem | narrated | Metric standardization across legacy organizations |
| 0:10 | 2. The foundation | `mgmt_analyst` | Harmonized, certified data; lineage; version-controlled change |
| 0:30 | 3. Ask, don't build | `west_director`, `east_director` | Natural-language Q&A, grounded answers, row-level security |
| 0:50 | 4. Spot it, explain it, review it | `retail_exec` | Anomaly, drivers, AI summary with human review |
| 1:00 | 5. It rolls up, trusted | `retail_exec` | Executive scorecard on certified KPIs |
| 1:15 | 6. Prove it's safe | admin | AI controls, auditing |
| 1:25 | 7. Run it at scale | admin | Performance, refresh and capacity diagnostics, inventory |

---

## Act 1 — The problem (5 min, narrated)
**Setup:** one slide with the two legacy definitions side by side. Use query 3 in `03_validate.sql` for the numbers.

| | Contoso CU | Fabrikam CU (legacy) |
|---|---|---|
| Delinquency definition | 30+ days past due | 60+ days past due |
| Reported delinquency | ~1.1% | ~0.5% |

**Say:** "Contoso and Fabrikam are one organization now, but the data still speaks two languages. The same risk metric means one thing on one side and something else on the other — Fabrikam's number looks half as risky purely because of the definition. For a regulated institution that's a board-reporting risk."
**Handoff:** "Let's start where trust starts: the data foundation."

## Act 2 — The foundation (20 min, `mgmt_analyst`)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | Open the `Contoso_CU` and `Fabrikam_CU` sources; preview `dim_branch` and `branches` | Two systems, two schemas: different names, region codes, fractions vs percentages |
| 2 | Open `Combined_Data` → `combined.usp_Load_Combined` | The merger rules in plain T-SQL: merged branch key, region mapping, unit conversion, certified 30-day delinquency |
| 3 | Run query 2 of `03_validate.sql` | Both organizations have a `BR001` — why a merged key matters |
| 4 | Run `SELECT SourceCU, COUNT(*) FROM combined.fact_monthly_kpi GROUP BY SourceCU` | One combined data set, labeled by legacy organization |
| 5 | Open the semantic model; show the measure descriptions | One documented definition for every KPI |
| 6 | Show the Promoted/Certified endorsement | Certified once, used everywhere |
| 7 | *Optional:* deployment pipeline → **Compare** Dev to Test → deploy with a note → history | Controlled promotion with an audit trail |
| 8 | *Optional:* the Git repo — TMDL commit history for the model | Version-controlled, readable definitions |
| 9 | **Lineage view**, then **Impact analysis** on the semantic model | Source → definition → report, and who a change would affect |

**Say:** "Your source systems stay where they are. In production Fabric mirrors them — Snowflake, Azure SQL, Oracle — without building ETL. Here we define delinquency once, certify it, and it means the same thing for both legacy organizations."
**Watch-outs:** be clear that the lakehouses stand in for mirrored sources. If asked about copies: mirroring is managed replication, the source stays the system of record.
**Optional live moment:** with the SQL database source, run `02_live_change.sql`, reload, refresh, and show the change arrive.

## Act 3 — Ask, don't build (20 min, `west_director` then `east_director`)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | Open the report, open **Copilot**; ask *"Which branches in my region have the highest delinquency rate this quarter?"* | Only West branches — and from **both** legacy organizations (Denver Tech Center from Fabrikam leads) |
| 2 | Expand how Copilot got the answer | Grounded in the certified measure |
| 3 | Ask *"How is delinquency rate defined?"* | The governed description from the model |
| 4 | Ask *"Show me East region delinquency"* | No East data — row-level security enforced |
| 5 | Ask *"How are loans doing?"* | Copilot states its assumption or asks which measure and period |
| 6 | Switch to `east_director`; ask question 1 again | Same certified measure, East-only answer (Fabrikam's Worcester stands out) |

**Say:** "This director isn't a data analyst and shouldn't have to be. Copilot runs as her, so the security defined in the model applies to every answer — AI never becomes a back door to data."
**Watch-outs:** directors must be Viewers. The same questions work in the optional Fabric data agent.

## Act 4 — Spot it, explain it, review it (10 min, `retail_exec`)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | Point to Worcester on the scorecard (falling NPS, rising delinquency) | The anomaly surfaces itself |
| 2 | Right-click Worcester → **Drill through → Driver Analysis** | Call-center wait time and staffing coverage hurting performance |
| 3 | Read the AI narrative | Plain-language explanation |
| 4 | Point out that a person reviews it before sharing | Human in the loop |

**Say:** "Nothing is decided automatically. Consequential decisions — especially anything touching credit — stay with people, with the evidence in front of them."
**Watch-outs:** don't show automated credit or exception decisions.

## Act 5 — It rolls up, trusted (15 min, `retail_exec`)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | KPI gauges for all regions | Executive scorecard on certified KPIs |
| 2 | **Source Credit Union** slicer: Contoso CU, then Fabrikam CU | Same definitions, comparable results |
| 3 | NPS trend by month | Consistent metric results across the merger |
| 4 | Branch bar chart | From enterprise to branch |
| 5 | The KPI glossary table (add a table visual if needed) | The business glossary behind every number |
| 6 | Copilot: *"Summarize this page for the board"* | Board-ready narrative grounded in certified KPIs |

**Say:** "The number the West director saw is the same number in the executive's scorecard. Same metric, same definition, no reconciliation."

## Act 6 — Prove it's safe (10 min, admin)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | Admin portal → Copilot tenant setting scoped to a security group | AI can be enabled or disabled by group, workspace or domain |
| 2 | Activity / audit log for the hub: views, Copilot use, exports, deployments | End-to-end activity audit |
| 3 | *Optional, needs Microsoft Purview:* prompts and responses from Act 3; a DLP policy tip on export | Prompt logging, data-exfiltration safeguards |
| 4 | *Optional, needs Microsoft Sentinel:* Fabric events ingested, an incident | SIEM investigation |

**Watch-outs:** activity data lags — stage it the day before. Use demo accounts only.

## Act 7 — Run it at scale (10 min, admin)

| # | Click / action | What the audience sees |
|---|---|---|
| 1 | A slow visual → **Performance analyzer** → DAX timing | Diagnose a slow view |
| 2 | **Monitoring hub**: a failed refresh and its error | Refresh failure root cause |
| 3 | **Capacity Metrics app**: the spike and the item behind it | Capacity bottleneck |
| 4 | Lineage to the source item behind the failure | Source issue identified |
| 5 | Governance notebook output: inventory, items unused for 90 days, orphaned workspaces | Stale content and ownership |

The sample tables in `Enterprise_Ref` (`ops_capacity_metrics_5min`, `ops_refresh_history`, `admin_inventory_artifacts`) let you build an illustrative operations page if your demo tenant has little real telemetry. Say so when you use them.

## Close
**Say:** "You saw one story: two legacy organizations' data brought together without moving off their platforms, certified once, questioned in plain language under the right security, explained with a human in the loop, rolled up to the board, and governed at every step."
