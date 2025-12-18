/* === ONE SCRIPT: Reload ALL Bronze tables with correct mappings/types === */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Bronze') EXEC('CREATE SCHEMA Bronze');
GO

CREATE OR ALTER PROCEDURE Bronze.Reload_All_Fixed
AS
BEGIN
  SET NOCOUNT ON; SET XACT_ABORT ON;
  BEGIN TRY
    BEGIN TRAN;

    /* 1) CRM — Customer Info */
    IF OBJECT_ID('Bronze.crm_cust_info') IS NOT NULL DROP TABLE Bronze.crm_cust_info;
    CREATE TABLE Bronze.crm_cust_info(
      cst_id INT, cst_key VARCHAR(50), cst_firstname VARCHAR(100), cst_lastname VARCHAR(100),
      cst_marital_status VARCHAR(10), cst_gndr VARCHAR(10), cst_create_date DATE
    );
    BULK INSERT Bronze.crm_cust_info FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);

    /* 2) CRM — Product Info */
    IF OBJECT_ID('Bronze.crm_prod_info') IS NOT NULL DROP TABLE Bronze.crm_prod_info;
    CREATE TABLE Bronze.crm_prod_info(
      prd_id INT, prd_key VARCHAR(50), prd_nm VARCHAR(200), prd_cost DECIMAL(10,2),
      prd_line VARCHAR(100), prd_start_dt DATE, prd_end_dt DATE
    );
    BULK INSERT Bronze.crm_prod_info FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);

    /* 3) CRM — Sales Details (correct mapping + dates) */
    IF OBJECT_ID('Bronze.crm_sales_details') IS NOT NULL DROP TABLE Bronze.crm_sales_details;
    CREATE TABLE Bronze.crm_sales_details(
      sls_ord_num     VARCHAR(50),      -- alphanumeric like SO43697
      sls_prd_key     VARCHAR(50),
      sls_cust_key    VARCHAR(50),      -- maps from sls_cust_id
      sls_order_dt    DATE,
      sls_ship_dt     DATE,
      sls_delivery_dt DATE,             -- maps from sls_due_dt
      sls_quantity    INT,
      sls_amount      DECIMAL(10,2)     -- from sls_sales or sls_price
    );

    IF OBJECT_ID('tempdb..#sales_raw') IS NOT NULL DROP TABLE #sales_raw;
    CREATE TABLE #sales_raw(
      sls_ord_num  VARCHAR(50),
      sls_prd_key  VARCHAR(50),
      sls_cust_id  VARCHAR(50),
      sls_order_dt VARCHAR(20),
      sls_ship_dt  VARCHAR(20),
      sls_due_dt   VARCHAR(20),
      sls_sales    VARCHAR(50),
      sls_quantity VARCHAR(50),
      sls_price    VARCHAR(50)
    );
    BULK INSERT #sales_raw FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);

    INSERT INTO Bronze.crm_sales_details
    SELECT
      s.sls_ord_num,
      LTRIM(RTRIM(s.sls_prd_key)),
      LTRIM(RTRIM(s.sls_cust_id))                         AS sls_cust_key,
      TRY_CONVERT(date, s.sls_order_dt, 112)              AS sls_order_dt,   -- 112 = YYYYMMDD
      TRY_CONVERT(date, s.sls_ship_dt, 112)               AS sls_ship_dt,
      TRY_CONVERT(date, s.sls_due_dt, 112)                AS sls_delivery_dt,
      TRY_CONVERT(int,  s.sls_quantity)                   AS sls_quantity,
      COALESCE(TRY_CONVERT(decimal(10,2), s.sls_sales),
               TRY_CONVERT(decimal(10,2), s.sls_price))   AS sls_amount
    FROM #sales_raw s;

    /* 4) ERP — Location A101 */
    IF OBJECT_ID('Bronze.erp_loc_a101') IS NOT NULL DROP TABLE Bronze.erp_loc_a101;
    CREATE TABLE Bronze.erp_loc_a101(cid VARCHAR(50), cntry VARCHAR(100));
    BULK INSERT Bronze.erp_loc_a101 FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);

    /* 5) ERP — Customer AZ12 (dirty dates → cleaned) */
    IF OBJECT_ID('Bronze.erp_cust_az12') IS NOT NULL DROP TABLE Bronze.erp_cust_az12;
    CREATE TABLE Bronze.erp_cust_az12(cid VARCHAR(50), bdate DATE, gen VARCHAR(10));

    IF OBJECT_ID('tempdb..#cust_raw') IS NOT NULL DROP TABLE #cust_raw;
    CREATE TABLE #cust_raw(cid VARCHAR(100), bdate VARCHAR(100), gen VARCHAR(50));
    BULK INSERT #cust_raw FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', FIELDQUOTE='"', MAXERRORS=100000, TABLOCK);

    ;WITH cleaned AS (
      SELECT
        LTRIM(RTRIM(cid)) AS cid,
        NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(bdate,'/','-'),'–','-'),'—','-'),CHAR(160),' '),CHAR(9),''))), '') AS bdate_txt,
        LTRIM(RTRIM(gen)) AS gen
      FROM #cust_raw
    )
    INSERT INTO Bronze.erp_cust_az12 (cid, bdate, gen)
    SELECT cid, CAST(TRY_CONVERT(datetime, bdate_txt, 105) AS DATE), gen
    FROM cleaned;

    /* 6) EXP — PX_CAT_G1V2 */
    IF OBJECT_ID('Bronze.exp_px_cat_g1v2') IS NOT NULL DROP TABLE Bronze.exp_px_cat_g1v2;
    CREATE TABLE Bronze.exp_px_cat_g1v2(id VARCHAR(50), cat VARCHAR(100), subcat VARCHAR(150), maintainence VARCHAR(10));
    BULK INSERT Bronze.exp_px_cat_g1v2 FROM 'C:\Users\syana\Downloads\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (FIRSTROW=2, DATAFILETYPE='char', CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);

    COMMIT TRAN;

    SELECT 'crm_cust_info' AS table_name, COUNT(*) AS rows_loaded FROM Bronze.crm_cust_info UNION ALL
    SELECT 'crm_prod_info', COUNT(*) FROM Bronze.crm_prod_info UNION ALL
    SELECT 'crm_sales_details', COUNT(*) FROM Bronze.crm_sales_details UNION ALL
    SELECT 'erp_loc_a101', COUNT(*) FROM Bronze.erp_loc_a101 UNION ALL
    SELECT 'erp_cust_az12', COUNT(*) FROM Bronze.erp_cust_az12 UNION ALL
    SELECT 'exp_px_cat_g1v2', COUNT(*) FROM Bronze.exp_px_cat_g1v2;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
  END CATCH
END;
GO

EXEC Bronze.Reload_All_Fixed;

