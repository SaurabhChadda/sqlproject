
show tables;

-- In this project we have seven tables of a company names as Maven_factory

-- Tables names with total rows
-- Transactions_1997(86837), 
-- transactions_1998(131889), 
-- customers(10281)  , 
-- products(1560) , 
-- regions(109), 
-- returns(7087) , 
-- stores(24)








select * from customers;

use adventure_works;
show tables;
select * from customer_lookup;
    
-- let's segragate our customers on the basis of there gender

Select Gender,count(CustomerKey) as Total
	from Customer_lookup
    Group By Gender;

-- Let's find out of total customers how many of them are married and single

select MaritalStatus,
	count(case when gender='M' then gender end) as 'male',
	count(case when gender ='F' then gender end) as 'Female'
	from customer_lookup
	group by maritalstatus;

select * from product_category;	
select * from product_lookup;
select * from product_sub;

select * from sales_2021;

-- let's count the distinct number of product sold by the business

select a.subcategoryName,count(b.productsku) as total_sales
from product_sub as a
 join product_lookup as b
on a.productsubcategorykey=b.productsubcategorykey
group by a.subcategoryname
order by total_sales desc;

-- let's find how many category of product we deal by joining the product category and subcategory table

select a.categoryname,count(b.subcategoryname)
from product_category as a
join product_sub as b
on a.productcategorykey=b.productcategorykey
group by a.categoryname;

-- let's find the the total transaction and total sales in each year for this I'll be creating a View for the consolidated sales

create View total_sales as
select * from sales_2021
union 
select * from sales_2022;

select * from total_sales;

-- Total number of transaction in each year

select year(orderdate), count(distinct(customerkey))
from total_sales
group by year(orderdate);

-- let's try to find that from which reagion we are getting the majority of our sales and we need to work to increase the sales

select * from territory_lookup;

select a.country,sum(b.orderquantity) as total_sales
from territory_lookup as a
join total_sales as b
on a.salesterritorykey=b.territorykey
group by 1
order by total_sales desc;



select year(orderdate),quarter(orderdate),sum(orderquantity)
from total_sales
group by 1,2;

select distinct(monthname(orderdate))
from total_sales
where year(orderdate)=2022;

-- let's find out the level of qualification majority of customers have pursued

select educationlevel,count(educationlevel)
from customer_lookup
group by 1										-- we can clearly see that majority of the customer are bachelors degree holders and there is some redundency in 
												-- educationlevel column hence we need to replace bachelors with graduate degree and high school and partial highschool
order by 2 desc;								-- as highschool only so, it will give us better clarity in the numbers.	

-- let's make the neccessary adjustments

update customer_lookup
set educationlevel='High School'               -- followed the same step for bachelors and graduate degree as well
where educationlevel='Partial High School';			
												
-- let's find out what is the average salary of each customers from different Occupation

select occupation,round(avg(annualincome),2)
from customer_lookup
group by occupation
order by 2 desc;

-- let's fetch details regarding from which occupation we having majority of priority and standard customers

select occupation,
count(case when badge='Standard' then badge end ) as 'standard',   
count(case when badge='priority' then badge end) as 'priority'
from customer_lookup
group by 1; 				-- by using sql pivot we can easily say that we only have priority customers from professional and people from the managerment background.


-- let's fetch the details regarding the name of categories of product from where we are getting majority of returned orders


select a.productname,sum(b.ReturnQuantity)
from product_lookup as a
inner join returns_data as b
on a.productkey=b.productkey
group by productname
order by 2 desc
limit 10;

-- Let's fetch details regarding the percentage change in total transaction from 2021-2022

with cte_transaction as 
(select year(orderdate) as year,case when year(orderdate)='2021' then count(distinct(customerkey))
			when year(orderdate)='2022' then count(distinct(customerkey)) 
            end as total_transaction
            from total_sales
            group by 1), 
cte_final as(
     select * ,lag(total_transaction) over() as last_year
     from cte_transaction)
     select year,total_transaction,concat(round(((total_transaction - last_year)/19635)*100,2), "%")
     as percent_change
     from cte_final;
	
-- Let's fetch details regarding that from which region we are maximum returned orders

select  a.Region,sum(b.returnQuantity) as total_item_returned
		from territory_lookup as a
        join returns_data as b
        on a.salesterritorykey = b.territorykey
        group by 1
        order by 2 desc;
        
-- revenue calculation

select * from product_lookup;
select * from total_sales;
select * from product_sub;    

-- let's fetch details regarding the the most demanded subcategory or sales generating categories
    
with product_analysis as
(select a.productname,a.modelname,a.productsubcategorykey,a.productprice,b.Orderquantity
	from product_lookup as a
    inner join total_sales as b
    on a.productkey=b.productkey
    group by a.productname),
 product_sub as
 (select a.productsubcategorykey,b.subcategoryname,sum(a.OrderQuantity) as total_quantity_sold
	from product_analysis as a
    join product_sub as b
    on a.productsubcategorykey=b.productsubcategorykey
    group by 1
    )
    select * from product_sub
    order by 3 desc;
    
 -- let's fetch details regarding the total profit from each product
select * from product_lookup;
select * from total_sales;
 
 with cte_revenue as 
	 (select a.productkey,a.productsubcategorykey,a.productname,a.productcost,a.productprice,sum(b.orderquantity) as total_quantity
	 from product_lookup as a
	 inner join total_sales as b
	 on a.productkey=b.productkey
	 group by a.productkey),
cte_cost_and_revenue as (
	select *,round((productprice * total_quantity),2) as total_revenue,round((productcost * total_quantity),2) as total_cost
    from cte_revenue),
profit_analysis as (
	select productkey,productname,concat('$',' ',round((total_revenue-total_cost),2)) as Net_Profit
    from cte_cost_and_revenue)
    select * from profit_analysis
    order by 3 desc;
    
use adventure_works;

-- let's see the increase in sales in each quarter
select * from total_sales;

with Quarterly_sales as
	(select Year(orderdate) as Year,quarter(orderdate) as Quarters,sum(OrderQuantity) as Sales
	from total_sales
    group by 1,2),
Percentage_change as(
	select *,lead(sales,1,0) over() as next_sales
    from quarterly_sales)
    select *,concat(round((next_sales-Sales)/sales *100,2),"%") as percent_change
    from percentage_change;

select * from customer_lookup;    

-- total number of customers who earn more than the average salary and grouping it by occupation
with above_average_salary as
	(select distinct occupation,
	count(customerkey) over(partition by occupation ) as total_customers
	from customer_lookup
	where annualincome  >(select avg(annualincome) from customer_lookup))
	select * from above_average_salary
	order by total_customers desc;

 

          
 delimiter //
create procedure sales_summary(in p_date1 date, in p_date2 date,in p_country varchar(20))
 BEGIN
select a.orderdate,b.prefix,b.firstname,b.lastname,b.emailaddress,b.annualincome,b.badge,a.orderquantity,
			c.productname as item_purchased,d.country
            from customer_lookup as b
            inner join total_sales as a
            on a.customerkey=b.customerkey
            inner join product_lookup as c
            on a.productkey=c.productkey
            inner join territory_lookup as d
            on a.territorykey=d.salesterritorykey
            where d.country=p_country and a.orderdate between p_date1 and p_date2
            order by a.orderdate;
END //
delimiter ;

call sales_summary('2021-01-01','2021-01-15','canada');		-- using this stored procedure  client and access the summarised data in a glance by providing the range
															-- of date from start to stop and by providing country name as well and they will find all the neccessary
                                                            -- information right away

use adventure_works;
show tables;
select * from customer_lookup;

--  Here we are checking the variability and dispersion of customer data and we can see that the majority chunk of customers upto 30% is from the professionals

select occupation,count(*) as frequency,
concat(round(count(occupation)/(select count(*) from customer_lookup)*100,2),' ','%') as relative_frequency
from customer_lookup
group by occupation
order by relative_frequency desc;       

-- check the spread(range of customer_income)
select max(annualincome) as max_income,min(annualincome) as low_income,max(annualincome)-min(annualincome) as income_range
from customer_lookup;

                                                  

-- let's check the relative frequency of our customers with each badge
-- As per the result we can clearly see that the majority of our customer falls under standard badge that is upto 93.01 % and only 6.99 % from the
-- priority badge.

select badge,count(badge) as badge_frequency,
concat(round(count(badge)/(select count(*) from customer_lookup) * 100,2),'','%') as relative_frequency
from customer_lookup
group by badge
order by relative_frequency desc;

show tables;
select * from total_sales;
select * from product_lookup;

-- Let's calculate the total amount generated from the sales of each items and from that we will try to do the profit analysis on the basis of that.

with profit_analysis as
(select a.productkey,b.productname,a.Orderquantity,round(b.productcost,2) as Cost_Price,
round(b.productprice,2) as Retail_Price,round(b.productprice*a.orderquantity,2) as total_revenue,
round(b.productcost*a.orderquantity,2) as total_cost
from total_sales as a
left join product_lookup as b
on a.productkey=b.productkey
group by a.productkey)
select * ,round(total_revenue-total_cost,2) as net_profit
from profit_analysis
order by net_profit desc
limit 10;

select * from total_sales;
select * from territory_lookup;


select a.territorykey,b.country,sum(a.orderquantity) as total_sales,
concat(round(sum(a.orderquantity)/(select sum(orderquantity) from total_sales)*100,2),'%') as relative_frequency
from total_sales as a 
left join territory_lookup as b
on a.territorykey=b.salesterritorykey
group by b.country
order by 1;