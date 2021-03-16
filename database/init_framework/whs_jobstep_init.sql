/****** Object:  StoredProcedure [dbo].[whs_jobstep_init]    Script Date: 08.04.2020 20:17:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE if exists [dbo].[whs_jobstep_init]
GO

/* =============================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-02-20
   Verison:     2020-03-02	v.1.0		Initial version
				2020-04-07	v.1.1		Added @step_line - this is a sub step of a step. Makes more steps available in the procedure
				2020-04-09	v.1.2		Output uid
				2021-02-23	v.1.3		Check to work either as a job or standalone

   ========================================== */
CREATE PROCEDURE [dbo].[whs_jobstep_init]
				( @step_name VARCHAR(100) = NULL,
				  @run_id NVARCHAR(8) = NULL,
				  @step_line SMALLINT = 0,
				  @step_uid UNIQUEIDENTIFIER OUTPUT)
AS
BEGIN TRY
	SET NOCOUNT ON;
    DECLARE
		 @Error_NUMBER          INT             = NULL
        ,@Error_MSG             NVARCHAR(4000)  = NULL
        ,@Error_LINE            INT             = NULL
        ,@Error_PROC            NVARCHAR(128)   = NULL
        ,@Error_SEV             INT             = NULL
        ,@Error_STATE           INT             = NULL
        ,@Error_COUNT           INT             = 0
	DECLARE
		 @job_specifics			VARCHAR(50) 	= 'Standalone step',
		 @result_message		VARCHAR(max)	= NULL,
		 @start_dttm			DATETIME		= GETDATE(),
		 @end_dttm				DATETIME		= NULL,
		 @row_cnt				INT				= NULL,
		 @duration				INT				= NULL,
		 @jobid				    INT				= 0,
		 @uid				    UNIQUEIDENTIFIER = NEWID()

	-- =============================================
	-- Start step: Initialize job step

	IF (NOT EXISTS (SELECT 1 FROM dbo.wht_steps_log WHERE run_id = @run_id))
	INSERT INTO dbo.wht_steps_log (id,job_id,job_name,step_id,step_name,step_seq_nr,run_id,comment,start_dttm,result)
	SELECT 
		@uid							as id,
		0								as job_id,
		@job_specifics					as job_name,
		0								as step_id,
		COALESCE(@step_name, @job_specifics) as step_name,
		0								as step_seq_nr,
		@run_id as run_id,
		'Step started'					as comment,
		@start_dttm						as start_dttm,
		1								as result
	
	SELECT @step_uid = @uid

	-- =============================================
END TRY
BEGIN CATCH
	-- End step: Handle ERROR

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
	SELECT @result_message = 'Jobstep init: ' + @step_name + ' FAILED ';

	SELECT
	     @Error_NUMBER      = ERROR_NUMBER()
        ,@Error_PROC        = ERROR_PROCEDURE()
        ,@Error_SEV         = ERROR_SEVERITY()
        ,@Error_STATE       = ERROR_STATE()
        ,@Error_LINE        = ERROR_LINE()
        ,@Error_MSG         = ERROR_MESSAGE()
        ,@Error_COUNT       = @Error_COUNT + 1
        ,@row_cnt           = 0
        ,@end_dttm          = GETDATE()

	UPDATE t
	   SET  row_cnt			= @row_cnt,
		    comment			= @result_message,
		    end_dttm		= @end_dttm,
		    duration		= @duration,
		    result			= 1,
			[error_number]	= @Error_NUMBER,
			[error_msg]		= @Error_MSG,
			[error_line]	= @Error_LINE,
			[error_proc]	= @Error_PROC,
			[error_sev]		= @Error_SEV,
			[error_state]	= @Error_STATE,
			[error_count]	= @Error_COUNT
	  FROM dbo.wht_steps_log t
	 WHERE t.id = @uid

	RETURN 1;

END CATCH

