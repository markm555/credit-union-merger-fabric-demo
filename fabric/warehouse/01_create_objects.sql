/* =====================================================================
   Credit Union Merger Demo - Combined_Data warehouse objects
   Run in the Combined_Data warehouse (same workspace as the lakehouses).
   Creates schema [combined] and the certified, harmonized tables that
   the semantic model reads.
   ===================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'combined')
    EXEC('CREATE SCHEMA combined');

DROP TABLE IF EXISTS combined.dim_branch;
CREATE TABLE combined.dim_branch
(
    SourceCU        VARCHAR(50)  NOT NULL,   -- legacy organization: 'Contoso CU' / 'Fabrikam CU'
    SourceBranchKey VARCHAR(20)  NOT NULL,   -- unique across the merged organization, e.g. CON-BR001
    BranchId        VARCHAR(10)  NOT NULL,   -- legacy branch code (collides across the two CUs)
    BranchName      VARCHAR(100) NOT NULL,
    Region          VARCHAR(20)  NOT NULL,   -- North / South / East / West
    State           CHAR(2)      NOT NULL
);

DROP TABLE IF EXISTS combined.dim_month;
CREATE TABLE combined.dim_month
(
    MonthStart DATE NOT NULL
);

DROP TABLE IF EXISTS combined.fact_monthly_kpi;
CREATE TABLE combined.fact_monthly_kpi
(
    SourceCU           VARCHAR(50)  NOT NULL,
    SourceBranchKey    VARCHAR(20)  NOT NULL,
    MonthStart         DATE         NOT NULL,
    BranchId           VARCHAR(10)  NOT NULL,
    Region             VARCHAR(20)  NOT NULL,
    LoansBooked        INT          NOT NULL,
    DepositGrowthPct   DECIMAL(9,2) NOT NULL,   -- percent (1.25 = 1.25%)
    NPS                DECIMAL(9,1) NOT NULL,
    DelinquencyRatePct DECIMAL(9,2) NOT NULL,   -- certified: 30+ days past due, percent
    DigitalAdoptionPct DECIMAL(9,1) NOT NULL    -- percent
);

DROP TABLE IF EXISTS combined.fact_driver_breakdown;
CREATE TABLE combined.fact_driver_breakdown
(
    SourceCU        VARCHAR(50)  NOT NULL,
    SourceBranchKey VARCHAR(20)  NOT NULL,
    MonthStart      DATE         NOT NULL,
    BranchId        VARCHAR(10)  NOT NULL,
    DriverName      VARCHAR(50)  NOT NULL,
    ImpactScore     FLOAT        NOT NULL,
    DriverValue     FLOAT        NOT NULL
);

DROP TABLE IF EXISTS combined.glossary_kpi_definitions;
CREATE TABLE combined.glossary_kpi_definitions
(
    KPI         VARCHAR(50)  NOT NULL,
    Definition  VARCHAR(400) NOT NULL,
    Owner       VARCHAR(100) NOT NULL,
    Calculation VARCHAR(200) NOT NULL
);

DROP TABLE IF EXISTS combined.security_user_scope;
CREATE TABLE combined.security_user_scope
(
    UserUPN  VARCHAR(200) NOT NULL,
    RoleName VARCHAR(50)  NOT NULL,
    Region   VARCHAR(20)  NOT NULL   -- 'ALL' = sees every region
);
