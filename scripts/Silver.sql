CREATE OR ALTER PROCEDURE Silver.Reload_All
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* =========================================================
           1️⃣  CRM — CUSTOMER INFO  (cst_info)
           ========================================================= */
        IF OBJECT_ID('Silver.crm_cust_info') IS NOT NULL 
            TRUNCATE TABLE Silver.crm_cust_info;

        INSERT INTO Silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            t.cst_id,
            t.cst_key,
            LTRIM(RTRIM(t.cst_firstname)),
            LTRIM(RTRIM(t.cst_lastname)),
            CASE
                WHEN UPPER(LTRIM(RTRIM(t.cst_marital_status))) IN ('M','MARRIED') THEN 'Married'
                WHEN UPPER(LTRIM(RTRIM(t.cst_marital_status))) IN ('S','SINGLE') THEN 'Single'
                ELSE 'N/A'
            END,
            CASE
                WHEN UPPER(LTRIM(RTRIM(t.cst_gndr))) = 'M' THEN 'Male'
                WHEN UPPER(LTRIM(RTRIM(t.cst_gndr))) = 'F' THEN 'Female'
                ELSE 'N/A'
            END,
            t.cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
            FROM Bronze.crm_cust_info
        ) t
        WHERE t.rn = 1;



        /* =========================================================
           2️⃣  CRM — PRODUCT INFO  (prd_info)
           ========================================================= */

        IF OBJECT_ID('Silver.crm_prod_info') IS NOT NULL 
            TRUNCATE TABLE Silver.crm_prod_info;

        INSERT INTO Silver.crm_prod_info (
            prd_id, 
            cat_id, 
            prd_key, 
            prd_nm, 
            prd_cost, 
            prd_line, 
            prd_start_dt, 
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            LTRIM(RTRIM(prd_nm)),
            ISNULL(prd_cost, 0),
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'N/A'
            END,
            prd_start_dt,
            COALESCE(prd_end_dt, '9999-12-31')
        FROM Bronze.crm_prod_info;



        /* =========================================================
           3️⃣  CRM — SALES DETAILS  (sales_details)
           ========================================================= */

        /* ⚠️ FIXED based on your REAL Bronze schema */
        IF OBJECT_ID('Silver.crm_sales_details') IS NOT NULL 
            TRUNCATE TABLE Silver.crm_sales_details;

        INSERT INTO Silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_key,
            sls_order_dt,
            sls_ship_dt,
            sls_delivery_dt,
            sls_quantity,
            sls_amount
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_key,
            sls_order_dt,
            sls_ship_dt,
            sls_delivery_dt,
            sls_quantity,
            sls_amount
        FROM Bronze.crm_sales_details;



        /* =========================================================
           4️⃣  ERP — LOCATION A101  
           ========================================================= */

        IF OBJECT_ID('Silver.erp_loc_a101') IS NOT NULL 
            TRUNCATE TABLE Silver.erp_loc_a101;

        INSERT INTO Silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', ''),
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
                WHEN TRIM(cntry) = '' THEN 'n/a'
                ELSE TRIM(cntry)
            END
        FROM Bronze.erp_loc_a101;



        /* =========================================================
           5️⃣  ERP — CUSTOMER AZ12  
           ========================================================= */

        IF OBJECT_ID('Silver.erp_cust_az12') IS NOT NULL 
            TRUNCATE TABLE Silver.erp_cust_az12;

        INSERT INTO Silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE 
                WHEN cid LIKE 'NASAW%' THEN 'AW' + SUBSTRING(cid, 6, LEN(cid))
                ELSE cid
            END AS cid,
            CASE 
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM Bronze.erp_cust_az12;



        /* =========================================================
           6️⃣  EXP — PX CAT G1V2  
           ========================================================= */

        IF OBJECT_ID('Silver.exp_px_cat_g1v2') IS NOT NULL 
            TRUNCATE TABLE Silver.exp_px_cat_g1v2;

        INSERT INTO Silver.exp_px_cat_g1v2 (id, cat, subcat, maintainence)
        SELECT id, cat, subcat, maintainence
        FROM Bronze.exp_px_cat_g1v2;



        /* =========================================================
           DONE
           ========================================================= */

        COMMIT TRAN;
        SELECT 'Silver Layer Reload Complete' AS status;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO
