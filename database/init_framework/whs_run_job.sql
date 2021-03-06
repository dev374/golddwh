/****** Object:  StoredProcedure [dbo].[whs_run_job]    Script Date: 23.02.2021 12:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

	DROP TABLE if exists [dbo].[whs_run_job]
	GO

*/
/* =============================================
   Author:		Mikołaj Paszkowski
   Create date: 2020-02-20
   Verison:     2020-02-20	v.1.0		Initial version - @job_name is mandatory
				2020-02-24	v.1.1		Merged with wht_run_job2
				2020-03-09	v.1.2		Invalid job = -1
				2020-04-09	v.1.3		

   ========================================== */
ALTER PROCEDURE [dbo].[whs_run_job] 
				( @job_name NVARCHAR(100) ) 
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
		 @step_uid				UNIQUEIDENTIFIER,
		 @step_cnt				SMALLINT		= NULL,
		 @step_passed			SMALLINT		= 0,
		 @step_current			SMALLINT		= 1,
		 @step_current_name		VARCHAR(100)	= NULL,
		 @duration				INT				= NULL,
		 @return_value			INT				= NULL,	  
		 @output_value			INT				= NULL,	  
		 @sql					NVARCHAR(MAX)
	-- =============================================
	-- Start: Initialize JOB step 
	-- =============================================
	SELECT TOP 1 @job_id = j.id 
	  FROM [dbo].wht_jobs j 
	 WHERE j.job_name = @job_name
	   AND j.active = 1 

	IF (@job_id is null) 
		SET @job_id = -1

	DROP TABLE if exists #steps;

	SELECT t.id				as id, 
		   t.step_name		as step_name, 
		   t.step_seq_nr	as step_seq_nr, 
		   @run_id			as run_id
	  INTO #steps
	  FROM wht_steps t 
	 WHERE t.job_id = @job_id
	   AND active = 1
	 ORDER BY step_seq_nr asc;

	SET @step_cnt = (SELECT count(*) FROM #steps)
		
	INSERT INTO dbo.wht_jobs_log (
				[job_id],
				[job_name],
				[run_id],
				[step_cnt],
				[step_current],
				[comment],
				[start_dttm],
				[result]) 
	 SELECT @job_id,
			@job_name,
			@run_id				as run_id,
			@step_cnt			as step_cnt,
			@step_current		as step_current,
			'job initialised'	as comment,
			@start_dttm			as start_dttm,
			1					as result

	-- =============================================
	-- Start: Initialize STEPS log
	-- =============================================
	IF (@job_id is null OR @job_id = -1) 
		RAISERROR ('Error - invalid job name ', 16, 1);
	ELSE

		INSERT INTO dbo.wht_steps_log (step_id,step_name,step_seq_nr,job_id,job_name,run_id,comment,start_dttm,result) 
		 SELECT t.id				as step_id,
				t.step_name			as step_name,
				t.step_seq_nr		as step_seq_nr,
				@job_id				as job_id,
				@job_name			as job_name,
				@run_id				as run_id,
				'Step initialised by job'	as comment,
				@start_dttm			as start_dttm,
				1					as result
		FROM #steps t
		ORDER BY t.step_seq_nr desc

	-- =============================================
    -- === Process steps
	-- =============================================
print @step_cnt	
	WHILE (@step_cnt > 0 )
		BEGIN

			SELECT @step_current = MIN(step_seq_nr) FROM #steps
			UPDATE wht_jobs_log 
			   SET step_current = COALESCE(@step_current, 0) 
			 WHERE run_id = @run_id
			  
			SELECT @step_current_name = step_name 
			  FROM #steps 
			 WHERE step_seq_nr = @step_current 
			
			UPDATE wht_steps_log 
			   SET start_dttm = COALESCE(@end_dttm, GETDATE()) 
			 WHERE run_id = @run_id
			   AND step_seq_nr = @step_current

			SET @sql = N'EXEC @rtn = dbo.' + @step_current_name + 
						' @run_id = @run_id'	-- v.1.3
			PRINT @sql

			EXEC sp_executesql @sql, N'@run_id NVARCHAR(100), @rtn INT OUTPUT', 
				@run_id = @run_id,
				@rtn = @return_value OUTPUT;
print @return_value
	-- === If no error then proceed next step
			
			IF @return_value = 0  
				BEGIN
					SET @step_cnt -= 1
					SET @step_passed += 1
					DELETE FROM #steps WHERE step_seq_nr = @step_current

				END
	-- === If error then catch

			ELSE 
				BEGIN
					SELECT TOP 1 
						@Error_SQL = N'SELECT * FROM [dbo].[wht_steps_log] 
										WHERE id = ''' + SUBSTRING(CONVERT(nvarchar(max), s.id),0, 100) + ''' ',
						@Error_MSG =  N'Error in step: ' + convert(nvarchar(100),@step_current),
						@Error_IN_STEP = @step_current -- SELECT TOP 1 *
					FROM [dbo].[wht_steps_log] s  -- ORDER BY start_dttm desc
					WHERE run_id = @run_id 
						AND s.step_seq_nr = @step_current
					ORDER BY start_dttm desc
			
					RAISERROR (@Error_MSG, 16, 1);
				END;
		END 
	-- === Penultimate job step (purge the log)


	-- =============================================
	-- End step: Handle output 
	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
		  ,@result_message = 'Job COMPLETED in ' + convert(varchar,@duration) + ' second(s) (' + @job_name + ')';

	UPDATE j
	   SET comment    = @result_message,
		   end_dttm   = @end_dttm,
		   duration   = @duration,
		   result     = 0 -- select *
	FROM dbo.wht_jobs_log j
	-- select * FROM dbo.wht_steps_log j   -- FD42B3B
	WHERE j.start_dttm = @start_dttm
	  AND j.job_name = @job_name

	RETURN 0;

	-- =============================================
END TRY
BEGIN CATCH
	-- End step: Handle ERROR 

	-- Update steps

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
	SELECT @result_message = 'Job FAILED after ' + convert(varchar,@step_passed) + ' steps in: ' + convert(varchar,@Error_IN_STEP) + ' (' + @job_name + ')';
    
	SELECT 
	     @Error_NUMBER      = ERROR_NUMBER()
        ,@Error_MSG         = ERROR_MESSAGE() 
        ,@end_dttm          = GETDATE()
	
	PRINT convert(varchar, @Error_MSG)

	-- Update job
		UPDATE j
		   SET  comment			= @result_message,
				end_dttm		= @end_dttm,
				duration		= @duration,
				result			= 1,
				[error_number]	= @Error_NUMBER,
				[error_msg]		= @Error_MSG,  
				[error_in_step]	= @Error_IN_STEP,
				[error_sql]   	= @Error_SQL
		  FROM dbo.wht_jobs_log j
		 WHERE j.start_dttm = @start_dttm
		   AND j.job_name = @job_name

		UPDATE s
		SET comment = 'Step COMPLETED and follower FAILED  * ROLL BACK'
		FROM [dbo].[wht_steps_log] s 
		WHERE run_id = @run_id 
			AND s.step_seq_nr < @step_current

		UPDATE s
		SET comment = 'Step FAILED * step ERROR',
			end_dttm		= @end_dttm,
			duration		= @duration,
			[error_number]	= @Error_NUMBER,
			[error_msg]		= @Error_MSG
		FROM [dbo].[wht_steps_log] s 
		WHERE run_id = @run_id 
			AND s.step_seq_nr = @step_current

		UPDATE s
		SET comment = 'Step initialised * aborting',
			end_dttm		= @end_dttm,
			duration		= @duration
		FROM [dbo].[wht_steps_log] s 
		WHERE run_id = @run_id 
			AND s.step_seq_nr > @step_current

	RETURN 1;

END CATCH
