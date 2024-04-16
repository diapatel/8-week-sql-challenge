-- Q1- What is the unique count and total amount for each transaction type?

SELECT txn_type, COUNT(*) AS "customer_count", SUM(txn_amount) AS "total_amount"
FROM customer_transactions
GROUP BY txn_type;

--------------------------------------------------------------------------------------------------------------

-- Q2 - What is the average total historical deposit counts and amounts for all customers?
SELECT customer_id, COUNT(*) AS "deposit_count", SUM(txn_amount) AS "total_amount"
FROM customer_transactions
WHERE txn_type='deposit'
GROUP BY customer_id
ORDER BY customer_id;

---------------------------------------------------------------------------------

-- Q3 - For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
USE data_bank;

WITH txn_type_cte AS (SELECT MONTH(txn_date) AS "txn_month", customer_id, 
	SUM(IF(txn_type='deposit',1,0))  AS deposit_count,
    SUM(IF(txn_type='purchase',1,0))  AS purchase_count,
    SUM(IF(txn_type='withdrawal',1,0))  AS withdrawal_count
FROM customer_transactions
GROUP BY customer_id, MONTH(txn_date)) 

SELECT `txn_month`, COUNT(customer_id) AS "customer_count"
FROM txn_type_cte
WHERE deposit_count>1 AND (withdrawal_count=1 OR purchase_count=1)
GROUP BY txn_month
ORDER BY txn_month;

--------------------------------------------------------------------------------------------------------------

-- Q4 - What is the closing balance for each customer at the end of the month?
WITH net_txn_cte AS (SELECT customer_id, 
	MONTH(txn_date) AS "month",
    SUM(CASE
			WHEN txn_type ='deposit' THEN txn_amount
			ELSE -txn_amount
			END) AS "net_txn_amount"
FROM customer_transactions
GROUP BY customer_id, MONTH(txn_date)
ORDER BY customer_id) 

SELECT customer_id, `month`, net_txn_amount,
	SUM(net_txn_amount) OVER(PARTITION BY customer_id 
								ORDER BY `month` ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "closing_balance"
FROM net_txn_cte;

---------------------------------------------------------------------------------------------------------------------------
