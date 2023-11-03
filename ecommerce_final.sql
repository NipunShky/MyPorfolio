-- Data cleaning in SQL for Online Retail store (over 1 million rows)


-- checking the table
select *
from ecomerce.online_retail;

-- to delete negative quantity of sales (22950 deleted)
delete from ecomerce.online_retail 
where quantity < 0;

-- to delete negative quantity of price (5 deleted)
delete from ecomerce.online_retail 
where price < 0;

-- updating null customers to be unknown (105,440 affected)
update ecomerce.online_retail 
set customer_id = "unknown"
where customer_id = "N/A" or customer_id is NULL;

-- checking to see if we removed all unwanted records
select *
from ecomerce.online_retail
where price < 0 or customer_id = "N/A" or customer_id is null or quantity<0;


-- to add a new sales_amt column with double data type
alter table ecomerce.online_retail 
add sales_amt double after price;

-- to calculate the sales price
update ecomerce.online_retail 
set sales_amt = price*quantity; 

-- to add a new invoice date column with datetime data type
alter table ecomerce.online_retail 
add invoice_date datetime;

-- to add dates in newer column
update ecomerce.online_retail 
set invoice_date = date_format(str_to_date(invoicedate,'%c/%e/%Y %H:%i'), '%Y-%m-%d %H:%m:%s'); 

-- dropping old invoicedate column
alter table ecomerce.online_retail 
drop invoicedate;


-- MOVING ONTO EXPLORING THE DATA AND GAINING INSIGHTS


-- average purchase by customer
select customer_id, round(avg(sales_amt),2) as average_purchase
from ecomerce.online_retail
group by customer_id
order by average_purchase desc;

-- finding out information about the sales and customers
select count(distinct customer_id) as unique_customers, round(avg(sales_amt),2) as avg_sales, 
count(distinct invoice_id) as total_transaction
from ecomerce.online_retail;

-- yearly total sales
select extract(year from invoice_date) as year, round(sum(sales_amt),2)
from ecomerce.online_retail
group by year;

-- understanding the monthly sales pattern and number of customers pattern
select extract(year from invoice_date) as year, extract(month from invoice_date) as month, round(sum(sales_amt),2) as total_sales,
round(avg(sales_amt),2) as avg_sales_pm,count(distinct customer_id) as no_customer_pm
from ecomerce.online_retail
group by year, month
order by year, month;

-- calculating monthly sales over all the years
select extract(month from invoice_date) as month, round(avg(sales_amt),2) as avg_sales, count(distinct customer_ID) as no_of_customer
from ecomerce.online_retail
group by month
order by month;


-- Delving in more depth of the data


-- filtering in the top customers having more than $10,000 in sales and creating a view
create view ecomerce.cust_over_tenthousand as
select customer_id ,round(Sum(sales_amt),2) as Sales, country
from ecomerce.online_retail
where customer_id <> 'unknown'
group by customer_id, country
having Sales > 10000;

select *
from ecomerce.cust_over_tenthousand
order by Sales desc;

-- finding the most popular items for customers having more than 10,000 sales
select stockcode, round(sum(sales_amt),2) as sum_sales
from ecomerce.online_retail
where customer_id IN (select customer_id from ecomerce.cust_over_tenthousand)
group by stockcode
order by sum_sales desc
limit 50;

-- finding the yearly sales amount of each country
select country,
	extract(year from invoice_date) as year,
	round(sum(sales_amt),2) as sales
from ecomerce.online_retail
group by country, year
order by country, year;

-- the biggest market for the ecommerce
select country, round(sum(sales_amt),2) as sales
from ecomerce.online_retail
group by Country 
order by sales desc;

-- finding out the top 3 most sold items in each country

-- Using CTE
with countrywise_sales (country, stockcode, description, sales)
as
(
select country, StockCode, Description,round(sum(sales_amt),2) as sales
from ecomerce.online_retail
group by country, stockcode, description
)
select country, stockcode, description, sales
from(
	select t.country,t.stockcode,t.description,t.sales,
	row_number() over(partition by country order by sales desc) as rn
	from countrywise_sales as t
		) as q
where rn <=3;

-- looking at the most purchased item
select Description, round(sum(sales_amt),2)as 'sales amount', count(StockCode) as no_sold
from ecomerce.online_retail
group by stockcode, description
order by count(stockcode) desc;

-- top 3 sales item for top 100 customers
-- Creating a CTE to calculate the top 3 items purchased by the top 100 customers
with top_3 as (select q.customer_id, q.stockcode, q.description, q.sales
from(
	select *, row_number() over(partition by customer_id order by t.sales desc) as rn
	from(
		select e2.customer_id,e2.stockcode,e2.description, sum(e2.sales_amt) as sales
		from ecomerce.online_retail as e2
		inner JOIN(
			select e1.customer_id
			from ecomerce.online_retail as e1
			where e1.customer_id <> 'unknown'
			group by e1.customer_id
			order by sum(e1.sales_amt) desc
			limit 100) as temp
		on e2.customer_id = temp.customer_id
		group by e2.customer_id, e2.stockcode,e2.description) as t) as q
	where rn <=3)
	
select top_3.stockCode, top_3.description, sum(top_3.sales) as sales_amt, count(top_3.stockcode) as number_times_sold
from top_3
group by 1,2
order by 3 desc;

