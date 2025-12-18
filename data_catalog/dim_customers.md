# dim_customers

## Description
Customer dimension that provides a consolidated view of customer information
for analytics and reporting.

## Grain
One row per customer.

## Source Tables
- Silver.crm_cust_info
- Silver.erp_cust_az12
- Silver.erp_loc_a101

## Business Keys
- customer_id
- customer_number

## Surrogate Key
- customer_key
