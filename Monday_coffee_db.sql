-- Monday Coffee 

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;


--Reports and Data Analysis

--1 How many people in each city are estimated to consume coffee ,given that 25% of the population does?

  SELECT 
 city_name,
  ROUND((population * 0.25)/1000000 ,2) AS coffee_consumers_in_millions,
  city_rank
  FROM city
  ORDER BY 2 DESC

--2 What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

  SELECT 
       ci.city_name,
       SUM(s.total) AS total_revenue
	   FROM sales AS s
	   JOIN customers AS c
	   ON s.customer_id = c.customer_id
	   JOIN city AS ci
	   ON ci.city_id = c.city_id
	   WHERE
	   EXTRACT(YEAR FROM s.sales_date) = 2023
	   AND 
	   EXTRACT(quarter FROM s.sales_date) = 4
	   GROUP BY 1
	   ORDER BY 2 DESC

--3 How many units of each coffee product have been sold?
   SELECT 
    p.product_name ,
	COUNT(s.sale_id) AS total_orders
  FROM products AS p
   LEFT JOIN 
   sales AS s
   ON s.product_id = p.product_id
   GROUP BY 1
   ORDER BY 2 DESC

--4 What is the average sales amount per customer in each city?
-- need 
-- city and total sales
-- no of customer in these city
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customer,
   ROUND(
	SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric 
	,2) AS avg_sale_per_cust
	
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

-- city population and coffee consumers(25%)
--5 Provide a list of cities along with their populations and estimated coffee consumers.
-- Return city_name, total current customer, estimated coffee consumers(25%)

WITH city_table AS
(  SELECT
  city_name,
 ROUND((population * 0.25 / 1000000),2) AS coffee_consumers_in_millions
 FROM city
),

customer_table
AS
(
SELECT 
 ci.city_name,
 COUNT(DISTINCT c.customer_id) AS unique_customer
 FROM sales AS s
 JOIN customers AS c
 ON c.customer_id = s.customer_id
 JOIN city AS ci
 ON ci.city_id = c.city_id
 GROUP BY 1
 )
  SELECT
  ct.city_name,
  ct.coffee_consumers_in_millions,
  cit.unique_customer
  FROM city_table AS ct
  JOIN customer_table AS cit
  ON cit.city_name = ct.city_name

--6 Top selling product by city
--What are the top 3 selling products in each city bsed on sales volume?
SELECT *
FROM -- TABLE NAME
(
 SELECT
 ci.city_name,
 p.product_name,
 COUNT(s.sale_id) AS total_orders,
 DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY  COUNT(s.sale_id) DESC ) AS rank
  FROM sales AS s
  JOIN products AS p
  ON s.product_id = p.product_id  
  JOIN customers AS c
  ON c.customer_id = s.customer_id
  JOIN city AS ci
  ON ci.city_id = c.city_id
  GROUP BY 1,2
--  ORDER BY 1, 3 DESC
) AS t1
  
   WHERE  rank <= 3 


--7 How many unique customers are there in each city who have purchased coffee products?

  SELECT 
  ci.city_name,
  COUNT(DISTINCT c.customer_id) AS unique_customer
  FROM
  city AS ci
  
  LEFT JOIN 
  customers AS c
  ON c.city_id = ci.city_id
  JOIN sales AS s
  ON s.customer_id = c.customer_id
  WHERE 
  s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
  GROUP BY 1


--8 Find each city and their average sales per customer and avg rent per customer
 WITH city_table
 AS
( SELECT 
    ci.city_name,
    
   
    COUNT(DISTINCT s.customer_id) AS total_customer,
   ROUND(
	SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric
	,2)AS avg_sale_per_cust
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS 
(
SELECT 
 city_name,
 estimated_rent 
 FROM city
 )
 SELECT 
  cr.city_name,
 cr.estimated_rent,
 ct.total_customer,
 ct.avg_sale_per_cust,
ROUND(
cr.estimated_rent::numeric/ct.total_customer::numeric
,2) AS avg_rent_per_customer
 FROM city_rent AS cr
 JOIN city_table AS ct
 ON cr.city_name = ct.city_name
 ORDER BY 4 DESC

--9 Monthly sales growth
--Sales growth rate : calculate the percentage growth (or decline ) in sales over different time periods(monthly)
 -- by each city
WITH
monthly_sales
AS
(
SELECT  
ci.city_name ,
EXTRACT(MONTH FROM sale_date) AS month,
EXTRACT(YEAR FROM sale_date) AS year,
SUM(s.total) AS total_sale

 FROM sales AS s
 JOIN customers AS c
 ON c.customer_id = s.customer_id
 JOIN city AS ci
 ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio
AS
(
SELECT 
city_name,
month,
year,
total_sale AS current_month_sale,
LAG(total_sale,1) OVER(PARTITION BY city_name ORDER BY year,month) AS last_month_sale
FROM monthly_sales
)
SELECT 
city_name,
month,
year,
current_month_sale,
last_month_sale,
ROUND(
(current_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100
,2) 
AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL


--10 Market potential Analysis
--Identify the top 3 citybased on highest sales, returncity name,totalsale,total,rent,total,customers,estimated
--coffee consumer


WITH city_table
 AS
( SELECT 
    ci.city_name,
    	SUM(s.total) as total_revenue,
   
    COUNT(DISTINCT s.customer_id) AS total_customer,
   ROUND(
	SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric
	,2)AS avg_sale_per_cust
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS 
(
SELECT 
 city_name,
 estimated_rent ,
ROUND((population * 0.25)/1000000 ,3)AS estimated_coffee_consumer_millions
 FROM city
 )
 SELECT 
  cr.city_name,
  total_revenue,
 cr.estimated_rent AS total_rent,
 ct.total_customer,
 estimated_coffee_consumer_millions,
 ct.avg_sale_per_cust,
ROUND(
cr.estimated_rent::numeric/ct.total_customer::numeric
,2) AS avg_rent_per_customer
 FROM city_rent AS cr
 JOIN city_table AS ct
 ON cr.city_name = ct.city_name
 ORDER BY 2 DESC

 /*
 recommendation
 City 1. Pune
   1. avg_rent_per_customer is very less,
   2. Highest total_revenue,
   3. avg_sale_per_customer is also high

  City 2. Delhi
    1. Highest estimated_coffee_consumer which is 7.7M,
	2. Highest total_customer which is 68,
	3. Average rent_per_customer is 330 (still under 500)

  City 3.Jaipur
    1. Highest total_customer which is 69,
	2. Average rent_per_customer is very less which is 156,
	3. avg_sale_per_customer is better which is 11.6K
	
   
   