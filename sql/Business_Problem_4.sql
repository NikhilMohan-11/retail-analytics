--Establish the RFM baseline

WITH customer_rfm_base AS (
    SELECT
        customer_id,
        MAX(invoicedate)::date AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    MIN(last_purchase_date) AS earliest_last_purchase_date,
    MAX(last_purchase_date) AS latest_last_purchase_date,
    ROUND(AVG(frequency), 2) AS average_invoice_frequency,
    MIN(frequency) AS minimum_invoice_frequency,
    MAX(frequency) AS maximum_invoice_frequency,
    ROUND(AVG(monetary_value), 2) AS average_monetary_value,
    ROUND(MIN(monetary_value), 2) AS minimum_monetary_value,
    ROUND(MAX(monetary_value), 2) AS maximum_monetary_value,
    ROUND(SUM(monetary_value), 2) AS total_recorded_monetary_value
FROM customer_rfm_base;

--Calculate the Recency distribution

WITH customer_rfm_base AS (
    SELECT
        customer_id,
        MAX(invoicedate)::date AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
reference_date AS (
    SELECT MAX(invoicedate)::date AS analysis_date
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
),
customer_rfm AS (
    SELECT
        c.customer_id,
        (r.analysis_date - c.last_purchase_date) AS recency_days,
        c.frequency,
        c.monetary_value
    FROM customer_rfm_base c
    CROSS JOIN reference_date r
)
SELECT
    COUNT(*) AS total_customers,
    MIN(recency_days) AS minimum_recency_days,
    ROUND(AVG(recency_days), 2) AS average_recency_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY recency_days
    ) AS recency_25th_percentile,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY recency_days
    ) AS recency_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY recency_days
    ) AS recency_75th_percentile,
    MAX(recency_days) AS maximum_recency_days
FROM customer_rfm;

--Examine the frequency and monetary distributions

WITH customer_rfm_base AS (
    SELECT
        customer_id,
        MAX(invoicedate)::date AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,

    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY frequency
    ) AS frequency_25th_percentile,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY frequency
    ) AS frequency_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY frequency
    ) AS frequency_75th_percentile,

    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY monetary_value
    ) AS monetary_25th_percentile,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY monetary_value
    ) AS monetary_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY monetary_value
    ) AS monetary_75th_percentile
FROM customer_rfm_base;

--Determine RFM scoring thresholds

WITH customer_rfm AS (
    SELECT
        customer_id,
        (
            DATE '2011-12-09' - MAX(invoicedate)::date
        ) AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    'Recency (days)' AS metric,
    PERCENTILE_CONT(0.20) WITHIN GROUP (
        ORDER BY recency_days
    ) AS p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (
        ORDER BY recency_days
    ) AS p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (
        ORDER BY recency_days
    ) AS p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (
        ORDER BY recency_days
    ) AS p80
FROM customer_rfm

UNION ALL

SELECT
    'Frequency (invoices)',
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY frequency),
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY frequency),
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY frequency),
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY frequency)
FROM customer_rfm

UNION ALL

SELECT
    'Monetary (£)',
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY monetary_value),
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY monetary_value),
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY monetary_value),
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY monetary_value)
FROM customer_rfm;

--Apply RFM scores and inspect score distribution

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATE '2011-12-09' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored_customers AS (
    SELECT
        customer_id,

        CASE
            WHEN recency_days <= 19 THEN 5
            WHEN recency_days <= 58 THEN 4
            WHEN recency_days <= 187 THEN 3
            WHEN recency_days <= 409 THEN 2
            ELSE 1
        END AS recency_score,

        CASE
            WHEN frequency <= 1 THEN 1
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 4 THEN 3
            WHEN frequency <= 8 THEN 4
            ELSE 5
        END AS frequency_score,

        CASE
            WHEN monetary_value <= 289.816 THEN 1
            WHEN monetary_value <= 616.214 THEN 2
            WHEN monetary_value <= 1246.104 THEN 3
            WHEN monetary_value <= 2956.236 THEN 4
            ELSE 5
        END AS monetary_score
    FROM customer_rfm
),
score_distribution AS (
    SELECT 'Recency' AS score_type, recency_score AS score, COUNT(*) AS customers
    FROM scored_customers
    GROUP BY recency_score

    UNION ALL

    SELECT 'Frequency', frequency_score, COUNT(*)
    FROM scored_customers
    GROUP BY frequency_score

    UNION ALL

    SELECT 'Monetary', monetary_score, COUNT(*)
    FROM scored_customers
    GROUP BY monetary_score
)
SELECT
    score_type,
    score,
    customers,
    ROUND(100.0 * customers / SUM(customers) OVER (
        PARTITION BY score_type
    ), 2) AS customer_percentage
FROM score_distribution
ORDER BY score_type, score;

--Create preliminary customer segments

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATE '2011-12-09' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored_customers AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,

        CASE
            WHEN recency_days <= 19 THEN 5
            WHEN recency_days <= 58 THEN 4
            WHEN recency_days <= 187 THEN 3
            WHEN recency_days <= 409 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency <= 1 THEN 1
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 4 THEN 3
            WHEN frequency <= 8 THEN 4
            ELSE 5
        END AS f_score,

        CASE
            WHEN monetary_value <= 289.816 THEN 1
            WHEN monetary_value <= 616.214 THEN 2
            WHEN monetary_value <= 1246.104 THEN 3
            WHEN monetary_value <= 2956.236 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_rfm
),
segmented_customers AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score IN (2, 3)
                THEN 'Potential Loyalists'
            WHEN r_score = 5 AND f_score = 1
                THEN 'Recent One-Time Customers'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating Customers'
            WHEN r_score <= 2 AND (f_score >= 4 OR m_score >= 4)
                THEN 'At-Risk Valuable Customers'
            ELSE 'Developing / Other Customers'
        END AS customer_segment
    FROM scored_customers
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)
        AS customer_percentage,
    ROUND(AVG(recency_days), 1) AS average_recency_days,
    ROUND(AVG(frequency), 2) AS average_invoice_frequency,
    ROUND(AVG(monetary_value), 2) AS average_monetary_value
FROM segmented_customers
GROUP BY customer_segment
ORDER BY customers DESC;

--Validate segment assignments

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATE '2011-12-09' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored_customers AS (
    SELECT
        *,
        CASE
            WHEN recency_days <= 19 THEN 5
            WHEN recency_days <= 58 THEN 4
            WHEN recency_days <= 187 THEN 3
            WHEN recency_days <= 409 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency <= 1 THEN 1
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 4 THEN 3
            WHEN frequency <= 8 THEN 4
            ELSE 5
        END AS f_score,
        CASE
            WHEN monetary_value <= 289.816 THEN 1
            WHEN monetary_value <= 616.214 THEN 2
            WHEN monetary_value <= 1246.104 THEN 3
            WHEN monetary_value <= 2956.236 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_rfm
),
segmented_customers AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score IN (2, 3)
                THEN 'Potential Loyalists'
            WHEN r_score = 5 AND f_score = 1
                THEN 'Recent One-Time Customers'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating Customers'
            WHEN r_score <= 2 AND (f_score >= 4 OR m_score >= 4)
                THEN 'At-Risk Valuable Customers'
            ELSE 'Developing / Other Customers'
        END AS customer_segment
    FROM scored_customers
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    COUNT(*) FILTER (
        WHERE f_score >= 4
    ) AS high_frequency_customers,
    COUNT(*) FILTER (
        WHERE m_score >= 4
    ) AS high_monetary_customers,
    COUNT(*) FILTER (
        WHERE f_score >= 4 AND m_score >= 4
    ) AS high_frequency_and_monetary_customers,
    COUNT(*) FILTER (
        WHERE r_score <= 2
    ) AS low_recency_score_customers
FROM segmented_customers
GROUP BY customer_segment
ORDER BY customers DESC;

--Finalize the segment logic

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATE '2011-12-09' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored AS (
    SELECT
        *,
        CASE
            WHEN recency_days <= 19 THEN 5
            WHEN recency_days <= 58 THEN 4
            WHEN recency_days <= 187 THEN 3
            WHEN recency_days <= 409 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency <= 1 THEN 1
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 4 THEN 3
            WHEN frequency <= 8 THEN 4
            ELSE 5
        END AS f_score,
        CASE
            WHEN monetary_value <= 289.816 THEN 1
            WHEN monetary_value <= 616.214 THEN 2
            WHEN monetary_value <= 1246.104 THEN 3
            WHEN monetary_value <= 2956.236 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_rfm
),
initial_segments AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score IN (2, 3)
                THEN 'Potential Loyalists'
            WHEN r_score = 5 AND f_score = 1
                THEN 'Recent One-Time Customers'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating Customers'
            WHEN r_score <= 2 AND (f_score >= 4 OR m_score >= 4)
                THEN 'At-Risk Valuable Customers'
            ELSE 'Developing / Other Customers'
        END AS customer_segment
    FROM scored
)
SELECT
    r_score,
    f_score,
    m_score,
    COUNT(*) AS customers,
    ROUND(AVG(recency_days), 1) AS average_recency_days,
    ROUND(AVG(frequency), 2) AS average_frequency,
    ROUND(AVG(monetary_value), 2) AS average_monetary_value
FROM initial_segments
WHERE customer_segment = 'Developing / Other Customers'
GROUP BY r_score, f_score, m_score
ORDER BY customers DESC;

--Validate the revised segment counts

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATE '2011-12-09' - MAX(invoicedate)::date AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(linevalue) AS monetary_value
    FROM staging.retail_full
    WHERE include_customer_analysis = TRUE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
scored AS (
    SELECT
        *,
        CASE
            WHEN recency_days <= 19 THEN 5
            WHEN recency_days <= 58 THEN 4
            WHEN recency_days <= 187 THEN 3
            WHEN recency_days <= 409 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency <= 1 THEN 1
            WHEN frequency <= 2 THEN 2
            WHEN frequency <= 4 THEN 3
            WHEN frequency <= 8 THEN 4
            ELSE 5
        END AS f_score,
        CASE
            WHEN monetary_value <= 289.816 THEN 1
            WHEN monetary_value <= 616.214 THEN 2
            WHEN monetary_value <= 1246.104 THEN 3
            WHEN monetary_value <= 2956.236 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score IN (2, 3)
                THEN 'Potential Loyalists'
            WHEN r_score = 5 AND f_score = 1
                THEN 'Recent One-Time Customers'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating Customers'
            WHEN r_score <= 2
                 AND (f_score >= 4 OR m_score >= 4)
                THEN 'At-Risk Valuable Customers'
            WHEN m_score >= 4 AND f_score <= 3
                THEN 'High-Monetary, Low-Frequency'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score <= 3
                THEN 'Active Low-Frequency Customers'
            ELSE 'Other Developing Customers'
        END AS customer_segment
    FROM scored
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)
        AS customer_percentage,
    ROUND(AVG(recency_days), 1) AS average_recency_days,
    ROUND(AVG(frequency), 2) AS average_invoice_frequency,
    ROUND(AVG(monetary_value), 2) AS average_monetary_value
FROM segmented
GROUP BY customer_segment
ORDER BY customers DESC;