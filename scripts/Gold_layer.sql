/* ============================
   GOLD LAYER
   ============================ */

-- ============================
-- DIM_CUSTOMERS
-- ============================
IF OBJECT_ID('Gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW Gold.dim_customers;
GO

CREATE VIEW Gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    ci.cst_marital_status AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ca.bdate AS birth_date,
    la.cntry AS country
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_az12 ca
    ON ci.cst_key = REPLACE(ca.cid, '-', '')
LEFT JOIN Silver.erp_loc_a101 la
    ON ci.cst_key = REPLACE(la.cid, '-', '');
GO

-- ============================
-- FACT_SALES
-- ============================
IF OBJECT_ID('Gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW Gold.fact_sales;
GO

CREATE VIEW Gold.fact_sales AS
SELECT
    sd.sls_ord_num           AS order_number,
    pr.surrogate_product_key AS product_key,
    cu.customer_key          AS customer_key,
    sd.sls_order_dt          AS order_date,
    sd.sls_ship_dt           AS ship_date,
    sd.sls_delivery_dt       AS delivery_date,
    sd.sls_quantity          AS quantity,
    sd.sls_amount            AS sales_amount,
    sd.sls_amount / NULLIF(sd.sls_quantity, 0) AS unit_price
FROM Silver.crm_sales_details sd
LEFT JOIN Gold.dimension_products pr
    ON sd.sls_prd_key = pr.business_product_key
LEFT JOIN Gold.dim_customers cu
    ON sd.sls_cust_key = RIGHT(cu.customer_number, 5);
GO
