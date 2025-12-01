------------------------------------------------------------
-- SILVER LAYER TABLES - DDL
-- Version: 1.0
-- Purpose: Standardized, cleaned tables for analytics
------------------------------------------------------------

-------------------------------
-- SILVER.CRM_CUST_INFO
-------------------------------
CREATE TABLE Silver.crm_cust_info (
    cst_id             INT            NOT NULL,
    cst_key            VARCHAR(50)    NOT NULL,
    cst_firstname      VARCHAR(100)   NULL,
    cst_lastname       VARCHAR(100)   NULL,
    cst_marital_status VARCHAR(20)    NULL,
    cst_gndr           VARCHAR(10)    NULL,
    cst_create_date    DATE           NULL,
    dwh_create_date    DATETIME       DEFAULT GETDATE()
);


-------------------------------
-- SILVER.CRM_PROD_INFO
-------------------------------
CREATE TABLE Silver.crm_prod_info (
    prd_id        INT            NOT NULL,
    cat_id        VARCHAR(50)    NULL,
    prd_key       VARCHAR(50)    NULL,
    prd_nm        VARCHAR(200)   NULL,
    prd_cost      DECIMAL(10,2)  NULL,
    prd_line      VARCHAR(50)    NULL,
    prd_start_dt  DATE           NULL,
    prd_end_dt    DATE           NULL,
    dwh_create_date DATETIME     DEFAULT GETDATE()
);


-------------------------------
- SILVER.CRM_SALES_DETAILS
-------------------------------
CREATE TABLE Silver.crm_sales_details (
    sls_ord_num     INT            NOT NULL,
    sls_prd_key     VARCHAR(50)    NOT NULL,
    sls_cust_key    VARCHAR(50)    NOT NULL,
    sls_order_dt    DATE           NULL,
    sls_ship_dt     DATE           NULL,
    sls_delivery_dt DATE           NULL,
    sls_quantity    INT            NULL,
    sls_amount      DECIMAL(10,2)  NULL,
    dwh_create_date DATETIME       DEFAULT GETDATE()
);


-------------------------------
-- 4️⃣ SILVER.ERP_LOC_A101
-------------------------------
CREATE TABLE Silver.erp_loc_a101 (
    cid      VARCHAR(50)   NOT NULL,
    cntry    VARCHAR(100)  NULL,
    dwh_create_date DATETIME DEFAULT GETDATE()
);


-------------------------------
--  SILVER.ERP_CUST_AZ12
-------------------------------
CREATE TABLE Silver.erp_cust_az12 (
    cid      VARCHAR(50)   NOT NULL,
    bdate    DATE          NULL,
    gen      VARCHAR(20)   NULL,
    dwh_create_date DATETIME DEFAULT GETDATE()
);


-------------------------------
--  SILVER.EXP_PX_CAT_G1V2
-------------------------------
CREATE TABLE Silver.exp_px_cat_g1v2 (
    id           INT            NOT NULL,
    cat          VARCHAR(100)   NULL,
    subcat       VARCHAR(100)   NULL,
    maintainence VARCHAR(200)   NULL,
    dwh_create_date DATETIME DEFAULT GETDATE()
);
