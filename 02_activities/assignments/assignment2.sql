/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

--Checking for null
select 
COUNT(CASE WHEN product_name IS NULL THEN 1 END) AS product_name_null,
COUNT(CASE WHEN product_size IS NULL THEN 1 END) AS product_size_null,
COUNT(CASE WHEN product_qty_type IS NULL THEN 1 END) AS product_qty_type_null
from product;

--Fixing Null
SELECT 
product_name || ', ' || coalesce(product_size, '')|| ' (' || coalesce(product_qty_type,'unit') || ')'
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

select *,
dense_rank() over (PARTITION by customer_id order by market_date) as rank_visits
from customer_purchases;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

with rankVisits as( 
select *,
dense_rank() over (PARTITION by customer_id order by market_date desc) as rank_visits
from customer_purchases)

select * from rankVisits where rank_visits=1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

select *,
count(transaction_time) over (PARTITION by customer_id, product_id) as count_product
from customer_purchases;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

select a.*, b.description from product a left join (select *,trim(
substr(product_name, instr(product_name, "-")+1)) as description from product where product_name like '%-%') b
on a.product_id=b.product_id;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

select a.*, b.description from product a left join (select *,trim(
substr(product_name, instr(product_name, "-")+1)) as description from product where product_name like '%-%') b
on a.product_id=b.product_id
where a.product_size REGEXP  '[0123456789]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

with 
sales as (
	select market_date, sum(quantity*cost_to_customer_per_qty) as total_sales
	from customer_purchases group by market_date),
RANKING AS (
	select *,dense_rank() over (order by market_date) as best_dates,
	dense_rank() over (order by market_date desc) as worst_dates
 from sales)
 select market_date,total_sales from ranking where best_dates=1
 union 
 select market_date,total_sales from ranking where worst_dates=1;


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--since not all products are sold by each vendor, we should list out which products are sold by which vendor 
--by on the vendor_inventory table. This table will tell which products they sell since it will be in their 
--inventory. 
select distinct vendor_id, product_id from vendor_inventory; --there are 8 distinct vendors and products. 
select distinct customer_id from customer; --there are 26 customers. so 26*8=208 combinations.
 
with names as (
select distinct vendor_name, product_name, original_price from vendor_inventory inv 
left join vendor a on inv.vendor_id=a.vendor_id
left join product prod on inv.product_id=prod.product_id),
combinations as (
select vendor_name, product_name,customer_id from names cross join customer),
groups as (
select vendor_name,product_name, count(customer_id) as cust_count from combinations
group by vendor_name, product_name)
select g.vendor_name, g.product_name, (cust_count*original_price*5) possible_rev from groups g
left join names n on g.vendor_name=n.vendor_name and g.product_name=n.product_name;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

drop table product_units;
create table product_units as
select *, CURRENT_TIMESTAMP as snapshot_timestamp from product
where product_qty_type='unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

select * from product_units;
insert into product_units
values(10, 'Eggs', '1 dozen', 6, 'unit', CURRENT_TIMESTAMP);
select * from product_units order by snapshot_timestamp;

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

delete from product_units
where product_name ='Eggs' and snapshot_timestamp<(select max(snapshot_timestamp) from product_units);

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;
with inventories as (
select *,
dense_rank() over (PARTITION by product_id order by market_date desc) as inventory_rank
 from vendor_inventory),
 first_ranks as (
select * from inventories where inventory_rank=1)
update product_units
set current_quantity=(select quantity from first_ranks r where product_units.product_id=r.product_id);
update product_units
set current_quantity=coalesce(current_quantity, 0);

select * from product_units;



