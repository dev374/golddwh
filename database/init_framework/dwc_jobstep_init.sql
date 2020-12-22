/****** Object:  StoredProcedure [dbo].[dwc_jobstep_init]    Script Date: 20.12.2020 20:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE if exists [dbo].[dwc_jobstep_init]
GO

/* =============================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-02-20
   Verison:     2020-12-20	v.1.3	    @step_uid and testing - working
   ========================================== */
CREATE PROCEDURE [dbo].[dwc_jobstep_init]
				( @step_name VARCHAR(100) = NULL,
				  @run_id NVARCHAR(8) = NULL,
				  @step_line SMALLINT = 0,
				  @step_uid UNIQUEIDENTIFIER = NULL OUTPUT)
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
		 @job_specifics			VARCHAR(100)	= 'Standalone step',
		 @result_message		VARCHAR(max)	= NULL,
		 @start_dttm			DATETIME		= GETDATE(),
		 @end_dttm				DATETIME		= NULL,
		 @row_cnt				INT				= NULL,
		 @duration				INT				= NULL,
		 @new_uid				UNIQUEIDENTIFIER = COALESCE(@step_uid, NEWID())

	-- =============================================
	-- Start step: Initialize job step
	IF ( 0 = (SELECT count(*)
			    FROM dbo.wht_steps_log  t
			   WHERE t.id = @new_uid )	OR
		@run_id = convert(varchar,(convert(varchar, @start_dttm, 112)) ) OR
		@step_line > 0 )
		INSERT INTO dbo.wht_steps_log (id, step_id,step_name,step_seq_nr,job_id,run_id,comment,start_dttm,result)
		SELECT 
			@new_uid								as id,
			t.id									as step_id,
			@step_name								as step_name,
			t.step_seq_nr + @step_line				as step_seq_nr,
			t.job_id								as job_id,			
			@run_id									as run_id,
			'Step started'							as comment,
			@start_dttm								as start_dttm,
			1										as result
		 FROM [dbo].wht_steps t
		WHERE t.step_name = @step_name
	ELSE
		UPDATE j
		   SET  comment			= 'Step found and restarted',
				start_dttm		= @start_dttm,
				duration		= 0
		  FROM dbo.wht_steps_log j
		 WHERE j.id = @new_uid

	/*  @uid
	-- v.1.2 Return uid
	SELECT @step_uid = id
	  FROM dbo.wht_steps_log
	 WHERE @run_id = run_id
	   AND 'step started' = comment
	*/
	PRINT 'sp job init uid'
	PRINT @new_uid
	SELECT @new_uid
	RETURN 

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
	 WHERE t.start_dttm = @start_dttm
	   AND t.step_name = @step_name

	RETURN 1;

END CATCH

