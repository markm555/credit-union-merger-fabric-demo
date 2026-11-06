"""
Synthetic data generator for the Credit Union Merger demo on Microsoft Fabric.

Creates two legacy credit unions with deliberately DIFFERENT source schemas,
plus enterprise reference data (certified KPI glossary and demo personas).

  data/contoso_cu/       Legacy CU #1 - "clean" schema, percentages stored as 0-100
  data/fabrikam_cu/      Legacy CU #2 - different table/column names, region codes,
                         rates stored as fractions (0-1), legacy 60-day delinquency KPI
  data/enterprise_ref/   Certified KPI glossary + persona-to-region security mapping

All data is synthetic. Standard library only.

Usage:
  python generate_data.py                       # defaults: Jan 2025 - Oct 2026, seed 42
  python generate_data.py --end 2026-12 --seed 7
"""
import argparse
import csv
import math
import os
import random
from datetime import date

DRIVERS = ["MemberGrowth", "CrossSellRate", "CallCenterWaitTime",
           "MobileAppStability", "StaffingCoverage", "LocalEconomicIndex"]

# (branch id, name, region, state, baseline NPS, baseline delinquency %, loans/month)
CONTOSO_BRANCHES = [
    ("BR001", "Seattle Downtown",      "North", "WA", 58, 0.9, 410),
    ("BR002", "Redmond",               "North", "WA", 62, 0.7, 380),
    ("BR003", "Bellevue",              "North", "WA", 60, 0.8, 395),
    ("BR004", "Portland Pearl",        "North", "OR", 55, 1.1, 330),
    ("BR005", "Boise",                 "North", "ID", 52, 1.2, 240),
    ("BR006", "San Jose",              "West",  "CA", 57, 1.0, 450),
    ("BR007", "Sunnyvale",             "West",  "CA", 59, 0.9, 400),
    ("BR008", "San Francisco SoMa",    "West",  "CA", 50, 1.3, 360),
    ("BR009", "Sacramento",            "West",  "CA", 54, 1.4, 300),
    ("BR010", "Austin",                "South", "TX", 56, 1.2, 340),
    ("BR011", "Phoenix",               "South", "AZ", 51, 1.5, 290),
    ("BR012", "Raleigh",               "East",  "NC", 55, 1.1, 270),
]

# Fabrikam deliberately reuses branch codes BR001..BR011 -> collisions with Contoso.
FABRIKAM_BRANCHES = [
    ("BR001", "Boston Back Bay",       "E", "MA", 61, 0.8, 420),
    ("BR002", "Worcester",             "E", "MA", 56, 1.0, 310),   # planted anomaly
    ("BR003", "Cambridge",             "E", "MA", 63, 0.7, 390),
    ("BR004", "Nashua",                "E", "NH", 58, 0.9, 260),
    ("BR005", "Manchester",            "E", "NH", 55, 1.1, 250),
    ("BR006", "Providence",            "E", "RI", 53, 1.2, 230),
    ("BR007", "Hartford",              "E", "CT", 52, 1.3, 240),
    ("BR008", "Portland Old Port",     "N", "ME", 57, 1.0, 200),
    ("BR009", "Burlington",            "N", "VT", 60, 0.8, 180),
    ("BR010", "Charlotte",             "S", "NC", 54, 1.3, 300),
    ("BR011", "Denver Tech Center",    "W", "CO", 53, 1.6, 320),   # elevated West branch
]

ANOMALY_BRANCH = ("fabrikam", "BR002")     # Worcester: last 3 months deteriorate
ELEVATED_BRANCH = ("fabrikam", "BR011")    # Denver: consistently highest West delinquency


def months_between(start, end):
    y, m = start
    out = []
    while (y, m) <= end:
        out.append(date(y, m, 1))
        m += 1
        if m == 13:
            y, m = y + 1, 1
    return out


def write_csv(path, header, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        w.writerow(header)
        w.writerows(rows)
    print(f"  {os.path.relpath(path)}: {len(rows)} rows")


def simulate(cu, branches, months, rng):
    """Return per-branch, per-month KPI dicts and driver rows (in common units)."""
    kpi, drivers = [], []
    n = len(months)
    for (bid, name, region, state, nps0, delq0, loans0) in branches:
        trend = rng.uniform(-0.15, 0.35)            # NPS drift per month
        digital0 = rng.uniform(55, 72)
        for i, m in enumerate(months):
            season = math.sin((m.month - 1) / 12 * 2 * math.pi)
            months_left = n - 1 - i
            shock = (cu, bid) == ANOMALY_BRANCH and months_left < 3
            sev = (3 - months_left) if shock else 0   # 1, 2, 3 in the last three months

            nps = nps0 + trend * i + rng.gauss(0, 1.8) - (7 * sev if shock else 0)
            delq = delq0 + 0.15 * season + rng.gauss(0, 0.08) + (0.75 * sev if shock else 0)
            if (cu, bid) == ELEVATED_BRANCH:
                delq += 0.6
            loans = int(loans0 * (1 + 0.08 * season) + rng.gauss(0, loans0 * 0.05)
                        - (loans0 * 0.12 * sev if shock else 0))
            dep = 0.9 + 0.4 * season + rng.gauss(0, 0.35) - (0.5 * sev if shock else 0)
            dig = min(95.0, digital0 + 0.6 * i + rng.gauss(0, 1.5))
            d60 = delq * rng.uniform(0.42, 0.52)       # 60+ day share of 30+ day delinquency

            kpi.append(dict(month=m, bid=bid, region=region, loans=max(loans, 0),
                            dep=round(dep, 2), nps=round(max(min(nps, 90), 5), 1),
                            delq30=round(max(delq, 0.1), 2), delq60=round(max(d60, 0.05), 2),
                            dig=round(dig, 1)))

            for d in DRIVERS:
                base_val = {"MemberGrowth": 30, "CrossSellRate": 32, "CallCenterWaitTime": 40,
                            "MobileAppStability": 96, "StaffingCoverage": 88,
                            "LocalEconomicIndex": 100}[d]
                val = base_val + rng.gauss(0, base_val * 0.06)
                impact = rng.gauss(0, 0.6)
                if shock and d == "CallCenterWaitTime":
                    val += 25 * sev
                    impact = -1.2 - 0.9 * sev
                if shock and d == "StaffingCoverage":
                    val -= 8 * sev
                    impact = -0.6 - 0.5 * sev
                if (cu, bid) == ELEVATED_BRANCH and d == "LocalEconomicIndex":
                    impact -= 0.8
                drivers.append(dict(month=m, bid=bid, driver=d,
                                    impact=round(impact, 2), value=round(val, 2)))
    return kpi, drivers


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2025-01")
    ap.add_argument("--end", default="2026-10")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default=os.path.dirname(os.path.abspath(__file__)))
    a = ap.parse_args()
    s = tuple(int(x) for x in a.start.split("-"))
    e = tuple(int(x) for x in a.end.split("-"))
    months = months_between(s, e)
    rng = random.Random(a.seed)
    out = a.out
    print(f"Generating {len(months)} months ({months[0]} to {months[-1]}), seed {a.seed}")

    # ---------------- Contoso CU (schema matches the combined model) ----------------
    ck, cd = simulate("contoso", CONTOSO_BRANCHES, months, rng)
    write_csv(f"{out}/contoso_cu/dim_branch.csv", ["BranchId", "BranchName", "Region", "State"],
              [(b[0], b[1], b[2], b[3]) for b in CONTOSO_BRANCHES])
    write_csv(f"{out}/contoso_cu/fact_monthly_kpi.csv",
              ["MonthStart", "BranchId", "Region", "LoansBooked", "DepositGrowthPct", "NPS",
               "DelinquencyRatePct", "DigitalAdoptionPct"],
              [(k["month"], k["bid"], k["region"], k["loans"], k["dep"], k["nps"], k["delq30"], k["dig"])
               for k in ck])
    write_csv(f"{out}/contoso_cu/fact_driver_breakdown.csv",
              ["MonthStart", "BranchId", "DriverName", "ImpactScore", "DriverValue"],
              [(d["month"], d["bid"], d["driver"], d["impact"], d["value"]) for d in cd])
    write_csv(f"{out}/contoso_cu/glossary_kpi_definitions.csv", ["KPI", "Definition", "Owner"], [
        ("DelinquencyRatePct", "Share of the loan portfolio 30+ days past due.", "Contoso Credit Risk"),
        ("NPS", "Net Promoter Score from post-interaction surveys.", "Contoso Member Experience"),
        ("DigitalAdoptionPct", "Members who logged in to online or mobile banking in the month.", "Contoso Digital"),
    ])

    # ---------------- Fabrikam CU (different schema on purpose) ----------------
    fk, fd = simulate("fabrikam", FABRIKAM_BRANCHES, months, rng)
    write_csv(f"{out}/fabrikam_cu/branches.csv",
              ["branch_code", "branch_name", "region_code", "state_code"],
              [(b[0], b[1], b[2], b[3]) for b in FABRIKAM_BRANCHES])
    write_csv(f"{out}/fabrikam_cu/branch_month_metrics.csv",
              ["period_month", "branch_code", "loans_funded", "deposit_growth_rate", "nps_score",
               "delinquent_30d_rate", "delinquent_60d_rate", "digital_active_rate"],
              [(k["month"], k["bid"], k["loans"], round(k["dep"] / 100, 4), k["nps"],
                round(k["delq30"] / 100, 4), round(k["delq60"] / 100, 4), round(k["dig"] / 100, 4))
               for k in fk])
    write_csv(f"{out}/fabrikam_cu/branch_driver_scores.csv",
              ["period_month", "branch_code", "driver", "impact", "value"],
              [(d["month"], d["bid"], d["driver"], d["impact"], d["value"]) for d in fd])
    write_csv(f"{out}/fabrikam_cu/kpi_glossary.csv", ["kpi_name", "definition", "owner"], [
        ("delinquency_rate", "Share of the loan portfolio 60+ days past due (legacy board metric).", "Fabrikam Lending"),
        ("nps_score", "Net Promoter Score from quarterly relationship surveys.", "Fabrikam Marketing"),
        ("digital_active_rate", "Members with any digital transaction in the month, as a fraction.", "Fabrikam Digital"),
    ])

    # ---------------- Enterprise reference data ----------------
    write_csv(f"{out}/enterprise_ref/glossary_kpi_definitions.csv",
              ["KPI", "Definition", "Owner", "Calculation"], [
        ("LoansBooked", "Count of newly funded consumer and small-business loans in the month.",
         "Retail Finance", "SUM(fact_monthly_kpi[LoansBooked])"),
        ("DepositGrowthPct", "Month-over-month percentage growth of total deposit balances.",
         "Treasury Analytics", "(CurrentMonthDeposits - PriorMonthDeposits) / PriorMonthDeposits * 100"),
        ("NPS", "Net Promoter Score from member post-interaction surveys (promoters % minus detractors %).",
         "Member Experience", "Promoters% - Detractors%"),
        ("DelinquencyRatePct", "Certified enterprise definition: share of the loan portfolio 30+ days past due, in percent. Replaces the legacy Fabrikam 60+ day metric.",
         "Enterprise Credit Risk", "DelinquentBalance30Plus / TotalLoanBalance * 100"),
        ("DigitalAdoptionPct", "Percent of active members who used at least one digital channel in the month.",
         "Digital Banking", "DigitalActiveMembers / ActiveMembers * 100"),
    ])
    # {TENANT_DOMAIN} is replaced by the load notebook, e.g. contoso.onmicrosoft.com
    write_csv(f"{out}/enterprise_ref/security_user_scope.csv", ["UserUPN", "RoleName", "Region"], [
        ("north_director@{TENANT_DOMAIN}", "RegionalDirector", "North"),
        ("south_director@{TENANT_DOMAIN}", "RegionalDirector", "South"),
        ("east_director@{TENANT_DOMAIN}", "RegionalDirector", "East"),
        ("west_director@{TENANT_DOMAIN}", "RegionalDirector", "West"),
        ("retail_exec@{TENANT_DOMAIN}", "Executive", "ALL"),
        ("mgmt_analyst@{TENANT_DOMAIN}", "Analyst", "ALL"),
    ])
    print("Done.")


if __name__ == "__main__":
    main()
