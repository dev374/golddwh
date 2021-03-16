SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE if exists [mtd].[master_create_all_rdv]
GO

/* =============================================
	Synopsis:	RDV complete table generator from "create_<xxx>" scripts

	Author:		Mikołaj Paszkowski
	Created: 	2020-12-08
	Verison:    2021-02-22	v.1.1		Mod create tables 
				2020-12-08	v.1.0		Initial version 
	
	NEED UPDATES for lsat, pit, ... etc!
										
   ========================================== */

CREATE PROCEDURE [mtd].[master_create_all_rdv] (@execute_sql INT = 0)
AS
BEGIN

	DECLARE @sql_table TABLE (
		id INT IDENTITY,
		command VARCHAR(max));
	DECLARE @sql NVARCHAR(max);
	DECLARE @cnt INT = 0;

with colhsat
as (
	select 
		h.table_name,
		h.schema_name, 
		string_agg(h.column_name+' '+h.data_type+
				   case when h.character_maximum_length is null then '' else '('+h.character_maximum_length+')' end +
				   case when h.numeric_precision is null then '' else '('+h.numeric_precision+','+h.numeric_scale+')' end +
				   case is_nullable_ind when 0 then ' NOT NULL' else ' NULL' end , ',')
		  within group (order by h.column_position) as column_list,
		string_agg(h.column_name,',')
		  within group (order by h.column_position) as column_ui_list
	from adf.meta_hsat_mapping h
	where h.active_ind = 1 
	group by h.table_name, h.schema_name
),
collnk
as (
	select 
		i.table_name,
		i.schema_name, 
		string_agg(h.table_name+'_hk '+h.data_type+
				   case when h.character_maximum_length is null then '' else '('+h.character_maximum_length+')' end +
				   case when h.numeric_precision is null then '' else '('+h.numeric_precision+','+h.numeric_scale+')' end +
				   ' NOT NULL', ',')
		  within group (order by i.column_position) as column_list,
		string_agg(h.table_name+'_hk ',',')
		  within group (order by i.column_position) as column_ui_list
	from adf.meta_lnk_mapping i
	inner join adf.meta_hub_mapping h
	   on i.hub_table_name = h.table_name
	  and i.column_name = h.column_name
	where i.active_ind = 1 
	group by i.table_name, i.schema_name
)
	INSERT INTO @sql_table
		SELECT -- hub
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_name)
						, '<column_statement_list>', h.column_name+' '+h.data_type+
					   case when h.character_maximum_length is null then '' else '('+h.character_maximum_length+')' end +
					   case when h.numeric_precision is null then '' else '('+h.numeric_precision+','+h.numeric_scale+')' end +
					   ' NOT NULL')
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			)
		FROM [mtd].[master_generator] g
		cross join adf.meta_hub_mapping h
		where generator_type = 'create_hub_table'
		  and h.active_ind = 1 
	UNION ALL
		SELECT DISTINCT -- hsat
			replace(
				replace(
					replace(
						replace(
							replace(g.core, '<column_ui_list>', h.column_ui_list)
						, '<column_statement_list>', h.column_list) 
					, '<table_name>', h.table_name) 
				, '<schema_name>', h.schema_name)
			, '<hub_table_name>', u.table_name
			) 
		FROM [mtd].[master_generator] g
		cross join colhsat h -- select * from 
		inner join adf.meta_hsat_mapping s
		   on h.table_name = s.table_name
		  and s.column_position = 1
		inner join adf.meta_hub_mapping u
		   on u.table_name = s.hub_table_name
		where g.generator_type = 'create_hsat_table'
		  and s.active_ind = 1 
	UNION ALL
		SELECT -- lnk
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_ui_list)
					, '<column_statement_list>', h.column_list)
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			) + char(10) + char(13)
		FROM [mtd].[master_generator] g
		cross join collnk h
		inner join adf.meta_lnk_mapping s
		   on h.table_name = s.table_name
		  and s.column_position = 1
		where generator_type = 'create_lnk_table'
		  and active_ind = 1
		/* todo 
	UNION ALL
		SELECT 
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_name)
					, '<column_statement_list>', h.column_name+' '+h.data_type+' NOT NULL')
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			)
		from [mtd].[master_generator] g
		cross join adf.meta_lsat_mapping h
		where g.generator_type = 'create_lsat_table'
		  and h.active_ind = 1 
	UNION ALL
		SELECT 
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_name)
					, '<column_statement_list>', h.column_name+' '+h.data_type+' NOT NULL')
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			)
		from [mtd].[master_generator] g
		cross join adf.meta_lsat_mapping h
		where g.generator_type = 'create_lsat_table'
		  and h.active_ind = 1 
	UNION ALL
		SELECT 
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_name)
					, '<column_statement_list>', h.column_name+' '+h.data_type+' NOT NULL')
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			)
		from [mtd].[master_generator] g
		cross join adf.meta_pit_mapping h
		where g.generator_type = 'create_pit_table'
		  and h.active_ind = 1 
	UNION ALL
		SELECT 
			replace(
				replace(
					replace(
						replace(g.core, '<column_ui_list>', h.column_name)
					, '<column_statement_list>', h.column_name+' '+h.data_type+' NOT NULL')
				, '<table_name>', h.table_name) 
			, '<schema_name>', h.schema_name 
			)
		from [mtd].[master_generator] g
		cross join adf.meta_ref_mapping h
		where g.generator_type = 'create_ref_table'
		  and h.active_ind = 1 
	*/	  
	;

	SET @cnt = (SELECT count(*) from @sql_table);

	WHILE @cnt > 0 
	BEGIN 
		SELECT @sql = command from @sql_table where id = @cnt;
		PRINT @sql
		IF @execute_sql = 1 
			EXEC sp_executesql @sql;
		SET @cnt -= 1;
	END;

END;