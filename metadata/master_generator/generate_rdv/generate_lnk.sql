WITH collnk 
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
	)
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
	order by h.table_name 