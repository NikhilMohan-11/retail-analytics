--BP2.1 Business question: How many records and invoices are associated with cancellations, and what recorded sales value do they represent?

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE iscancellationinvoice = TRUE
    ) AS cancellation_invoice_rows,

    COUNT(DISTINCT invoice) FILTER (
        WHERE iscancellationinvoice = TRUE
    ) AS cancellation_invoices,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE iscancellationinvoice = TRUE
        )::numeric,
        2
    ) AS cancellation_invoice_recorded_value,

    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE quantity < 0
        )::numeric,
        2
    ) AS negative_quantity_recorded_value,

    COUNT(*) FILTER (
        WHERE iscancellationinvoice = TRUE
          AND quantity >= 0
    ) AS cancellation_invoice_rows_nonnegative_qty

FROM staging.retail_full;

--BP2.2 - months with the highest cancellation-associated recorded value and invoice counts.


SELECT
    DATE_TRUNC('month', invoicedate)::date AS cancellation_month,
    COUNT(*) AS cancellation_rows,
    COUNT(DISTINCT invoice) AS cancellation_invoices,
    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,
    ROUND(SUM(linevalue)::numeric, 2)
        AS cancellation_recorded_value
FROM staging.retail_full
WHERE iscancellationinvoice = TRUE
GROUP BY 1
ORDER BY 1;

--BP2.3 — Investigate the December 2011 outlier

SELECT
    invoice,
    invoicedate,
    stockcode,
    description,
    quantity,
    price,
    ROUND(linevalue::numeric, 2) AS recorded_line_value
FROM staging.retail_full
WHERE iscancellationinvoice = TRUE
  AND invoicedate >= DATE '2011-12-01'
  AND invoicedate <  DATE '2012-01-01'
ORDER BY linevalue ASC
LIMIT 15;

--BP2.4 - which products and countries account for the largest cancellation-associated recorded values?

WITH product_patterns AS (
    SELECT
        'PRODUCT' AS analysis_level,
        stockcode::text AS category,
        MAX(description) AS description,
        COUNT(*) AS cancellation_rows,
        COUNT(DISTINCT invoice) AS cancellation_invoices,
        ROUND(SUM(linevalue)::numeric, 2) AS recorded_value
    FROM staging.retail_full
    WHERE iscancellationinvoice = TRUE
      AND stockcode::text NOT IN (
          'DOT', 'POST', 'AMAZONFEE', 'CRUK', 'M'
      )
    GROUP BY stockcode
    ORDER BY SUM(linevalue) ASC
    LIMIT 10
),
country_patterns AS (
    SELECT
        'COUNTRY' AS analysis_level,
        country::text AS category,
        NULL::text AS description,
        COUNT(*) AS cancellation_rows,
        COUNT(DISTINCT invoice) AS cancellation_invoices,
        ROUND(SUM(linevalue)::numeric, 2) AS recorded_value
    FROM staging.retail_full
    WHERE iscancellationinvoice = TRUE
    GROUP BY country
    ORDER BY SUM(linevalue) ASC
    LIMIT 10
)
SELECT *
FROM product_patterns

UNION ALL

SELECT *
FROM country_patterns

ORDER BY analysis_level, recorded_value ASC;


SELECT
    stockcode::text AS stock_code,
    MAX(description) AS product_description,
    COUNT(*) AS cancellation_rows,
    COUNT(DISTINCT invoice) AS cancellation_invoices,
    ROUND(SUM(linevalue)::numeric, 2)
        AS cancellation_recorded_value
FROM staging.retail_full
WHERE iscancellationinvoice = TRUE
  AND stockcode::text NOT IN (
      'DOT', 'POST', 'AMAZONFEE', 'CRUK', 'M',
      'BANK CHARGES', 'D', 'S'
  )
GROUP BY stockcode
ORDER BY SUM(linevalue) ASC
LIMIT 10;


SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE iscancellationinvoice = TRUE
    ) AS cancellation_rows,

    COUNT(DISTINCT invoice) FILTER (
        WHERE iscancellationinvoice = TRUE
    ) AS cancellation_invoices,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE iscancellationinvoice = TRUE
        )::numeric, 2
    ) AS cancellation_recorded_value,

    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE quantity < 0
        )::numeric, 2
    ) AS negative_quantity_recorded_value,

    COUNT(*) FILTER (
        WHERE iscancellationinvoice = TRUE
          AND invoicedate >= DATE '2011-12-01'
          AND invoicedate < DATE '2012-01-01'
    ) AS december_2011_cancellation_rows,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE iscancellationinvoice = TRUE
              AND invoicedate >= DATE '2011-12-01'
              AND invoicedate < DATE '2012-01-01'
        )::numeric, 2
    ) AS december_2011_recorded_value,

    COUNT(*) FILTER (
        WHERE invoice = 'C581484'
          AND stockcode::text = '23843'
    ) AS exceptional_cancellation_lines,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE invoice = 'C581484'
              AND stockcode::text = '23843'
        )::numeric, 2
    ) AS exceptional_cancellation_value,

    ROUND(
        SUM(linevalue) FILTER (
            WHERE invoice = '581483'
              AND stockcode::text = '23843'
        )::numeric, 2
    ) AS original_sale_recorded_value

FROM staging.retail_full;
