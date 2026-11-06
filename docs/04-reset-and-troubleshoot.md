# 4. Reset and troubleshooting

## Reset between rehearsals
1. If you used the live SQL database change, run the reset `UPDATE` at the bottom of `optional/sql-database/02_live_change.sql`.
2. In the warehouse: `EXEC combined.usp_Load_Combined;`
3. Refresh the semantic model.
4. Close Copilot panes and clear chat history in each persona's browser profile.
5. Pause the capacity if you're done for the day.

To rebuild the source data from scratch, rerun `Load_Source_Data.ipynb` (it overwrites the tables).

## Common problems

| Symptom | Cause | Fix |
|---|---|---|
| `Invalid object name 'Contoso_CU.dbo.dim_branch'` in the warehouse | Lakehouse SQL endpoint hasn't synced the new tables, or the lakehouse is in another workspace | Open the lakehouse SQL analytics endpoint → **Refresh**. Keep all items in the same workspace. |
| Notebook: *Lakehouse 'X' was not found* | Lakehouse not created or named differently | Create it, or change `LAKEHOUSES` in the parameters cell |
| Notebook can't read from GitHub | Private repo or outbound access blocked | Use `DATA_SOURCE = "files"` and upload the `data` folder to `Enterprise_Ref/Files/data` |
| Directors see every region | They are Admin/Member/Contributor, or not in the role | Make them **Viewers** and add them to **Security Scope** |
| A director sees **nothing** | UPN in `security_user_scope` doesn't match the sign-in name | Check query 6 in `03_validate.sql`; rerun the notebook with the right `TENANT_DOMAIN`, then reload the warehouse |
| Report shows blanks after publishing | Data source credentials not set | Semantic model settings → **Data source credentials** → OAuth2 |
| Refresh fails with an invalid server | `SqlEndpoint` still has the placeholder | Desktop: *Transform data → Edit parameters*; Service: semantic model settings → **Parameters** |
| Copilot button missing | Capacity not paid F2+, tenant setting off, or user not in the allowed group | See [01-prerequisites.md](01-prerequisites.md) |
| Git sync fails on the warehouse with `SQL71561 … unresolved reference` | A query over two or more tables in another database has unqualified columns | Give every table an alias and qualify every column (the shipped procedure already does) |
| Git sync fails on `IDENTITY` / `CLUSTER BY` syntax | Old `.sqlproj` SDK version in the repo | Commit from a healthy workspace to regenerate it, or update `Microsoft.Build.Sql` in the `.sqlproj` |
| Deployment pipeline: Test shows Dev's data | Model still points at Dev's warehouse | Add a **parameter rule** for `SqlEndpoint` on the semantic model in each stage |
