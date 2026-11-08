# BP1 — Revenue and Sales Performance Analysis

## 1. Business Problem

**Business question:** How did sales performance change over time, and which products contributed most to the recorded sales value?

The objective of this analysis is to understand historical sales trends, identify high-performing and declining products, compare year-over-year performance, and generate actionable insights for business decision-making.

This analysis forms the first business problem in the Retail Revenue, Returns & Customer Retention Analytics portfolio project.

## 2. Business Objectives

- Establish the baseline size and quality of the transaction dataset.
- Measure overall recorded sales value, invoice activity and sales quantity.
- Analyse monthly sales trends and identify high-performing periods.
- Compare January–November sales performance between 2010 and 2011.
- Identify products with high recorded sales value and sales quantity.
- Compare selected products across the two years.
- Examine recorded sales value by country.
- Investigate exceptional transactions that could distort the sales analysis.
- Validate key totals and calculations before using the results in a dashboard.

## 3. Dataset and Scope

**Source table:** `staging.retail_full`

**Database:** `retail_analytics`

**SQL dialect:** PostgreSQL

The dataset contains online retail transaction records spanning December 2009 to December 2011.

### Dataset overview

| Metric | Result |
|---|---:|
| Total source rows | 1,067,371 |
| Merchandise-candidate rows | 1,040,749 |
| Customer-analysis-eligible rows | 804,808 |
| Distinct invoices in source data | 53,628 |
| Distinct identifiable customers in source data | 5,942 |
| Missing Customer ID rows | 243,007 |
| Missing Description rows | 4,382 |
| Exact duplicate candidates flagged | 34,335 |
| First transaction | 1 Dec 2009 |
| Last transaction | 9 Dec 2011 |

The source table contains positive sales, cancellations, negative quantities, zero-price records, missing customer identifiers and rows flagged for review. These characteristics must be considered when interpreting the results.

The existing `include_merchandise_analysis` flag was used to define the merchandise-candidate population for the core sales analysis.

## 4. Data Preparation and Definitions

### Recorded line value

The transaction line value is calculated as:

`LineValue = Quantity × Price`

The sum of line values is referred to as **recorded sales value** throughout this analysis.

It should not automatically be interpreted as profit or fully reconciled net revenue because the dataset does not include product costs and cancellation matching was not completely resolved.

### Merchandise-analysis population

The merchandise-candidate population consists of 1,040,749 rows, with a recorded line value of £20,586,257.81.

This population is used for the principal sales performance, monthly trend, product and country analyses.

### Duplicate candidates

A total of 34,335 rows were flagged as exact duplicate candidates. These records were retained in the source table.

The flag is a review indicator and does not establish that every flagged row is safe to delete. Removing records without validating their meaning could distort sales totals.

### Exceptional transactions

Transactions involving unusual quantities, cancellation invoices and non-merchandise codes were reviewed where relevant. The exceptional stock code 23843 was investigated separately because its transaction value was unusually large.

## 5. Overall Sales Performance

The merchandise-candidate population contains:

| Metric | Result |
|---|---:|
| Merchandise-candidate rows | 1,040,749 |
| Recorded sales value | £20,586,257.81 |

The full source table has a recorded line value of £19,287,250.57. This differs from the merchandise-candidate total because the two figures represent different transaction populations.

These totals establish the baseline for the subsequent time-series and product-level analysis.

**Interpretation:** Population definitions matter. The full-table total should not be compared with the merchandise-candidate total as though they represented the same set of transactions.

## 6. Monthly Sales Performance

Monthly recorded sales value and invoice activity were calculated by grouping eligible merchandise-candidate rows by calendar month.

The monthly analysis examined:

- Recorded sales value by month.
- Distinct invoices by month.
- Total recorded quantity.
- Month-over-month changes in recorded sales value.
- The highest-sales months across the observation period.

### Key findings

- Sales activity generally strengthened during the autumn period.
- November was the strongest month in both 2010 and 2011 among the reported monthly results.
- November 2010 recorded sales value was **£1,460,600.25**, across 2,739 invoices.
- November 2011 recorded sales value was **£1,506,153.91**, across 2,759 invoices.

November 2011 therefore recorded a higher sales value and more invoices than November 2010.

**Business interpretation:** The repeated November peak suggests a seasonal pattern worth investigating further. The analysis identifies an association with the calendar period but does not establish the cause of the increase.

## 7. Year-over-Year Sales Comparison

To make the annual comparison more meaningful, January–November 2010 was compared with January–November 2011. December was excluded because the 2011 dataset ends on 9 December and does not contain a complete month.

The comparison calculated:

- Monthly recorded sales value for each year.
- Absolute year-over-year change.
- Percentage year-over-year change.
- Distinct invoice counts for each month.

### Key findings

- Recorded sales value increased in **8 of the 11 comparable months**.
- September had the largest reported increase: **£169,272.02**, or **19.17%**.
- April had the largest reported decrease: **£130,427.41**, or **19.82%**.

**Business interpretation:** The year-over-year results indicate that the improvement was not uniform across the year. September showed particularly strong growth, while April showed a substantial decline.

These changes are useful indicators for further investigation into seasonal demand, product mix and order activity. The transaction data alone does not establish the underlying causes.

## 8. Product Performance Analysis

Products were ranked using recorded sales value and sales quantity.

Common postage and service-related stock codes, including `DOT` and `POST`, were excluded from product rankings. Other service-related codes were excluded from the relevant ranking queries as documented in the SQL script.

### Selected product comparison

January–November 2010 was compared with January–November 2011 for selected products.

| Product | 2010 recorded value | 2011 recorded value | Change |
|---|---:|---:|---:|
| Regency Cakestand 3 Tier | £156,599.53 | £140,607.91 | −10.21% |
| Party Bunting | £48,298.95 | £97,378.11 | +101.62% |
| White Hanging Heart Tea-Light Holder | £136,189.51 | £91,857.03 | −32.55% |
| Red Retrospot Jumbo Bag | £79,846.48 | £88,094.00 | +10.33% |
| Jam Making Set | £1,302.23 | £33,136.57 | Large increase from a low base |

### Key findings

**Party Bunting:** Recorded sales value more than doubled, increasing by 101.62%. This product warrants further investigation to understand whether the increase was driven by quantity, price, order frequency or other factors.

**Regency Cakestand 3 Tier:** Recorded sales value declined by 10.21%, indicating lower value compared with the equivalent months in 2010.

**White Hanging Heart Tea-Light Holder:** Recorded sales value declined by 32.55%, representing a substantial decrease among the selected products.

**Red Retrospot Jumbo Bag:** Recorded sales value increased by 10.33%, indicating a more moderate improvement.

**Jam Making Set:** Recorded sales value increased from £1,302.23 to £33,136.57. Because the earlier value was low, the percentage increase should be interpreted alongside the absolute values.

**Business interpretation:** Product performance differed considerably. Some products recorded strong increases while others declined. Comparing both absolute and percentage changes helps avoid overemphasising products with small starting values.

## 9. Country-Level Sales Analysis

Recorded sales value, distinct invoices, identifiable customers and quantities were aggregated by country.

This analysis provides a geographical view of the transaction dataset and helps identify where recorded sales activity is concentrated.

Country totals should be interpreted with the dataset's customer identification and transaction eligibility limitations in mind. They represent recorded transaction activity rather than market share or profitability.

Country-level cancellation totals were investigated separately in BP2. A large negative recorded value in a country does not by itself demonstrate that the country has a higher cancellation rate; that conclusion requires an appropriate denominator and a consistent cancellation definition.

## 10. Exceptional Transaction Investigation — Stock Code 23843

An unusually large transaction involving stock code `23843`, described as `PAPER CRAFT LITTLE BIRDIE`, was investigated.

| Transaction | Date and time | Quantity | Recorded value |
|---|---|---:|---:|
| Original invoice `581483` | 9 Dec 2011, 09:15 | 80,995 | +£168,469.60 |
| Cancellation invoice `C581484` | 9 Dec 2011, 09:27 | −80,995 | −£168,469.60 |

The two records occurred 12 minutes apart and have equal and opposite recorded values.

### Finding

The original transaction and the cancellation offset one another when considered together. This demonstrates why exceptional transactions and cancellation records must be investigated before drawing conclusions from large individual values.

### Limitation

Although this case was clearly identified, the wider cancellation-matching analysis produced ambiguous candidate matches. The project therefore does not claim to have fully reconciled all cancellation transactions to their original sales.

The source data was retained, and no automatic deletion or blanket cancellation adjustment was applied as part of BP1.

## 11. Data Validation

Three key validation areas were checked during BP1.

### 11.1 Population and flag validation

The row counts and quality flags were checked against the established source-table baseline and merchandise-analysis population.

### 11.2 Recorded value validation

The recorded line value totals were checked against the corresponding populations to ensure that the overall and merchandise-candidate totals were not being confused.

### 11.3 Monthly and year-over-year validation

Monthly recorded values and year-over-year calculations were independently checked. The monthly results were reconciled to the overall merchandise-candidate recorded value.

These checks support the reproducibility of the core BP1 results. They do not establish that recorded sales value is equivalent to fully reconciled net revenue or profit.

## 12. Business Findings

### Finding 1 — Recorded sales activity shows seasonal variation

November was the strongest month in both 2010 and 2011 among the reported monthly results.

**Business implication:** Seasonal patterns should be considered when planning inventory, campaigns and staffing, while recognising that the analysis does not establish the cause of the pattern.

### Finding 2 — Year-over-year performance was positive in most comparable months

Eight of eleven months recorded year-over-year increases in January–November comparisons. September had the largest reported increase, while April had the largest reported decline.

**Business implication:** Investigating the months with the largest changes may help identify changes in product mix, demand or transaction activity.

### Finding 3 — Product performance was uneven

Party Bunting and Jam Making Set recorded substantial increases in value, while Regency Cakestand 3 Tier and White Hanging Heart Tea-Light Holder declined.

**Business implication:** Product-level monitoring should include both absolute recorded value and percentage change, rather than relying on either metric alone.

### Finding 4 — Exceptional transactions can materially affect totals

The £168,469.60 original transaction for stock code 23843 was offset by an equal and opposite cancellation shortly afterwards.

**Business implication:** Large transactions and cancellations should be reviewed before using recorded values for business conclusions.

### Finding 5 — Transaction definitions must remain explicit

The full-table recorded value and merchandise-candidate recorded value differ because they represent different populations.

**Business implication:** Reports and dashboards should label the selected population and clearly distinguish recorded sales value from fully reconciled net revenue and profit.

## 13. Limitations

1. **Recorded value is not profit:** Product costs, operating costs and other expenses are not available.
2. **Cancellation reconciliation is incomplete:** The project does not claim that all cancellation records have been reliably matched to original transactions.
3. **Duplicate candidates remain flagged rather than automatically deleted:** The flag alone is not sufficient evidence for deletion.
4. **The final month is incomplete:** December 2011 data ends on 9 December, so it should not be compared as a full month with previous Decembers.
5. **Customer identifiers are incomplete:** Some transaction rows lack a Customer ID, limiting customer-level interpretations.
6. **Product exclusions affect rankings:** Service-related stock codes are excluded from selected product rankings. This exclusion should be documented consistently.
7. **Observed patterns are descriptive:** Seasonal and year-over-year changes do not by themselves establish causation.

## 14. Final Business Conclusion

BP1 established a baseline for retail sales performance and identified meaningful changes across months, years, products and countries.

The analysis found stronger recorded sales activity in November, year-over-year increases in eight of eleven comparable months, and significant variation in selected product performance. It also demonstrated the importance of investigating exceptional transactions and maintaining clear definitions for the analysed population.

These findings provide a foundation for the next business problems: cancellation and revenue-adjustment analysis (BP2), customer retention and cohort analysis (BP3), and customer segmentation using RFM analysis (BP4).

The final dashboard should present recorded sales value with clear population definitions, show the incomplete December 2011 period appropriately, and avoid labelling the figures as profit or fully reconciled net revenue.