/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*            Ignoring Forced Plans - environment variables                 */
/*                                                                          */
/****************************************************************************/


USE WideWorldImporters;
GO
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


--playing with ARITHABORT

SET ARITHABORT OFF;
EXEC dbo.GetSalesOrdersSince '20150101';
SET ARITHABORT ON;
GO

SELECT * FROM sys.query_store_query_text;
SELECT * FROM sys.query_store_query;
SELECT * FROM sys.query_context_settings;
 --ARITHABORT:4096
select cast(0x000010FB as int) - cast(0x000000FB as int)
