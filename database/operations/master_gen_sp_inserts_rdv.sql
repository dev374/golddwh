/****** Object:  StoredProcedure [mtd].[master_gen_sp_inserts_rdv]    Script Date: 16.03.2021 12:15:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
	DECLARE @datecols_table TABLE (
		id INT IDENTITY,
		tablename VARCHAR(100),
		datecol VARCHAR(100),
		target_datatype VARCHAR(100),
		subscol as 'CAST(SUBSTRING(stg.'+datecol+', CHARINDEX('','',stg.'+datecol+',0)+1,50) as '+target_datatype+')');
	DECLARE @sql NVARCHAR(max);
	DECLARE @cnt INT = 0;

-- Date columns search
	INSERT INTO @datecols_table
	  (tablename,datecol,target_datatype)
	SELECT  s.table_name,
			s.stg_column_name,
			s.data_type
	FROM adf.meta_hsat_mapping s 
	WHERE s.data_type in ('datetime','date');		

-- Generate SQL for each procedure
WITH colhsat 
as (
	SELECT 
		h.table_name,
		h.hub_table_name,
		h.schema_name, 
		h.stg_schema_name, 
		h.stg_table_name, 
		string_agg(coalesce(d.subscol,'stg.'+h.stg_column_name),',')
		  within group (order by h.column_position) as column_stg_list,
		string_agg(h.column_name,',')
		  within group (order by h.column_position) as column_ui_list
	FROM adf.meta_hsat_mapping h
	LEFT JOIN @datecols_table d
	  on d.tablename = h.table_name
	 and d.datecol = h.column_name
	WHERE h.active_ind = 1 
	group by h.table_name, h.hub_table_name, h.schema_name, h.stg_schema_name, h.stg_table_name
	) ,
bkhsat 
as ( 
	SELECT t.table_name, 
		   t.column_name as hub_column_name,
		   t.stg_table_name, 
		   stg_column_name as bk_column_name -- select * -- bk specified in hub
	FROM adf.meta_hsat_mapping t	  
	WHERE t.business_key = 1
	--SELECT distinct 
	--	   s.table_name, 
	--	   s.stg_table_name as stg_table_name,
	--	   t.column_name as hub_column_name,
	--	   t.stg_column_name as bk_column_name -- select * -- bk specified in hub
	--FROM adf.meta_hub_mapping t
	--join adf.meta_hsat_mapping s
	--  on t.table_name = s.hub_table_name
	--where t.business_key = 1
),
collnk 
as (
	SELECT 
		h.table_name,
		h.schema_name, 
		string_agg(case h.column_position when 1 then ' hk.' when 2 then ' hm.' else ' hn.' end+
			h.hub_table_name + '_hk',',') as column_sch_list,
		string_agg(h.hub_table_name + '_hk', ',') 
		  within group (order by h.column_position) as column_ui_list, 
		string_agg(case h.column_position when 1 then ' hk.' when 2 then ' hm.' else ' hn.' end+
			h.hub_table_name + '_hk', '+'';''+') 
		  within group (order by h.column_position) as column_ui_semico,
		string_agg(
			h.stg_schema_name +'.'+ h.stg_table_name+ 
			case h.column_position when 1 then ' k' when 2 then ' m' else ' n' end,
			char(13)+char(10)+'INNER JOIN ') 
		  within group (order by h.column_position) as from_stg_tables,
		'ON ' + string_agg(
			case h.column_position when 1 then 'k.' when 2 then 'm.' else 'n.' end+
			h.stg_column_name, '= ') 
		  within group (order by h.column_position) as on_stg_tables,
		string_agg(
			'INNER JOIN '+h.schema_name+'.'+h.hub_table_name+ 
			case h.column_position when 1 then ' hk' when 2 then ' hm' else ' hn' end+
			char(13)+char(10)+'ON '+
			case h.column_position when 1 then ' hk.' when 2 then ' hm.' else ' hn.' end+
			t.column_name +' = '+
			case h.column_position when 1 then 'k.' when 2 then 'm.' else 'n.' end+
			t.stg_column_name,
			char(13)+char(10)+'')
		  within group (order by h.column_position) as join_hub_tables
	FROM adf.meta_lnk_mapping h
	JOIN adf.meta_hub_mapping t 
	  ON t.table_name = h.hub_table_name
	WHERE h.active_ind = 1 
	GROUP BY h.table_name, h.schema_name
)
INSERT INTO @sql_table
	SELECT --hub
		replace(
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
				, '<stg_column_name>', h.stg_column_name)
			,'<stg_schema_name>', h.stg_schema_name)
		,'<stg_table_name>', h.stg_table_name
		) + ';' + char(13)
	FROM [mtd].[master_generator] g
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
								replace(
									replace(
										replace(g.core, 
											'<column_stg_list>', h.column_stg_list) -- stg is the alias for the stg table!
									, '<column_ui_list>', h.column_ui_list) 
								, '<hub_table_name>', h.hub_table_name) 
							, '<table_name>', h.table_name) 
						, '<schema_name>', h.schema_name) 
					,'<stg_schema_name>', h.stg_schema_name)
				,'<stg_table_name>', h.stg_table_name)
			,'<bk_column_name>', b.bk_column_name)
		,'<hub_column_name>', b.hub_column_name
		) + ';' + char(13)
	FROM [mtd].[master_generator] g
	cross join colhsat h
	inner join bkhsat b
	   on b.table_name = h.table_name
	  and b.stg_table_name = h.stg_table_name 
	where g.generator_type = 'sp_insert_hsat_table'
UNION ALL
	SELECT -- lnk
		replace(
			replace(
				replace(
					replace(
						replace(
							replace(
								replace(
									replace(g.core, '<column_ui_list>', h.column_ui_list)
								,'<column_sch_list>', h.column_sch_list)
							, '<column_ui_semico>', h.column_ui_semico)
						, '<table_name>', h.table_name) 
					, '<schema_name>', h.schema_name)
				,'<from_stg_tables>', h.from_stg_tables) 
			,'<on_stg_tables>', h.on_stg_tables) 
		,'<join_hub_tables>', h.join_hub_tables) 
		+ ';' -- select * 
	FROM [mtd].[master_generator] g
	cross join collnk h
	where generator_type = 'sp_insert_lnk_table'
	;

	SET @cnt = (SELECT count(*) FROM @sql_table);

	WHILE @cnt > 0 
	BEGIN 
		SELECT @sql = command FROM @sql_table where id = @cnt;
		PRINT @sql
		IF @execute_sql = 1 
			EXEC dbo.sp_executesql @sql;
		SET @cnt -= 1;
	END;
	
	SELECT * FROM @sql_table;

END;
GO

