CREATE DATABASE SQL_challenge;
USE SQL_challenge;

-- Q1 - Salary Ranking With Ties

select
	dept,
    name,
    salary,
    
    dense_rank() over(
		partition by dept
        order by salary desc
	) as salary_rank,
    
    max(salary) over(
		partition by dept
	) - salary as below_top_earner
    
from employees

order by
	dept,
    salary desc;
    
-- Q2 - Month-Over-Month Growth

with monthly_sales as (
	select
		date_format(sale_date, '%y-%m') as sales_month,
        sum(amount) as total_sales
	from sales
    group by date_format(sale_date, '%y-%m')
),

sales_with_previous as (
	select
		sales_month,
        total_sales,
        
        lag(total_sales) over (
			order by sales_month
		) as previous_month_sales
        
	from monthly_sales
)

select
	sales_month,
    total_sales,
    previous_month_sales,
    
    round(
		(total_sales - previous_month_sales)
        / nullif(previous_month_sales, 0) * 100,
        2
	) as percentage_change

from sales_with_previous

order by sales_month;

-- Q3 - Top Performer Per Region

with employee_region_sales as (
	select
		s.region,
        e.emp_id,
        e.name,
        sum(s.amount) as total_sales
        
	from sales s
    
    inner join employees e
		on s.emp_id = e.emp_id
        
	group by
		s.region,
        e.emp_id,
        e.name
),

ranked_sales as (
	select
		region,
        emp_id,
        name,
        total_sales,
        
        dense_rank() over (
			partition by region
            order by total_sales desc
		) as sales_rank
        
	from employee_region_sales
)

select
	region,
    emp_id,
    name,
    total_sales
    
from ranked_sales

where sales_rank = 1

order by region;

-- Q4 - Employees With No Sales

select
	e.emp_id,
    e.name,
    e.dept
    
from employees e

left join sales s
	on e.emp_id = s.emp_id
    
where s.emp_id is null

order by e.emp_id;

-- Q5 - Management Hierarchy Depth

with recursive employee_hierarchy as (
	
    -- Level 1: Employees who have no manager
    select
		emp_id,
        name,
        mgr_id,
        1 as level_number
        
	from employees
    
    where mgr_id is null
    
    union all
    
    -- Find employees reporting to the previous level
    select
		e.emp_id,
        e.name,
        e.mgr_id,
        eh.level_number + 1 as level_number
        
	from employees e
	
    inner join employee_hierarchy eh
		on e.mgr_id = eh.emp_id
)

select
	level_number,
    count(*) as employee_count,
    group_concat(name order by name separator ', ') as employee_names
    
from employee_hierarchy
    
group by level_number
    
order by level_number;
    
-- Q6 - Products Against Category Average

select
	product_id,
    category,
    price,
    
    round(
		avg(price) over (
			partition by category
		),
        2
	) as category_average,
    
    round(
		(price - avg(price) over (
			partition by category
		))
        / nullif(
			avg(price) over (
				partition by category
			),
            0
		) * 100,
        2
	) as percentage_from_average

from products

order by
	category,
    product_id;
    
-- Q7 - Running Total and Moving Average
--
-- Moving average shows the recent sales trend/smoothed
-- performance, while the running total only shows cumulative
-- sales from the beginning.

select
	s.sale_id,
    e.name,
    s.sale_date,
    s.region,
    s.amount,
    
    sum(s.amount) over(
		order by s.sale_date, s.sale_id
        rows between unbounded preceding and current row
	) as running_total,
    
    round(
		avg(s.amount) over (
			order by s.sale_date, s.sale_id
            rows between 2 preceding and current row
		),
        2
	) as moving_average_3_sales
    
from sales s

inner join employees e
	on s.emp_id = e.emp_id
    
where e.name = 'priya'

order by
	s.sale_date,
    s.sale_id;
    
-- Q8 - Tenure Bands

select
	case
		when hire_date < '2021-01-01'
			then 'before 2021'
            
		when hire_date < '2023-01-01'
			then '2021 to 2022'
            
		else '2023 onward'
	end as tenure_band,
    
    count(*) as headcount,
    
    round(avg(salary), 2) as average_salary
    
from employees

group by
	case
		when hire_date < '2021-01-01'
			then 'before 2021'
            
		when hire_date < '2023-01-01'
			then '2021 to 2022'
            
		else '2023 onward'
	end

order by
	average_salary desc;
