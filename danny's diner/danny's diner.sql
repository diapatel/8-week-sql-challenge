USE dannys_diner;

---------------------------------------------------------------------------------------------------------------
-- Q1 - total amount each customer spent at the restaurant
SELECT customer_id , CONCAT('$ ',SUM(price)) AS "total_amount"
FROM sales t1
JOIN menu t2
ON t1.product_id = t2.product_id
GROUP BY t1.customer_id;

-------------------------------------------------------------------------------------------------------
-- Q2 - how many days has each customer visited the restaurant
SELECT customer_id, COUNT(DISTINCT order_date) AS "num_days_visited"
FROM sales
GROUP BY customer_id;

------------------------------------------------------------------------------------------------------------------
-- Q3 - what was the first item from the menu purchased by each customer
SELECT customer_id, GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS "food_items"
FROM (SELECT customer_id, product_name,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS "rank_num"
FROM sales t1
JOIN menu t2
ON t1.product_id = t2.product_id) t
WHERE t.`rank_num`=1
GROUP BY customer_id;

-------------------------------------------------------------------------------------------------------------
-- Q4 - What is the most purchased item on the menu and how many times was it ordered?
SELECT product_name, COUNT(*) AS "order_count"
FROM sales t1
JOIN menu t2
ON t1.product_id = t2.product_id
GROUP BY t1.product_id
ORDER BY COUNT(*) DESC
LIMIT 1;

------------------------------------------------------------------------------------------------------------------

-- Q5 - Which item was the most popular for each customer?

SELECT customer_id, GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS "fav_food"
FROM (SELECT customer_id, product_name,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*)) AS "rank_num"
FROM sales t1
JOIN menu t2
ON t1.product_id = t2.product_id
GROUP BY customer_id, t1.product_id) t
WHERE t.rank_num=1
GROUP BY customer_id;

------------------------------------------------------------------------------------------------------------
-- Q6 - Which item was purchased by the customer first after they became a member?

SELECT customer_id, GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS "product_name"
FROM (SELECT t1.customer_id, join_date, order_date, t2.product_id, product_name, DATEDIFF(join_date, order_date),
DENSE_RANK() OVER(PARTITION BY t1.customer_id ORDER BY DATEDIFF(join_date, order_date)) AS "rank_num"
FROM members t1
JOIN sales t2
ON t1.customer_id=  t2.customer_id
JOIN menu t3
ON t2.product_id =  t3.product_id
WHERE order_date < join_date) t
WHERE t.rank_num=1
GROUP BY customer_id;

---------------------------------------------------------------------------------------------------
--  Q8- What is the total items and amount spent for each member before they became a member?
SELECT t1.customer_id, COUNT(*) AS "num_items", CONCAT('$ ', SUM(price)) AS "total_price"
FROM sales t1
JOIN members t2
ON t1.customer_id = t2.customer_id
JOIN menu t3
ON t1.product_id = t3.product_id
WHERE order_date < join_date
GROUP BY t1.customer_id
ORDER BY t1.customer_id;

-------------------------------------------------------------------------------------------------------------
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT t1.customer_id, 
SUM(CASE 
	WHEN product_name = 'sushi' THEN price*20
    ELSE price*10
END) AS "points"
FROM sales t1
JOIN menu t2
ON t1.product_id = t2.product_id
GROUP BY t1.customer_id;

-----------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------
-- Q10 - in the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January

SELECT t1.customer_id,
SUM(IF(order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY), price*10*2,
		IF(product_name='sushi', price*10*2, price*10))) AS "customer_points"
FROM sales t1
JOIN members t2
ON t1.customer_id= t2.customer_id
JOIN menu t3
ON t1.product_id = t3.product_id
WHERE order_date >= join_date
AND order_date < '2021-01-31'
GROUP BY t1.customer_id
ORDER BY t1.customer_id;

--------------------------------------------------------------------------------------------------------------------------
-- BONUS :Create basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. Fill Member column as 'N' 
-- if the purchase was made before becoming a member and 'Y' if the after is amde after joining the membership. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for 
-- non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH data_table AS (SELECT t1.customer_id,
order_date,
product_name,
price,
IF(order_date>=join_date, 'Y','N') AS "is_member"
FROM sales t1
JOIN members t2
ON t1.customer_id = t2.customer_id
JOIN menu t3
ON t1.product_id = t3.product_id
ORDER BY t1.customer_id, order_date)
SELECT *,
IF (`is_member` = 'N', NULL, DENSE_RANK() OVER(PARTITION BY customer_id
												ORDER BY order_date)) AS "ranking"
FROM data_table;

--------------------------------------------------------------------------------------------------------

