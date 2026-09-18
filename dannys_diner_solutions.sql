set search_path = "dannys_diner";

-------------------------------------------------------------------------
-- CREATE THE SCHEMA 
---------------------------------------------------------------------------
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

---------------------------------------------------------------------
-- Case study questions
--------------------------------------------------------

select * from members;

-- 1. total amount each customer spent at the restaurant?
select customer_id, sum(price)
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id
order by customer_id;


-- 2. how many days has each customer visited the restuarant?
select customer_id,  count(distinct order_date) as num_days_visited
from sales
group by customer_id
order by customer_id;

-- 3. what was the first item from the menu purchased by each customer
with orders_ranked_cte as (select *,
dense_rank() over(partition by customer_id order by order_date) as rnk
from sales)

select customer_id, order_date, product_name, rnk
from orders_ranked_cte t1
join menu m
on t1.product_id = m.product_id
where rnk=1
order by customer_id;


-- 4. most purchased item on the menu and how many times was ti purchased by each customer
-- using cte here and not just limit 1 because what if multiple items had the same freq and that was the max freq
with freq as (select s.product_id, count(*) as order_freq
from sales s
group by s.product_id)
select m.product_name, order_freq
from freq f
join menu m on f.product_id = m.product_id 
where order_freq = (select max(order_freq) from freq);

-- 5. which item was most popular for each customer
with item_order_count_cte as (select customer_id, product_id, count(*) order_frequency
from sales
group by customer_id, product_id
order by customer_id, product_id),
 
fav_foods_cte as (
select *,
dense_rank() over(partition by customer_id order by order_frequency desc) as rnk
from item_order_count_cte)

select customer_id, product_name, order_frequency
from fav_foods_cte c
join menu m
on c.product_id = m.product_id
where rnk=1
order by customer_id;

-- 6. which item was first purhcased by the customer after they became a member
with orders_after_mship_cte as (select m.customer_id, join_date, order_date, s.product_id
from members m
join sales s
on m.customer_id = s.customer_id 
where s.order_date >= m.join_date),

 orders_ranked as (
select *,
dense_rank() over(partition by c.customer_id order by order_date) as rnk
from orders_after_mship_cte c
)

select c.customer_id, product_name, join_date, order_date
from orders_ranked c
join menu m
on c.product_id = m.product_id
where rnk=1
order by c.customer_id;



-- 7. which item was purchased just before the customer became a member?
with ranked as (select s.customer_id, s.product_id,
dense_rank() over(partition by s.customer_id order by s.order_date desc) as rnk
from sales s
join members m on s.customer_id = m.customer_id 
where s.order_date < m.join_date)

select r.customer_id, m.product_name
from ranked r
join menu m on r.product_id = m.product_id 
where rnk=1
order by r.customer_id;


-- 8. what is the ttoal items and amoutn spent for each member before they became a member?
select s.customer_id, count(*), sum(m.price)
from sales s 
join members mb on s.customer_id = mb.customer_id 
join menu m on s.product_id = m.product_id 
where s.order_date < mb.join_date
group by s.customer_id
order by s.customer_id;


-- 9. if each $1 spent equates to 10 points and sushi has a 2x multiplier, find total points for each customer
select s.customer_id,
sum(case when m.product_name='sushi' then m.price * 2* 10 else m.price*10 end) as points
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id 
order by s.customer_id;


-- 10. if a customer orders within one week of their join date, they get a 2x multiplier points on all the items they order, not just sushi
-- find the total points for each customer for orders before january 31 
select s.customer_id ,
sum(case when s.order_date between mb.join_date and mb.join_date + interval '6 days'
			then m.price * 2* 10
		when m.product_name='sushi' then m.price * 2* 10
		else m.price * 10 end)
	 as points
from sales s
join menu m on s.product_id = m.product_id 
join members mb on s.customer_id = mb.customer_id 
where s.order_date <= '2021-01-31'
group by s.customer_id 
order by s.customer_id;


--------------------------------------------------------------------------------------------------------------------------
-- list of all questions
-- 1. what is the total amount spent by each customer
-- 2. hwo many days has each custmer visited?
-- 3. what was teh first item on the menu purchased by each customer?
-- 4. most frequently purchased item on the menu and how many times was it purchased?
-- 5. which item was most popular for each customer?
-- 6. which item was purchased first by the customer after they became a member?
-- 7.which item was purchased just before the customer became a member?
-- 8. what is the ttoal items and amoutn spent for each member before they became a member?
-- 9. if each $1 spent equates to 10 points and sushi has a 2x multiplier, find total points for each customer
-- 10. if a customer orders within one week of their join date, they get a 2x multiplier points on all the items they order, not just sushi
-- find the total points for each customer for orders before january 31 

















