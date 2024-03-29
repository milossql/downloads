/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*              Ignoring Forced Plans - comments in query                   */
/*                                                                          */
/****************************************************************************/

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

--alter the procedure by adding a comment
ALTER PROCEDURE dbo.GetSalesOrdersSince 
	@OrderDate DATETIME
AS
	SELECT *
	FROM Sales.Orders o --here we forced the plan
	INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	WHERE OrderDate >= @OrderDate
	ORDER BY o.ExpectedDeliveryDate DESC;
GO

EXEC dbo.GetSalesOrdersSince '20150101';
GO
/*
Query Store generated a new query_id for the query and thus forcing plan
does not work */