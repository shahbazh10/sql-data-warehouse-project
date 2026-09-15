/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';

	Insert Into Silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

	select
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' then 'Married'
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' then 'Single'
	Else 'N/A'
	END as cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gender)) ='F' then 'Female'
		WHEN UPPER(TRIM(cst_gender)) = 'M' then 'Male'
		Else 'N/A'
	END as cst_gndr,
	cst_create_date
	from(

	select
	*,
	ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
	from Bronze.crm_cust_info
	)t
	where flag_last = 1 AND cst_id IS NOT NULL; -- Select the most recent record per customer
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading silver.crm_prd_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';

	Insert into Silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt)

		select
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1,5),'-','_') as cat_id,
		SUBSTRING(prd_key,7,len(prd_key)) as prd_key,
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'N/A'
		END as prd_line,
		CAST(prd_start_dt as DATE) as prd_start_dt,
		CAST(Lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 AS DATE) as prd_end_dt
		from Bronze.crm_prd_info;
		 SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading crm_sales_details
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';

	INSERT INTO Silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
	)
	select
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 or len(sls_order_dt)!=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt as VARCHAR) as DATE)
		END as sls_order_dt,
		CASE WHEN sls_ship_dt = 0 or len(sls_ship_dt)!=8 THEN NULL
		else CAST(CAST(sls_ship_dt AS varchar) as date)
		END as sls_ship_dt,
		CASE WHEN sls_due_dt = 0 or len(sls_due_dt)!=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt as varchar) as DATE)
		END as sls_due_dt,
		CASE WHEN sls_sales IS NULL or sls_sales <=0 or sls_sales != sls_quantity*ABS(sls_price) THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
	END as sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL or sls_price <=0
	THEN sls_sales/NULLIF(sls_quantity,0)
	else sls_price
	END as sls_price
	from Bronze.crm_sales_details;
	SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading erp_cust_az12
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';

	Insert into Silver.erp_cust_az12
	(cid,
	bdate,
	gen)

	Select
	CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
	ELSE CID
	END as CID,
	CASE WHEN BDATE > GETDATE() THEN NULL
	ELSE BDATE
	END as BDATE,
	CASE WHEN UPPER(TRIM(GEN)) IN ('F','Female') THEN 'Female'
	WHEN UPPER(TRIM(GEN)) IN ('M','Male') THEN 'Male'
	Else 'N/A'
	END as Gen
	from Bronze.erp_CUST_AZ12;
	SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

        -- Loading erp_loc_a101
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';

INSERT INTO Silver.erp_loc_a101(cid,cntry)

select
Replace(CID,'-','') as CID,
CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
WHEN TRIM(CNTRY) IN ('USA','US') THEN 'United States'
WHEN TRIM(CNTRY) = '' or CNTRY IS NULL then 'N/A'
ELSE trim(CNTRY)
END CNTRY
from Bronze.erp_LOC_A101;
SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';


	INSERT INTO Silver.erp_px_cat_g1v2
	(id,
	cat,
	subcat,
	maintenance)

	select
	ID,
	CAT,
	SUBCAT,
	MAINTENANCE
	from Bronze.erp_PX_CAT_G1V2;
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END



