/****************************************************************************/
/*                     Data Saturday  #40 München                           */
/*                     Author: Miloš Radivojević                            */
/*          Session: Demystifying Query Store Forced Plans                  */
/****************************************************************************/
/*                 Plan forcing for a parameter sensitive query             */
/*                                                                          */
/****************************************************************************/

/*
For this demo we'll create a new database from scratch
*/

IF DB_ID('NewDB') IS NULL CREATE DATABASE NewDB;
GO
USE NewDB;
GO

--create a sample table:
--help function GetNums created by Itzik Ben-Gan (http://tsql.solidq.com)
IF OBJECT_ID('dbo.GetNums') IS NOT NULL DROP FUNCTION dbo.GetNums;
GO
CREATE FUNCTION dbo.GetNums(@n AS BIGINT) RETURNS TABLE
AS
RETURN
  WITH
  L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
  SELECT n FROM Nums WHERE n <= @n;
GO

--Create a sample table
DROP TABLE IF EXISTS dbo.Events;
CREATE TABLE dbo.Events(
Id INT IDENTITY(1,1) NOT NULL,
EventType TINYINT NOT NULL,
EventDate DATETIME NOT NULL,
Note CHAR(100) NOT NULL DEFAULT 'test',
CONSTRAINT PK_Events PRIMARY KEY CLUSTERED (id ASC)
);
GO
-- Populate the table with 1M rows
DECLARE @date_from DATETIME = '20000101';
DECLARE @date_to DATETIME = '20190901';
DECLARE @number_of_rows INT = 1000000;
INSERT INTO dbo.Events(EventType,EventDate)
SELECT 1 + ABS(CHECKSUM(NEWID())) % 5 AS eventtype,
(SELECT(@date_from +(ABS(CAST(CAST( NewID() AS BINARY(8)) AS INT))%CAST((@date_to - @date_from)AS INT)))) AS EventDate
FROM dbo.GetNums(@number_of_rows)
GO
--Create index on the orderdate column
CREATE INDEX ix1 ON dbo.Events(EventDate);
GO
CREATE OR ALTER PROCEDURE dbo.GetEventsSince
@OrderDate DATETIME
AS
BEGIN
	SELECT * FROM dbo.Events
	WHERE EventDate >= @OrderDate
	ORDER BY Note DESC;
END
GO
ALTER DATABASE NewDB SET COMPATIBILITY_LEVEL = 140;
GO
/*
####################################################
##					DEMO SETUP					  ##
####################################################
*/
--setup Query Store
ALTER DATABASE NewDB SET QUERY_STORE CLEAR;
GO
ALTER DATABASE NewDB SET QUERY_STORE = ON;
GO

--Ensure that the Discard results after execution option is turned on
--Execute the following code
EXEC dbo.GetEventsSince '20200101' -- 0 rows
GO 1000
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.GetEventsSince '20140101' --237K rows
GO 3

/*
open the Top Resource Consuming Queries report and find the query_id
you can again see two plans
You can choose the good plan and click the Force plan button to force 
the Nested Loops Join based plan, but in this case this is not good idea
 */

--run the same query again
EXEC dbo.GetEventsSince '20140102' --237K rows
GO 3
/*
The execution is slower than the initial one
Be careful with parameter sensitive queries!
*/
 