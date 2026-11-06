/* =====================================================================
   OPTIONAL - "Live change" moment for the demo (run in the Fabrikam_CU SQL database)

   Story: a late delinquency correction is posted in Fabrikam's core system.
   1. Run the UPDATE below.
   2. Wait for replication to OneLake (usually under a minute).
   3. In the Combined_Data warehouse:  EXEC combined.usp_Load_Combined;
   4. Refresh the semantic model and show Worcester's delinquency jump in the report.
   No pipeline, no export file, no manual copy.
   ===================================================================== */

-- Before
SELECT period_month, branch_code, delinquent_30d_rate FROM dbo.branch_month_metrics
WHERE branch_code = 'BR002' AND period_month = '2026-10-01';

-- The correction
UPDATE dbo.branch_month_metrics
SET delinquent_30d_rate = 0.0450
WHERE branch_code = 'BR002' AND period_month = '2026-10-01';

-- Reset after the demo (original value)
-- UPDATE dbo.branch_month_metrics SET delinquent_30d_rate = 0.0317
-- WHERE branch_code = 'BR002' AND period_month = '2026-10-01';
