/****** Object:  StoredProcedure [mtd].[master_dropper_rdv]    Script Date: 16.03.2021 12:17:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =============================================
   Author:		Mikołaj Paszkowski
   Create date: 2020-12-08
   Verison:     2020-12-08	v.1.0		Initial version 
										RDV complete dropper of the rdv
										
   ========================================== */

CREATE PROCEDURE [mtd].[master_dropper_rdv] (@execute_sql INT = 0)
AS
BEGIN

	DECLARE @sql_table TABLE (
		id INT IDENTITY,
		command VARCHAR(max));
	DECLARE @sql NVARCHAR(max);
	DECLARE @cnt INT = 0;


	INSERT INTO @sql_table
		SELECT DISTINCT command
		FROM (
		SELECT --hub
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name as command
		from [mtd].[master_generator] g
		cross join adf.meta_hub_mapping h
		where generator_type = 'create_hub_table'
		UNION ALL
		SELECT -- hsat
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_hsat_mapping h
		where generator_type = 'create_hsat_table'
		UNION ALL
		SELECT 
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_lnk_mapping h
		where generator_type = 'create_lnk_table'
		/*
		UNION ALL
		SELECT 
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_lsat_mapping h
		where generator_type = 'create_lsat_table'
		UNION ALL
		SELECT 
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_lsat_status_mapping h
		where generator_type = 'create_lsat_status_table'
		UNION ALL
		SELECT 
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_pit_mapping h
		where generator_type = 'create_pit_table'
		UNION ALL
		SELECT 
			'DROP TABLE if exists ' + h.schema_name + '.' + h.table_name
		from [mtd].[master_generator] g
		cross join adf.meta_ref_mapping h
		where generator_type = 'create_ref_table'
		*/
		) t;

	SET @cnt = (select count(*) from @sql_table);

	WHILE @cnt > 0 
	BEGIN 
		SELECT @sql = command from @sql_table where id = @cnt;
		PRINT @sql
		IF @execute_sql = 1 
			EXEC dbo.sp_executesql @sql;
		SET @cnt -= 1;
	END;

END;
GO

