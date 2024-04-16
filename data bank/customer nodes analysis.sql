-- Q1 - How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS "node_count"
FROM customer_nodes;

---------------------------------------------------------------------------------------------------------------------

-- Q2 - What is the number of nodes per region?
SELECT t1.region_id, region_name, COUNT(node_id) AS "node_count"
FROM customer_nodes t1
JOIN regions t2
ON t1.region_id = t2.region_id
GROUP BY t1.region_id;

----------------------------------------------------------------------------------------------------------------

-- Q3 - How many customers are allocated to each region?
SELECT t1.region_id, region_name, COUNT(DISTINCT customer_id) AS "customer_count"
FROM customer_nodes t1
JOIN regions t2
ON t1.region_id = t2.region_id
GROUP BY t1.region_id;

-------------------------------------------------------------------------------------------------------------------

-- Q4 - 
SELECT ROUND(AVG(DATEDIFF(end_date, start_date)),2 ) AS "avg_num_days"
FROM customer_nodes
WHERE end_Date != '9999-12-31';

----------------------------------------------------------------------------------------------------------------------
USE data_bank;
-- Q5- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- median
WITH reallocation_days_cte AS
  (SELECT *,
          (datediff(end_date, start_date)) AS reallocation_days
   FROM customer_nodes
   INNER JOIN regions USING (region_id)
   WHERE end_date!='9999-12-31'),
     percentile_cte AS
  (SELECT *,
          percent_rank() over(PARTITION BY region_id
                              ORDER BY reallocation_days)*100 AS p
   FROM reallocation_days_cte)
SELECT region_id,
       region_name,
       reallocation_days
FROM percentile_cte
WHERE p >50;

-- 85th percentile
WITH reallocation_days_cte AS 
		(SELECT *,
				DATEDIFF(end_date, start_date) AS "reallocation_days"
		FROM customer_nodes  t1
        JOIN regions t2
        USING (region_id)
		WHERE end_date !='9999-12-31'),
        
        percentile_cte AS (SELECT *,
							percent_rank() OVER(PARTITION BY customer_id ORDER BY start_date)*100 AS p
					FROM reallocation_days_cte)
                    
SELECT region_id,
       region_name,
       reallocation_days
FROM percentile_cte
WHERE p > 85
GROUP BY region_id
ORDER BY region_id;

-- 95th percentile
WITH reallocation_days_cte AS 
		(SELECT *,
				DATEDIFF(end_date, start_date) AS "reallocation_days"
		FROM customer_nodes  t1
        JOIN regions t2
        USING (region_id)
		WHERE end_date !='9999-12-31'),
        
        percentile_cte AS (SELECT *,
							percent_rank() OVER(PARTITION BY customer_id ORDER BY start_date)*100 AS p
					FROM reallocation_days_cte)
                    
SELECT region_id,
       region_name,
       reallocation_days
FROM percentile_cte
WHERE p > 95
GROUP BY region_id
ORDER BY region_id;

