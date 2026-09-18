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

select * from menu;

-- 1. total amount each customer spent at the restaurant?
select customer_id, sum(price)
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id
order by customer_id;


-- 2. how many days has each customer visited hte restuarant?
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
with fav_item as (select m.product_name
from sales s
join menu m
on s.product_id = m.product_id
group by s.product_id, m.product_name
order by count(*) desc
limit 1)

select s.customer_id, count(*) as num_times_ordered
from sales s
join menu m
on s.product_id = m.product_id 
where m.product_name = (select * from fav_item)
group by s.customer_id 
order by s.customer_id;




-- 5. whic item was most popular for each customer
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


-- 8. whaqt is the total items and amount spent for each member before they became a member?
select s.customer_id, count(*) as num_items, sum(price) as total_spent
from sales s
join members m
on s.customer_id  = m.customer_id
join menu mn
on s.product_id = mn.product_id 
where s.order_date < m.join_date
group by s.customer_id
order by s.customer_id;

-- 9. - 860 points for A 
select s.customer_id,
sum(case when m.product_name = 'sushi' then m.price * 2 *10 else m.price*10 end) 
from sales s
join menu m
on s.product_id = m.product_id 
group by s.customer_id
order by s.customer_id ;


-- 10.
select s.customer_id,
sum(case when s.order_date between join_date and join_date+6 then price * 2 * 10
		 when mn.product_name='sushi' 
		 	then price*2*10 
		 else price*10 
	end) as points
from sales s
join members m
on s.customer_id = m.customer_id
join menu mn
on s.product_id = mn.product_id 
where s.order_date <='2021-01-31'
group by s.customer_id;
