CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

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

select * from members;

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(price) as total_spent
from sales s 
join menu m 
on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as num_days_visited
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with order_items_ranked_cte as (select *,
							dense_rank() over(partition by customer_id order by order_date) as rnk
							from sales)
							
select customer_id, product_name
from order_items_ranked_cte oi
join menu m
on oi.product_id = m.product_id
where rnk=1
order by customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(*) as purchase_frequency
from sales s
join menu m
on s.product_id = m.product_id 
group by s.product_id, m.product_name 
order by count(*) desc
limit 1;


-- 5. Which item was the most popular for each customer?
with item_order_freq_cte as (select customer_id, product_id, count(*) as order_freq
							from sales
							group by customer_id,product_id ),

customer_favs_ranked as ( select *,
dense_rank() over(partition by customer_id order by order_freq desc) as rnk
from item_order_freq_cte
				)
				
select cfr.customer_id, m.product_name 
from customer_favs_ranked cfr
join menu m
on cfr.product_id = m.product_id
where rnk=1
order by cfr.customer_id; 

-- 6. Which item was purchased first by the customer after they became a member?
with member_orders_ranked as (select s.customer_id, s.product_id,
dense_rank() over(partition by s.customer_id order by order_date) as rnk
from sales s
join members m
on s.customer_id = m.customer_id
where order_date >= join_date)

select mor.customer_id, m.product_name 
from member_orders_ranked mor
join menu m
on mor.product_id = m.product_id 
where rnk=1
order by mor.customer_id;


-- 7. Which item was purchased just before the customer became a member?
with member_orders_ranked as (select s.customer_id, s.product_id,
dense_rank() over(partition by s.customer_id order by order_date desc) as rnk
from sales s
join members m
on s.customer_id = m.customer_id
where order_date < join_date)

select mor.customer_id, m.product_name 
from member_orders_ranked mor
join menu m
on mor.product_id = m.product_id 
where rnk=1
order by mor.customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(*) as item_count, sum(price) as amount_spent
from sales s
join members m
on s.customer_id = m.customer_id 
join menu mn
on s.product_id = mn.product_id 
where order_date < join_date
group by s.customer_id
order by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points 
-- would each customer have?
select customer_id,
sum(case when product_name='sushi' then 2*10*price else 10*price end) as points
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id
order by customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x 
-- points on all items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id,
sum(case 
	when order_date BETWEEN join_date AND join_date + INTERVAL '7 days' 
		then 2*10*price
	when product_name='sushi' 
		then 2*10*price 
	else 10*price 
end) as points
from sales s
join menu m
on s.product_id = m.product_id
join members mm
on mm.customer_id = s.customer_id
where order_date::timestamp <= '2021-01-31'
group by s.customer_id;

