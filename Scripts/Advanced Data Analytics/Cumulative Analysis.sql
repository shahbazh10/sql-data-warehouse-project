-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) as running_total_sales,
AVG(Avg_Price) OVER (ORDER BY order_date) as moving_average
From
(Select
DATETRUNC(Year,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(sls_price) as Avg_Price
from Gold.fact_sales
where order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
)t