/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*            Automatic Tuning - sys.dm_db_tuning_recommendations           */
/*                                                                          */
/****************************************************************************/

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
 