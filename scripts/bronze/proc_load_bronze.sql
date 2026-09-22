/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================

Purpose:
    Loads raw data from external CSV files into the bronze schema.
    The procedure truncates the bronze tables and bulk-loads the source data
    into the target bronze tables using PostgreSQL CSV ingestion.

Parameters:
    None

Returns:
    None

Example:
    CALL bronze.load_bronze();
===============================================================================
*/
CREATE OR REPLACE PROCEDURE bronze.load_bronze () 
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
		RAISE NOTICE 'Loading the Bronze Layer';
		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the CRM Tables';
		RAISE NOTICE '==============================================';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		
		RAISE NOTICE 'Inserting Data Into: bronze.crm_cust_info';
		COPY bronze.crm_cust_info
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		
		RAISE NOTICE 'Inserting Data Into: bronze.crm_prd_info';
		COPY bronze.crm_prd_info
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
	    end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
	
		RAISE NOTICE 'Inserting Data Into: bronze.crm_sales_details';
		COPY bronze.crm_sales_details
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		
		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the ERP Tables';
		RAISE NOTICE '==============================================';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
	
		RAISE NOTICE 'Inserting Data Into: bronze.erp_cust_az12';
		COPY bronze.erp_cust_az12
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		
		RAISE NOTICE 'Inserting Data Into: bronze.erp_loc_a101';
		COPY bronze.erp_loc_a101
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		RAISE NOTICE '----------------------------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
		RAISE NOTICE 'Inserting Data Into: bronze.erp_px_cat_g1v2';
		COPY bronze.erp_px_cat_g1v2
		FROM '/Users/manaswinid/Documents/Projects/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
		WITH (
			FORMAT csv,
		    HEADER true,
		    DELIMITER ','
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time)));
		batch_end_time := clock_timestamp();

		RAISE NOTICE '==============================================';
		RAISE NOTICE 'Loading the Bronze Layer is completed';
		RAISE NOTICE 'Batch Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (batch_end_time - batch_start_time)));
		RAISE NOTICE '==============================================';
	
	EXCEPTION  
		WHEN OTHERS THEN
			RAISE NOTICE '==============================================';
			RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
			RAISE NOTICE 'Error Message: %', SQLERRM;
			RAISE NOTICE 'Error State: %', SQLSTATE;
			RAISE NOTICE '==============================================';
	END;

END;
$$;