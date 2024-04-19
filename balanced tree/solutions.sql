USE balanced_tree;

-- HIGH LEVEL ANALYSIS
-- Q1 - Total quantity of products sold
SELECT SUM(qty) AS "Total_quantity_sold"
FROM sales;

-- Q2 - Total revenue before discount
SELECT SUM(qty*price) AS "Total_revenue_before_discount"
FROM sales;

-- Q3 - total discount amount for all products
SELECT SUM(discount) AS "total_discount_for_all_products"
FROM sales;

-- TRANSACTION ANALYSIS
-- 1. Number of unique transactions
SELECT COUNT(DISTINCT txn_id) AS "num_unique_transactions"
FROM sales;

-- 2. Average number of unique products per transaction
SELECT AVG(DISTINCT prod_id) AS "avg_unique_products_per_txn"
FROM sales;

-- 3. average discount value per transaction
SELECT ROUND(AVG(discount), 2) AS "average_discount_value"
FROM sales;

-- 4. Percentage split of transactions for members vs. non-members
SELECT `member`, ROUND(((COUNT(DISTINCT txn_id) / (SELECT COUNT(DISTINCT txn_id) FROM sales))) * 100, 2) AS "percent_of_transactions"
FROM sales
GROUP BY `member`;

-- 5. Average revenue for members and non-members
SELECT `member`, ROUND(AVG(price*qty - discount), 2) AS "average_revenue_before_discount"
FROM sales
GROUP BY `member`;

-- PRODUCT ANALYSIS
-- 1. Top 3 products by revenue before discount
SELECT prod_id, product_name, SUM(qty*t1.price) AS "revenue_before_discount"
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY t1.prod_id, product_name
ORDER BY SUM(qty*price) DESC 
LIMIT 3;

-- total quantity, revenue and discount for each segment
SELECT segment_id, segment_name, SUM(qty) AS "total_quantity", SUM(qty*t1.price) AS "total_revenue", SUM(discount) AS "total_discount"
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY segment_id, segment_name
ORDER BY segment_id;

-- 3. Top selling product for each segment
WITH product_rank_cte AS (SELECT segment_id, segment_name, product_name, SUM(qty * t1.price) AS "total_sales",
						RANK() OVER(PARTITION BY segment_name ORDER BY SUM(qty * t1.price)) AS "product_rank"
						FROM sales t1
						JOIN product_details t2
						ON t1.prod_id = t2.product_id
						GROUP BY segment_id, segment_name, product_name
						ORDER BY segment_id)

SELECT segment_name, product_name, total_sales
FROM product_rank_cte
WHERE product_rank=1;

-- Total quantity, revenue and discount for each category
SELECT category_id, category_name, SUM(qty) AS "total_quantity", SUM(qty*t1.price) AS "total_sales", SUM(discount) AS "total_discount"
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY category_id, category_name;

-- Top selling product for each category
WITH product_rank_cte AS (SELECT category_name, product_name, SUM(qty*t2.price) AS "total_sales",
								RANK() OVER(PARTITION BY category_name ORDER BY SUM(qty*t2.price) DESC) AS "product_rank"
							FROM sales t1
							JOIN product_details t2
							ON t1.prod_id = t2.product_id
							GROUP BY category_name, product_name
							ORDER BY category_name, product_name)

SELECT category_name, product_name, total_sales
FROM product_rank_cte
WHERE product_rank=1;

-- percentage split of revenue by product for each segment
SELECT segment_name, product_name, ROUND(((SUM(qty*t2.price) / (SELECT SUM(qty*price) FROM sales)) * 100), 2) AS "sales_percent_split"
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY segment_name, product_name
ORDER BY segment_name, product_name;

-- percentage split of revenue for each segment by category
SELECT category_name, segment_name, ROUND(((SUM(qty*t2.price) / (SELECT SUM(qty*price) FROM sales)) * 100), 2) AS "percent_split"
FROM sales t1 
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY category_name, segment_name
ORDER BY category_name, segment_name;

-- percentage split of total revenue by category
SELECT category_name, ROUND((SUM(qty*t2.price) / (SELECT SUM(qty*price) FROM sales)) * 100, 2) AS "percent_split"
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY category_name
ORDER BY category_name;

-- Transaction penetration of each product
SELECT prod_id, 
	product_name,  
    SUM(CASE WHEN qty>1 THEN 1 ELSE 0 END) / (SELECT COUNT(DISTINCT txn_id) FROM sales) AS "penetration" 
FROM sales t1
JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY prod_id, product_name
ORDER BY `penetration` DESC;

-- most common combination of 3 products
WITH combinations_cte AS (SELECT t1.txn_id, t1.prod_id AS "prod1", t2.prod_id AS "prod2", t3.prod_id AS "prod3"
							FROM sales t1 
							JOIN sales t2
							ON t1.txn_id = t2.txn_id AND t1.prod_id < t2.prod_id
							JOIN sales t3
							ON t2.txn_id = t3.txn_id AND t2.prod_id < t3.prod_id
							WHERE t1.qty>=1 AND t2.qty>=2 AND t3.qty>=1)
                            
SELECT t2.product_name AS "product1", 
		t3.product_name AS "product2",
		t4.product_name AS "product3",
		COUNT(*) AS "frequency"
FROM combinations_cte t1
JOIN product_details t2
ON t1.prod1 = t2.product_id
JOIN product_details t3
ON t1.prod2 = t3.product_id
JOIN product_details t4
ON t1.prod3 = t4.product_id
GROUP BY prod1, prod2, prod3, t2.product_name, t3.product_name, t4.product_name
ORDER BY `frequency` DESC
LIMIT 1;
