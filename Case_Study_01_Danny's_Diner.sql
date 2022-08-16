/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first Iek after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?

-- check sales table, it has 15 rows

select * from dannys_diner.sales;

-- join sales, members(customer) and  menu tables.

select *
from dannys_diner.sales sl
	join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
;

-- I get 12 records, 3 records missing. 
-- This is because customer_id "C" is not a member of loyalty program
-- so I have to use left join between sales and members table to get data from all customers.
-- as I don't have quantities in sales table, I assume that each bought product had 1 unit
-- I sum the price column and group by customer_id, finally I order de result ascending by the first column (customer_id)

select sl.customer_id,
	   sum(mn.price) tot_amount
from dannys_diner.sales sl
	left join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
group by sl.customer_id
order by 1
;

-- I get the same result without using members table, because I don't have a customer table so I get de customer info from sales table.

select sl.customer_id,
	   sum(mn.price) tot_amount
from dannys_diner.sales sl
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
group by sl.customer_id
order by 1
;


-- 2. How many days has each customer visited the restaurant?

select sl.customer_id,
	   count(distinct sl.order_date) days_visited
from dannys_diner.sales sl
group by sl.customer_id
order by 1
;

-- 3. What was the first item from the menu purchased by each customer?
-- I use row_number windows function
-- with clause instead subquery because reutilization

with prd_rn as(
	select sl.customer_id,
		   mn.product_name,
		   row_number() over (partition by sl.customer_id order by sl.order_date, sl.product_id) rn
	from dannys_diner.sales sl
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
)
select prd_rn.customer_id ,
	   prd_rn.product_name
from prd_rn
where prd_rn.rn=1
order by 1
;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- using window function within group clause

with prd_rn as(
	select mn.product_name,
		   sum(1) pchse_times,
		   row_number() over( order by sum(1) desc) rn
	from dannys_diner.sales sl
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
	group by mn.product_name
)
select prd_rn.product_name ,
	   prd_rn.pchse_times
from prd_rn
where prd_rn.rn=1
;

-- Same result using count(sl.product_id) instead of sum(1)
with prd_rn as(
	select mn.product_name,
		   count(sl.product_id) pchse_times,
		   row_number() over( order by count(sl.product_id) desc) rn
	from dannys_diner.sales sl
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
	group by mn.product_name
)
select prd_rn.product_name ,
	   prd_rn.pchse_times
from prd_rn
where prd_rn.rn=1
;


-- 5. Which item was the most popular for each customer?
-- using dense_rank because can not guarantee a popular product for B customer so I show all

with prd_rn as(
	select sl.customer_id,
		   mn.product_name,
		   count(sl.product_id) pchse_times,
		   dense_rank() over (partition by customer_id order by count(sl.product_id) desc) rn
	from dannys_diner.sales sl
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
	group by sl.customer_id,
			 mn.product_name 
)
select prd_rn.customer_id,
	   prd_rn.product_name ,
	   prd_rn.pchse_times
from prd_rn
where prd_rn.rn=1
order by 1
;

-- 6. Which item was purchased first by the customer after they became a member?

with prd_rn as(
	select sl.customer_id,
		   mb.join_date,
		   sl.order_date,
		   (sl.order_date - mb.join_date) day_diff,
		   case when (sl.order_date - mb.join_date)<=0 then null else (sl.order_date - mb.join_date) end  day_diff_case,
		   mn.product_name,
		   dense_rank() over(partition by sl.customer_id order by case when (sl.order_date - mb.join_date)<=0 then null else (sl.order_date - mb.join_date) end) rn
	from dannys_diner.sales sl
		join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
)
select prd_rn.customer_id,
	   prd_rn.product_name ,
	   prd_rn.day_diff
from prd_rn
where prd_rn.rn=1
order by 1
;

-- 7. Which item was purchased just before the customer became a member?

with prd_rn as(
	select sl.customer_id,
		   mb.join_date,
		   sl.order_date,
		   (sl.order_date - mb.join_date) day_diff,
		   case when (sl.order_date - mb.join_date)>=0 then null else (sl.order_date - mb.join_date) end  day_diff_case,
		   mn.product_name,
		   dense_rank() over(partition by sl.customer_id order by case when (sl.order_date - mb.join_date)>=0 then null else (sl.order_date - mb.join_date) end desc nulls last) rn
	from dannys_diner.sales sl
		join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
		join dannys_diner.menu mn on (sl.product_id = mn.product_id)
)
select prd_rn.customer_id,
	   prd_rn.product_name ,
	   prd_rn.join_date,
	   prd_rn.order_date,
	   abs(day_diff) days_before_member
from prd_rn
where prd_rn.rn=1
order by 1
;


-- 8. What is the total items and amount spent for each member before they became a member?

select sl.customer_id,
	   count(case when (sl.order_date < mb.join_date) then mn.product_name else null end) items,
	   sum(case when (sl.order_date < mb.join_date) then mn.price else 0 end) amount
from dannys_diner.sales sl
	join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
group by sl.customer_id
;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
	-- 2. Analysis for all customers
	

select sl.customer_id,
	   sum(case when mn.product_name='sushi' then mn.price*20 else mn.price*10 end) points
from dannys_diner.sales sl
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
group by sl.customer_id
order by 1
;

-- 10. In the first Iek after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- full uppercase month name (blank-padded to 9 chars)

select sl.customer_id,
	   trim(to_char(sl.order_date,'Month')) as month,
	   sum(case when sl.order_date >= mb.join_date then
			   case when (sl.order_date-mb.join_date) betIen 0 and 7
					then mn.price*20
			   else
					case when mn.product_name='sushi' then mn.price*20 else mn.price*10 end
			   end
		   else 0
		   end) as points
from dannys_diner.sales sl
	join dannys_diner.members mb on (sl.customer_id = mb.customer_id)
	join dannys_diner.menu mn on (sl.product_id = mn.product_id)
where trim(to_char(sl.order_date,'Month'))='January'
group by sl.customer_id,
	   trim(to_char(sl.order_date,'Month'))
order by 1
;