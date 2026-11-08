# Online Retail Data Analytics & Customer Segmentation

An end-to-end data analytics project using **Python, PostgreSQL, and Power BI** to investigate retail sales performance, product trends, transaction quality, customer purchasing behaviour, and customer segmentation.

The project follows a structured analytics workflow: data understanding and preparation using Python, exploratory and business analysis using PostgreSQL, and interactive dashboard development using Power BI.

---

## Project Overview

This project analyses an online retail transaction dataset containing more than one million transaction records across multiple countries and approximately two years.

The objective is to transform raw transactional data into meaningful business insights by examining:

- Overall sales performance and trends
- Product and country-level performance
- Sales seasonality and product contribution
- Cancellations and transaction-quality issues
- Customer purchasing frequency and behaviour
- Customer segmentation using the RFM framework

The final deliverable is a five-page interactive Power BI dashboard supported by Python-based data inspection and preparation and PostgreSQL-based analysis.

## Technology Stack

| Technology       | Purpose                                                            |
| ---------------- | ------------------------------------------------------------------ |
| Python           | Data understanding, inspection, quality assessment and preparation |
| Pandas & NumPy   | Data manipulation and analysis                                     |
| Jupyter Notebook | Interactive data exploration and preparation                       |
| PostgreSQL       | SQL-based data analysis and business queries                       |
| Power BI         | Interactive dashboard development                                  |
| DAX              | Measures and customer analytics calculations                       |
| Git & GitHub     | Version control and project documentation                          |

---

## Project Workflow

### 1. Data Understanding & Preparation — Python

Python was used to inspect and understand the source dataset before conducting the analysis.

Key activities included:

- Combining the available dataset worksheets.
- Examining the dataset structure and data types.
- Identifying missing values.
- Detecting duplicate records.
- Investigating cancellation transactions.
- Identifying negative quantities and zero or negative prices.
- Examining unusual and non-merchandise records.
- Creating derived fields for subsequent analysis.

The initial dataset contained approximately **1,067,371 records and 8 columns**.

The dataset covered transactions from December 2009 to December 2011.

### 2. Data Analysis — PostgreSQL

PostgreSQL was used to perform structured SQL analysis and investigate business questions.

The analysis covered:

- Overall sales performance.
- Sales trends and country-level contribution.
- Product performance.
- Cancellation transactions.
- Transaction-quality issues.
- Customer purchasing patterns.
- Repeat purchasing behaviour.
- Customer-level RFM analysis.

SQL queries were used to aggregate, filter, compare, and investigate the transactional data.

### 3. Dashboard Development — Power BI

Power BI was used to build an interactive five-page dashboard.

DAX measures and calculated fields were used to support the dashboard's KPIs, comparisons, and customer analysis.

---

## Dashboard Overview

The final dashboard consists of five analytical pages.

### Page 1 — Executive Overview

Provides a high-level summary of the retail business.

Key elements:

- Total Recorded Sales
- Total Invoices
- Customer Count
- Transaction Count
- Monthly recorded sales trend
- Top countries by recorded sales
- Missing Customer ID percentage

### Page 2 — Revenue & Product Performance

Examines product-level performance and sales patterns.

Key elements:

- Top 10 products by recorded sales
- Monthly sales seasonality
- Product volume versus recorded sales
- Top product ranking over time

### Page 3 — Cancellations & Transaction Quality

Investigates cancellations and potential data-quality issues.

Key elements:

- Cancellation recorded value
- Cancellation invoice count
- Negative quantity records
- Zero-price records
- Cancellation trends over time
- Country-level cancellation impact
- Transaction exception investigation

### Page 4 — Customer Retention & Behaviour

Explores customer purchasing frequency and repeat behaviour.

Key elements:

- Eligible customer count
- Repeat customer rate
- Repeat customer count
- One-invoice customer count
- Customer purchase frequency distribution
- New customer acquisition by month

### Page 5 — RFM Customer Segmentation

Segments customers based on their purchasing behaviour using the Recency, Frequency, and Monetary framework.

The three RFM dimensions are:

- **Recency:** How recently a customer made a purchase.
- **Frequency:** How often a customer purchased.
- **Monetary:** The recorded value of a customer's purchases.

The dashboard groups customers into segments such as:

- Champions
- Loyal Customers
- Potential Loyalists
- At Risk
- Hibernating
- Others

Key visualisations include customer distribution by segment, recorded value by segment, and average days since last purchase.

---

## Dataset Information

The project uses an online retail transactional dataset with the following original fields:

| Column      | Description                              |
| ----------- | ---------------------------------------- |
| Invoice     | Invoice number identifying a transaction |
| StockCode   | Product code                             |
| Description | Product description                      |
| Quantity    | Quantity purchased                       |
| InvoiceDate | Transaction date and time                |
| Price       | Unit price                               |
| Customer ID | Customer identifier                      |
| Country     | Customer's country                       |

### Dataset characteristics

| Metric                         | Initial observation |
| ------------------------------ | ------------------: |
| Total records                  |           1,067,371 |
| Original columns               |                   8 |
| Distinct invoices              |              53,628 |
| Distinct customers in raw data |               5,942 |
| Missing Customer ID records    |             243,007 |
| Exact duplicate records        |              34,335 |
| Date range                     | Dec 2009 – Dec 2011 |

The figures above describe the initial source dataset and should not be interpreted as the final eligible population for every analysis.

### Dataset availability

The raw and processed CSV files are intentionally excluded from this GitHub repository because of their size.

To reproduce the project:

1. Obtain the original dataset from its source.
2. Place the source file in the local `data/raw/` directory.
3. Follow the Python data inspection and preparation workflow.
4. Load the prepared data into PostgreSQL.
5. Execute the SQL analysis scripts.
6. Open the Power BI dashboard.

The repository does not contain the original or processed CSV files.

---

## Important Analytical Definitions & Limitations

To interpret the results correctly, the following distinctions matter.

### Recorded Sales vs. Profit

The project's recorded sales measure is calculated as:

`Quantity × Price`

This represents the recorded transaction value. It is **not profit**, because product costs and operating expenses are not available.

The source-level Power BI measure includes records such as cancellations and other exceptional transactions unless a visual or measure applies additional filters.

### Cancellation Transactions

Cancellation invoices are identified using invoice numbers beginning with `C`.

Cancellation invoice counts and negative-quantity row counts represent different measures. They should not be treated as interchangeable, and issue categories may overlap.

### Customer Analysis

Customer analysis excludes blank customer identifiers and applies non-cancellation invoice conditions in the relevant calculations.

The eligibility criteria are not identical across every dashboard calculation. Therefore, customer counts and metrics may differ between the customer behaviour and RFM pages.

### RFM Segmentation

RFM analysis uses a filtered population of identified customers with non-cancellation invoices, positive quantities, and positive prices.

RFM scores are relative to the analysed dataset. Segment labels are analytical groupings rather than verified descriptions of customer intent.

The monetary measure represents filtered recorded purchase value, not customer lifetime profit or lifetime value.

---

## Repository Structure

The repository is organised to separate data preparation, SQL analysis, dashboard development, and documentation.

```text
online-retail-analytics/
│
├── README.md
├── .gitignore
├── requirements.txt
│
│
├── notebooks/
│   ├── Retail_Analytics.ipynb
│
├── sql/
│   ├── Business_Problem_1.sql
│   ├── Business_Problem_2.sql
│   ├── Business_Problem_3.sql
│   └── Business_Problem_4.sql
│   └── create_table.sql
│
├── dashboards/
│   └── Retail_Analytics_Dashboard.pbix
|   └──assets/
│      ├── executive_overview.png
│      ├── product_performance.png
│      ├── transaction_quality.png
│      ├── customer_behaviour.png
│      └── rfm_segmentation.png
│
└── reports/
    ├── BP1_documentation.md
    ├── BP2_documentation.md
    ├── BP3_documentation.md
    ├── BP4_documentation.md
```

This is the intended structure. Only files actually created and verified should be included in the published repository.

---

## How to Reproduce the Project

### Prerequisites

- Python
- Jupyter Notebook
- PostgreSQL
- Power BI Desktop

### Steps

1. Clone this repository.
2. Obtain the original dataset separately.
3. Set up the Python environment and install the required dependencies.
4. Place the dataset in the local raw-data directory.
5. Run the data inspection and preparation notebooks.
6. Load the prepared data into PostgreSQL.
7. Execute the SQL analysis scripts.
8. Open the Power BI project file.
9. Configure the required data source connections if necessary.

Dataset files and database credentials are not included in the repository.

---

## Key Learning Outcomes

This project demonstrates practical experience with:

- Working with large transactional datasets.
- Data inspection and quality assessment.
- Handling missing values, duplicates, and unusual transactions.
- Data preparation using Python.
- SQL-based business analysis using PostgreSQL.
- Developing analytical measures using DAX.
- Building multi-page interactive Power BI dashboards.
- Customer purchasing behaviour analysis.
- RFM-based customer segmentation.
- Documenting analytical definitions and limitations.

---

## Author

**Nikhil Mohan**

- GitHub: [https://github.com/NikhilMohan-11](https://github.com/NikhilMohan-11)
- LinkedIn: [https://www.linkedin.com/in/nikhil-mohan-1127/](https://www.linkedin.com/in/nikhil-mohan-1127/)

---

## Project Status

**Dashboard development completed.**

Repository documentation, final validation, and publication are being finalised.

