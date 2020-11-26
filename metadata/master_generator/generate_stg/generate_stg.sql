with colist 
as (
	select 
		h.table_name,
		h.schema_name, 
		string_agg(h.column_name+' '+h.data_type+
				   case when character_length is null or data_type like 'int%' then '' else '('+character_length+')' end +
				   case when numeric_precision is null or data_type like 'int%' then '' else '('+numeric_precision+','+numeric_scale+')' end +
				   case is_nullable_ind when 0 then ' NOT NULL' else ' NULL' end , ',')
		  within group (order by h.ordinal_position) as column_list,
		string_agg(h.column_name,',')
		  within group (order by h.ordinal_position) as column_ui_list,
		(select top 1 column_name from adf.data_model_mapping c 
								  where c.business_key_ind = 1 
								  and h.table_name = h.table_name 
								  and h.schema_name = h.schema_name) as business_key_column_name
	from adf.data_model_mapping h
	where h.active_ind = 1
	group by h.schema_name , h.table_name
)
select 
	replace(
		replace(
			replace(
				replace(
					replace(g.core, '<column_ui_list>', h.column_ui_list)
				, '<column_statement_list>', replace(replace(h.column_list,'(NULL)',''),'(NULL,NULL)','')) 
			, '<column_name_id>', h.business_key_column_name) -- business column - it could be only one!
		, '<table_name>', h.table_name) 
	, '<schema_name>', h.schema_name
	)
from [mtd].[master_generator] g
cross join colist h
where generator_type = 'create_stg_table'     -- column_name_id
