                            --ADVANCED ANALYTICS PROJECT--

/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

SELECT * FROM gold.dim_customers

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

SELECT * FROM gold.dim_products

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

SELECT * FROM gold.fact_sales

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM "C:\Users\Hp\Downloads\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv"
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM "C:\Users\Hp\Downloads\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.dim_products.csv"
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM "C:\Users\Hp\Downloads\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.fact_sales.csv"
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO
--============================================================================================================================
--==============================================================================================================================
			--CHAGE-OVER-TIME(Trends)--

--1. Analyze Sales Performance Over Time.

--DATABASE
USE
	DataWarehouseAnalytics

--OVERALL DATA:-
SELECT
	* 
FROM
	gold.fact_sales

SELECT
	YEAR(order_date) as order_Years,
	MONTH(order_date) as order_Month,
	SUM(sales_amount) as Total_Sales,
	COUNT(DISTINCT customer_key) as Total_customers,
	SUM(quantity) as Total_quantity
FROM
	gold.fact_sales
WHERE
	order_date IS NOT NULL
GROUP BY
	YEAR(order_date),MONTH(order_date)
ORDER BY
	YEAR(order_date),MONTH(order_date)

	--(OR)--

SELECT
	FORMAT(order_date,'yyyy-MMM') as order_date,
	SUM(sales_amount) as Total_Sales,
	COUNT(DISTINCT customer_key) as Total_customers,
	SUM(quantity) as Total_quantity
FROM
	gold.fact_sales
WHERE
	order_date IS NOT NULL
GROUP BY
	FORMAT(order_date,'yyyy-MMM')
ORDER BY
	FORMAT(order_date,'yyyy-MMM')
-----------------------------------------------

			--COMULATIVE ANALYSTICS--

--2. Calculate the total sales per month and
   --the running total of sales over time.

SELECT
	order_date,
	total_sales,
--windows function
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS moving_avg_price
--sub query
FROM
	(
	SELECT
		DATETRUNC(year, order_date) AS order_date,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM
		gold.fact_sales
	WHERE 
		order_date IS NOT NULL
	GROUP BY
		DATETRUNC(year, order_date)
	--ORDER BY
		--DATETRUNC(month, order_date)
)t
---------------------------------------------------------------------------------

				--Performance Analysis--

--3. Analyze the yearly performance of products by comparing each Product's
-- to both its average sales performance and the previous year's sales.

WITH 
	Yearly_product_sales as
(
SELECT
	YEAR(f.order_date) as Order_year,
	p.product_name,
	SUM(f.sales_amount) as Current_sales
FROM
	gold.fact_sales f
LEFT JOIN
	gold.dim_products p
ON
	f.product_key=p.product_key
WHERE 
	f.order_date IS NOT NULL
GROUP BY
	YEAR(f.order_date),
	p.product_name
)

SELECT
	Order_year,
	product_name,
	Current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
	current_sales-AVG(current_sales) OVER (PARTITION BY product_name) diff_avg,
CASE WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name)>0 THEN 'Above Average'
	 WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name)<0 THEN 'Below Average'
	 ELSE 'Avg'
END
	avg_change,
--Year_Over_Year_Analysis
LAG
	(Current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales,
	Current_sales-LAG (Current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales-LAG (Current_sales) OVER (PARTITION BY product_name ORDER BY order_year)>0 THEN 'Increase'
	 WHEN current_sales-LAG (Current_sales) OVER (PARTITION BY product_name ORDER BY order_year)<0 THEN 'Decrease'
	 ELSE 'No Change'
END
	py_change
FROM
	Yearly_product_sales
ORDER BY
	product_name,
	Order_year

---------------------------------------------------------------------

			--Part_To_Whole_Analysis--

--4. Which categories conrribute the most to overall sales?

WITH
	category_sales AS(
SELECT
	category,
	SUM(sales_amount) total_sales
FROM
	gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON
	p.product_key=f.product_key
GROUP BY
	category
)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER() overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER())*100,2),'%')AS Percentage_of_total
FROM
	category_sales
ORDER BY
	total_sales DESC

--------------------------------------------------------------------------------------------------------------

			--Data_Segmentation--

--5. Segment productrs into cost range and
   --count how many products fall into seach segment.

WITH product_segments AS(
SELECT
	product_key,
	product_name,
	cost,
CASE
	WHEN cost <100 THEN 'Below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	ELSE 'Above 1000'
END
	cost_range

FROM
	gold.dim_products
)

SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM
	product_segments
GROUP BY
	cost_range
ORDER BY
	COUNT(product_key) DESC

--------------------------------------------------------------------

/* --6. GROUP customers into three segments based on their spending behaviot:
		--VIP: Customers with at least 12 months of history and spending more than ₹5,000.
		--Regular: Customers with at least 12 months of history but spending ₹5,000 or less.
		--NEW: Customers with a lifespen less than 12 months.
		--And find the total numbers of customers by each group
*/

WITH customer_spending AS(
SELECT
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(order_date) AS fisrt_order,
	MAX(order_date) AS last_order,
	DATEDIFF(month,MIN(order_date), MAX(order_date)) AS lifespan
FROM
	gold.fact_sales f
	LEFT JOIN
	gold.dim_customers c
	ON
	f.customer_key=c.customer_key
GROUP BY
	c.customer_key
)
SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM(
		SELECT
			customer_key,
			total_spending,
			lifespan,
			CASE 
				WHEN lifespan >=12 AND total_spending >5000 THEN 'VIP'
				WHEN lifespan >=12 AND total_spending <= 5000 THEN 'Regular'
				ELSE 'New'
		END customer_segment
		FROM
			customer_spending
GROUP BY
	customer_segment
ORDER BY
	total_customers DESC

--======================================================================================================================================================
--======================================================================================================================================================

/*
===================================================================================================
										Customer Report
===================================================================================================
Purpose:
	-This report connsolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such names,age, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregate customer-level metrics:
		-total orders
		-total sales
		-total quantity purchased
		-total products
		-lifespen (in months)
	4. Calculates valuable KPIs:
		-recency (months since last order)
		-average order value
		-average monthly spend
===================================================================================================
*/

WITH base_query AS (
/*----------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(year, c.birthdate, GETDATE()) AS age
    FROM
        gold.fact_sales f
        LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    WHERE
        order_date IS NOT NULL
),
customer_aggregations AS (
/*----------------------------------------------------------------------------
2) Customersd Aggregations: Summarize key matrics at the customer level
-----------------------------------------------------------------------------*/
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM
        base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    last_order_date,
    lifespan,
--compute average order value (AVO)
	CASE WHEN total_sales=0 THEN 0
		 ELSE total_sales / total_orders
	END AS avg_order_value,

--compute average monthly spend
	CASE WHEN lifespan=0 THEN total_sales
		 ELSE total_sales/lifespan
	END AS avg_monthly_spend
FROM
    customer_aggregations

--=====================================================================================================================================
--===================================================================================================================================

/*
===============================================================================
Product Report
===============================================================================
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
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO
--SELECT * FROM gold.report_products

CREATE VIEW gold.report_products AS
WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations 