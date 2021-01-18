DECLARE	@return_value int

EXEC	@return_value = [dbo].[master_gen_sp_drop_rdv] @execute_sql = 1

SELECT	'Return Value' = @return_value

GO
