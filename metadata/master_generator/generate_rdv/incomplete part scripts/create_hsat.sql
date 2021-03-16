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
)
select distinct -- hsat
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
from [mtd].[master_generator] g
cross join colhsat h -- select * from 
inner join adf.meta_hsat_mapping s
   on h.table_name = s.table_name
  and s.column_position = 1
inner join adf.meta_hub_mapping u
   on u.table_name = s.hub_table_name
where g.generator_type = 'create_hsat_table'
  and s.active_ind = 1 

