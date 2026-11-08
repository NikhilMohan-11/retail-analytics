# BP2 — Cancellations and Revenue Adjustments

## 1. Business Problem

**Business Question:** How much recorded sales value is associated with cancellations, and which products, periods, and markets account for the largest cancellation values?

The objective of this analysis is to quantify recorded cancellation activity, identify patterns over time and across markets, investigate products with unusually large negative values, and assess the limitations of reconciling cancellation transactions with their original sales.

This analysis uses the existing retail transaction dataset in PostgreSQL. The source data is retained unchanged.

---

## 2. Analysis Objectives

The analysis aims to:

1. Quantify cancellation-invoice activity and its recorded line value.
2. Compare cancellation-invoice rows with transactions containing negative quantities.
3. Identify monthly patterns in cancellation counts and recorded values.
4. Identify countries contributing the largest recorded cancellation values.
5. Identify products with large negative values on cancellation invoices.
6. Investigate exceptional transactions and assess whether cancellation lines can be reliably matched to original sales.
7. Document data-quality limitations that affect the interpretation of cancellation and revenue figures.

---

## 3. Dataset and Scope

**Source table:** `staging.retail_full`

**Source dataset period:** 1 December 2009 to 9 December 2011.

| Data attribute | Value |
|---|---:|
| Total source rows | 1,067,371 |
| Cancellation-invoice rows | 19,494 |
| Distinct cancellation invoices | 8,292 |
| Rows with negative quantities | 22,950 |
| Cancellation-invoice recorded value | −£1,526,667.86 |
| Negative-quantity recorded value | −£1,527,041.43 |

The analysis uses the existing `iscancellationinvoice` flag to identify cancellation-invoice rows.

Recorded line value is calculated as:

`LineValue = Quantity × Price`

These values represent recorded transaction line values. They are not automatically equivalent to reconciled net revenue, cash refunds, or profit. The dataset does not provide the cost information required to calculate profit.

December 2011 is a partial month because the source data ends on 9 December 2011. Its figures must not be compared directly with complete months without accounting for this difference.

---

## 4. Business Question 1 — What Is the Overall Scale of Cancellation Activity?

The baseline validation returned the following results:

| Metric | Result |
|---|---:|
| Total source rows | 1,067,371 |
| Cancellation-invoice rows | 19,494 |
| Distinct cancellation invoices | 8,292 |
| Recorded value of cancellation-invoice rows | −£1,526,667.86 |
| Negative-quantity rows | 22,950 |
| Recorded value of negative-quantity rows | −£1,527,041.43 |
| Cancellation-invoice rows with nonnegative quantity | 1 |

### Findings

- The dataset contains 19,494 rows marked as cancellation-invoice rows across 8,292 distinct cancellation invoices.
- Their combined recorded line value is −£1,526,667.86.
- There are 22,950 rows with negative quantities, with a combined recorded line value of −£1,527,041.43.
- Cancellation-invoice rows and negative-quantity rows are not identical populations. The row counts and recorded values differ.
- The cancellation recorded value must not be added to the negative-quantity recorded value because the populations overlap and represent related transaction characteristics.

### Interpretation

These figures establish the scale of recorded cancellation activity. They do not, by themselves, establish the final financial impact of cancellations after matching original transactions, nor do they establish the amount of revenue permanently lost.

---

## 5. Business Question 2 — How Does Cancellation Activity Change Over Time?

Monthly cancellation activity was analysed using cancellation-invoice rows grouped by invoice month.

The analysis examined cancellation row counts, distinct cancellation invoices, negative-quantity rows, and recorded line value.

### Monthly Results

| Month | Cancellation rows | Cancellation invoices | Negative-quantity rows | Recorded value (£) |
|---|---:|---:|---:|---:|
| Dec 2009 | 1,015 | 401 | 1,015 | −25,838.65 |
| Jan 2010 | 686 | 300 | 686 | −28,675.61 |
| Feb 2010 | 576 | 240 | 575 | −20,248.31 |
| Mar 2010 | 844 | 407 | 844 | −67,721.37 |
| Apr 2010 | 626 | 304 | 626 | −37,354.20 |
| May 2010 | 983 | 407 | 983 | −44,536.03 |
| Jun 2010 | 793 | 357 | 793 | −72,483.53 |
| Jul 2010 | 734 | 344 | 734 | −31,444.79 |
| Aug 2010 | 573 | 273 | 573 | −40,498.57 |
| Sep 2010 | 812 | 371 | 812 | −70,682.58 |
| Oct 2010 | 1,041 | 476 | 1,041 | −81,389.69 |
| Nov 2010 | 1,194 | 576 | 1,194 | −47,617.84 |
| Dec 2010 | 1,057 | 326 | 1,057 | −136,153.32 |
| Jan 2011 | 701 | 260 | 701 | −131,364.30 |
| Feb 2011 | 475 | 219 | 475 | −25,569.24 |
| Mar 2011 | 699 | 318 | 699 | −34,372.28 |
| Apr 2011 | 559 | 240 | 559 | −44,601.50 |
| May 2011 | 621 | 314 | 621 | −47,202.51 |
| Jun 2011 | 711 | 329 | 711 | −70,616.78 |
| Jul 2011 | 685 | 270 | 685 | −37,921.08 |
| Aug 2011 | 668 | 278 | 668 | −54,333.75 |
| Sep 2011 | 805 | 333 | 805 | −38,902.55 |
| Oct 2011 | 1,200 | 362 | 1,200 | −84,274.63 |
| Nov 2011 | 1,076 | 441 | 1,076 | −47,740.08 |
| Dec 2011* | 360 | 146 | 360 | −205,124.67 |

*December 2011 covers only the available period through 9 December.*

### Findings

- October 2011 had the highest monthly cancellation row count in the observed period, with 1,200 rows.
- October 2010 had 1,041 cancellation rows across 476 cancellation invoices.
- December 2010 recorded a negative line value of £136,153.32.
- January 2011 recorded a negative line value of £131,364.30.
- December 2011 recorded the largest negative monthly value, at £205,124.67, despite containing only 360 cancellation rows.
- The December 2011 result is heavily affected by one exceptional transaction investigated in Section 7.

### Interpretation

Cancellation row counts and recorded values do not always move together. A relatively small number of unusually large transaction values can materially affect a month's total.

The December 2011 result should not be interpreted as evidence of a general deterioration in cancellation performance. It requires transaction-level context, and the month is incomplete.

---

## 6. Business Question 3 — Which Countries Have the Largest Recorded Cancellation Values?

Country-level cancellation activity was aggregated using rows marked as cancellation invoices.

### Top Countries by Absolute Recorded Cancellation Value

| Country | Cancellation rows | Cancellation invoices | Recorded value (£) |
|---|---:|---:|---:|
| United Kingdom | 16,650 | 7,315 | −1,329,717.74 |
| EIRE | 512 | 180 | −48,912.23 |
| France | 389 | 124 | −28,752.80 |
| Norway | 18 | 8 | −20,866.59 |
| Spain | 91 | 34 | −17,319.05 |
| Germany | 921 | 306 | −13,273.90 |
| Singapore | 7 | 3 | −12,158.90 |
| Hong Kong | 6 | 6 | −9,855.02 |
| Netherlands | 47 | 21 | −5,707.39 |
| Portugal | 58 | 29 | −4,879.85 |

### Findings

- The United Kingdom recorded the largest cancellation-invoice value by a substantial margin.
- Its recorded cancellation value was −£1,329,717.74, approximately 87.1% of the overall cancellation-invoice recorded value of −£1,526,667.86.
- EIRE and France followed in the country ranking.
- Some countries have relatively few cancellation rows but comparatively large negative recorded values.

### Interpretation and Limitation

These are absolute recorded values, not cancellation rates.

The United Kingdom's large value may partly reflect its greater share of overall transaction activity. Without comparing cancellation activity against each country's eligible sales, invoice counts, or other suitable denominator, the analysis cannot conclude that the United Kingdom has a higher cancellation rate or worse cancellation performance.

The country ranking also depends on the transaction types included in the cancellation totals. Service charges, fees, and other non-merchandise adjustments can affect the results.

---

## 7. Business Question 4 — Which Products Have the Largest Recorded Cancellation Values?

A product-level ranking was produced from cancellation-invoice rows after excluding the known codes `DOT`, `POST`, `AMAZONFEE`, `CRUK`, `M`, `BANK CHARGES`, `D`, and `S`.

These exclusions reduce the effect of known postage, fee, discount, sample, and other adjustment entries. They do not guarantee that every remaining row represents an ordinary merchandise cancellation.

### Top Products by Absolute Recorded Cancellation Value

| Stock code | Product description | Cancellation rows | Cancellation invoices | Recorded value (£) |
|---|---|---:|---:|---:|
| 23843 | PAPER CRAFT, LITTLE BIRDIE | 1 | 1 | −168,469.60 |
| 23166 | MEDIUM CERAMIC TOP STORAGE JAR | 10 | 10 | −77,479.64 |
| 22423 | REGENCY CAKESTAND 3 TIER | 347 | 341 | −16,749.60 |
| 85123A | WHITE HANGING HEART T-LIGHT HOLDER | 135 | 134 | −9,389.65 |
| 71477 | COLOURED GLASS STAR T-LIGHT HOLDER | 70 | 67 | −7,173.87 |
| 21108 | FAIRY CAKE FLANNEL ASSORTED COLOUR | 4 | 4 | −6,614.37 |
| 79323W | WHITE CHERRY LIGHTS | 126 | 124 | −6,421.10 |
| 21843 | RETRO SPOT CAKE STAND | 159 | 154 | −5,401.60 |
| 84078A | SET/4 WHITE RETRO STORAGE CUBES | 20 | 20 | −5,187.65 |
| 23113 | PANTRY CHOPPING BOARD | 6 | 6 | −4,803.06 |

### Findings

- Stock code 23843 has the largest recorded negative value, but it is represented by only one cancellation line. Its exceptional value is investigated separately below.
- Stock code 23166 has a recorded cancellation value of −£77,479.64 across 10 rows and 10 invoices. This is a candidate for further transaction-level review.
- Stock code 22423 has 347 cancellation rows across 341 invoices, with a combined recorded value of −£16,749.60.
- Other listed products have smaller aggregate negative values but may warrant investigation depending on their sales volumes and transaction history.

### Interpretation

A product's absolute cancellation value does not establish that it has an unusually high cancellation rate. To assess relative cancellation performance, cancellation values or quantities should be compared against eligible sales for the same products and period.

This ranking describes the recorded values on cancellation invoices. It is not a calculation of the net financial impact after matching original sales.

---

## 8. Exceptional Transaction Investigation — Stock Code 23843

The largest cancellation line in the analysis was investigated at transaction level.

| Attribute | Original sale | Cancellation |
|---|---|---|
| Invoice | 581483 | C581484 |
| Date | 9 December 2011 | 9 December 2011 |
| Time | 09:15 | 09:27 |
| Stock code | 23843 | 23843 |
| Product | PAPER CRAFT, LITTLE BIRDIE | PAPER CRAFT, LITTLE BIRDIE |
| Quantity | 80,995 | −80,995 |
| Price | £2.08 | £2.08 |
| Recorded line value | +£168,469.60 | −£168,469.60 |

### Findings

- The original sale and cancellation have the same stock code and price.
- Their quantities are equal in absolute terms but opposite in sign.
- Their recorded line values exactly offset each other.
- The cancellation was recorded 12 minutes after the original sale.
- The cancellation value of £168,469.60 accounts for approximately 82.1% of December 2011's total negative recorded cancellation value of £205,124.67.

### Interpretation

This is strong evidence that the cancellation represents a reversal of the original transaction. It demonstrates why unusually large cancellation entries should be investigated before drawing conclusions from monthly or product-level totals.

The transaction is a verified example of an exact value offset. It should not be used as proof that all cancellation entries can be matched in the same way.

---

## 9. Cancellation Matching and Reconciliation Limitations

A matching investigation was conducted to assess whether cancellation lines could be linked to original sales using available transaction attributes, including stock code, absolute quantity, price, and a 24-hour time window.

The investigation produced the following diagnostics:

| Matching diagnostic | Result |
|---|---:|
| Candidate original-sale/cancellation pairs | 6,656 |
| Original lines with at least one candidate match | 6,079 |
| Original lines with multiple candidate matches | 496 |
| Cancellation lines with at least one candidate match | 4,370 |
| Cancellation lines with multiple candidate matches | 1,457 |

### What These Results Mean

- A candidate match is not necessarily a confirmed match.
- Multiple candidate matches make it unclear which original transaction a cancellation belongs to.
- Stock code, quantity, price, and temporal proximity can help identify possible matches, but they do not always uniquely identify the original transaction.
- Automatically subtracting every candidate cancellation from an original sale could produce incorrect adjustments.
- Treating every negative line as a confirmed cancellation of a specific original sale could also misstate the financial impact.

### Decision

The analysis does not attempt to force ambiguous matches into a fully reconciled net-revenue figure.

Instead:

1. The source transaction data remains unchanged.
2. Cancellation activity is reported separately.
3. The exceptional stock code 23843 transaction is documented as a specific, strongly supported reversal.
4. Ambiguous candidate matches are not treated as confirmed matches.
5. Cancellation recorded values are not described as definitively lost revenue, refunds paid, or reconciled net-revenue adjustments.

### What Would Improve Reconciliation?

More reliable reconciliation would require stronger transaction identifiers or additional business rules that establish how each cancellation relates to its original sale. Those rules would need to be validated before applying automated adjustments across the dataset.

---

## 10. Data Quality and Analytical Considerations

The following considerations affect the interpretation of BP2:

- **Cancellation flags and negative quantities are different criteria.** Their populations should be analysed separately rather than assumed to be interchangeable.
- **Recorded line value is not automatically net revenue.** The effect of a cancellation depends on its relationship to the original transaction and the business's accounting rules.
- **Exceptional values can dominate aggregates.** The stock code 23843 reversal materially affects December 2011's recorded cancellation value.
- **Country and product totals are not rates.** Rankings based on absolute values do not establish relative cancellation performance without suitable denominators.
- **Known non-merchandise codes were excluded from the product ranking.** This reduces certain known sources of distortion but does not prove that every remaining code is a standard merchandise item.
- **December 2011 is incomplete.** Its monthly totals should not be compared directly with full months.
- **Ambiguous transaction matches remain unresolved.** The analysis does not claim complete cancellation reconciliation.
- **The source table was not altered.** Analysis and matching diagnostics were performed without deleting or rewriting source transactions.

---

## 11. Reproducible SQL Analysis

The following queries reproduce the main BP2 aggregations. They use the existing source table and column names.

### Query 1 — Cancellation Baseline

```sql
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
          AND quantity >= 0
    ) AS cancellation_rows_with_nonnegative_quantity

FROM staging.retail_full;
```

### Query 2 — Monthly Cancellation Profile

```sql
SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,
    COUNT(*) AS cancellation_rows,
    COUNT(DISTINCT invoice) AS cancellation_invoices,
    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,
    ROUND(SUM(linevalue)::numeric, 2)
        AS cancellation_recorded_value

FROM staging.retail_full

WHERE iscancellationinvoice = TRUE

GROUP BY DATE_TRUNC('month', invoicedate)::date

ORDER BY month;
```

### Query 3 — Largest Cancellation Lines in December 2011

```sql
SELECT
    invoice,
    invoicedate,
    stockcode,
    description,
    quantity,
    price,
    linevalue

FROM staging.retail_full

WHERE iscancellationinvoice = TRUE
  AND invoicedate >= DATE '2011-12-01'
  AND invoicedate < DATE '2012-01-01'

ORDER BY linevalue ASC

LIMIT 15;
```

### Query 4 — Top Countries by Recorded Cancellation Value

```sql
SELECT
    country,
    COUNT(*) AS cancellation_rows,
    COUNT(DISTINCT invoice) AS cancellation_invoices,
    ROUND(SUM(linevalue)::numeric, 2)
        AS cancellation_recorded_value

FROM staging.retail_full

WHERE iscancellationinvoice = TRUE

GROUP BY country

ORDER BY SUM(linevalue) ASC

LIMIT 10;
```

### Query 5 — Top Products by Recorded Cancellation Value

```sql
SELECT
    stockcode,
    description,
    COUNT(*) AS cancellation_rows,
    COUNT(DISTINCT invoice) AS cancellation_invoices,
    ROUND(SUM(linevalue)::numeric, 2)
        AS cancellation_recorded_value

FROM staging.retail_full

WHERE iscancellationinvoice = TRUE
  AND stockcode::text NOT IN (
      'DOT',
      'POST',
      'AMAZONFEE',
      'CRUK',
      'M',
      'BANK CHARGES',
      'D',
      'S'
  )

GROUP BY stockcode, description

ORDER BY SUM(linevalue) ASC

LIMIT 10;
```

### Query 6 — Final Validation

```sql
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
```

The final validation returned 1,067,371 total rows, 19,494 cancellation rows, 8,292 distinct cancellation invoices, cancellation recorded value of −£1,526,667.86, 22,950 negative-quantity rows, negative-quantity recorded value of −£1,527,041.43, 360 December 2011 cancellation rows, December recorded value of −£205,124.67, one exceptional cancellation line valued at −£168,469.60, and the corresponding original sale valued at +£168,469.60.

---

## 12. Final Business Findings

### Q1 — What is the scale of cancellation activity?

The dataset contains 19,494 cancellation-invoice rows across 8,292 distinct cancellation invoices, with a combined recorded line value of −£1,526,667.86. Negative-quantity rows form a different population and should not be treated as interchangeable with cancellation-invoice rows.

### Q2 — How does cancellation activity change over time?

October 2011 had the highest monthly cancellation row count at 1,200. December 2011 had the largest negative recorded value at −£205,124.67, but the result was heavily influenced by one exceptional reversal and covers only the first nine days of the month.

### Q3 — Which countries contribute the largest recorded cancellation values?

The United Kingdom accounted for −£1,329,717.74, approximately 87.1% of the total cancellation-invoice recorded value. This is an absolute-value comparison, not evidence that the United Kingdom has the highest cancellation rate.

### Q4 — Which products warrant further investigation?

Stock code 23843 had a cancellation value of −£168,469.60 that exactly offset a corresponding original sale. Stock code 23166 had a recorded cancellation value of −£77,479.64 across 10 cancellation rows. These products illustrate the value of transaction-level investigation before interpreting aggregate cancellation values.

### Q5 — Has all cancellation activity been reconciled against original sales?

No. Matching diagnostics identified ambiguous candidate matches. The analysis therefore reports cancellation activity separately and does not claim a complete net-revenue reconciliation.

---

## 13. Conclusion and Project Status

BP2 established a validated baseline of recorded cancellation activity, examined monthly patterns, identified the countries and products with the largest negative recorded values, and investigated an exceptional transaction with an exact original-sale reversal.

The analysis also identified a material limitation: available transaction attributes do not uniquely match every cancellation to an original sale. This limitation is documented rather than concealed by applying uncertain adjustments.

**BP2 status:** Core cancellation analysis and final validation completed. Full transaction-level reconciliation remains unresolved and is outside the conclusions supported by the current analysis.

The next business problem is **BP3 — Customer Retention and Cohort Analysis**, which will investigate whether customers return after their first purchase and how repeat-purchase behaviour changes across customer cohorts.