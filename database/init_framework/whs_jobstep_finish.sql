/****** Object:  StoredProcedure [dbo].[whs_jobstep_finish]    Script Date: 02.03.2020 12:58:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE if exists [dbo].[whs_jobstep_finish]
GO

/* =============================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-02-20
   Verison:     2020-03-02	v.1.0		Initial version
				2020-03-09	v.1.1		Added @step_uid
   ========================================== */
CREATE PROCEDURE [dbo].[whs_jobstep_finish]
				( @step_name VARCHAR(100) = NULL,
				  @run_id NVARCHAR(8) = NULL,
				  @start_dttm DATETIME = NULL,
				  @row_cnt INT = NULL,
				  @step_uid UNIQUEIDENTIFIER = NULL		-- see whs_jobstep_init
				)
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
		 @end_dttm				DATETIME		= NULL,
		 @duration				INT				= NULL

	-- =============================================
	-- End step: Finish
	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
	SELECT @result_message = 'Step: ' + @step_name + ' completed in ' + convert(varchar,@duration) + ' second(s). Rows merged: ' + convert(varchar, @row_cnt) + ' ';

	UPDATE t
	   SET row_cnt	  = @row_cnt,
		   comment    = @result_message,
		   end_dttm   = @end_dttm,
		   duration   = @duration,
		   result     = 0
	FROM dbo.wht_steps_log t 
	WHERE 
		t.id = COALESCE(@step_uid, t.id)
	AND	run_id = @run_id 
	AND t.step_name = @step_name
	

	RETURN 0;

	-- =============================================
END TRY
BEGIN CATCH
	-- End step: Handle ERROR

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
	SELECT @result_message = 'Step init: ' + @step_name + ' FAILED ';

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
