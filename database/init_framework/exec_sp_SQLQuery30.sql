DECLARE	@return_value int
EXEC	@return_value = [dbo].[sp_list_job_control]
		@run_id = N'SP_LIST'
SELECT	'Return Value' = @return_value
GO

DECLARE	@return_value int
EXEC	@return_value = [dbo].[sp_list_job_error]
		@run_id = N'SP_ERR'
SELECT	'Return Value' = @return_value
GO