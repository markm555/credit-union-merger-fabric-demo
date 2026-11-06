/* Credit Union Merger Demo - validation and demo queries (Combined_Data warehouse) */

-- 1. One combined data set, labeled by legacy organization (Act 2)
SELECT k.SourceCU, COUNT(*) AS KpiRows, COUNT(DISTINCT k.SourceBranchKey) AS Branches,
       MIN(k.MonthStart) AS FirstMonth, MAX(k.MonthStart) AS LastMonth
FROM combined.fact_monthly_kpi AS k
GROUP BY k.SourceCU;

-- 2. Why a merged branch key is needed: the same branch code exists in both CUs
SELECT b.BranchId, STRING_AGG(CONCAT(b.SourceCU, ': ', b.BranchName), ' | ') AS BranchesUsingThisCode
FROM combined.dim_branch AS b
GROUP BY b.BranchId
HAVING COUNT(DISTINCT b.SourceCU) > 1
ORDER BY b.BranchId;

-- 3. Legacy definitions disagree (Act 1): Fabrikam's old board metric vs the certified metric
SELECT 'Fabrikam legacy (60+ days)' AS Definition, CAST(AVG(fm.delinquent_60d_rate) * 100 AS DECIMAL(9,2)) AS AvgDelinquencyPct
FROM [Fabrikam_CU].[dbo].[branch_month_metrics] AS fm
UNION ALL
SELECT 'Certified (30+ days)', CAST(AVG(k.DelinquencyRatePct) AS DECIMAL(9,2))
FROM combined.fact_monthly_kpi AS k
WHERE k.SourceCU = 'Fabrikam CU';

-- 4. The branch that stands out (Act 4): last six months for Fabrikam BR002 (Worcester)
SELECT k.MonthStart, b.BranchName, k.NPS, k.DelinquencyRatePct, k.LoansBooked
FROM combined.fact_monthly_kpi AS k
JOIN combined.dim_branch AS b ON b.SourceBranchKey = k.SourceBranchKey
WHERE k.SourceBranchKey = 'FAB-BR002'
  AND k.MonthStart >= DATEADD(MONTH, -5, (SELECT MAX(m.MonthStart) FROM combined.dim_month AS m))
ORDER BY k.MonthStart;

-- 5. West region, latest month - what the West director should see (both legacy CUs)
SELECT b.SourceCU, b.BranchName, k.DelinquencyRatePct
FROM combined.fact_monthly_kpi AS k
JOIN combined.dim_branch AS b ON b.SourceBranchKey = k.SourceBranchKey
WHERE b.Region = 'West'
  AND k.MonthStart = (SELECT MAX(m.MonthStart) FROM combined.dim_month AS m)
ORDER BY k.DelinquencyRatePct DESC;

-- 6. Personas - UPNs must match your demo users exactly
SELECT s.UserUPN, s.RoleName, s.Region FROM combined.security_user_scope AS s;
