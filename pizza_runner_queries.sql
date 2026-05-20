SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

--------------------------------------------------------------------------------------------------------
-- DATA CLEANING
---------------------------------------------------------------------------------------------
-- cleaning customer_orders
select *
from customer_orders
where exclusions like '%,%';

update customer_orders 
set exclusions = case 
	when exclusions in ('','null') then null 
	else exclusions
	end,
	extras = case
	when extras in ('', 'null') then null
	else extras
end;

create table order_exclusions as
select order_id,
trim(unnest(string_to_array(exclusions, ','))) as exclusion_id
from customer_orders
where exclusions is not null;

create table order_extras as
select order_id,
trim(unnest(string_to_array(extras, ','))) as exclusion_id
from customer_orders
where exclusions is not null;

-- drop columns exclusions and extras from customer_orders table
alter table customer_orders
drop column exclusions,
drop column extras;

-- cleaning runner orders
update runner_orders
set pickup_time = case 
		when pickup_time in ('', 'null') then null
		else pickup_time
		end,
	distance = case 
		when distance in ('', 'null') then null
		else cast(replace(distance, 'km','') as float)
	end,
	duration = case
		when duration in ('null', '') then null
		else cast(regexp_replace(duration, '[^0-9]', '', 'g') as int)
	end,
	cancellation = case
		when cancellation in ('', 'null') then null
		else cancellation 
	end;

select * from runner_orders;

-- normalize pizza_recipes
create table pizza_recipes_normalized as
select pizza_id,
cast(trim(unnest(string_to_array(toppings, ','))) as int) as topping_id
from pizza_recipes;

select * from pizza_recipes_normalized;


---------------------------------------------------------------------------------------------------
-- A. PIZZA METRICS
----------------------------------------------------------------------------------------------
-- 1. How many pizzas were ordered?
select count(order_id) 
from customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct order_id)
from customer_orders;

-- 3. How many successful orders were delivered by each runner?
select runner_id, count(*)
from runner_orders
where cancellation is null
group by runner_id
order by runner_id;

--4. How many of each type of pizza was delivered?
select pn.pizza_name, count(*)
from runner_orders ro
join customer_orders co
on ro.order_id = co.order_id
join pizza_names pn 
on co.pizza_id = pn.pizza_id 
where cancellation is null
group by co.pizza_id, pn.pizza_name;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select co.customer_id,
sum(case when pn.pizza_name = 'Vegetarian' then 1 else 0 end) as num_vegetarian,
sum(case when pn.pizza_name = 'Meatlovers' then 1 else 0 end) as num_meatlovers
from customer_orders co
join pizza_names pn 
on co.pizza_id = pn.pizza_id 
group by co.customer_id 
order by co.customer_id;


-- 6.What was the maximum number of pizzas delivered in a single order?
select co.order_id, count(*)
from runner_orders ro
join customer_orders co
on ro.order_id = co.order_id 
where cancellation is null
group by co.order_id
order by count(*) desc
limit 1;


-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id,
  SUM(CASE WHEN EXISTS (SELECT 1 FROM order_exclusions e WHERE e.order_id = c.order_id)
            OR EXISTS (SELECT 1 FROM order_extras ex WHERE ex.order_id = c.order_id) 
           THEN 1 ELSE 0 END) AS with_changes,
  SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM order_exclusions e WHERE e.order_id = c.order_id)
            AND NOT EXISTS (SELECT 1 FROM order_extras ex WHERE ex.order_id = c.order_id) 
           THEN 1 ELSE 0 END) AS no_changes
FROM customer_orders c
JOIN runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

select * from order_exclusions;

-- 8. How many pizzas were delivered that had both exclusions and extras?
select 
sum(case when exists(select 1 from order_exclusions e where ro.order_id = e.order_id)
			and exists (select 1 from order_extras  et where ro.order_id = et.order_id)
	then 1 else 0 end) 
from runner_orders ro
join customer_orders co
on ro.order_id = co.order_id
where cancellation is null;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
select extract(hour from order_time) as hour_of_day, count(*)
from customer_orders
group by hour_of_day
order by hour_of_day;


-- 10. What was the volume of orders for each day of the week?
select extract(DOW from order_time) day_of_week, count(*)
from customer_orders
group by day_of_week
order by day_of_week;