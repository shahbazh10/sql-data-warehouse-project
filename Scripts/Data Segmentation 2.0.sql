/* Group customers into three segments based on their spendng behaviour:
- VIP: Customers with atleast 12 months of history and spending more than €5,000.
- Regular : Customers with atleast 12 months of history but spending €5,000 or less.
- New: Customers with a lifespan less than 12 months.
AND find total number of cusomers by each group
*/

With customer_spending AS( 
Select
c.customer_key,
SUM(f.sales_amount) as total_spending,
MIN(f.order_date) as first_order,
MAX(f.order_date) as last_order,
datediff(Month, MIN(f.order_date), MAX(f.order_date)) as Lifespan
from Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
on f.customer_key=c.customer_key
Group By c.customer_key)

Select
customer_segment,
COUNT(customer_key) as total_customers
FROM(
Select
customer_key,
CASE WHEN total_spending > 5000 AND Lifespan>=12 THEN 'VIP'
WHEN total_spending <= 5000 AND Lifespan>= 12 THEN 'Regular'
ELSE 'New'
END customer_segment
from customer_spending)t
Group by customer_segment
Order by total_customers DESC
