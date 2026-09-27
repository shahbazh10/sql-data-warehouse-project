/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
       - total orders
       - total sales
       - total quantity purchased
       - total products
       - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
===============================================================================
*/

--STEP BY STEP APPROACH

CREATE VIEW gold.report_customers AS
WITH base_query AS(
-- 1) Base Query: Retrieve core columns from tables
Select
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name,' ', c.last_name) AS customer_name,
    DATEDIFF(Year, c.birthdate, GETDATE()) age
from Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
ON f.customer_key = c.customer_key
where order_date IS NOT NULL)


,customer_aggregation as(
-- 2) Customer aggregation: Summarizes key metrics at the customer level  
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(Distinct order_number) as Total_Orders,
    SUM(sales_amount) as Total_Sales,
    SUM(quantity) as total_quantity,
    COUNT(Distinct product_key) as total_products,
    MAX(order_date) as last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) as lifespan
FROM base_query
GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age)

SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
    WHEN age<20 THEN 'Under 20'
    When age between 20 and 29 THEN '20-29'
    When age between 30 and 39 THEN '30-39'
    When age between 40 and 49 THEN '40-49'
    ELSE '50 and Above'
End as age_group,
CASE 
    WHEN Total_Sales > 5000 AND Lifespan>=12 THEN 'VIP'
    WHEN Total_Sales<= 5000 AND Lifespan>= 12 THEN 'Regular'
    ELSE 'New'
END customer_segment,
DATEDIFF(month,last_order_date, GETDATE()) AS recency,
Total_Orders,
Total_Sales,
total_quantity,
total_products,
last_order_date,
lifespan,
-- Compute average order value (AVO)
CASE WHEN
Total_Orders = 0 THEN 0
ELSE Total_Sales/Total_Orders 
END AS avg_order_value,

-- Compute average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
ELSE Total_Sales/lifespan
END AS avg_monthly_spend

from customer_aggregation

