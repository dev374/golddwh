DECLARE	@return_value int

EXEC	@return_value = [dbo].[whs_run_job] 'LOAD_RDV_HUB'

SELECT	'Return Value' = @return_value

GO


SELECT * FROM [dbo].[wht_steps_log] ORDER BY start_dttm desc