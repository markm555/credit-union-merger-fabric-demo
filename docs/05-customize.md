# 5. Customize

## Rename the credit unions
1. In `fabric/warehouse/02_usp_Load_Combined.sql` change the labels `'Contoso CU'` / `'Fabrikam CU'` and the key prefixes `CON-` / `FAB-`.
2. If you rename the lakehouses, update the three-part names in the procedure (`[Contoso_CU]`, `[Fabrikam_CU]`, `[Enterprise_Ref]`) and `LAKEHOUSES` in the notebook.
3. Update descriptions in `powerbi/.../tables/*.tmdl` that mention the names.
4. Reload the warehouse and refresh the model.

## Regenerate or extend the data
```bash
python data/generate_data.py --start 2025-01 --end 2026-12 --seed 7
```
- Branch lists, baselines and the planted storylines are at the top of `generate_data.py` (`CONTOSO_BRANCHES`, `FABRIKAM_BRANCHES`, `ANOMALY_BRANCH`, `ELEVATED_BRANCH`).
- The anomaly always lands in the **last three months** of the range.
- If you regenerate, also regenerate the optional SQL database seed script (or edit its INSERTs).

## Add a third credit union
Add a folder under `data/`, a lakehouse, an entry in the notebook's `TABLES` and `LAKEHOUSES`, and one more `INSERT … SELECT` block per table in the procedure. The model and report need no change — `SourceCU` picks up the new value.

## Use real Mirroring instead of lakehouses
Create mirrored databases (Snowflake, Azure SQL, Oracle and so on) with the **same names** as the lakehouses, or change the three-part names in the procedure. Everything downstream stays the same.

## Switch the model to Direct Lake
The model ships in Import mode so it works with any warehouse SQL endpoint. To use Direct Lake, recreate the tables against `Combined_Data` with Direct Lake storage mode and keep the measure, relationship and role definitions.
