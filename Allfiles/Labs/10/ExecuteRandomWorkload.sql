/*
// Source via Bradley Ball :: braball@microsoft.com
// Credits – Jonathan Kehayias :: https://www.sqlskills.com/blogs/jonathan/the-adventureworks2008r2-books-online-random-workload-generator/
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
*/
-- http://msdn.microsoft.com/en-us/library/ms178544.aspx
USE AdventureWorks2017;
GO
exec p_sel_SalesQuota

------

-- http://msdn.microsoft.com/en-us/library/bb510624.aspx
USE AdventureWorks2017;
GO
declare @i int, @x int
set @i=round(16*rand(), 0)
set @x=round(16*rand(), 0)

select @i, @x

if (@i=0)
	begin
		set @i=1
	end
	  
if (@x=0)
	begin
		set @x=1
	end

exec p_sel_Dept_Employee_Count @i, @x;

------

-- http://msdn.microsoft.com/en-us/library/bb510624.aspx
USE AdventureWorks2017;
GO
declare @i int, @x int
set @i=round(16*rand(), 0)
set @x=round(16*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
	  
if (@x=0)
	begin
		set @x=1
	end

exec p_sel_Dept_Employees_by_Job_Titles @i, @x;

------

-- http://msdn.microsoft.com/en-us/library/bb510624.aspx
USE AdventureWorks2017;
GO
declare @i int, @x int
set @i=round(16*rand(), 0)
set @x=round(16*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
	  
if (@x=0)
	begin
		set @x=1
	end

exec p_sel_Dept_Employees_Count_By_Title @i, @x;

------

--http://msdn.microsoft.com/en-us/library/bb677202.aspx

USE AdventureWorks2017;
GO
declare @i int, @x int
set @i=round(290*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end


exec p_sel_get_originization_by_employee @i;


------

-- http://msdn.microsoft.com/en-us/library/ms181708.aspx
USE AdventureWorks2017;
GO
GO
declare @i int, @x int
set @i=round(292*rand(), 0)

if (@i<274)
	begin
		set @i=274
	end
exec p_sel_get_sales_per_sales_person @i;
exec p_sel_get_sales_per_by_sales_person;
GO

------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
A. Using SELECT to retrieve rows and columns 
The following example shows three code examples. This first code 
example returns all rows (no WHERE clause is specified) and all
columns (using the *) from the Product table in the 
AdventureWorks2017 database.
*/

USE AdventureWorks2017;
GO
exec p_sel_aliased_select;
GO

/*
This example returns all rows (no WHERE clause is specified), and 
only a subset of the columns (Name, ProductNumber, ListPrice) from 
the Product table in the AdventureWorks2017 database. Additionally, 
a column heading is added.
*/

USE AdventureWorks2017;
GO
exec p_sel_product_info;
GO

------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx
/*
This example returns only the rows for Product that have a product 
line of Null and that have days to manufacture that is less than 4.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(4*rand(), 0)

if (@i>5)
	begin
		set @i=4
	end


exec p_sel_products_withDTM_Null @i
------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx
/*
This example returns only the rows for Product that have a product 
line of R and that have days to manufacture that is less than 4.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(4*rand(), 0)

if (@i>5)
	begin
		set @i=4
	end

exec p_sel_products_withDTM_R @i

------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx
/*
This example returns only the rows for Product that have a product 
line of M and that have days to manufacture that is less than 4.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(4*rand(), 0)

if (@i>5)
	begin
		set @i=4
	end
exec p_sel_products_withDTM_M @i

------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx
/*
This example returns only the rows for Product that have a product 
line of S and that have days to manufacture that is less than 4.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(4*rand(), 0)

if (@i>5)
	begin
		set @i=4
	end
exec p_sel_products_withDTM_S @i
------

-- http://msdn.microsoft.com/en-us/library/ms187731.aspx
/*
This example returns only the rows for Product that have a product 
line of T and that have days to manufacture that is less than 4.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(4*rand(), 0)

if (@i>5)
	begin
		set @i=4
	end
exec p_sel_products_withDTM_T @i

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
B. Using SELECT with column headings and calculations 
The following examples return all rows from the Product table. The 
first example returns total sales and the discounts for each product. 
In the second example, the total revenue is calculated for each 
product.
*/

USE AdventureWorks2017;
GO
exec p_sel_discount_sales;
GO


/*
This is the query that calculates the revenue for each product in 
each sales order.
*/

USE AdventureWorks2017;
GO
exec p_calc_revenue_for_each_product;
GO
----LEAVING OFF HERE---
------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
C. Using DISTINCT with SELECT 
The following example uses DISTINCT to prevent the retrieval 
of duplicate titles.
*/

USE AdventureWorks2017;
GO
p_sel_Employee_Jobtitles;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
D. Creating tables with SELECT INTO 
The following first example creates a temporary table named 
#Bicycles in tempdb. 
*/

USE AdventureWorks2017;
GO
p_ins_temp_bicycles;
GO

/*
This second example creates the permanent table NewProducts.
*/

USE AdventureWorks2017;
GO
p_ins_NewProducts;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
  E. Using correlated subqueries 
The following example shows queries that are semantically 
equivalent and illustrates the difference between using the 
EXISTS keyword and the IN keyword. Both are examples of a 
valid subquery that retrieves one instance of each product 
name for which the product model is a long sleeve logo jersey, 
and the ProductModelID numbers match between the Product and 
ProductModel tables.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(128*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
	
exec p_sel_all_products_like @i;

GO
------
/*
The following example uses IN in a correlated, or repeating, 
subquery. This is a query that depends on the outer query for 
its values. The query is executed repeatedly, one time for each 
row that may be selected by the outer query. This query 
retrieves one instance of the first and last name of each 
employee for which the bonus in the SalesPerson table is 5000.00 
and for which the employee identification numbers match in the 
Employee and SalesPerson tables.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(290*rand(), 0)

if (@i<274)
	begin
		set @i=277
	end
exec p_sel_salesperson_by_bonus @i;
GO
------
/*
The previous subquery in this statement cannot be evaluated 
independently of the outer query. It requires a value for 
Employee.BusinessEntityID, but this value changes as the SQL 
Server Database Engine examines different rows in Employee.

A correlated subquery can also be used in the HAVING clause of 
an outer query. This example finds the product models for which 
the maximum list price is more than twice the average for the 
model.
*/

USE AdventureWorks2017;
GO
exec p_sel_max_price_double_average_model;
GO

/*
This example uses two correlated subqueries to find the names 
of employees who have sold a particular product.
*/
------
USE AdventureWorks2017;
GO
declare @i int
set @i=round(999*rand(), 0)

if (@i=0)
	begin
		set @i=777
	end
if (@i>5 and @i<316)
	begin
		set @i=4
	end
select @i 
exec p_sel_employee_name_by_product_sales @i;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
F. Using GROUP BY 
The following example finds the total of each sales order in 
the database.
*/

USE AdventureWorks2017;
GO
exec p_sel_total_by_sales_order;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
Because of the GROUP BY clause, only one row containing the sum of all 
sales is returned for each sales order.

G. Using GROUP BY with multiple groups 
The following example finds the average price and the sum of 
year-to-date sales, grouped by product ID and special offer ID.
*/

USE AdventureWorks2017;
GO
exec p_sel_group_by_clause;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
  H. Using GROUP BY and WHERE 
The following example puts the results into groups after retrieving 
only the rows with list prices greater than $1000.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(999*rand(), 0)

if (@i<513)
	begin
		set @i=716
	end
exec p_sel_results_by_price @i;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
I. Using GROUP BY with an expression 
The following example groups by an expression. You can group 
by an expression if the expression does not include aggregate 
functions.
*/

USE AdventureWorks2017;
GO
exec p_sel_group_by_w_expression;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
J. Using GROUP BY with ORDER BY 
The following example finds the average price of each type of 
product and orders the results by average price.
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(44*rand(), 0)

if (@i=0)
	begin
		set @i=41
	end
exec p_sel_get_avg_price_by_product @i;
GO


------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
K. Using the HAVING clause 
The first example that follows shows a HAVING clause with an 
aggregate function. It groups the rows in the SalesOrderDetail 
table by product ID and eliminates products whose average order 
quantities are five or less. The second example shows a HAVING 
clause without aggregate functions. 
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(44*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
exec p_sel_product_by_quantity @i;
GO
------
/*
This query uses the LIKE clause in the HAVING clause. 
*/

USE AdventureWorks2017 ;
GO
declare @i int
set @i=round(121317*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
exec p_sel_order_by_tracking_partial @i;
GO  

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
L. Using HAVING and GROUP BY 
The following example shows using GROUP BY, HAVING, WHERE, and 
ORDER BY clauses in one SELECT statement. It produces groups and 
summary values but does so after eliminating the products with 
prices over $25 and average order quantities under 5. It also 
organizes the results by ProductID.
*/

USE AdventureWorks2017;
GO
declare @i int, @x int
set @i=round(3578*rand(), 0)

if (@i=0)
	begin
		set @i=1
	end
set @x=round(44*rand(), 0)

if (@x=0)
	begin
		set @x=1
	end
exec p_sel_product_by_price_and_quantity @i, @x;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
M. Using HAVING with SUM and AVG 
The following example groups the SalesOrderDetail table by product 
ID and includes only those groups of products that have orders 
totaling more than $1000000.00 and whose average order quantities 
are less than 3.
*/

USE AdventureWorks2017;
GO
exec p_sel_products_over_onemil_qlessthan3;
GO
------
/*
To see the products that have had total sales greater than 
$2000000.00, use this query:
*/

USE AdventureWorks2017;
GO
exec p_sel_products_over_twomil;
GO

------
/*
create some temp tables and latch contention
*/

USE AdventureWorks2017;
GO
exec p_ins_temp_bicycles;
GO

/*
If you want to make sure there are at least one thousand five 
hundred items involved in the calculations for each product, use 
HAVING COUNT(*) > 1500 to eliminate the products that return totals 
for fewer than 1500 items sold. The query looks like this:
*/

USE AdventureWorks2017;
GO
declare @i int
set @i=round(1500*rand(), 0)

if (@i=0)
	begin
		set @i=100
	end
exec p_sel_sales_products_where_q_GT @i;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
N. Calculating group totals by using COMPUTE BY 
The following example uses two code examples to show the use 
of COMPUTE BY. The first code example uses one COMPUTE BY with 
one aggregate function, and the second code example uses one 
COMPUTE BY item and two aggregate functions.

This query calculates the sum of the orders, for products with 
prices less than $5.00, for each type of product.
*/
USE AdventureWorks2017;
GO
declare @i int
set @i=round(3579*rand(), 0)

if (@i=0)
	begin
		set @i=1000
	end
exec p_sel_get_sales_rollup_by_product_linetotal @i;
GO

------

/*  http://msdn.microsoft.com/en-us/library/ms187731.aspx
O. Calculating grand values by using COMPUTE without BY 
The COMPUTE keyword can be used without BY to generate grand 
totals, grand counts, and so on.

The following example finds the grand total of the prices and 
advances for all types of products les than $2.00.
*/
USE AdventureWorks2017;
GO
declare @i int
set @i=round(3579*rand(), 0)

if (@i=0)
	begin
		set @i=1000
	end
exec p_sel_get_sales_cube_by_prod_ord_unit_line @i;
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
The following examples return all rows from the Product table. The first example returns total sales and the discounts for each product. In the second example, the total revenue is calculated for each product.
*/

USE AdventureWorks2017;
GO
exec p_sel_prod_tble_discounts
GO

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
Q. Using SELECT INTO with UNION 
In the following example, the INTO clause in the second SELECT statement specifies that the table named ProductResults holds the final result set of the union of the designated columns of the ProductModel and Gloves tables. Note that the Gloves table is created in the first SELECT statement.
*/

USE AdventureWorks2017;
GO

exec p_sel_select_into_union

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx

R. Using UNION of two SELECT statements with ORDER BY 
The order of certain parameters used with the UNION clause is important. The following example shows the incorrect and correct use of UNION in two SELECT statements in which a column is to be renamed in the output.
*/

USE AdventureWorks2017;
GO
exec p_sel_union_of_2_selects
