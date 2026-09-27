/*
==================================================================================
Product Report
==================================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
==================================================================================
*/

-- STEP BY STEP APPROACH
Create View Gold.report_products AS
With base_query as(

--1) Base Query: Retrieve Core columns from the table

Select
f.order_number,
f.customer_key,
f.order_date,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from Gold.fact_sales f
LEFT JOIN Gold.dim_products p
on f.product_key = p.product_key
WHERE f.order_date IS NOT NULL),


product_aggregations as(
-- 2) Product aggregation: Summarizes key metrics at the product level  

Select
product_key,
product_name,
subcategory,
category,
cost,
MAX(order_date) as last_sale_date,
COUNT(distinct order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity_sold,
COUNT( DISTINCT customer_key) as total_customers,
DATEDIFF(Month,MIN(order_date),MAX(order_date)) as Lifespan,
Round(AVG (CAST(sales_amount AS FLOAT)/ nullif(quantity,0)),1) as avg_selling_price

from base_query
Group by product_key,
product_name,
subcategory,
category,
cost)

SELECT
product_key,
product_name,
subcategory,
category,
cost,
last_sale_date,
DATEDIFF(Month, last_sale_date, GETDATE()) as recency_in_months,
CASE 
    WHEN total_sales > 50000 THEN 'High Revenue'
    WHEN total_sales >=10000 THEN 'Mid-Range'
ELSE 'Low-Performer'
End as product_segment,
Lifespan,
total_orders,
total_sales,
total_quantity_sold,
total_customers,
avg_selling_price,
--Average Order Revenue (AOR)

CASE 
    WHEN total_orders=0 THEN 0
    ELSE (total_sales/total_orders)
End as avg_order_revenuem,
-- Average monthly revenue
CASE 
    WHEN lifespan=0 THEN 0
    Else total_sales/lifespan
End as avg_monthly_revenue

from product_aggregations


SELECT*
FROM Gold.report_products
