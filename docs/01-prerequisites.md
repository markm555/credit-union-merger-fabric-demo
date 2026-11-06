# 1. Prerequisites

## Fabric capacity
- A **paid Fabric capacity (F2 or larger)** for the demo workspace. Copilot in Power BI and Fabric data agents need a paid capacity; a Fabric trial capacity is fine for everything else.
- **Below F64**, people who *view* the report (the director and executive personas) need a **Power BI Pro** or **Premium Per User** license. On F64 or larger, viewers don't need a per-user license.
- Pause the capacity between rehearsals to save cost.

## Tenant settings (Fabric admin portal → Tenant settings)
| Setting | Why |
|---|---|
| Users can create Fabric items | Lakehouses, warehouse, notebook |
| Copilot and Azure OpenAI Service | Copilot in Power BI (Act 3, 4, 5) |
| Data sent to Azure OpenAI can be processed outside your capacity's geographic region (and the related storing setting) | Required for Copilot / data agents if your capacity is outside the regions where Azure OpenAI runs |
| The Fabric data agent tenant setting | Only if you use the optional data agent |
| Users can synchronize workspace items with their Git repositories | Only for the optional Git / CI-CD part of Act 2 |

Scope the settings to a security group that contains the demo users if you don't want them tenant-wide.

## Demo users (Microsoft Entra ID)
Create these six users in the tenant. The **part before the @ must match exactly** — row-level security matches on the user principal name.

```
mgmt_analyst@<yourtenant>
west_director@<yourtenant>
east_director@<yourtenant>
north_director@<yourtenant>
south_director@<yourtenant>
retail_exec@<yourtenant>
```

- Assign Power BI Pro (or PPU) licenses if the capacity is smaller than F64.
- Sign in once as each user (in a separate browser profile) to set the password and accept any prompts. One browser profile per persona makes the live demo fast.
- Keep passwords **out of the repository**.

## Tools
- **Power BI Desktop** (current version) to open the Power BI Project (`.pbip`). If Desktop asks, enable **Power BI Project (.pbip) save option** and **Store semantic model using TMDL format** under *File → Options → Preview features*.
- Optional: **Python 3.9+** to regenerate data (`data/generate_data.py`, standard library only).
- Optional: a **GitHub or Azure DevOps** repository for the Git / deployment pipeline moment.
