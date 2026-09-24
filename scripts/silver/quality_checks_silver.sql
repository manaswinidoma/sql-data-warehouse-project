/*
===============================================================================
Data Quality Checks for Silver Layer
===============================================================================
This script contains data quality validation queries used to review the quality
of the transformed data after it has been loaded into the silver layer.

The checks are grouped by source domain:
- CRM datasets: customer, product, and sales data
- ERP datasets: customer, location, and product category data

These queries help identify issues such as duplicates, null values, invalid
formatting, inconsistent codes, unexpected dates, and broken business rules.
===============================================================================
*/

-------------------------------------------
-- CRM DATA QUALITY CHECKS
-------------------------------------------

-- Data filtering: identify duplicate customer IDs and missing primary keys.
SELECT * FROM silver.crm_cust_info;

SELECT 
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Data standardization and consistency check: trim and validate customer name values.
SELECT 
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Data standardization and consistency check: confirm normalized gender values.
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

-- Data standardization and consistency check: confirm normalized marital status values.
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;



-------------------
SELECT * FROM silver.crm_prd_info;

SELECT 
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Data standardization and consistency check: detect unwanted spaces in product names.
SELECT 
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Business rule validation: identify negative or missing product cost values.
SELECT 
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization and consistency check: validate normalized product line values.
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Data validation: flag invalid product date ranges where end date is earlier than start date.
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

--------------------------------
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Data standardization and consistency check: detect untrimmed order numbers and whitespace issues.
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

---check for invalid dates

SELECT * FROM silver.crm_sales_details;

-- Outlier detection and date validation: flag invalid date sequences in sales transactions.
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Business rule validation: confirm sales, quantity, and price remain logically consistent after transformation.
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Expected business rules during validation:
-- If sales is negative, zero, or null, derive it using quantity and price.
-- If price is zero or null, calculate it using sales and quantity.
-- If price is negative, convert it to a positive value.
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-------------------------------------------
-- ERP DATA QUALITY CHECKS
-------------------------------------------

-- Outlier detection: identify unrealistic birth dates in ERP customer data.
SELECT 
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1926-01-01' OR bdate > CURRENT_DATE;

-- Data standardization and consistency check: confirm normalized gender values.
SELECT DISTINCT gen
FROM silver.erp_cust_az12;

-- Data quality review: inspect the cleaned ERP customer dimension after transformation.
SELECT * FROM silver.erp_cust_az12;

-------
---Validation in silver table 
SELECT * FROM silver.erp_loc_a101;

-- Data standardization and consistency check: confirm normalized country values.
SELECT DISTINCT cntry FROM silver.erp_loc_a101;

-- Data quality review: validate ERP category data for consistency after transformation.
SELECT * FROM silver.erp_px_cat_g1v2;