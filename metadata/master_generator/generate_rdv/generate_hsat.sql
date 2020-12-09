with colist 
as (
select 
	h.table_name,
	h.hub_table_name,
	h.schema_name, 
	string_agg(h.column_name+' '+h.data_type+
			   case when character_maximum_length is null then '' else '('+character_maximum_length+')' end +
			   case when numeric_precision is null then '' else '('+numeric_precision+','+numeric_scale+')' end +
			   case is_nullable_ind when 0 then ' NOT NULL' else ' NULL' end , ',')
	  within group (order by h.column_position) as column_list,
	string_agg(h.column_name,',')
	  within group (order by h.column_position) as column_ui_list
from adf.meta_hsat_mapping h
where h.active_ind = 1 
group by h.table_name, h.hub_table_name, h.schema_name 
)
SELECT -- hsat
	replace(
		replace(
		replace(
			replace(
				replace(g.core, '<column_ui_list>', h.column_ui_list)
			, '<column_statement_list>', h.column_list) 
		, '<hub_table_name>', h.hub_table_name) 
		, '<table_name>', h.table_name) 
	, '<schema_name>', h.schema_name 
	)
from [mtd].[master_generator] g
cross join colist h
where g.generator_type = 'create_hsat_table'

;
