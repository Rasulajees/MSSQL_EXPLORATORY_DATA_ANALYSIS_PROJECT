📊 Data Warehouse Analytics Project 🚀

Overview
Welcome to the Data Warehouse Analytics Project! This project is designed to create a robust data warehouse for advanced analytics, focusing on sales performance, customer behavior, and product metrics.

🏗️ Database Creation
The script initiates by creating a new database named DataWarehouseAnalytics. If the database already exists, it will be dropped and recreated.

⚠️ Warning
Running this script will permanently delete all data in the DataWarehouseAnalytics database if it exists. Please ensure you have proper backups before proceeding!

📂 Schema and Tables
Schema
gold: This schema contains the main tables for analytics.

Tables
dim_customers: Customer information.
dim_products: Product details.
fact_sales: Sales transaction data.

📥 Data Ingestion
Data is loaded into the tables using the BULK INSERT command from CSV files. The tables are truncated before loading new data to prevent duplication.

📈 Analytics Queries
The project includes several analytical queries to derive insights:

1. 📅 Sales Performance Over Time
Analyzes total sales, unique customers, and quantity sold over time, grouped by year and month.

2. 📊 Cumulative Analytics
Calculates total sales per month and the running total of sales over time using window functions.

3. 📦 Yearly Product Performance
Compares each product's sales performance to its average and the previous year's sales.

4. 📊 Category Contribution to Sales
Identifies which product categories contribute the most to overall sales.

5. 💰 Product Segmentation by Cost
Segments products into cost ranges and counts how many products fall into each segment.

6. 👥 Customer Segmentation by Spending Behavior
Segments customers into VIP, Regular, and New categories based on their spending and lifespan.

📋 Customer Report
The customer report consolidates key metrics and behaviors, including:

Total orders, sales, quantity purchased, and products.
Customer segmentation by age and spending behavior.
Key performance indicators such as recency, average order value, and average monthly spend.

📦 Product Report
The product report consolidates key product metrics, including:

Total orders, sales, quantity sold, and unique customers.
Segmentation of products by revenue performance.
Key performance indicators such as recency, average order revenue, and average monthly revenue.

⚙️ Usage
To run the script:

Ensure you have SQL Server installed and configured.
Update the file paths in the BULK INSERT commands to point to your CSV files.
Execute the script in SQL Server Management Studio (SSMS) or any SQL client that supports T-SQL.

⚠️ Caution
Running this script will drop the existing DataWarehouseAnalytics database if it exists, leading to permanent data loss. Ensure you have proper backups before executing the script.

🎉 Conclusion
