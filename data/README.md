# Data dictionary (synthetic)

Regenerate with `python generate_data.py` (seeded, standard library only). Default range: January 2025 – October 2026.

## contoso_cu — legacy credit union #1 ("clean" schema)
| Table | Columns |
|---|---|
| `dim_branch` | BranchId, BranchName, Region (North/South/East/West), State |
| `fact_monthly_kpi` | MonthStart, BranchId, Region, LoansBooked, DepositGrowthPct, NPS, DelinquencyRatePct (30+ days, %), DigitalAdoptionPct (%) |
| `fact_driver_breakdown` | MonthStart, BranchId, DriverName, ImpactScore, DriverValue |
| `glossary_kpi_definitions` | Contoso's legacy KPI definitions |

## fabrikam_cu — legacy credit union #2 (different schema on purpose)
| Table | Columns | Differences from Contoso |
|---|---|---|
| `branches` | branch_code, branch_name, region_code, state_code | Region **codes** N/S/E/W; same branch codes as Contoso |
| `branch_month_metrics` | period_month, branch_code, loans_funded, deposit_growth_rate, nps_score, delinquent_30d_rate, delinquent_60d_rate, digital_active_rate | Rates are **fractions** (0.0125 = 1.25%); legacy board metric uses **60+ days** |
| `branch_driver_scores` | period_month, branch_code, driver, impact, value | Different column names |
| `kpi_glossary` | Fabrikam's legacy KPI definitions | |

## enterprise_ref — certified and shared data
| Table | Purpose |
|---|---|
| `glossary_kpi_definitions` | Certified enterprise definitions (the model's business glossary) |
| `security_user_scope` | Persona → region mapping for row-level security; `{TENANT_DOMAIN}` is replaced by the load notebook |
| `ops_capacity_metrics_5min`, `ops_refresh_history`, `admin_inventory_artifacts` | Illustrative platform telemetry for Act 7 |

## Planted storylines
- Branch codes `BR001`–`BR011` exist in both credit unions.
- Fabrikam **Worcester (BR002)**: delinquency rises from about 1% to about 3% and NPS falls from about 63 to about 41 over the last three months; drivers *CallCenterWaitTime* and *StaffingCoverage* turn sharply negative.
- Fabrikam **Denver Tech Center (BR011)** has the highest delinquency in the West region, so the West director's answer mixes both legacy organizations.
