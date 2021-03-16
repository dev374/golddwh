with collnk
as (
	select 
		i.table_name,
		i.schema_name, 
		string_agg(h.column_name+' '+h.data_type+
				   case when h.character_maximum_length is null then '' else '('+h.character_maximum_length+')' end +
				   case when h.numeric_precision is null then '' else '('+h.numeric_precision+','+h.numeric_scale+')' end +
				   ' NOT NULL', ',')
		  within group (order by i.column_position) as column_list,
		string_agg(i.column_name,',')
		  within group (order by i.column_position) as column_ui_list
	from adf.meta_lnk_mapping i
	inner join adf.meta_hub_mapping h
	   on i.hub_table_name = h.table_name
	  and i.column_name = h.column_name
	where i.active_ind = 1 
	group by i.table_name, i.schema_name
)
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