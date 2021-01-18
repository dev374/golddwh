DROP PROCEDURE if exists [mtd].[master_gen_sp_inserts_rdv]
GO

/* =============================================
	Synopsis:	Complete generator for insert procedures RDV --> jobs

	Author:		Mikołaj Paszkowski
	Created: 	2021-01-15
	Verison:    2021-01-15	v.1.0		Initial version 
										
   ========================================== */

CREATE PROCEDURE [mtd].[master_gen_sp_inserts_rdv] (@execute_sql INT = 0)
AS
BEGIN

	DECLARE @sql_table TABLE (
		id INT IDENTITY,
		command VARCHAR(max));
	DECLARE @sql NVARCHAR(max);
	DECLARE @cnt INT = 0;

WITH colist 
as (
	SELECT 
		h.table_name,
		h.hub_table_name,
		h.schema_name, 
		h.stg_schema_name, 
		h.stg_table_name, 
		string_agg(h.column_name+' '+h.data_type+
				   case when character_maximum_length is null then '' else '('+character_maximum_length+')' end +
				   case when numeric_precision is null then '' else '('+numeric_precision+','+numeric_scale+')' end +
				   case is_nullable_ind when 0 then ' NOT NULL' else ' NULL' end , ',')
		  within group (order by h.column_position) as column_list,
		string_agg(h.column_name,',')
		  within group (order by h.column_position) as column_ui_list
	from adf.meta_hsat_mapping h
	where h.active_ind = 1 
	group by h.table_name, h.hub_table_name, h.schema_name, h.stg_schema_name, h.stg_table_name
	) /* todo 
,collnk 
as (
	SELECT 
		h.table_name,
		string_agg(h.hub_table_name + '_hk VARCHAR(32) NOT NULL', ',' + char(13)) as column_list,
		h.schema_name, 
		string_agg(u.column_name + ' ' + u.data_type +
				   case when character_maximum_length is null then '' else '(' + character_maximum_length + ')' end +
				   case when numeric_precision is null then '' else '(' + numeric_precision+','+numeric_scale + ')' end +
				   ' NOT NULL', ',')
		  within group (order by h.column_position) as column_base_list,
		string_agg(h.hub_table_name + '_hk', ',') 
		  within group (order by h.column_position) as column_ui_list

	from adf.meta_lnk_mapping h
	left join adf.meta_hub_mapping u on u.table_name = h.hub_table_name
	where h.active_ind = 1 
	group by h.table_name, h.schema_name 
	) */
INSERT INTO @sql_table
	SELECT --hub
		replace(
			replace(
				replace(
				replace(
					replace(
						replace(
							replace(g.core, '<column_ui_list>', h.column_name)
						, '<column_statement_list>', h.column_name+' '+h.data_type+' NOT NULL')
					, '<table_name>', h.table_name) 
				, '<schema_name>', h.schema_name)
				, '<column_name>', h.column_name)
			,'<stg_schema_name>', h.stg_schema_name)
		,'<stg_table_name>', h.stg_table_name
		) + ';' + char(13)
	from [mtd].[master_generator] g
	cross join adf.meta_hub_mapping h
	where g.generator_type = 'sp_insert_hub_table'
	  and h.active_ind = 1 
UNION ALL
	SELECT -- hsat
		replace(
			replace(
				replace(
					replace(
						replace(
							replace(
								replace(g.core, '<column_ui_list>', h.column_ui_list)
							, '<column_statement_list>', h.column_list) 
						, '<hub_table_name>', h.hub_table_name) 
					, '<table_name>', h.table_name) 
				, '<schema_name>', h.schema_name) 
			,'<stg_schema_name>', h.stg_schema_name)
		,'<stg_table_name>', h.stg_table_name
		) + ';' + char(13)
	from [mtd].[master_generator] g
	cross join colist h
	where g.generator_type = 'sp_insert_hsat_table'
	/* todo 
UNION ALL
	SELECT 
	replace(
		replace(
			replace(
				replace(g.core, '<column_ui_list>', h.column_ui_list)
			, '<column_statement_list>', h.column_list)
		, '<table_name>', h.table_name) 
	, '<schema_name>', h.schema_name 
	)
	FROM [mtd].[master_generator] g
	cross join collnk h
	where generator_type = 'create_lnk_table'
  	*/
	;

	SET @cnt = (SELECT count(*) from @sql_table);

	WHILE @cnt > 0 
	BEGIN 
		SELECT @sql = command from @sql_table where id = @cnt;
		--PRINT @sql
		IF @execute_sql = 1 
			EXEC sp_executesql @sql;
			--EXEC sp_executesql N'GO';
		SET @cnt -= 1;
	END;
	
	SELECT * from @sql_table;

END;