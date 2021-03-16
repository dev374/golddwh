DECLARE	@return_value int

--EXEC [mtd].[master_dropper_rdv]
--EXEC [mtd].[master_create_all_rdv] @execute_sql = 0

EXEC	@return_value = [mtd].[master_gen_sp_drop_rdv] @execute_sql = 0
EXEC	@return_value = [mtd].[master_gen_sp_inserts_rdv] @execute_sql = 0

SELECT	'Return Value' = @return_value

GO