--Customer Population Validation using the actual column names.
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE include_customer_analysis = TRUE
    ) AS customer_analysis_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NOT NULL
    ) AS rows_with_customer_id,

    COUNT(DISTINCT customer_id) FILTER (
        WHERE include_customer_analysis = TRUE
          AND customer_id IS NOT NULL
    ) AS eligible_unique_customers,

    COUNT(DISTINCT invoice) FILTER (
        WHERE include_customer_analysis = TRUE
          AND customer_id IS NOT NULL
    ) AS eligible_distinct_invoices,

    MIN(invoicedate) FILTER (
        WHERE include_customer_analysis = TRUE
          AND customer_id IS NOT NULL
    ) AS first_eligible_transaction,

    MAX(invoicedate) FILTER (
        WHERE include_customer_analysis = TRUE
          AND customer_id IS NOT NULL
    ) AS last_eligible_transaction

FROM staging.retail_full;

--Verify which transaction types are eligible

SELECT
    transactiontype,
    include_customer_analysis,
    COUNT(*) AS row_count,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) FILTER (
        WHERE iscancellationinvoice = TRUE
    ) AS cancellation_rows,
    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,
    ROUND(SUM(linevalue)::numeric, 2) AS recorded_line_value

FROM staging.retail_full

WHERE customer_id IS NOT NULL

GROUP BY
    transactiontype,
    include_customer_analysis

ORDER BY
    transactiontype,
    include_customer_analysis;

--Measure customer repeat purchasing

WITH customer_purchases AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS purchase_invoices,
        MIN(invoicedate) AS first_purchase_date,
        MAX(invoicedate) AS last_purchase_date,
        SUM(linevalue) AS recorded_merchandise_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE purchase_invoices = 1
    ) AS one_invoice_customers,

    COUNT(*) FILTER (
        WHERE purchase_invoices >= 2
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE purchase_invoices >= 2
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage,

    ROUND(
        AVG(purchase_invoices)::numeric,
        2
    ) AS average_invoices_per_customer,

    MAX(purchase_invoices) AS maximum_invoices_by_customer

FROM customer_purchases;

--Build the monthly customer cohorts

WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoicedate)::date AS activity_month
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
),

customer_cohorts AS (
    SELECT
        customer_id,
        MIN(activity_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
),

cohort_activity AS (
    SELECT
        c.cohort_month,
        m.activity_month,
        (
            (EXTRACT(YEAR FROM m.activity_month)
             - EXTRACT(YEAR FROM c.cohort_month)) * 12
            +
            (EXTRACT(MONTH FROM m.activity_month)
             - EXTRACT(MONTH FROM c.cohort_month))
        )::integer AS months_since_first_purchase,
        COUNT(DISTINCT m.customer_id) AS active_customers
    FROM customer_months m
    JOIN customer_cohorts c
      ON m.customer_id = c.customer_id
    GROUP BY
        c.cohort_month,
        m.activity_month
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)

SELECT
    a.cohort_month,
    a.months_since_first_purchase,
    s.cohort_customers,
    a.active_customers,
    ROUND(
        100.0 * a.active_customers
        / NULLIF(s.cohort_customers, 0),
        2
    ) AS retention_percentage
FROM cohort_activity a
JOIN cohort_sizes s
  ON a.cohort_month = s.cohort_month
WHERE a.months_since_first_purchase >= 0
ORDER BY
    a.cohort_month,
    a.months_since_first_purchase;

--Compare cohorts at equivalent ages

WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoicedate)::date AS activity_month
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
),

customer_cohorts AS (
    SELECT
        customer_id,
        MIN(activity_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
),

cohort_activity AS (
    SELECT
        c.cohort_month,
        (
            (EXTRACT(YEAR FROM m.activity_month)
             - EXTRACT(YEAR FROM c.cohort_month)) * 12
            +
            (EXTRACT(MONTH FROM m.activity_month)
             - EXTRACT(MONTH FROM c.cohort_month))
        )::integer AS months_since_first_purchase,
        COUNT(DISTINCT m.customer_id) AS active_customers
    FROM customer_months m
    JOIN customer_cohorts c
      ON m.customer_id = c.customer_id
    GROUP BY
        c.cohort_month,
        months_since_first_purchase
),

mature_cohort_activity AS (
    SELECT
        a.cohort_month,
        s.cohort_customers,

        MAX(a.active_customers) FILTER (
            WHERE a.months_since_first_purchase = 1
        ) AS month_1_active,

        MAX(a.active_customers) FILTER (
            WHERE a.months_since_first_purchase = 3
        ) AS month_3_active,

        MAX(a.active_customers) FILTER (
            WHERE a.months_since_first_purchase = 6
        ) AS month_6_active,

        MAX(a.active_customers) FILTER (
            WHERE a.months_since_first_purchase = 12
        ) AS month_12_active

    FROM cohort_activity a
    JOIN cohort_sizes s
      ON a.cohort_month = s.cohort_month

    WHERE a.cohort_month <= DATE '2010-11-01'

    GROUP BY
        a.cohort_month,
        s.cohort_customers
)

SELECT
    cohort_month,
    cohort_customers,

    month_1_active,
    ROUND(
        100.0 * month_1_active / cohort_customers,
        2
    ) AS month_1_retention_pct,

    month_3_active,
    ROUND(
        100.0 * month_3_active / cohort_customers,
        2
    ) AS month_3_retention_pct,

    month_6_active,
    ROUND(
        100.0 * month_6_active / cohort_customers,
        2
    ) AS month_6_retention_pct,

    month_12_active,
    ROUND(
        100.0 * month_12_active / cohort_customers,
        2
    ) AS month_12_retention_pct

FROM mature_cohort_activity
ORDER BY cohort_month;

--Validate the cohort calculations

WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoicedate)::date AS activity_month
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
),
customer_cohorts AS (
    SELECT
        customer_id,
        MIN(activity_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        (
            (EXTRACT(YEAR FROM m.activity_month)
             - EXTRACT(YEAR FROM c.cohort_month)) * 12
            +
            (EXTRACT(MONTH FROM m.activity_month)
             - EXTRACT(MONTH FROM c.cohort_month))
        )::integer AS months_since_first_purchase,
        COUNT(DISTINCT m.customer_id) AS active_customers
    FROM customer_months m
    JOIN customer_cohorts c
        ON m.customer_id = c.customer_id
    GROUP BY
        c.cohort_month,
        months_since_first_purchase
)
SELECT
    (SELECT COUNT(*) FROM customer_cohorts)
        AS total_eligible_customers,
    (SELECT SUM(cohort_customers) FROM cohort_sizes)
        AS summed_cohort_sizes,
    COUNT(*) FILTER (
        WHERE a.months_since_first_purchase = 0
          AND a.active_customers = s.cohort_customers
    ) AS cohorts_with_100pct_month0_retention,
    COUNT(*) FILTER (
        WHERE a.active_customers > s.cohort_customers
    ) AS activity_counts_exceeding_cohort_size,
    COUNT(*) FILTER (
        WHERE a.months_since_first_purchase = 0
          AND a.active_customers <> s.cohort_customers
    ) AS month0_retention_failures
FROM cohort_activity a
JOIN cohort_sizes s
    ON a.cohort_month = s.cohort_month;