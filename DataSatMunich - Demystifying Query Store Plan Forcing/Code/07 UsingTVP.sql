/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*            Ignoring Forced Plans - using table-valued parameters         */
/*                                                                          */
/****************************************************************************/

USE WideWorldImporters;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
--create a user table type
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE is_table_type = 1 AND name = N'IntList')
	CREATE TYPE dbo.IntList AS TABLE(
	Id INT NOT NULL PRIMARY KEY CLUSTERED
	)
GO
--create a sample stored proc
CREATE OR ALTER PROCEDURE dbo.GetOrderList (@tvp AS dbo.IntList READONLY)
AS
	SELECT o.* FROM Sales.Orders o
	INNER JOIN @tvp t on o.OrderID = t.Id;
GO

--clear and turn on Query Store
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON;
GO

--execute the code
DECLARE @t AS dbo.IntList;
INSERT @t SELECT TOP (10) OrderId FROM Sales.Orders ORDER BY 1 DESC;
EXEC dbo.GetOrderList @t;
GO 
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
DECLARE @t AS dbo.IntList;
INSERT @t SELECT TOP (2000) OrderId FROM Sales.Orders ORDER BY 1 DESC;
EXEC dbo.GetOrderList @t;
GO


--force the plan


--alter proc
ALTER PROCEDURE dbo.GetOrderList (@tvp AS dbo.IntList READONLY)
AS
	SELECT o.* FROM Sales.Orders o
	INNER JOIN @tvp t on o.OrderID = t.Id;
GO
--call 

DECLARE @t AS dbo.IntList;
INSERT @t SELECT TOP (2000) OrderId FROM Sales.Orders ORDER BY 1 DESC;
EXEC dbo.GetOrderList @t;
GO


SELECT * FROM sys.query_store_query_text;
SELECT * FROM sys.query_store_query;
 

SELECT qs.query_id, q.query_sql_text, qs.query_hash, qs.batch_sql_handle
FROM sys.query_store_query AS qs
INNER JOIN sys.query_store_query_text AS q ON qs.query_text_id = q.query_text_id
WHERE object_id = OBJECT_ID('dbo.GetOrderList')
ORDER BY qs.last_execution_time DESC