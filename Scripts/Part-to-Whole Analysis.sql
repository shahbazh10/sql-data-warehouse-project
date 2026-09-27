-- Which categories contribute the most to overall sales.
WITH category_sales AS(
Select
d.category,
SUM(f.sales_amount) total_sales
from Gold.fact_sales f
LEFT JOIN Gold.dim_products d
ON f.product_key=d.product_key
Group by d.category)

SELECT
category,
total_sales,
SUM(total_sales)  OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales as FLOAT)/SUM(total_sales)  OVER ())*100,2),'%') AS percentage_total
from category_sales
Order BY total_sales DESC