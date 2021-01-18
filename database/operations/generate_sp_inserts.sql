DECLARE	@return_value int

EXEC	@return_value = [mtd].[master_gen_sp_inserts_rdv] @execute_sql = 1
--EXEC	@return_value = [mtd].[master_gen_sp_drop_rdv] @execute_sql = 1
SELECT	'Return Value' = @return_value

GO
