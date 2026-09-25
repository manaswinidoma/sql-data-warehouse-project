# Gold Layer Data Catalog

## Overview

The Gold layer is the business reporting layer of the data warehouse. It brings together customer, product, and sales information in a format that is ready for dashboards, reports, and analysis.

It helps answer common business questions such as:

- Who are our customers and where are they located?
- What products do we sell and how are they grouped?
- What was sold, to whom, when, and for how much?

The catalog contains three main views:

- `gold.dim_customers`: customer dimension
- `gold.dim_products`: current product dimension
- `gold.fact_sales`: sales transaction fact view

Together, these views connect sales activity to customer and product information. This makes it easier for business users to measure sales, review customer activity, and analyze product performance.

## Data Model

## `gold.dim_customers`

This customer dimension uses CRM customer data and adds customer and location data from ERP.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `customer_key` | INT | Surrogate key that uniquely identifies each customer record in the dimension table. |
| `customer_id` | INT | Unique numeric identifier assigned to each customer. |
| `customer_number` | VARCHAR(50) | Alphanumeric customer identifier used for tracking and reference. |
| `first_name` | VARCHAR(50) | Customer's first name as recorded in the system. |
| `last_name` | VARCHAR(50) | Customer's last name or family name. |
| `country` | VARCHAR(50) | Customer's country of residence, such as Australia. |
| `marital_status` | VARCHAR(50) | Customer's marital status, such as Married or Single. |
| `gender` | VARCHAR(50) | Customer's gender, such as Male, Female, or `n/a`. |
| `birth_date` | DATE | Customer's date of birth, stored in `YYYY-MM-DD` format. |
| `create_date` | DATE | Date when the customer record was created in the system. |

## `gold.dim_products`

This product dimension uses CRM product data and adds category information from ERP. It contains current products only.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `product_key` | INT | Surrogate key that uniquely identifies each product record in the dimension table. |
| `product_id` | INT | A unique identifier assigned to the product for internal tracking and referencing. |
| `product_number` | VARCHAR(50) | Code that represents the product and supports inventory and category tracking. |
| `product_name` | VARCHAR(50) | Product's descriptive name, which can include its type, color, or size. |
| `category_id` | VARCHAR(50) | Unique ID that links the product to its main category. |
| `category` | VARCHAR(50) | Broader classification for related products, such as Bikes or Components. |
| `subcategory` | VARCHAR(50) | Detailed group that describes the product within its category. |
| `maintenance` | VARCHAR(50) | States whether maintenance is required for the product, using values such as `Yes` or `No`. |
| `cost` | INT | Monetary amount representing the product's cost or base price. |
| `product_line` | VARCHAR(50) | Identifies the product series to which the product belongs, such as Road or Mountain. |
| `start_date` | DATE | Date on which the product became available for sale or use, recorded as `YYYY-MM-DD`. |

## `gold.fact_sales`

This fact view contains sales order-line data and the surrogate keys from the gold dimensions.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `order_number` | VARCHAR(50) | Unique alphanumeric identifier assigned to each sales order, such as `SO54496`. |
| `product_key` | INT | Surrogate key that links the order line to the product dimension. |
| `customer_key` | INT | Surrogate key that links the order line to the customer dimension. |
| `order_date` | DATE | Date on which the customer placed the order. |
| `shipping_date` | DATE | Date on which the order was shipped to the customer. |
| `due_date` | DATE | Date by which payment for the order was due. |
| `sales_amount` | INT | Total monetary value of the order line, recorded in whole currency units, such as 25. |
| `quantity` | INT | Number of product units ordered on the order line, such as 1. |
| `price` | INT | Price of one product unit on the order line, recorded in whole currency units, such as 25. |

## Relationship and Usage Notes

- Join sales to customers with `fact_sales.customer_key = dim_customers.customer_key`.
- Join sales to products with `fact_sales.product_key = dim_products.product_key`.
- Add `sales_amount`, `quantity`, and `price` based on the needs of the report. Check whether `price` is a unit price or line price before using it to calculate revenue.
- The product dimension removes old product versions. A sale for an old product may therefore have a null `product_key`.
- `ROW_NUMBER()` creates the surrogate keys when the views run. The key values can change if the source data or ordering changes.
- This catalog describes the SQL in `scripts/gold/ddl_gold.sql`.
