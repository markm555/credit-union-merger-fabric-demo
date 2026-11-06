/* =====================================================================
   combined.usp_Load_Combined
   Harmonizes the two legacy credit unions into one certified data set.

   What the merger logic does:
     * Gives every branch a key that is unique across both organizations
       (both legacy CUs use branch codes BR001, BR002, ...).
     * Maps Fabrikam's region codes (N/S/E/W) to enterprise region names.
     * Converts Fabrikam's fractions (0.0125) to percentages (1.25).
     * Applies the CERTIFIED delinquency definition (30+ days past due).
       Fabrikam's legacy board metric used 60+ days; that column is
       intentionally not used.

   Cross-database queries use three-part names. Every column is qualified
   with a table alias - required for Fabric Git integration, which fails
   with SQL71561 "unresolved reference" when a query that touches two or
   more tables in another database has unqualified columns.
   ===================================================================== */
CREATE OR ALTER PROCEDURE combined.usp_Load_Combined
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE combined.dim_branch;
    TRUNCATE TABLE combined.dim_month;
    TRUNCATE TABLE combined.fact_monthly_kpi;
    TRUNCATE TABLE combined.fact_driver_breakdown;
    TRUNCATE TABLE combined.glossary_kpi_definitions;
    TRUNCATE TABLE combined.security_user_scope;

    /* ---------- Branches ---------- */
    INSERT INTO combined.dim_branch (SourceCU, SourceBranchKey, BranchId, BranchName, Region, State)
    SELECT 'Contoso CU', CONCAT('CON-', cb.[BranchId]), cb.[BranchId], cb.[BranchName], cb.[Region], cb.[State]
    FROM [Contoso_CU].[dbo].[dim_branch] AS cb
    UNION ALL
    SELECT 'Fabrikam CU', CONCAT('FAB-', fb.[branch_code]), fb.[branch_code], fb.[branch_name],
           CASE fb.[region_code] WHEN 'N' THEN 'North' WHEN 'S' THEN 'South'
                                 WHEN 'E' THEN 'East'  WHEN 'W' THEN 'West' ELSE 'Unknown' END,
           fb.[state_code]
    FROM [Fabrikam_CU].[dbo].[branches] AS fb;

    /* ---------- Monthly KPIs ---------- */
    INSERT INTO combined.fact_monthly_kpi
        (SourceCU, SourceBranchKey, MonthStart, BranchId, Region, LoansBooked,
         DepositGrowthPct, NPS, DelinquencyRatePct, DigitalAdoptionPct)
    SELECT 'Contoso CU', CONCAT('CON-', ck.[BranchId]), ck.[MonthStart], ck.[BranchId], ck.[Region],
           ck.[LoansBooked], ck.[DepositGrowthPct], ck.[NPS], ck.[DelinquencyRatePct], ck.[DigitalAdoptionPct]
    FROM [Contoso_CU].[dbo].[fact_monthly_kpi] AS ck;

    INSERT INTO combined.fact_monthly_kpi
        (SourceCU, SourceBranchKey, MonthStart, BranchId, Region, LoansBooked,
         DepositGrowthPct, NPS, DelinquencyRatePct, DigitalAdoptionPct)
    SELECT 'Fabrikam CU', CONCAT('FAB-', fm.[branch_code]), fm.[period_month], fm.[branch_code],
           CASE fb.[region_code] WHEN 'N' THEN 'North' WHEN 'S' THEN 'South'
                                 WHEN 'E' THEN 'East'  WHEN 'W' THEN 'West' ELSE 'Unknown' END,
           fm.[loans_funded],
           CAST(fm.[deposit_growth_rate] * 100 AS DECIMAL(9,2)),
           fm.[nps_score],
           CAST(fm.[delinquent_30d_rate] * 100 AS DECIMAL(9,2)),   -- certified 30+ day definition
           CAST(fm.[digital_active_rate] * 100 AS DECIMAL(9,1))
    FROM [Fabrikam_CU].[dbo].[branch_month_metrics] AS fm
    JOIN [Fabrikam_CU].[dbo].[branches]             AS fb ON fb.[branch_code] = fm.[branch_code];

    /* ---------- Driver breakdown ---------- */
    INSERT INTO combined.fact_driver_breakdown
        (SourceCU, SourceBranchKey, MonthStart, BranchId, DriverName, ImpactScore, DriverValue)
    SELECT 'Contoso CU', CONCAT('CON-', cd.[BranchId]), cd.[MonthStart], cd.[BranchId],
           cd.[DriverName], cd.[ImpactScore], cd.[DriverValue]
    FROM [Contoso_CU].[dbo].[fact_driver_breakdown] AS cd
    UNION ALL
    SELECT 'Fabrikam CU', CONCAT('FAB-', fd.[branch_code]), fd.[period_month], fd.[branch_code],
           fd.[driver], fd.[impact], fd.[value]
    FROM [Fabrikam_CU].[dbo].[branch_driver_scores] AS fd;

    /* ---------- Months ---------- */
    INSERT INTO combined.dim_month (MonthStart)
    SELECT DISTINCT k.[MonthStart] FROM combined.fact_monthly_kpi AS k;

    /* ---------- Certified glossary and security (enterprise reference) ---------- */
    INSERT INTO combined.glossary_kpi_definitions (KPI, Definition, Owner, Calculation)
    SELECT g.[KPI], g.[Definition], g.[Owner], g.[Calculation]
    FROM [Enterprise_Ref].[dbo].[glossary_kpi_definitions] AS g;

    INSERT INTO combined.security_user_scope (UserUPN, RoleName, Region)
    SELECT s.[UserUPN], s.[RoleName], s.[Region]
    FROM [Enterprise_Ref].[dbo].[security_user_scope] AS s;

    /* ---------- Load summary ---------- */
    SELECT 'dim_branch' AS TableName, COUNT(*) AS RowsLoaded FROM combined.dim_branch
    UNION ALL SELECT 'dim_month', COUNT(*) FROM combined.dim_month
    UNION ALL SELECT 'fact_monthly_kpi', COUNT(*) FROM combined.fact_monthly_kpi
    UNION ALL SELECT 'fact_driver_breakdown', COUNT(*) FROM combined.fact_driver_breakdown
    UNION ALL SELECT 'glossary_kpi_definitions', COUNT(*) FROM combined.glossary_kpi_definitions
    UNION ALL SELECT 'security_user_scope', COUNT(*) FROM combined.security_user_scope;
END;
