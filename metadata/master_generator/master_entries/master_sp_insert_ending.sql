DELETE FROM mtd.master_generator
WHERE generator_type = 'sp_insert_ending'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'sp_insert_ending',
'BEGIN CATCH
	PRINT N''sp catch''

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
		  ,@result_message = ''Step: '' + @step_name + '' FAILED '';
    
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
		    result			= -1,
			[error_number]	= @Error_NUMBER,
			[error_msg]		= @Error_MSG,
			[error_line]	= @Error_LINE,
			[error_proc]	= @Error_PROC,
			[error_sev]		= @Error_SEV,
			[error_state]	= @Error_STATE,
			[error_count]	= @Error_COUNT 
	  FROM dbo.wht_steps_log t
	 WHERE t.id = @step_uid_out 
	
	PRINT convert(varchar(4000), @Error_MSG)

END CATCH;
GO;
');