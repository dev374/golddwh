	DECLARE	@return_value int
	EXEC	@return_value = [dbo].[master_generate_rdv] @execute_sql = 0
	SELECT	'Return Value' = @return_value
	GO
