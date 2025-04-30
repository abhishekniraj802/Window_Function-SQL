-- Window Function 

create database mySQLWF;
use mySQLWF;

-- Create sales table -- 

CREATE TABLE sales(
	year INT,
    country varchar(50),
    product VARCHAR(50),
    profit INT

);

-- Insert data into sales table

INSERT INTO sales (year, country, product, profit) VALUES
(2000, 'Finland', 'Computer', 1500),
(2000, 'Finland', 'Phone', 100),
(2001, 'Finland', 'Phone', 10),
(2000, 'India', 'Calculator', 75),
(2000, 'India', 'Calculator', 75),
(2000, 'India', 'Computer', 1200),
(2000, 'USA', 'Calculator', 75),
(2000, 'USA', 'Computer', 1500),
(2001, 'USA', 'Calculator', 50),
(2001, 'USA', 'Computer', 1500),
(2000, 'USA', 'Computer', 1200),
(2000, 'USA', 'TV', 150),
(2000, 'USA', 'TV', 100);


-- 1 Introduction to window Function 

 Window functions perform calculations across a "window" of rows determined by the 
without actually grouping those rows together as a regular aggregate function would.

The key parts of a window function are:
 The window function itself (like SUM, AVG, ROW_NUMBER)
 The OVER clause, which defines the "window" of rows
 Optional PARTITION BY, which divides rows into groups
 Optional ORDER BY, which determines the order of rows within each partition
 Optional frame clause, which further refines which rows are included
 
-- Basic Syntax

--  SELECT
    --  column1, column2, 
    --  WINDOW_FUNCTION() OVER (
	-- 	[PARTITION BY column] 
	--	[ORDER BY column] 
	--	[Frame_clause]
    --	) AS alias_name
-- FROM table_name;


--  2. Simple Aggregate Window Functions

SELECT 
	year,
    country,
    product,
    profit,
    AVG(profit) OVER() AS avg_profit
FROM sales;


-- 3. PARTITION BY: Grouping Data Without Collapsing Rows

SELECT 
	year,
    country,
    product,
    profit,
    AVG(profit) OVER(Partition BY country) AS country_avg_profit
FROM sales;

-- We can Multiple aggeragate by country

SELECT 
	year,
    country,
    product,
    profit,
    AVG(profit) OVER(Partition BY country) AS country_avg_profit,
    SUM(profit) OVER(Partition BY country) AS country_total_profit,
    COUNT(*) OVER(Partition BY country) AS country_sales_count
FROM sales;

-- 4. ORDER BY: Creating Running Totals and Moving

SELECT
	year,
    country,
    product,
    profit,
    SUM(profit) OVER(ORDER BY year) AS running_total
FROM sales;

-- We can combine PARTITION BY and ORDER BY

SELECT
	year,
    country,
    product,
    profit,
    SUM(profit) OVER(Partition BY country ORDER BY year) AS country_running_profit
FROM sales;

--  5. Ranking Functions

-- ROW_NUMBER() : Assigns unique sequential numbers

SELECT
	year,
    country,
    product,
    profit,
    row_number() OVER(ORDER BY profit DESC) AS profit_rank
FROM sales;

-- RANK() and DENSE_RANK(): Handle ties differently
-- DENSE_RANK() not supported in version 8
SELECT
    year,
    country,
    product,
    profit,
    ROW_NUMBER() OVER(ORDER BY profit DESC) AS profit_num,
    RANK() OVER(ORDER BY profit DESC) AS rank_with_gaps,
    DENSE_RANK() OVER(ORDER BY profit DESC) AS dense_rank
FROM sales;

-- Rank products by profit within each country


SELECT
	year,
    country,
    product,
    profit,
    RANK() OVER(PARTITION BY country ORDER BY profit DESC) AS profit_rank_in_country
FROM sales;


--  6. NTILE(): Dividing Results into Equal Groups

SELECT 
	year,
    country,
    product,
    profit,
    NTILE(3) OVER(ORDER BY profit DESC) AS profit_tercile
FROM sales;

--  LEAD and LAG  
LEAD() and LAG()
are time-series window functions which let us grab values from subsequent or
previous records relative to the position of the "current" record in our data.-> They can be useful any time we want to compare a value in a given column to the next or previous
value in the same column — but side by side, in the same row.-> This is a very common problem in real-world analytics scenarios.

--  1. How to use the LEAD() function to access data from the next row in the same result set without using a self-join?
 
LEAD(profit, 1): This specifies that we want to access the profit value from the next row (1 row ahead).
PARTITION BY country: This divides the result set into partitions by country .
ORDER BY year, product: This specifies the order of the rows within each partition.
 
 SELECT
	year,
    country,
    profit,
    LEAD(profit, 1) OVER(PARTITION BY country ORDER BY year, product) AS next_profit
FROM sales;


-- 7. Lead and Lag Functions: Accessing Previous and Next Rows
-- Compare each sale with the next and previous sale

SELECT 
	year,
    country,
    product,
    profit,
    LAG(profit) OVER(ORDER BY year, country, product) AS previous_profit,
    LEAD(profit) OVER(ORDER BY year, country, product) AS next_profit
FROM sales;

-- Calculate profit difference from previous sale

SELECT
	year,
    country,
    product,
    profit,
    
    profit - LAG(profit, 1, 0) OVER(ORDER BY year, country, product) AS profit_change
FROM sales;

The second parameter (1) is the offset, and the third parameter (0) is the default value if there's no
 previous row.

 -- 8. Using Window Functions in Analytical Queries
 
 --  Calculating percentage of total
 -- Calculate what percentage each sale contributes to country's total profit
 
 SELECT
	year,
    country,
    product,
    profit,
    profit / SUM(profit) OVER(PARTITION BY country) * 100 AS percent_of_country_profit
FROM sales;


-- Finding products with above-average profits
-- Find sales with above-average profit

 SELECT
	year,
	country,
	product,
	profit,
	AVG(profit) OVER() AS avg_profit
FROM sales
 WHERE profit > (SELECT AVG(profit) FROM sales);
 
 -- Limiting by rank using subqueries
 
 -- Find the top 2 most profitable products in each country
 
 WITH RankedSales AS (
 SELECT
 year,
 country,
 product,
 profit,
 RANK() OVER(PARTITION BY country ORDER BY profit DESC) AS profit_rank
 FROM sales
 )
 SELECT
 year,
 country,
 product,
 profit
 FROM RankedSales
 WHERE profit_rank <= 2;
 
 
 9. Window Function Limitations
 Window functions can only appear in the SELECT or ORDER BY clauses
 Window functions are processed after regular aggregations, WHERE, and GROUP BY
 Window functions cannot be nested directly, though you can use subqueries or CTEs
 10. Summary and Best Practices
 Window functions provide powerful analytical capabilities:
 Use empty OVER() for whole-table calculations
 Use PARTITION BY similar to GROUP BY, but without reducing rows
 Add ORDER BY for running totals and cumulative values
 Use ranking functions for position-based analysis
 LEAD/LAG help with time-series and sequential analyses
 Window functions greatly improve SQL's analytical capabilities by allowing you to perform complex
 calculations while preserving the detail rows of your data, avoiding the need for self-joins or
 subqueries in many cases


