/* Analyse the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales*/

With yearly_product_sales AS(

Select
YEAR(f.order_date) as Order_Year,
d.product_name,
SUM(f.sales_amount) as current_sales
from Gold.fact_sales f
LEFT JOIN Gold.dim_products d
ON f.product_key = d.product_key
Where  f.order_date IS NOT NULL
Group by YEAR(f.order_date),d.product_name)

Select
Order_Year,
product_name,
current_sales,
AVG(current_sales) over (Partition by product_name) avg_sales,
current_sales-AVG(current_sales) over (Partition by product_name) as diff_avg,
CASE WHEN current_sales-AVG(current_sales) over (Partition by product_name) > 0 THEN 'Above Avg'
WHEN current_sales-AVG(current_sales) over (Partition by product_name) < 0 THEN 'Below Avg'
Else 'Avg'
END avg_change,
--Year-over-Year Analysis
LAG(current_sales) Over (Partition by product_name Order By Order_Year) as py_sales,
current_sales - LAG(current_sales) Over (Partition by product_name Order By Order_Year) as diff_py,
CASE WHEN current_sales - LAG(current_sales) Over (Partition by product_name Order By Order_Year) > 0 THEN 'Increase'
WHEN current_sales - LAG(current_sales) Over (Partition by product_name Order By Order_Year) < 0 THEN 'Decrease'
Else 'No change'
END py_change
from yearly_product_sales
Order by product_name,Order_Year