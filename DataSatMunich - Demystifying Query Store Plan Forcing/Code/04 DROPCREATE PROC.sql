/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*                 Ignoring Forced Plans - DROP/CREATE                      */
/*                                                                          */
/****************************************************************************/


 
USE WideWorldImporters;
GO
CREATE OR ALTER PROCEDURE dbo.GetSalesOrdersSince 
	@OrderDate DATETIME
AS
	SELECT *
	FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	WHERE OrderDate >= @OrderDate
	ORDER BY o.ExpectedDeliveryDate DESC;
GO

----------------------------------------------------------------
-- Plan forcing and drop/create procedure
----------------------------------------------------------------

--clear and turn on Query Store
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON;
GO

--call the SP
EXEC dbo.GetSalesOrdersSince '20170101';

--force the plan
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;
GO
--call the SP with less selective parameter
EXEC dbo.GetSalesOrdersSince '20150101';
GO

--drop and recreate procedure
DROP PROCEDURE dbo.GetSalesOrdersSince 
GO
CREATE PROCEDURE dbo.GetSalesOrdersSince 
	@OrderDate DATETIME
AS
	SELECT *
	FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	WHERE OrderDate >= @OrderDate
	ORDER BY o.ExpectedDeliveryDate DESC;
GO

EXEC dbo.GetSalesOrdersSince '20150101';
GO
--plan is not respected anymore, the query got a new query_id
--Check query_ids
SELECT * FROM sys.query_store_query_text;
SELECT * FROM sys.query_store_query;
