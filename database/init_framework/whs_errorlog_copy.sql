SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
   Author:		Mikołaj Paszkowski
   Create date: 2020-04-20
   Verison:     2020-04-20	v.1.0		Initial version

   ========================================== */
CREATE PROCEDURE [dbo].[whs_errorlog_copy]
AS
BEGIN TRY
	SET NOCOUNT ON;
    DECLARE
		 @Error_NUMBER          INT             = NULL             
        ,@Error_MSG             NVARCHAR(4000)  = NULL  
        ,@Error_IN_STEP         INT             = 0
        ,@Error_SQL				NVARCHAR(128)   = NULL   
	DECLARE 
		 @job_id				INT				= NULL,
		 @run_id				NVARCHAR(8) 	= SUBSTRING(CONVERT(varchar(max), NEWID()),0,8),
		 @result_message		VARCHAR(max),
		 @start_dttm			DATETIME		= GETDATE(),
		 @end_dttm				DATETIME		= NULL,
		 @step_cnt				SMALLINT		= NULL,
		 @step_passed			SMALLINT		= 0,
		 @step_current			SMALLINT		= 1,
		 @step_current_name		VARCHAR(100)	= NULL,
		 @duration				INT				= NULL,
		 @return_value			INT				= NULL,	  
		 @output_value			INT				= NULL,	  
		 @sql					NVARCHAR(MAX)
	-- =============================================

DROP TABLE if exists #errorlog

SELECT *
INTO #errorlog   -- 
FROM (

	SELECT 'Error found in a LOAD job' as scope
		  ,load_desc as comment
		  ,t.[load_start_dttm] as start_dttm
		  ,'SELECT * FROM [dbo].[wht_loads_log] WHERE [run_id] = ''' + [run_id] + '''' as sql_query
		  ,t.[error_msg]
	  FROM [dbo].[wht_loads_log] t
	 WHERE [error_msg] is not NULL
	UNION
	SELECT 'Error found in ' + job_name as scope
		  ,t.comment
		  ,t.[start_dttm] as start_dttm
		  ,'SELECT * FROM [dbo].[wht_jobs_log] WHERE [id] = ' + CONVERT(varchar,[id]) + ' ' as sql_query
		  ,t.[error_msg]
	  FROM [dbo].[wht_jobs_log] t
	 WHERE result = 1  
	    OR [error_msg] is not NULL	  
) x
ORDER BY start_dttm desc

INSERT INTO dbo.wht_error_log 
	(hash_diff, scope, comment, start_dttm, sql_query, error_msg)
SELECT 
	 dbo.fn_hashbk(
		a.scope, 
		a.comment, 
		a.start_dttm, 
		a.sql_query, 
		a.error_msg) as hash_diff,
	 b.scope, 
	 b.comment, 
	 b.start_dttm, 
	 b.sql_query, 
	 b.error_msg
	 FROM #errorlog a
 LEFT JOIN dbo.wht_error_log b 
   ON  dbo.fn_hashbk(
			a.scope, 
			a.comment, 
			a.start_dttm, 
			a.sql_query, 
			a.error_msg) = b.hash_diff
   WHERE b.hash_diff is NULL

	-- =============================================
END TRY
BEGIN CATCH
	-- End step: Handle ERROR 

	-- Update steps

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
	SELECT @result_message = 'Job FAILED ';
    
	SELECT 
	     @Error_NUMBER      = ERROR_NUMBER()
        ,@Error_MSG         = ERROR_MESSAGE() 
        ,@end_dttm          = GETDATE()
	
	PRINT convert(varchar, @Error_MSG)

	RETURN 1;

END CATCH