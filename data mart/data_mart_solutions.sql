SELECT * FROM weekly_sales;
DROP TABLE clean_weekly_sales;

-- DATA CLEANING 
CREATE TABLE clean_weekly_sales AS
SELECT
	week_date AS "original_date",
	DATE_FORMAT(STR_TO_DATE(week_date, "%d/%m/%y"), "%Y-%m-%d")AS "week_date",
	WEEK(DATE_FORMAT(STR_TO_DATE(week_date, "%d/%m/%y"), "%Y-%m-%d")) AS "week_number",
    MONTH(week_date) AS "month_number",
    YEAR(DATE_FORMAT(STR_TO_DATE(week_date, "%d/%m/%y"), "%Y-%m-%d")) AS "calendar_year",
    CASE
		WHEN segment = "null" OR segment = "" OR RIGHT(segment, 1)=0 THEN "Unknown"
		WHEN CAST(RIGHT(segment, 1) AS DECIMAL) = 1 THEN "Young Adults"
        WHEN CAST(RIGHT(segment, 1) AS DECIMAL) = 2 THEN "Middle Aged"
        WHEN CAST(RIGHT(segment, 1) AS DECIMAL) IN (3,4) THEN "Retirees"
	END AS "age_band",
    
    CASE
		WHEN segment ="null" OR segment ="" THEN "Unknown"
		WHEN LEFT(segment,1) = "C" THEN "Couples"
        WHEN LEFT(segment, 1) = "F" THEN "Families"
	END AS "demographic",
    
	ROUND(sales / transactions, 2) AS "avg_transaction"
FROM weekly_sales;

SELECT * FROM clean_weekly_sales;


-- DATA EXPLORATION STARTS
-- Q1 day of week that is used for each week_date value
SELECT DAYOFWEEK(week_date) AS "day_of_week" FROM weekly_sales;

-- Q2 - week numbers that are missing from the data
    
WITH RECURSIVE week_numbers AS
	(SELECT 1 AS "week_number"
    UNION ALL
    SELECT week_number+1
    FROM week_numbers
    WHERE week_number<53)
SELECT DISTINCT t1.week_number
FROM week_numbers t1
LEFT JOIN clean_weekly_sales t2
ON t1.week_number = t2.week_number ;

-- Q3 - total transactions for each year
SELECT YEAR(STR_TO_DATE(week_date, "%d/%m/%y")) AS "year", SUM(transactions) AS "total_transactions"
FROM weekly_sales 
GROUP BY YEAR(STR_TO_DATE(week_date, "%d/%m/%y"))
ORDER BY `year`;

-- Q4 -Total sales for each region for each month
SELECT region, 
	MONTHNAME(STR_TO_DATE(week_date, "%d/%m/%y")) AS "month_name",
	SUM(sales) AS "total_sales"
FROM weekly_sales
GROUP BY region, MONTHNAME(STR_TO_DATE(week_date, "%d/%m/%y"));

-- Q5 - total count of transactions for each platform
SELECT platform, SUM(transactions) AS "transaction_count"
FROM weekly_sales
GROUP BY platform;


-- Q6 - % of sales of retail vs shopify for each month
SELECT MONTHNAME(STR_TO_DATE(week_date, "%d/%m/%y")) AS "month_name", 
	platform, 
    ROUND((SUM(sales) / (SELECT SUM(sales) FROM weekly_sales)) * 100, 2)  AS "sales_percent"
FROM weekly_sales
GROUP BY MONTHNAME(STR_TO_DATE(week_date, "%d/%m/%y")), platform
ORDER BY MONTHNAME(STR_TO_DATE(week_date, "%d/%m/%y")), platform;

-- Q7 - sales percent by demographic by year
SELECT calendar_year, 
	demographic, 
	(SUM(sales) / (SELECT SUM(sales) FROM weekly_sales)) AS "sales_percent"
FROM clean_weekly_sales t1
JOIN weekly_sales t2
ON t1.original_date =  t2.week_date
GROUP BY calendar_year, demographic
ORDER BY calendar_year, demographic;


-- q8 - the age band and demographic which contribute the most to sales
WITH total_sales_cte AS  (SELECT age_band, demographic, SUM(sales) AS "total_sales",
							RANK() OVER(ORDER BY SUM(sales)) AS "sales_rank"
							FROM weekly_sales t1
							JOIN clean_weekly_sales t2
							ON t1.week_date = t2.original_date
							WHERE platform = "Retail"
							GROUP BY age_band, demographic
							ORDER BY age_band, demographic)
SELECT age_band, demographic
FROM total_sales_cte
WHERE sales_rank=1;


-- Q9 - average transaction for each year for retail vs shopify
SELECT calendar_year, platform, ROUND(AVG(transactions), 2) AS "average_transaction_size"
FROM weekly_sales t1
JOIN clean_weekly_sales t2
ON t1.week_date = t2.original_date
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform; 


-- BEFORE AND AFTER ANALYSIS
SELECT 
	SUM(CASE WHEN t2.week_date >= "2020-06-15" THEN sales ELSE 0 END) AS "total_sales_after",
	SUM(CASE WHEN t2.week_date < "2020-06-15" THEN sales ELSE 0 END) AS "total_sales_before"
FROM weekly_sales t1
JOIN clean_weekly_sales t2
ON t1.week_date = t2.original_date
WHERE t2.week_date BETWEEN DATE_SUB(t2.week_date, INTERVAL 4 WEEK) AND DATE_ADD(t2.week_date, INTERVAL 4 WEEK);

-- sales 12 weeks before and after 2020-06-15
WITH sales_cte AS (SELECT 
			SUM(CASE WHEN t2.week_date >= "2020-06-15" THEN sales ELSE 0 END) AS "total_sales_after",
			SUM(CASE WHEN t1.week_date < "2020-06-15" THEN sales ELSE 0 END) AS "total_sales_before"
		FROM clean_weekly_sales t1
		JOIN weekly_sales t2
		ON t1.original_date = t2.week_date
		WHERE t1.week_date BETWEEN DATE_SUB("2020-06-15", INTERVAL 12 WEEK) AND DATE_ADD("2020-06-15", INTERVAL 12 WEEK))
	
SELECT *, ROUND(((total_sales_after - total_sales_before) / total_sales_before) * 100, 2) AS "percent_growth"
FROM sales_cte;

WITH sales_summary_cte AS (WITH sales_cte AS (SELECT t1.week_date, t2.original_date, t2.week_date AS "corrected_week_date", t2.calendar_year, sales
					FROM weekly_sales t1
					JOIN clean_weekly_sales t2
					ON t1.week_date = t2.original_date)
SELECT 
 "2018" AS "year",
 SUM(sales) AS "total_sales"
FROM sales_cte
WHERE calendar_year="2018"

UNION 
SELECT 
 "2019" AS "year",
 SUM(sales) AS "total_sales"
FROM sales_cte
WHERE calendar_year="2019"

UNION
SELECT 
	"12 weeks before 2020-06-15" AS "year",
    SUM(CASE WHEN `corrected_week_date` < "2020-06-15" THEN sales ELSE 0 END) AS "total_sales"
FROM sales_cte
WHERE calendar_year="2020" AND `corrected_week_date` < "2020-06-15"

UNION
SELECT 
	"12 weeks after 2020-06-15" AS "year",
    SUM(CASE WHEN `corrected_week_date` >= "2020-06-15" THEN sales ELSE 0 END) AS "total_sales"
FROM sales_cte
WHERE calendar_year="2020" AND `corrected_week_date` >= "2020-06-15")


SELECT *,
ROUND(((total_sales - LAG(total_sales) OVER()) / LAG(total_sales) OVER()) * 100, 2) AS "difference_percent"
FROM sales_summary_cte;
