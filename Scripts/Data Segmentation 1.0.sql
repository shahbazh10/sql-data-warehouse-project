/* Segment products into cost ranges and
count how many products fall into each segment*/

With product_segments as (
Select
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
WHEN cost BETWEEN 100 AND 500 THEN '100-500'
WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
ELSE 'Above 1000'
END cost_range
from Gold.dim_products)

SELECT
cost_range,
Count(product_key) as total_products
FROM product_segments
Group by cost_range
Order by total_products DESC