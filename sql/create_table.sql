
CREATE TABLE staging.retail_full (
    invoice TEXT,
    stockcode TEXT,
    description TEXT,
    quantity INTEGER,
    invoicedate TIMESTAMP,
    price NUMERIC(18, 4),
    customer_id NUMERIC(12, 0),
    country TEXT,
    description_clean TEXT,
    linevalue NUMERIC(20, 6),

    iscancellationinvoice BOOLEAN,
    isnegativequantity BOOLEAN,
    iszeroprice BOOLEAN,
    isnegativeprice BOOLEAN,
    missingcustomerid BOOLEAN,
    missingdescription BOOLEAN,
    isexactduplicatecandidate BOOLEAN,
    isspecialdescription BOOLEAN,

    transactiontype TEXT,
    include_merchandise_analysis BOOLEAN,
    include_customer_analysis BOOLEAN,
    requires_review BOOLEAN,
    duplicate_sensitivity_flag BOOLEAN
);


SELECT
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'retail_full'
ORDER BY ordinal_position;
