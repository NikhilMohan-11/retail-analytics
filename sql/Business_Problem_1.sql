-- BP1 — Revenue and Sales Performance Analysis

-- ============================================================
-- 1. SOURCE DATA VALIDATION
-- ============================================================

-- 1.1 Overall dataset size, date range and basic completeness

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice) AS distinct_invoice_numbers,
    COUNT(DISTINCT customer_id) AS distinct_nonnull_customers,
    COUNT(DISTINCT stockcode) AS distinct_stock_codes,
    MIN(invoicedate) AS first_transaction_date,
    MAX(invoicedate) AS last_transaction_date,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id_rows,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_description_rows,
    COUNT(*) FILTER (WHERE isexactduplicatecandidate) AS duplicate_candidate_rows,
    ROUND(SUM(linevalue), 2) AS total_recorded_line_value
FROM staging.retail_full;


-- 1.2 Transaction classification summary

SELECT
    transactiontype,
    COUNT(*) AS row_count,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    ROUND(SUM(linevalue), 2) AS recorded_line_value
FROM staging.retail_full
GROUP BY transactiontype
ORDER BY row_count DESC;


-- 1.3 Validate the merchandise-analysis population

SELECT
    COUNT(*) AS merchandise_rows,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    ROUND(SUM(linevalue), 2) AS recorded_line_value,
    COUNT(*) FILTER (WHERE iscancellationinvoice) AS cancellation_rows,
    COUNT(*) FILTER (WHERE isnegativequantity) AS negative_quantity_rows
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE;


-- 1.4 Data-quality flags

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE iscancellationinvoice) AS cancellation_invoice_rows,
    COUNT(*) FILTER (WHERE isnegativequantity) AS negative_quantity_rows,
    COUNT(*) FILTER (WHERE iszeroprice) AS zero_price_rows,
    COUNT(*) FILTER (WHERE isnegativeprice) AS negative_price_rows,
    COUNT(*) FILTER (WHERE missingcustomerid) AS missing_customer_id_rows,
    COUNT(*) FILTER (WHERE missingdescription) AS missing_description_rows,
    COUNT(*) FILTER (WHERE isexactduplicatecandidate) AS duplicate_candidate_rows,
    COUNT(*) FILTER (WHERE isspecialdescription) AS special_description_rows,
    COUNT(*) FILTER (WHERE requires_review) AS rows_requiring_review
FROM staging.retail_full;


-- ============================================================
-- 2. OVERALL RECORDED SALES PERFORMANCE
-- ============================================================

-- 2.1 Overall merchandise-candidate performance

SELECT
    COUNT(*) AS merchandise_rows,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value,
    ROUND(AVG(linevalue), 2) AS average_line_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE;


-- 2.2 Compare full-table and merchandise-candidate totals

SELECT
    'Full source table' AS population,
    COUNT(*) AS row_count,
    COUNT(DISTINCT invoice) AS invoice_count,
    ROUND(SUM(linevalue), 2) AS recorded_value
FROM staging.retail_full

UNION ALL

SELECT
    'Merchandise-analysis population' AS population,
    COUNT(*) AS row_count,
    COUNT(DISTINCT invoice) AS invoice_count,
    ROUND(SUM(linevalue), 2) AS recorded_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE;


-- ============================================================
-- 3. MONTHLY SALES TREND
-- ============================================================

-- 3.1 Monthly recorded sales value, invoices and quantity

SELECT
    DATE_TRUNC('month', invoicedate)::date AS sales_month,
    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY sales_month;


-- 3.2 Monthly sales with previous-month comparison

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate)::date AS sales_month,
        COUNT(DISTINCT invoice) AS distinct_invoices,
        ROUND(SUM(linevalue), 2) AS recorded_sales_value
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
    GROUP BY DATE_TRUNC('month', invoicedate)
),
monthly_comparison AS (
    SELECT
        sales_month,
        distinct_invoices,
        recorded_sales_value,
        LAG(recorded_sales_value) OVER (
            ORDER BY sales_month
        ) AS previous_month_value
    FROM monthly_sales
)
SELECT
    sales_month,
    distinct_invoices,
    recorded_sales_value,
    previous_month_value,
    ROUND(
        recorded_sales_value - previous_month_value,
        2
    ) AS month_over_month_change,
    ROUND(
        100.0 * (recorded_sales_value - previous_month_value)
        / NULLIF(previous_month_value, 0),
        2
    ) AS month_over_month_change_pct
FROM monthly_comparison
ORDER BY sales_month;


-- 3.3 Identify the highest-sales months

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate)::date AS sales_month,
        COUNT(DISTINCT invoice) AS distinct_invoices,
        ROUND(SUM(linevalue), 2) AS recorded_sales_value
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
    GROUP BY DATE_TRUNC('month', invoicedate)
)
SELECT
    sales_month,
    distinct_invoices,
    recorded_sales_value
FROM monthly_sales
ORDER BY recorded_sales_value DESC
LIMIT 10;


-- ============================================================
-- 4. YEAR-OVER-YEAR COMPARISON
-- ============================================================

-- 4.1 Compare 2010 and 2011 for January-November.
-- December is excluded because 2011 data ends on December 9.

WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM invoicedate)::int AS sales_year,
        EXTRACT(MONTH FROM invoicedate)::int AS sales_month,
        ROUND(SUM(linevalue), 2) AS recorded_sales_value,
        COUNT(DISTINCT invoice) AS distinct_invoices
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
      AND invoicedate >= DATE '2010-01-01'
      AND invoicedate < DATE '2011-12-01' + INTERVAL '1 year'
      AND EXTRACT(MONTH FROM invoicedate) BETWEEN 1 AND 11
      AND EXTRACT(YEAR FROM invoicedate) IN (2010, 2011)
    GROUP BY
        EXTRACT(YEAR FROM invoicedate),
        EXTRACT(MONTH FROM invoicedate)
),
year_comparison AS (
    SELECT
        sales_month,
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2010) AS sales_2010,
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2011) AS sales_2011,
        MAX(distinct_invoices)
            FILTER (WHERE sales_year = 2010) AS invoices_2010,
        MAX(distinct_invoices)
            FILTER (WHERE sales_year = 2011) AS invoices_2011
    FROM monthly_sales
    GROUP BY sales_month
)
SELECT
    sales_month,
    sales_2010,
    sales_2011,
    invoices_2010,
    invoices_2011,
    ROUND(sales_2011 - sales_2010, 2) AS yoy_value_change,
    ROUND(
        100.0 * (sales_2011 - sales_2010)
        / NULLIF(sales_2010, 0),
        2
    ) AS yoy_change_pct
FROM year_comparison
ORDER BY sales_month;


-- 4.2 Total January-November sales comparison

SELECT
    EXTRACT(YEAR FROM invoicedate)::int AS sales_year,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE
  AND invoicedate >= DATE '2010-01-01'
  AND invoicedate < DATE '2012-01-01'
  AND EXTRACT(MONTH FROM invoicedate) BETWEEN 1 AND 11
  AND EXTRACT(YEAR FROM invoicedate) IN (2010, 2011)
GROUP BY EXTRACT(YEAR FROM invoicedate)
ORDER BY sales_year;


-- ============================================================
-- 5. PRODUCT PERFORMANCE
-- ============================================================

-- 5.1 Top 20 products by recorded sales value.
-- Excludes common postage and service-related stock codes.
-- Review the exclusion list against the actual business definitions.

SELECT
    stockcode,
    MAX(description_clean) AS product_description,
    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE
  AND stockcode NOT IN (
      'DOT',
      'POST',
      'AMAZONFEE',
      'CRUK',
      'M',
      'BANK CHARGES',
      'D',
      'S'
  )
GROUP BY stockcode
ORDER BY recorded_sales_value DESC
LIMIT 20;


-- 5.2 Top products by quantity sold

SELECT
    stockcode,
    MAX(description_clean) AS product_description,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE
  AND stockcode NOT IN (
      'DOT',
      'POST',
      'AMAZONFEE',
      'CRUK',
      'M',
      'BANK CHARGES',
      'D',
      'S'
  )
GROUP BY stockcode
ORDER BY total_quantity DESC
LIMIT 20;


-- 5.3 Compare selected product performance:
-- January-November 2010 versus January-November 2011.

WITH product_year_sales AS (
    SELECT
        stockcode,
        MAX(description_clean) AS product_description,
        EXTRACT(YEAR FROM invoicedate)::int AS sales_year,
        ROUND(SUM(linevalue), 2) AS recorded_sales_value,
        SUM(quantity) AS total_quantity
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
      AND invoicedate >= DATE '2010-01-01'
      AND invoicedate < DATE '2011-12-01' + INTERVAL '1 year'
      AND EXTRACT(MONTH FROM invoicedate) BETWEEN 1 AND 11
      AND EXTRACT(YEAR FROM invoicedate) IN (2010, 2011)
      AND stockcode NOT IN (
          'DOT',
          'POST',
          'AMAZONFEE',
          'CRUK',
          'M',
          'BANK CHARGES',
          'D',
          'S'
      )
    GROUP BY
        stockcode,
        EXTRACT(YEAR FROM invoicedate)
),
product_comparison AS (
    SELECT
        stockcode,
        MAX(product_description) AS product_description,
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2010) AS sales_2010,
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2011) AS sales_2011,
        MAX(total_quantity)
            FILTER (WHERE sales_year = 2010) AS quantity_2010,
        MAX(total_quantity)
            FILTER (WHERE sales_year = 2011) AS quantity_2011
    FROM product_year_sales
    GROUP BY stockcode
)
SELECT
    stockcode,
    product_description,
    sales_2010,
    sales_2011,
    ROUND(sales_2011 - sales_2010, 2) AS value_change,
    ROUND(
        100.0 * (sales_2011 - sales_2010)
        / NULLIF(sales_2010, 0),
        2
    ) AS value_change_pct,
    quantity_2010,
    quantity_2011
FROM product_comparison
WHERE sales_2010 IS NOT NULL
  AND sales_2011 IS NOT NULL
ORDER BY sales_2011 DESC
LIMIT 20;


-- ============================================================
-- 6. COUNTRY-LEVEL RECORDED SALES
-- ============================================================

SELECT
    country,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE
GROUP BY country
ORDER BY recorded_sales_value DESC;


-- ============================================================
-- 7. INVESTIGATE EXCEPTIONAL STOCK CODE 23843
-- ============================================================

-- 7.1 Inspect every row for stock code 23843.

SELECT
    invoice,
    invoicedate,
    stockcode,
    description_clean,
    quantity,
    price,
    linevalue,
    transactiontype,
    iscancellationinvoice,
    isnegativequantity,
    include_merchandise_analysis
FROM staging.retail_full
WHERE stockcode = '23843'
ORDER BY invoicedate, invoice;


-- 7.2 Inspect the original invoice and the related cancellation.
-- These invoice numbers were identified during the BP1 investigation.

SELECT
    invoice,
    invoicedate,
    stockcode,
    description_clean,
    quantity,
    price,
    linevalue,
    transactiontype,
    iscancellationinvoice,
    isnegativequantity
FROM staging.retail_full
WHERE invoice IN ('581483', 'C581484')
  AND stockcode = '23843'
ORDER BY invoicedate;


-- 7.3 Compare the combined recorded value of these two invoices.

SELECT
    stockcode,
    COUNT(*) AS matching_rows,
    COUNT(DISTINCT invoice) AS invoice_count,
    SUM(quantity) AS net_recorded_quantity,
    ROUND(SUM(linevalue), 2) AS combined_recorded_value
FROM staging.retail_full
WHERE invoice IN ('581483', 'C581484')
  AND stockcode = '23843'
GROUP BY stockcode;


-- ============================================================
-- 8. DUPLICATE-CANDIDATE REVIEW
-- ============================================================

-- 8.1 Quantify flagged duplicate candidates.
-- The flag does not mean that every flagged row is safe to delete.

SELECT
    isexactduplicatecandidate,
    COUNT(*) AS row_count,
    ROUND(SUM(linevalue), 2) AS recorded_line_value
FROM staging.retail_full
GROUP BY isexactduplicatecandidate
ORDER BY isexactduplicatecandidate;


-- 8.2 Inspect flagged rows for manual review.

SELECT
    invoice,
    invoicedate,
    stockcode,
    description_clean,
    quantity,
    price,
    linevalue,
    customer_id,
    country,
    transactiontype
FROM staging.retail_full
WHERE isexactduplicatecandidate = TRUE
ORDER BY invoicedate, invoice
LIMIT 100;


-- ============================================================
-- 9. FINAL VALIDATION CHECKS
-- ============================================================

-- 9.1 Validate the core merchandise-analysis baseline.

SELECT
    COUNT(*) AS merchandise_rows,
    COUNT(DISTINCT invoice) AS distinct_invoices,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    ROUND(SUM(linevalue), 2) AS recorded_sales_value,
    COUNT(*) FILTER (WHERE iscancellationinvoice) AS cancellation_rows,
    COUNT(*) FILTER (WHERE isnegativequantity) AS negative_quantity_rows
FROM staging.retail_full
WHERE include_merchandise_analysis = TRUE;


-- 9.2 Reconcile the monthly totals to the overall merchandise total.
-- The difference should be zero, subject to rounding.

WITH overall_total AS (
    SELECT SUM(linevalue) AS overall_value
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
),
monthly_total AS (
    SELECT SUM(month_value) AS summed_monthly_value
    FROM (
        SELECT
            DATE_TRUNC('month', invoicedate) AS sales_month,
            SUM(linevalue) AS month_value
        FROM staging.retail_full
        WHERE include_merchandise_analysis = TRUE
        GROUP BY DATE_TRUNC('month', invoicedate)
    ) m
)
SELECT
    ROUND(o.overall_value, 2) AS overall_recorded_value,
    ROUND(m.summed_monthly_value, 2) AS summed_monthly_value,
    ROUND(o.overall_value - m.summed_monthly_value, 2) AS difference
FROM overall_total o
CROSS JOIN monthly_total m;


-- 9.3 Verify monthly YoY calculations independently.

WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM invoicedate)::int AS sales_year,
        EXTRACT(MONTH FROM invoicedate)::int AS sales_month,
        SUM(linevalue) AS recorded_sales_value
    FROM staging.retail_full
    WHERE include_merchandise_analysis = TRUE
      AND EXTRACT(YEAR FROM invoicedate) IN (2010, 2011)
      AND EXTRACT(MONTH FROM invoicedate) BETWEEN 1 AND 11
    GROUP BY
        EXTRACT(YEAR FROM invoicedate),
        EXTRACT(MONTH FROM invoicedate)
)
SELECT
    sales_month,
    ROUND(
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2010),
        2
    ) AS sales_2010,
    ROUND(
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2011),
        2
    ) AS sales_2011,
    ROUND(
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2011)
        -
        MAX(recorded_sales_value)
            FILTER (WHERE sales_year = 2010),
        2
    ) AS independently_calculated_change
FROM monthly_sales
GROUP BY sales_month
ORDER BY sales_month;


-- ============================================================
-- END OF BP1
-- ============================================================