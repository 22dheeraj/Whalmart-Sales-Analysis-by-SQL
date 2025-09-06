/*
  IMPORTANT NOTE:

  The queries in this project are ideally written using Common Table Expressions (CTEs) 
  with the `WITH` clause for better readability and maintainability.

  I highly recommend upgrading the target server to MySQL 8.0 or later to ensure compatibility
  and to take full advantage of these improvements in future maintenance and scalability.
*/

-- Task 1: Top Branch by Sales Growth Rate
WITH MonthlySales AS (
    SELECT 
        Branch,
        DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') AS Month_Year,
        SUM(Total) AS Monthly_Sales
    FROM walmartsales
    GROUP BY Branch, Month_Year
),

GrowthCalc AS (
    SELECT 
        Branch,
        Month_Year,
        Monthly_Sales,
        LAG(Monthly_Sales) OVER (PARTITION BY Branch ORDER BY Month_Year) AS Prev_Month_Sales
    FROM MonthlySales
)

SELECT 
    Branch,
    ROUND(AVG((Monthly_Sales - Prev_Month_Sales) / Prev_Month_Sales) * 100, 2) AS Avg_Monthly_Growth_Rate_Percent
FROM GrowthCalc
WHERE Prev_Month_Sales IS NOT NULL
GROUP BY Branch
ORDER BY Avg_Monthly_Growth_Rate_Percent DESC;

-- Task 2: Most Profitable Product Line per Branch

WITH RankedProfits AS (
    SELECT 
        Branch,
        Product_line,
        round(SUM(Gross_Income),2) AS Total_Profit,
        RANK() OVER (PARTITION BY Branch ORDER BY SUM(Gross_Income) DESC) AS Rnk
    FROM 
        WalmartSales
    GROUP BY 
        Branch, Product_line
)
SELECT 
    Branch,
    Product_line AS Most_Profitable_Product_Line,
    Total_Profit
FROM 
    RankedProfits
WHERE 
    rnk = 1;
    
-- Task 3: Customer Segmentation Based on Spending

with avg_spending as(
select Customer_ID,round(avg(Total),2) as avg_spend from walmartsales
group by Customer_ID
)

select Customer_ID, avg_spend,
case
 when avg_spend<300 then 'low'
 when avg_spend between 300 and 325 then "Medium"
 else "High"
end as Spending_Tier
from avg_spending
order by Customer_ID;

-- Task 4: Detecting Anomalies in Sales

with product_avg as (

select Product_line, round(avg(Total),2) as avg_total from walmartsales
group by Product_line
)

select w.Invoice_ID, w.Customer_ID,w.Product_line, w.Total, p.avg_total,
case
 when w.Total>1.5*p.avg_total then 'High Anomly'
 when w.Total<0.5*p.avg_total then 'Low Anomly'
 else 'Normal'
end as Anomly_Flag
from  walmartsales as w 
join product_avg as p 
on  w.Product_line=p.Product_line
where w.Total>1.5*p.avg_total or w.Total<0.5*p.avg_total;

-- Task 5: Most Popular Payment Method by City

WITH payment_counts AS (
  SELECT 
    City,
    Payment,
    COUNT(*) AS payment_count
  FROM walmartsales
  GROUP BY City, Payment
),
ranked_payments AS (
  SELECT 
    City,
    Payment,
    payment_count,
    RANK() OVER (PARTITION BY City ORDER BY payment_count DESC) AS rnk
  FROM payment_counts
)
SELECT 
  City,
  Payment AS most_popular_payment_method,
  payment_count
FROM ranked_payments
WHERE rnk = 1;

-- Task 6: Monthly Sales Distribution by Gender

select Gender, monthname((str_to_date(Date, '%d-%m-%Y'))) as month_name  ,round(sum(Total),2) as total_sales from walmartsales
group by Gender, month_name
ORDER BY str_to_date(concat('01-', month_name, '-2024'), '%d-%M-%Y'), Gender;

-- Task 7: Best Product Line by Customer Type

with p_line as(
select Customer_type, Product_line as best_product_line, count(*) as total_purchase from walmartsales
group by Customer_type, best_product_line
),
ranked as(
select *,
row_number() over(partition by Customer_type order by Customer_type, total_purchase desc) as row_num
from p_line)
select Customer_type, best_product_line, total_purchase from ranked
where row_num=1;

-- Task 8: Identifying Repeat Customers (within 30 days)

select * from walmartsales;
WITH formatted_sales AS (
  SELECT 
    Customer_ID,
    STR_TO_DATE(Date, '%d-%m-%Y') AS purchase_date
  FROM walmartsales
),
ranked_sales AS (
  SELECT 
    Customer_ID,
    purchase_date,
    LEAD(purchase_date) OVER (PARTITION BY Customer_ID ORDER BY purchase_date) AS next_purchase_date
  FROM formatted_sales
)
SELECT 
  Customer_ID,
  purchase_date,
  next_purchase_date,
  DATEDIFF(next_purchase_date, purchase_date) AS days_between
FROM ranked_sales
WHERE DATEDIFF(next_purchase_date, purchase_date) <= 30;

-- Task 9: Top 5 Customers by Sales Volume

select Customer_ID, round(sum(Total),2) as Sales_Revenue from walmartsales
group by Customer_ID
order by Sales_Revenue desc
limit 5;

-- Task 10: Sales Trends by Day of the Week

select dayname(str_to_date(Date, '%d-%m-%Y')) as day_of_week, round(sum(Total),2)as Total_Sales 
from walmartsales
group by day_of_week
order by Total_Sales desc
limit 1;    
