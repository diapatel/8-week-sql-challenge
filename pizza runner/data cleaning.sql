SELECT *
FROM customer_orders;
-------------------------------------------------------------

-- cleaning exclusions and extras column and creating a new temporary table called customer_orders_temp
CREATE TEMPORARY TABLE customer_orders_temp AS 
SELECT order_id,
	customer_id,
    pizza_id,
    CASE WHEN exclusions = '' THEN NULL
		 WHEN exclusions = 'null' THEN NULL
		 ELSE exclusions
	END AS "exclusions",
CASE WHEN extras =''  THEN NULL
	 WHEN extras = 'null' THEN NULL
     ELSE extras
END AS "extras",
	order_time
FROM customer_orders;

SELECT * 
FROM runner_orders;

CREATE TEMPORARY TABLE runner_orders_temp AS
SELECT order_id,
	runner_id,
    CASE WHEN pickup_time LIKE 'null' THEN NULL
		 ELSE pickup_time
	END AS "pickup_time",
    CASE WHEN distance LIKE 'null' THEN NULL
		ELSE CAST(REGEXP_REPLACE(distance, '[a-z]+','') AS FLOAT)
    END AS "distance",
    CASE WHEN duration = 'null' THEN NULL
		ELSE CAST(REGEXP_REPLACE(duration, '[a-z]+', '') AS FLOAT)
	END AS "duration",
    CASE WHEN cancellation = '' THEN NULL
		 WHEN cancellation LIKE 'null' THEN NULL
         ELSE cancellation
	END AS "cancellation"
FROM runner_orders;

SELECT *
FROM runner_orders_temp;

-------------------------------------------------------------------------------------
-- pizza toppings
SELECT * FROM pizza_toppings;
--------------------------------------------------------------------------------------------

SELECT * FROM pizza_recipes;







