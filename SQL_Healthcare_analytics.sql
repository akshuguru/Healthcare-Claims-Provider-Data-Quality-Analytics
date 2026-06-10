USE Healthcare_Claims_Analytics;
GO

/* 1. BASIC SELECT: View first 10 members */
SELECT TOP 10 *
FROM dbo.members_clean;

/* 2. BASIC SELECT: View first 10 providers */
SELECT TOP 10 *
FROM dbo.providers_clean;

/* 3. BASIC SELECT: View first 10 claims */
SELECT TOP 10 *
FROM dbo.claims_clean;

/* 4. DISTINCT: What plan types exist? */
SELECT DISTINCT plan_type
FROM dbo.members_clean;

/* 5. DISTINCT: What provider specialties exist? */
SELECT DISTINCT specialty
FROM dbo.providers_clean;

/* 6. WHERE: Which claims were denied? */
SELECT *
FROM dbo.claims_clean
WHERE claim_status = 'Denied';

/* 7. ORDER BY: Top 10 highest paid claims */
SELECT TOP 10 *
FROM dbo.claims_clean
ORDER BY paid_amount DESC;

/* 8. AND / OR: High-value paid or denied claims */
SELECT *
FROM dbo.claims_clean
WHERE paid_amount > 4000
  AND claim_status IN ('Paid', 'Denied');

/* 9. LIKE / Pattern Match: Providers with Family specialty */
SELECT *
FROM dbo.providers_clean
WHERE specialty LIKE '%Family%';

/* 10. AGGREGATE: Total medical spend */
SELECT 
    SUM(paid_amount) AS total_medical_spend,
    AVG(paid_amount) AS avg_claim_cost,
    COUNT(*) AS total_claims
FROM dbo.claims_clean;

/* 11. GROUP BY: Claims by status */
SELECT claim_status, COUNT(*) AS claim_count
FROM dbo.claims_clean
GROUP BY claim_status;

/* 12. HAVING: Provider IDs with more than 100 claims */
SELECT provider_id, COUNT(*) AS claim_count
FROM dbo.claims_clean
GROUP BY provider_id
HAVING COUNT(*) > 100;

/* 13. KPI: Denial Rate */
SELECT 
    100.0 * SUM(CASE WHEN claim_status = 'Denied' THEN 1 ELSE 0 END) / COUNT(*) AS denial_rate
FROM dbo.claims_clean;

/* 14. KPI: Claims Adjudication Rate */
SELECT 
    100.0 * SUM(CASE WHEN claim_status IN ('Paid', 'Denied') THEN 1 ELSE 0 END) / COUNT(*) AS adjudication_rate
FROM dbo.claims_clean;

/* 15. INNER JOIN: Claims with member details */
SELECT TOP 20
    c.claim_id,
    m.member_id,
    m.plan_type,
    c.claim_status,
    c.paid_amount
FROM dbo.claims_clean c
INNER JOIN dbo.members_clean m
    ON c.member_id = m.member_id;

/* 16. INNER JOIN: Claims with provider details */
SELECT TOP 20
    c.claim_id,
    p.provider_name,
    p.specialty,
    c.paid_amount
FROM dbo.claims_clean c
INNER JOIN dbo.providers_clean p
    ON c.provider_id = p.provider_id;

/* 17. LEFT JOIN: Members without claims */
SELECT m.member_id, m.plan_type
FROM dbo.members_clean m
LEFT JOIN dbo.claims_clean c
    ON m.member_id = c.member_id
WHERE c.claim_id IS NULL;

/* 18. RIGHT JOIN: Providers and claims relationship */
SELECT TOP 20
    p.provider_id,
    p.provider_name,
    c.claim_id,
    c.paid_amount
FROM dbo.claims_clean c
RIGHT JOIN dbo.providers_clean p
    ON c.provider_id = p.provider_id;

/* 19. FULL OUTER JOIN: Member and claims data completeness check */
SELECT TOP 20
    m.member_id,
    c.claim_id
FROM dbo.members_clean m
FULL OUTER JOIN dbo.claims_clean c
    ON m.member_id = c.member_id;

/* 20. CROSS JOIN: Plan type and specialty combinations */
SELECT DISTINCT
    m.plan_type,
    p.specialty
FROM dbo.members_clean m
CROSS JOIN dbo.providers_clean p;

/* 21. SELF JOIN: Providers in same county and specialty */
SELECT TOP 20
    p1.provider_id AS provider_1,
    p2.provider_id AS provider_2,
    p1.specialty,
    p1.county
FROM dbo.providers_clean p1
JOIN dbo.providers_clean p2
    ON p1.specialty = p2.specialty
   AND p1.county = p2.county
   AND p1.provider_id <> p2.provider_id;

/* 22. COMPOSITE JOIN EXAMPLE: Same county provider/member analysis */
SELECT TOP 20
    m.member_id,
    p.provider_id,
    m.county,
    p.specialty
FROM dbo.members_clean m
JOIN dbo.providers_clean p
    ON m.county = p.county;

/* 23. UNION: Combine member and provider counties */
SELECT county
FROM dbo.members_clean
UNION
SELECT county
FROM dbo.providers_clean;

/* 24. UNION ALL: Combine all member/provider counties including duplicates */
SELECT county
FROM dbo.members_clean
UNION ALL
SELECT county
FROM dbo.providers_clean;

/* 25. INTERSECT: Counties having both members and providers */
SELECT county
FROM dbo.members_clean
INTERSECT
SELECT county
FROM dbo.providers_clean;

/* 26. EXCEPT: Member counties without providers */
SELECT county
FROM dbo.members_clean
EXCEPT
SELECT county
FROM dbo.providers_clean;

/* 27. SCALAR CONCAT: Create member plan label */
SELECT TOP 20
    member_id,
    CONCAT(member_id, ' - ', plan_type, ' - ', county) AS member_plan_label
FROM dbo.members_clean;

/* 28. CASE: Claim cost category */
SELECT TOP 20
    claim_id,
    paid_amount,
    CASE
        WHEN paid_amount >= 4000 THEN 'High Cost Claim'
        WHEN paid_amount BETWEEN 1000 AND 3999 THEN 'Medium Cost Claim'
        ELSE 'Low Cost Claim'
    END AS claim_cost_category
FROM dbo.claims_clean;

/* 29. DATE FUNCTION: Current report date */
SELECT 
    GETDATE() AS report_run_datetime,
    YEAR(GETDATE()) AS report_year,
    MONTH(GETDATE()) AS report_month;

/* 30. CONVERSION: Convert paid amount into decimal */
SELECT TOP 20
    claim_id,
    CAST(paid_amount AS DECIMAL(12,2)) AS paid_amount_decimal
FROM dbo.claims_clean;

/* 31. SUBQUERY: Members above average total spend */
SELECT member_id, SUM(paid_amount) AS total_paid
FROM dbo.claims_clean
GROUP BY member_id
HAVING SUM(paid_amount) >
(
    SELECT AVG(member_total)
    FROM (
        SELECT member_id, SUM(paid_amount) AS member_total
        FROM dbo.claims_clean
        GROUP BY member_id
    ) x
);

/* 32. CORRELATED SUBQUERY: Claims above provider average */
SELECT c.claim_id, c.provider_id, c.paid_amount
FROM dbo.claims_clean c
WHERE c.paid_amount >
(
    SELECT AVG(c2.paid_amount)
    FROM dbo.claims_clean c2
    WHERE c2.provider_id = c.provider_id
);

/* 33. EXISTS: Members with denied claims */
SELECT m.member_id, m.plan_type
FROM dbo.members_clean m
WHERE EXISTS
(
    SELECT 1
    FROM dbo.claims_clean c
    WHERE c.member_id = m.member_id
      AND c.claim_status = 'Denied'
);

/* 34. CTE: Total spend by member */
WITH member_spend AS
(
    SELECT member_id, SUM(paid_amount) AS total_paid
    FROM dbo.claims_clean
    GROUP BY member_id
)
SELECT TOP 10 *
FROM member_spend
ORDER BY total_paid DESC;

/* 35. CTE: PMPM-style cost by plan */
WITH plan_spend AS
(
    SELECT 
        m.plan_type,
        COUNT(DISTINCT m.member_id) AS total_members,
        SUM(c.paid_amount) AS total_paid
    FROM dbo.members_clean m
    JOIN dbo.claims_clean c
        ON m.member_id = c.member_id
    GROUP BY m.plan_type
)
SELECT 
    plan_type,
    total_paid,
    total_members,
    total_paid / total_members AS cost_per_member
FROM plan_spend;

/* 36. ROW_NUMBER: Detect duplicate claim IDs */
SELECT *
FROM
(
    SELECT 
        claim_id,
        ROW_NUMBER() OVER(PARTITION BY claim_id ORDER BY claim_id) AS row_num
    FROM dbo.claims_clean
) x
WHERE row_num > 1;

/* 37. RANK: Rank members by medical spend */
SELECT 
    member_id,
    SUM(paid_amount) AS total_paid,
    RANK() OVER(ORDER BY SUM(paid_amount) DESC) AS spend_rank
FROM dbo.claims_clean
GROUP BY member_id;

/* 38. DENSE_RANK: Rank providers by total paid amount */
SELECT 
    provider_id,
    SUM(paid_amount) AS total_paid,
    DENSE_RANK() OVER(ORDER BY SUM(paid_amount) DESC) AS provider_rank
FROM dbo.claims_clean
GROUP BY provider_id;

/* 39. NTILE: Top 5% high-cost members */
WITH member_spend AS
(
    SELECT member_id, SUM(paid_amount) AS total_paid
    FROM dbo.claims_clean
    GROUP BY member_id
),
ranked_members AS
(
    SELECT *,
           NTILE(20) OVER(ORDER BY total_paid DESC) AS spend_bucket
    FROM member_spend
)
SELECT *
FROM ranked_members
WHERE spend_bucket = 1;

/* 40. WINDOW FUNCTION: Provider specialty benchmark */
WITH provider_avg AS
(
    SELECT 
        c.provider_id,
        p.specialty,
        AVG(c.paid_amount) AS provider_avg_paid
    FROM dbo.claims_clean c
    JOIN dbo.providers_clean p
        ON c.provider_id = p.provider_id
    GROUP BY c.provider_id, p.specialty
),
specialty_avg AS
(
    SELECT 
        p.specialty,
        AVG(c.paid_amount) AS specialty_avg_paid
    FROM dbo.claims_clean c
    JOIN dbo.providers_clean p
        ON c.provider_id = p.provider_id
    GROUP BY p.specialty
)
SELECT 
    pa.provider_id,
    pa.specialty,
    pa.provider_avg_paid,
    sa.specialty_avg_paid,
    pa.provider_avg_paid - sa.specialty_avg_paid AS variance_from_specialty_avg
FROM provider_avg pa
JOIN specialty_avg sa
    ON pa.specialty = sa.specialty
ORDER BY variance_from_specialty_avg DESC;

/* 41. DATA QUALITY: Orphan claims without valid member */
SELECT c.*
FROM dbo.claims_clean c
LEFT JOIN dbo.members_clean m
    ON c.member_id = m.member_id
WHERE m.member_id IS NULL;

/* 42. DATA QUALITY: Orphan claims without valid provider */
SELECT c.*
FROM dbo.claims_clean c
LEFT JOIN dbo.providers_clean p
    ON c.provider_id = p.provider_id
WHERE p.provider_id IS NULL;

/* 43. DATA QUALITY: Duplicate members */
SELECT member_id, COUNT(*) AS duplicate_count
FROM dbo.members_clean
GROUP BY member_id
HAVING COUNT(*) > 1;

/* 44. DATA QUALITY: Duplicate providers */
SELECT provider_id, COUNT(*) AS duplicate_count
FROM dbo.providers_clean
GROUP BY provider_id
HAVING COUNT(*) > 1;

/* 45. DATA QUALITY KPI: Claims integrity score */
SELECT
    100.0 *
    SUM(CASE 
            WHEN c.member_id IS NOT NULL 
             AND c.provider_id IS NOT NULL
             AND c.claim_id IS NOT NULL
            THEN 1 ELSE 0 
        END) / COUNT(*) AS claims_integrity_score
FROM dbo.claims_clean c;

/* 46. DDL: Create audit table for data quality issues */
CREATE TABLE dbo.data_quality_audit
(
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    issue_type VARCHAR(100),
    table_name VARCHAR(100),
    issue_count INT,
    audit_date DATETIME DEFAULT GETDATE()
);

/* 47. INSERT INTO AUDIT TABLE: Store duplicate claim issue count */
INSERT INTO dbo.data_quality_audit(issue_type, table_name, issue_count)
SELECT 
    'Duplicate Claim ID',
    'claims_clean',
    COUNT(*)
FROM
(
    SELECT claim_id
    FROM dbo.claims_clean
    GROUP BY claim_id
    HAVING COUNT(*) > 1
) x;

/* 48. ALTER TABLE / CHECK CONSTRAINT: Paid amount cannot be negative */
ALTER TABLE dbo.claims_clean
ADD CONSTRAINT chk_paid_amount_nonnegative
CHECK (paid_amount >= 0);

/* 49. UNIQUE CONCEPT: Unique claim ID constraint */
ALTER TABLE dbo.claims_clean
ADD CONSTRAINT uq_claim_id
UNIQUE (claim_id);

/* 50. INDEXING: Improve joins and KPI query performance */
CREATE INDEX idx_claims_member_id
ON dbo.claims_clean(member_id);

CREATE INDEX idx_claims_provider_id
ON dbo.claims_clean(provider_id);

CREATE INDEX idx_claims_status
ON dbo.claims_clean(claim_status);

/* 51. PRIMARY KEY: Member table primary key */
ALTER TABLE dbo.members_clean
ADD CONSTRAINT pk_members_clean
PRIMARY KEY (member_id);

/* 52. PRIMARY KEY: Provider table primary key */
ALTER TABLE dbo.providers_clean
ADD CONSTRAINT pk_providers_clean
PRIMARY KEY (provider_id);

/* 53. FOREIGN KEY: Claims to members */
ALTER TABLE dbo.claims_clean
ADD CONSTRAINT fk_claims_members
FOREIGN KEY (member_id)
REFERENCES dbo.members_clean(member_id);

/* 54. FOREIGN KEY: Claims to providers */
ALTER TABLE dbo.claims_clean
ADD CONSTRAINT fk_claims_providers
FOREIGN KEY (provider_id)
REFERENCES dbo.providers_clean(provider_id);

/* 55. STORED PROCEDURE: Executive KPI summary */

DROP PROCEDURE IF EXISTS dbo.sp_healthcare_executive_kpi_summary;
GO

CREATE PROCEDURE dbo.sp_healthcare_executive_kpi_summary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(DISTINCT claim_id) AS total_claims,
        COUNT(DISTINCT member_id) AS claiming_members,
        COUNT(DISTINCT provider_id) AS active_providers,
        SUM(claim_amount) AS total_billed_amount,
        SUM(paid_amount) AS total_paid_amount,
        AVG(paid_amount) AS avg_claim_cost,
        100.0 * SUM(CASE WHEN claim_status = 'Denied' THEN 1 ELSE 0 END) / COUNT(*) AS denial_rate,
        100.0 * SUM(CASE WHEN claim_status IN ('Paid', 'Denied') THEN 1 ELSE 0 END) / COUNT(*) AS adjudication_rate
    FROM dbo.claims_clean;
END;
GO

/* 56. EXECUTE STORED PROCEDURE */
EXEC dbo.sp_healthcare_executive_kpi_summary;

/* 57. DATABASE DESIGN: Candidate key / Super key check for members */
SELECT member_id, COUNT(*) AS record_count
FROM dbo.members_clean
GROUP BY member_id
HAVING COUNT(*) = 1;

/* 58. DATABASE DESIGN: Functional dependency check — member_id determines plan_type */
SELECT member_id, COUNT(DISTINCT plan_type) AS plan_type_count
FROM dbo.members_clean
GROUP BY member_id
HAVING COUNT(DISTINCT plan_type) > 1;

/* 59. DATABASE DESIGN: 1NF check — no blank key fields */
SELECT *
FROM dbo.claims_clean
WHERE claim_id IS NULL
   OR member_id IS NULL
   OR provider_id IS NULL;

/* 60. FINAL EXECUTIVE KPI DASHBOARD QUERY */
SELECT
    COUNT(DISTINCT c.claim_id) AS total_claims,
    COUNT(DISTINCT c.member_id) AS active_claim_members,
    COUNT(DISTINCT c.provider_id) AS active_providers,
    SUM(c.claim_amount) AS total_billed_amount,
    SUM(c.paid_amount) AS total_medical_spend,
    AVG(c.paid_amount) AS average_claim_cost,
    SUM(CASE WHEN c.claim_status = 'Paid' THEN 1 ELSE 0 END) AS paid_claims,
    SUM(CASE WHEN c.claim_status = 'Denied' THEN 1 ELSE 0 END) AS denied_claims,
    100.0 * SUM(CASE WHEN c.claim_status = 'Denied' THEN 1 ELSE 0 END) / COUNT(*) AS denial_rate,
    100.0 * SUM(CASE WHEN c.claim_status IN ('Paid', 'Denied') THEN 1 ELSE 0 END) / COUNT(*) AS claims_adjudication_rate
FROM dbo.claims_clean c;