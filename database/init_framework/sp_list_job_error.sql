SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =============================================
   Author:		Mikołaj Paszkowski
   Create date: 2020-12-20
   Verison:     2020-12-20	v.1.0		Initial version

   ========================================== */
ALTER PROCEDURE [dbo].[sp_list_job_error]
				( @run_id NVARCHAR(8) = '98765432' )
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
        ,@Error_SPECIFICS       SQL_VARIANT     = NULL
	DECLARE
		 @step_name				VARCHAR(100),
		 @result_message		VARCHAR(max)	= NULL,
		 @start_dttm			DATETIME		= GETDATE(),
		 @end_dttm				DATETIME		= NULL,
		 @duration				INT				= NULL,
		 @row_cnt				INT				= 0,
		 @step_uid				UNIQUEIDENTIFIER = NEWID();
	-- =============================================		 
	SELECT @run_id = COALESCE(@run_id, convert(varchar,@@SPID))
	SELECT @step_name = OBJECT_NAME(@@PROCID)	
	-- =============================================
	-- Start step: Initialize job step
	EXEC @step_uid = dbo.whs_jobstep_init @step_name, @run_id, @step_uid = @step_uid
	-- =============================================
	PRINT N'sp step uid: ' + convert(nvarchar(max), @step_uid)
	WAITFOR DELAY '00:00:05'
	--INSERT INTO rdv.hsat_card (card_id)
	SELECT t.id FROM mtd.job_control t
	SELECT  5/0

	-- =============================================
	-- End step: Handle output
	PRINT 'sp finish'
	EXEC dbo.whs_jobstep_finish @step_name, @run_id, @start_dttm, @row_cnt, @step_uid
	RETURN 0;
	-- =============================================

END TRY
BEGIN CATCH
	-- End step: Handle ERROR 
	PRINT N'sp catch'
	-- Update steps

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
		  ,@result_message = 'Step: ' + @step_name + ' FAILED ';
    
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
			[error_count]	= @Error_COUNT -- select * 
	  FROM dbo.wht_steps_log t
	 WHERE t.id = @step_uid 
	
	PRINT convert(varchar(100), @Error_MSG)
	PRINT N'sp catch 2'

	RETURN 1;

END CATCH
GO


