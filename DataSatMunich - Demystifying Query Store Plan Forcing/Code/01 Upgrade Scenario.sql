/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*    Upgrade from SQL Server 2012 to SQL Server 2019 (CL 110 to CL 150)    */
/*                                                                          */
/****************************************************************************/


/*
For this demo you need to get the backup of the WideWorldImporters database
from this link: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
and restore it as WideWorldImporters database
*/
USE WideWorldImporters;
GO

--this line should be executed to ensure that Query Store is cleared in case it was turned on
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO

/*
turn Query Store on with custom settings, to reduce number of queries,
you can also use simple
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON
if you want */
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON (
QUERY_CAPTURE_MODE = AUTO
)
GO


--simulate SQL Server 2012
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 110;
GO

--Ensure that the Discard results after execution option is turned on
--run query with CL 110 100 times
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.PickedByPersonID IN (0, 900);
GO 100

--change CL to the latest one
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 150;
GO

--run the same query again
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.PickedByPersonID IN (0, 900);
GO 100

/*
open the Top Resource Consuming Queries report and find the query_id
you can see two plans, a good one, Nested Loop Join based under CL 110
and a bad plan with Hash Joins under 150
You can choose the good plan and click the Force plan button to force 
the Nested Loops Join based plan
 */
 --run the same query again
SELECT * FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.PickedByPersonID IN (0, 900);
GO 100
/*
query runs faster, with the forced plan
forced plan means that SQL Server has created a new plan (third plan for this query)
with the same shape as for the plan 1
It is recommended to use the SP for plan forcing rather than clicking on the button
in order to document changes you made
 i.e.
--EXEC sp_query_store_force_plan  @query_id = 1 , @plan_id = 1
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;