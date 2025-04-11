/*
// Source via Bradley Ball :: braball@microsoft.com
// Credits – Jonathan Kehayias :: https://www.sqlskills.com/blogs/jonathan/the-adventureworks2008r2-books-online-random-workload-generator/
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
*/

Use AdventureWorks2017
go
if exists(select name from sys.procedures where name='p_sel_SalesQuota')
begin
	drop procedure p_sel_SalesQuota
end
go
create procedure p_sel_SalesQuota
as
begin
	SELECT SalesQuota, SUM(SalesYTD) 'TotalSalesYTD', GROUPING(SalesQuota) AS 'Grouping'
	FROM Sales.SalesPerson
	GROUP BY SalesQuota WITH ROLLUP;
end
go

if exists(select name from sys.procedures where name='p_sel_Dept_Employee_Count')
begin
	drop procedure p_sel_Dept_Employee_Count
end
go
create procedure p_sel_Dept_Employee_Count(@i int, @x int)
as
begin
	SELECT D.Name
		,CASE 
		WHEN GROUPING_ID(D.Name, E.JobTitle) = 0 THEN E.JobTitle
		WHEN GROUPING_ID(D.Name, E.JobTitle) = 1 THEN N'Total: ' + D.Name 
		WHEN GROUPING_ID(D.Name, E.JobTitle) = 3 THEN N'Company Total:'
			ELSE N'Unknown'
		END AS N'Job Title'
		,COUNT(E.BusinessEntityID) AS N'Employee Count'
	FROM HumanResources.Employee E
		INNER JOIN HumanResources.EmployeeDepartmentHistory DH
			ON E.BusinessEntityID = DH.BusinessEntityID
		INNER JOIN HumanResources.Department D
			ON D.DepartmentID = DH.DepartmentID     
	WHERE DH.EndDate IS NULL
		AND D.DepartmentID IN (@i,@x)
	GROUP BY ROLLUP(D.Name, E.JobTitle);
end
go
if exists(select name from sys.procedures where name='p_sel_Dept_Employees_by_Job_Titles')
begin
	drop procedure p_sel_Dept_Employees_by_Job_Titles
end
go
create procedure p_sel_Dept_Employees_by_Job_Titles(@i int, @x int)
as
begin
	SELECT D.Name
		,E.JobTitle
		,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
		,COUNT(E.BusinessEntityID) AS N'Employee Count'
	FROM HumanResources.Employee AS E
		INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH
			ON E.BusinessEntityID = DH.BusinessEntityID
		INNER JOIN HumanResources.Department AS D
			ON D.DepartmentID = DH.DepartmentID     
	WHERE DH.EndDate IS NULL
		AND D.DepartmentID IN (@i,@x)
	GROUP BY ROLLUP(D.Name, E.JobTitle)
	HAVING GROUPING_ID(D.Name, E.JobTitle) = 0; --All titles
end
go
if exists(select name from sys.procedures where name='p_sel_Dept_Employees_Count_By_Title')
begin
	drop procedure p_sel_Dept_Employees_Count_By_Title
end
go
create procedure p_sel_Dept_Employees_Count_By_Title(@i int, @x int)
as
begin
	SELECT D.Name
		,E.JobTitle
		,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
		,COUNT(E.BusinessEntityID) AS N'Employee Count'
	FROM HumanResources.Employee AS E
		INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH
			ON E.BusinessEntityID = DH.BusinessEntityID
		INNER JOIN HumanResources.Department AS D
			ON D.DepartmentID = DH.DepartmentID     
	WHERE DH.EndDate IS NULL
		AND D.DepartmentID IN (@i,@x)
	GROUP BY ROLLUP(D.Name, E.JobTitle)
	HAVING GROUPING_ID(D.Name, E.JobTitle) = 1; --Group by Name;
end
go

	



if exists(select name from sys.procedures where name='p_sel_get_originization_by_employee')
begin
	drop procedure p_sel_get_originization_by_employee
end
go
create procedure p_sel_get_originization_by_employee(@i int)
as
begin

	DECLARE @CurrentEmployee hierarchyid

	SELECT 
		@CurrentEmployee=OrganizationNode
	from
		HumanResources.Employee
	where
		BusinessEntityID=@i

	

	SELECT OrganizationNode.ToString() AS Text_OrganizationNode, *
	FROM HumanResources.Employee
	WHERE OrganizationNode.GetAncestor(1) = @CurrentEmployee ;
end
go


if exists(select name from sys.procedures where name='p_sel_get_sales_per_sales_person')
begin
	drop procedure p_sel_get_sales_per_sales_person
end
go
Create Procedure p_sel_get_sales_per_sales_person(@i int)
as
Begin
SELECT CustomerID, OrderDate, SubTotal, TotalDue
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = @i
ORDER BY OrderDate 

select sum(subtotal), sum(totaldue)
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = @i 

end
go
if exists(select name from sys.procedures where name='p_sel_get_sales_per_by_sales_person')
begin
	drop procedure p_sel_get_sales_per_by_sales_person
end
go
Create Procedure p_sel_get_sales_per_by_sales_person
as
Begin
SELECT SalesPersonID, CustomerID, OrderDate, SubTotal, TotalDue
FROM Sales.SalesOrderHeader
group by grouping sets(SalesPersonID), CustomerID, OrderDate, SubTotal, TotalDue
ORDER BY SalesPersonID, OrderDate 

select salespersonid, sum(subtotal), sum(totaldue)
FROM Sales.SalesOrderHeader
group by SalesPersonID
ORDER BY SalesPersonID

end

go
if exists(select name from sys.procedures where name='p_sel_aliased_select')
begin
	drop procedure p_sel_aliased_select
end
go
Create Procedure p_sel_aliased_select
as
Begin
SELECT *
FROM Production.Product
ORDER BY Name ASC;

SELECT p.*
FROM Production.Product AS p
ORDER BY Name ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_product_info')
begin
	drop procedure p_sel_product_info
end
go
Create Procedure p_sel_product_info
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
ORDER BY Name ASC

end
go
if exists(select name from sys.procedures where name='p_sel_products_withDTM_NULL')
begin
	drop procedure p_sel_products_withDTM_NULL
end
go
Create Procedure p_sel_products_withDTM_NULL(@i as int)
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = NULL
AND DaysToManufacture < @i
ORDER BY Name ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_products_withDTM_M')
begin
	drop procedure p_sel_products_withDTM_M
end
go
Create Procedure p_sel_products_withDTM_M(@i as int)
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = 'M'
AND DaysToManufacture < @i
ORDER BY Name ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_products_withDTM_R')
begin
	drop procedure p_sel_products_withDTM_R
end
go
Create Procedure p_sel_products_withDTM_R(@i as int)
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = 'R'
AND DaysToManufacture < @i
ORDER BY Name ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_products_withDTM_S')
begin
	drop procedure p_sel_products_withDTM_S
end
go
Create Procedure p_sel_products_withDTM_S(@i as int)
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = 'S'
AND DaysToManufacture < @i
ORDER BY Name ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_products_withDTM_T')
begin
	drop procedure p_sel_products_withDTM_T
end
go
Create Procedure p_sel_products_withDTM_T(@i as int)
as
Begin

SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = 'T'
AND DaysToManufacture < @i
ORDER BY Name ASC;

end

go
if exists(select name from sys.procedures where name='p_sel_discount_sales')
begin
	drop procedure p_sel_discount_sales
end
go
Create Procedure p_sel_discount_sales
as
Begin

SELECT p.Name AS ProductName, 
NonDiscountSales = (OrderQty * UnitPrice),
Discounts = ((OrderQty * UnitPrice) * UnitPriceDiscount)
FROM Production.Product AS p 
INNER JOIN Sales.SalesOrderDetail AS sod
ON p.ProductID = sod.ProductID 
ORDER BY ProductName DESC;


end
go
if exists(select name from sys.procedures where name='p_calc_revenue_for_each_product')
begin
	drop procedure p_calc_revenue_for_each_product
end
go
Create Procedure p_calc_revenue_for_each_product
as
Begin

SELECT 'Total income is', ((OrderQty * UnitPrice) * (1.0 - UnitPriceDiscount)), ' for ',
p.Name AS ProductName 
FROM Production.Product AS p 
INNER JOIN Sales.SalesOrderDetail AS sod
ON p.ProductID = sod.ProductID 
ORDER BY ProductName ASC;

end
go
if exists(select name from sys.procedures where name='p_sel_Employee_Jobtitles')
begin
	drop procedure p_sel_Employee_Jobtitles
end
go
Create Procedure p_sel_Employee_Jobtitles
as
Begin

SELECT DISTINCT JobTitle
FROM HumanResources.Employee
ORDER BY JobTitle;

end

go
if exists(select name from sys.procedures where name='p_ins_NewProducts')
begin
	drop procedure p_ins_NewProducts
end
go
Create Procedure p_ins_NewProducts
as
Begin
if exists(select name from sys.tables where name = 'NewProducts')
begin
	drop table dbo.NewProducts
end

SELECT * INTO dbo.NewProducts
FROM Production.Product
WHERE ListPrice > $25 
AND ListPrice < $100;

end
go
if exists(select name from sys.procedures where name='p_sel_all_products_like')
begin
	drop procedure p_sel_all_products_like
end
go
Create Procedure p_sel_all_products_like(@i int)
as
begin
declare @pName char(5), @sqltext nvarchar(4000)

set @pname=(select left(name, 5) from Production.ProductModel where ProductModelID=@i)
 

set @sqltext='SELECT DISTINCT Name
FROM Production.Product AS p 
WHERE EXISTS
    (SELECT *
     FROM Production.ProductModel AS pm 
     WHERE p.ProductModelID = pm.ProductModelID
           AND pm.Name LIKE ' + ''''+ @pname + '%' + ''''+');'
exec sp_executesql @sqltext

end
go
if exists(select name from sys.procedures where name='p_sel_salesperson_by_bonus')
begin
	drop procedure p_sel_salesperson_by_bonus
end
go
Create Procedure p_sel_salesperson_by_bonus(@i int)
as
begin
declare @pmoney money, @sqltext nvarchar(4000)

set @pmoney=(select bonus from sales.SalesPerson where BusinessEntityID=@i)
set @sqltext='SELECT DISTINCT p.LastName, p.FirstName 
FROM Person.Person AS p 
JOIN HumanResources.Employee AS e
    ON e.BusinessEntityID = p.BusinessEntityID WHERE ' + cast(@pmoney as varchar(20)) +'IN
    (SELECT Bonus
     FROM Sales.SalesPerson AS sp
     WHERE e.BusinessEntityID = sp.BusinessEntityID);'

exec sp_executesql @sqltext

end
go
if exists(select name from sys.procedures where name='p_sel_max_price_double_average_model')
begin
	drop procedure p_sel_max_price_double_average_model
end
go
Create Procedure p_sel_max_price_double_average_model
as
Begin
SELECT p1.ProductModelID
FROM Production.Product AS p1
GROUP BY p1.ProductModelID
HAVING MAX(p1.ListPrice) >= ALL
    (SELECT AVG(p2.ListPrice)
     FROM Production.Product AS p2
     WHERE p1.ProductModelID = p2.ProductModelID);
end
go
if exists(select name from sys.procedures where name='p_sel_total_by_sales_order')
begin
	drop procedure p_sel_total_by_sales_order
end
go
Create Procedure p_sel_total_by_sales_order
as
Begin
SELECT SalesOrderID, SUM(LineTotal) AS SubTotal
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
ORDER BY SalesOrderID;
end
go
if exists(select name from sys.procedures where name='p_sel_employee_name_by_product_sales')
begin
	drop procedure p_sel_employee_name_by_product_sales
end
go
Create Procedure p_sel_employee_name_by_product_sales(@i int)
as
Begin
declare @productNumber varchar(200)
set @productNumber=(select ProductNumber from production.Product where productid=@i)

	SELECT DISTINCT pp.LastName, pp.FirstName 
	FROM Person.Person pp JOIN HumanResources.Employee e
	ON e.BusinessEntityID = pp.BusinessEntityID WHERE pp.BusinessEntityID IN 
	(SELECT SalesPersonID 
	FROM Sales.SalesOrderHeader
	WHERE SalesOrderID IN 
	(SELECT SalesOrderID 
	FROM Sales.SalesOrderDetail
	WHERE ProductID IN 
	(SELECT ProductID 
	FROM Production.Product p 
	WHERE ProductNumber = @productNumber)));
end
go
if exists(select name from sys.procedures where name='p_sel_group_by_clause')
begin
	drop procedure p_sel_group_by_clause
end
go
Create Procedure p_sel_group_by_clause
as
Begin
	SELECT ProductID, SpecialOfferID, AVG(UnitPrice) AS 'Average Price', 
		SUM(LineTotal) AS SubTotal
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID, SpecialOfferID
	ORDER BY ProductID;
end
go
if exists(select name from sys.procedures where name='p_sel_results_by_price')
begin
	drop procedure p_sel_results_by_price 
end
go
Create Procedure p_sel_results_by_price(@i int)
as
Begin
	declare @pmoney money
	set @pmoney=(select listprice from production.product where productid=@i)

	SELECT ProductModelID, AVG(ListPrice) AS 'Average List Price'
	FROM Production.Product
	WHERE ListPrice > @pmoney
	GROUP BY ProductModelID
	ORDER BY ProductModelID;
end
go
if exists(select name from sys.procedures where name='p_sel_group_by_w_expression')
begin
	drop procedure p_sel_group_by_w_expression
end
go
Create Procedure p_sel_group_by_w_expression
as
Begin
	SELECT AVG(OrderQty) AS 'Average Quantity', 
	NonDiscountSales = (OrderQty * UnitPrice)
	FROM Sales.SalesOrderDetail
	GROUP BY (OrderQty * UnitPrice)
	ORDER BY (OrderQty * UnitPrice) DESC;
end
go
if exists(select name from sys.procedures where name='p_sel_get_avg_price_by_product')
begin
	drop procedure p_sel_get_avg_price_by_product
end
go
Create Procedure p_sel_get_avg_price_by_product(@i int)
as
Begin
	SELECT ProductID, AVG(UnitPrice) AS 'Average Price'
	FROM Sales.SalesOrderDetail
	WHERE OrderQty > @i
	GROUP BY ProductID
	ORDER BY AVG(UnitPrice);
end
go
if exists(select name from sys.procedures where name='p_sel_product_by_quantity')
begin
	drop procedure p_sel_product_by_quantity
end
go
Create Procedure p_sel_product_by_quantity(@i int)
as
Begin
	SELECT ProductID 
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
	HAVING AVG(OrderQty) > @i
	ORDER BY ProductID;
end
go
if exists(select name from sys.procedures where name='p_sel_order_by_tracking_partial')
begin
	drop procedure p_sel_order_by_tracking_partial
end
go
Create Procedure p_sel_order_by_tracking_partial(@i int)
as
Begin
	declare @ctNum nvarchar(25), @sqltext nvarchar(4000)
	set @ctnum=(select left(carriertrackingnumber, 4) from sales.SalesOrderDetail where SalesOrderDetailID=@i)

	set @sqltext='SELECT SalesOrderID, CarrierTrackingNumber 
	FROM Sales.SalesOrderDetail
	GROUP BY SalesOrderID, CarrierTrackingNumber
	HAVING CarrierTrackingNumber LIKE ' + ''''+ @ctNum+  '%'+ ''''+'
	ORDER BY SalesOrderID ;'

	exec sp_executesql @sqltext 
end
go
if exists(select name from sys.procedures where name='p_sel_product_by_price_and_quantity')
begin
	drop procedure p_sel_product_by_price_and_quantity
end
go
Create Procedure p_sel_product_by_price_and_quantity(@i int, @x int)
as
Begin
  

	SELECT ProductID 
	FROM Sales.SalesOrderDetail
	WHERE UnitPrice < @i
	GROUP BY ProductID
	HAVING AVG(OrderQty) > @x
	ORDER BY ProductID;
end
go
if exists(select name from sys.procedures where name='p_sel_products_over_onemil_qlessthan3')
begin
	drop procedure p_sel_products_over_onemil_qlessthan3
end
go
Create Procedure p_sel_products_over_onemil_qlessthan3
as
Begin
	SELECT ProductID, AVG(OrderQty) AS AverageQuantity, SUM(LineTotal) AS Total
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
	HAVING SUM(LineTotal) > $1000000.00
	AND AVG(OrderQty) < 3;
end
go
if exists(select name from sys.procedures where name='p_sel_products_over_twomil')
begin
	drop procedure p_sel_products_over_twomil
end
go
Create Procedure p_sel_products_over_twomil
as
Begin
	SELECT ProductID, Total = SUM(LineTotal)
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
	HAVING SUM(LineTotal) > $2000000.00;
end
go
if exists(select name from sys.procedures where name='p_sel_sales_products_where_q_GT')
begin
	drop procedure p_sel_sales_products_where_q_GT
end
go
Create Procedure p_sel_sales_products_where_q_GT(@i int)
as
Begin
	SELECT ProductID, SUM(LineTotal) AS Total
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
	HAVING COUNT(*) > @i;
end
go
if exists(select name from sys.procedures where name='p_ins_temp_bicycles')
begin
	drop procedure p_ins_temp_bicycles
end
go
Create Procedure p_ins_temp_bicycles
as
Begin
if object_id('tempdb..#Bicycles') is not null
begin
	drop table #Bicycles
end

SELECT * 
INTO #Bicycles
FROM Production.Product
WHERE ProductNumber LIKE 'BK%';

end
go
if exists(select name from sys.procedures where name='p_sel_get_sales_rollup_by_product_linetotal')
begin
	drop procedure p_sel_get_sales_rollup_by_product_linetotal
end
go
Create Procedure p_sel_get_sales_rollup_by_product_linetotal(@i int)
as
Begin
	SELECT ProductID, LineTotal, sum(linetotal), max(linetotal)
	FROM Sales.SalesOrderDetail
	WHERE UnitPrice < @i
	group by rollup(productid, linetotal)
	 ORDER BY ProductID, LineTotal
end
go
if exists(select name from sys.procedures where name='p_sel_get_sales_cube_by_prod_ord_unit_line')
begin
	drop procedure p_sel_get_sales_cube_by_prod_ord_unit_line
end
go
Create Procedure p_sel_get_sales_cube_by_prod_ord_unit_line(@i int)
as
Begin
	SELECT ProductID, OrderQty, UnitPrice, LineTotal, sum(orderqty), sum(linetotal)
	FROM Sales.SalesOrderDetail
	WHERE UnitPrice < @i
	group by cube(ProductID, OrderQty, UnitPrice, LineTotal)
	 ORDER BY ProductID, LineTotal
end
go
if exists(select name from sys.procedures where name='p_sel_prod_tble_discounts')
begin
	drop procedure p_sel_prod_tble_discounts
end
go
Create Procedure p_sel_prod_tble_discounts
as
Begin
	SELECT p.Name AS ProductName, 
	NonDiscountSales = (OrderQty * UnitPrice),
	Discounts = ((OrderQty * UnitPrice) * UnitPriceDiscount)
	FROM Production.Product AS p 
	INNER JOIN Sales.SalesOrderDetail AS sod
	ON p.ProductID = sod.ProductID 
	ORDER BY ProductName DESC;
end
go

if exists(select name from sys.procedures where name='p_sel_select_into_union')
begin
	drop procedure p_sel_select_into_union
end
go
Create Procedure p_sel_select_into_union
as
Begin
IF OBJECT_ID ('dbo.ProductResults', 'U') IS NOT NULL
DROP TABLE dbo.ProductResults;

IF OBJECT_ID ('dbo.Gloves', 'U') IS NOT NULL
DROP TABLE dbo.Gloves;

-- Create Gloves table.
SELECT ProductModelID, Name
INTO dbo.Gloves
FROM Production.ProductModel
WHERE ProductModelID IN (3, 4);


SELECT ProductModelID, Name
INTO dbo.ProductResults
FROM Production.ProductModel
WHERE ProductModelID NOT IN (3, 4)
UNION
SELECT ProductModelID, Name
FROM dbo.Gloves;


SELECT ProductModelID, Name 
FROM dbo.ProductResults;
end
go
if exists(select name from sys.procedures where name='p_sel_union_of_2_selects')
begin
	drop procedure p_sel_union_of_2_selects
end
go
Create Procedure p_sel_union_of_2_selects
as
Begin
IF OBJECT_ID ('dbo.Gloves2', 'U') IS NOT NULL
DROP TABLE dbo.Gloves2;


SELECT ProductModelID, Name
INTO dbo.Gloves2
FROM Production.ProductModel
WHERE ProductModelID IN (3, 4);


SELECT ProductModelID, Name
FROM Production.ProductModel
WHERE ProductModelID NOT IN (3, 4)
UNION
SELECT ProductModelID, Name
FROM dbo.Gloves2
ORDER BY Name;

end
go

---LEAVING OFF HERE!!!!---