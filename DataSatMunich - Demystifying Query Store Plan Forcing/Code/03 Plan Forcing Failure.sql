/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*                             Plan Forcing Failure                         */
/*                                                                          */
/****************************************************************************/


USE WideWorldImporters;
GO
--clear and turn on Query Store
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON;
GO

--add a sample stored proc
CREATE OR ALTER PROCEDURE dbo.GetSalesOrdersSince 
	@OrderDate DATETIME
AS
	SELECT *
	FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	WHERE OrderDate >= @OrderDate
	ORDER BY o.ExpectedDeliveryDate DESC;
GO

--add an index on the OrderDate column
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'ix1' AND object_id = OBJECT_ID('Sales.Orders'))
	CREATE INDEX ix1 ON Sales.Orders(OrderDate);
GO


/*
####################################################
##					DEMO 				  	      ##
####################################################
*/
--call the SP
EXEC dbo.GetSalesOrdersSince '20170101';
--force the plan
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;
GO
--remove the index
DROP INDEX ix1 ON Sales.Orders;
GO
--call the SP again
EXEC dbo.GetSalesOrdersSince '20170101';
GO

/*
	SQL Server tried to create a plan with forced plan as a shape and failed,
	but it creates a new plan
	forcing failure reason is set to NO_INDEX
*/
--remove  plans from cache
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
EXEC dbo.GetSalesOrdersSince '20170101';
GO
--the failure count attribute is incremented


--when you create an index on the given column, but with different name, 
--forcing won't work
CREATE INDEX ix2 ON Sales.Orders(OrderDate);
GO
EXEC dbo.GetSalesOrdersSince '20170101';
GO

--when you create the index with that name but different column, forcing won't work
CREATE INDEX ix1 ON Sales.Orders(CustomerId);
GO
EXEC dbo.GetSalesOrdersSince '20170101';
GO
--this time forcing failure reason is NO_PLAN
GO
DROP INDEX ix2 ON Sales.Orders;DROP INDEX i1 ON Sales.Orders;
GO

--Index name and leading column must be the same
CREATE INDEX ix1 ON Sales.Orders(OrderDate, CustomerId);
GO
EXEC dbo.GetSalesOrdersSince '20170101';
--this time forcing plan works
GO

---------------------------------------
----- simple query with index hint
------------------------------------------

--In case of index hnts, you'll always get an exception
CREATE INDEX ix1 ON Sales.Orders(OrderDate) WITH DROP_EXISTING;
GO

SELECT * FROM Sales.Orders WITH (INDEX(ix1)) WHERE OrderDate >= '20190505';

DROP INDEX ix1 ON Sales.Orders;

SELECT * FROM Sales.Orders WITH (INDEX(ix1)) WHERE OrderDate >= '20190505';
GO

 