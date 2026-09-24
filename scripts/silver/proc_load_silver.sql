
/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Purpose:
    This stored procedure performs the ETL process to populate the silver schema
    tables from the bronze schema.
	
Actions:
    - Truncates existing data from the silver tables.
    - Inserts transformed and cleaned data from bronze into the silver tables.

Parameters:
    None.
    No parameters are required, and no values are returned.

Example:
    CALL silver.load_silver();
===============================================================================
*/
CREATE OR REPLACE PROCEDURE silver.load_silver () 
LANGUAGE plpgsql   --Procedural Language/PostgreSQL
AS $$
BEGIN
	DECLARE 
		start_time TIMESTAMPTZ; 
		end_time TIMESTAMPTZ;
		batch_start_time TIMESTAMPTZ;
		batch_end_time TIMESTAMPTZ;
	BEGIN 
		batch_start_time := clock_timestamp();
		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the Silver Layer';
		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the CRM Tables';
		RAISE NOTICE '==============================================';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		RAISE NOTICE 'Inserting into Table silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		-- Keep the latest record per customer and clean names, marital status, and gender values.
		INSERT INTO silver.crm_cust_info(
			cst_id              ,
		    cst_key             ,
		    cst_firstname       ,
		    cst_lastname        ,
		    cst_marital_status  ,
		    cst_gndr            ,
		    cst_create_date     
		)
		
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END cst_marital_status,  --Normalize marital status values to readable format
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END cst_gndr, --Normalize gender  values to readable format
			cst_create_date
		FROM (
			SELECT *,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t
		WHERE flag_last =1 ;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		RAISE NOTICE 'Inserting into Table silver.crm_prd_info';
		-- Standardize product keys, category values, product line labels, and date ranges.
		INSERT INTO silver.crm_prd_info(
			prd_id ,
			cat_id ,
			prd_key ,
			prd_nm ,
			prd_cost ,
			prd_line ,
			prd_start_dt ,
			prd_end_dt   
		)
		SELECT 
		prd_id ,
		REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id,
		SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
		prd_nm ,
		COALESCE(prd_cost, 0) AS prd_cost,
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'other Sales'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END prd_line ,
		CAST (prd_start_dt AS DATE) AS prd_start_dt ,
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt ) - INTERVAL '1 day' AS DATE) AS prd_end_dt 
		FROM bronze.crm_prd_info;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		RAISE NOTICE 'Inserting into Table silver.crm_sales_details';
		-- Fix invalid date values and recalculate sales/price when the source data is missing or inconsistent.
		INSERT INTO silver.crm_sales_details(
		    sls_ord_num  ,
		    sls_prd_key ,
		    sls_cust_id  ,
		    sls_order_dt ,
		    sls_ship_dt  ,
		    sls_due_dt   ,
		    sls_sales    ,
		    sls_quantity ,
		    sls_price        
		)
		
		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt =0 OR LENGTH (CAST(sls_order_dt AS VARCHAR)) !=8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
		END sls_order_dt,
		CASE 
			WHEN sls_ship_dt =0 OR LENGTH (CAST(sls_ship_dt AS VARCHAR)) !=8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
		END sls_ship_dt,
		CASE 
			WHEN sls_due_dt =0 OR LENGTH (CAST(sls_due_dt AS VARCHAR)) !=8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
		END sls_due_dt,
		CASE 
			WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales!= sls_quantity * ABS(sls_price) 
				THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales  ---Recalcuate sales if original value is missing or incorrect
		END sls_sales,
		sls_quantity,
		CASE
			WHEN sls_price<=0 OR sls_price IS NULL 
				THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price  --- Derive price if original value is invalid
		END sls_price
		FROM bronze.crm_sales_details;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the ERP Tables';
		RAISE NOTICE '==============================================';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		RAISE NOTICE 'Inserting into Table silver.erp_cust_az12';
		-- Clean customer identifiers, remove invalid future dates, and standardize gender values.
		INSERT INTO silver.erp_cust_az12(
		cid,
		bdate,
		gen
		)
		
		SELECT 
		CASE
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid) ) --Remove 'NAS' prefix if present
			ELSE cid
		END cid,
		CASE 
			WHEN bdate > CURRENT_DATE THEN NULL
			ELSE bdate 
		END bdate,  -- Set future birthdates to NULL
		CASE
			WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			ELSE 'n/a'
		END gen  -- Normalisegender values and handle unknown cases
		FROM bronze.erp_cust_az12;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		RAISE NOTICE 'Inserting into Table silver.erp_loc_a101';
		-- Remove invalid characters and normalize country values for consistent reporting.
		INSERT INTO silver.erp_loc_a101(cid,cntry)
		SELECT 
		REPLACE(cid,'-','') AS cid,   -- Handled invalid values
		CASE 
			WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END cntry -- Normalize and Handle missing or blank country codes
		FROM bronze.erp_loc_a101;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		RAISE NOTICE 'Inserting into Table silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
		SELECT 
		id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2;
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';
		batch_end_time := clock_timestamp();

		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the Silver Layer is completed';
		RAISE NOTICE 'Batch Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (batch_end_time - batch_start_time)));
		RAISE NOTICE '==============================================';
	
	EXCEPTION  
		WHEN OTHERS THEN
			RAISE NOTICE '==============================================';
			RAISE NOTICE 'ERROR OCCURRED DURING LOADING SILVER LAYER';
			RAISE NOTICE 'Error Message: %', SQLERRM;
			RAISE NOTICE 'Error State: %', SQLSTATE;
			RAISE NOTICE '==============================================';
	END;

	
END;
$$;

