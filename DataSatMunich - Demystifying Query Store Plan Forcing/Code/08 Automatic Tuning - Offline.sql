/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*    Upgrade from SQL Server 2012 to SQL Server 2019 (CL 110 to CL 150)    */
/*                                                                          */
/****************************************************************************/


USE WideWorldImporters;
GO
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 110;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR;
GO
ALTER DATABASE WideWorldImporters SET QUERY_STORE = ON (QUERY_CAPTURE_MODE = AUTO)
GO
ALTER DATABASE current SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = OFF); 
GO


--Ensure that the Discard results after execution option is turned on
--run query with CL 110
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0, 900);
GO 100

 

--change CL to the latest one
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 150;
GO


--run the same query
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE o.SalespersonPersonID IN (0, 900);
GO 50

--check DMV recommendations
SELECT * FROM sys.dm_db_tuning_recommendations;
GO
SELECT   
	reason,
	estimated_gain =  (regressedPlanExecutionCount + recommendedPlanExecutionCount)
      * (regressedPlanCpuTimeAverage - recommendedPlanCpuTimeAverage)/1000000,
	score,
	execute_action_initiated_by,
	script = JSON_VALUE(details, '$.implementationDetails.script'),
	d.[query_id],
	d.regressedPlanId,
    d.recommendedPlanId,
	error_prone = IIF(regressedPlanErrorCount > recommendedPlanErrorCount, 'YES','NO')
FROM sys.dm_db_tuning_recommendations
CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            regressedPlanId int '$.regressedPlanId',
            recommendedPlanId int '$.recommendedPlanId',
            regressedPlanErrorCount int,
            recommendedPlanErrorCount int,
            regressedPlanExecutionCount int,
            regressedPlanCpuTimeAverage float,
            recommendedPlanExecutionCount int,
            recommendedPlanCpuTimeAverage float
          ) AS d;



SELECT
	name,
	d.currentValue,
	d.reason
FROM sys.dm_db_tuning_recommendations
CROSS APPLY OPENJSON (State)
    WITH ( 
		currentValue varchar(50) '$.currentValue',
 		reason varchar(50) '$.reason' 
          ) AS d;
 