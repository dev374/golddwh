
select 
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
where generator_type = 'create_lsat_table'
order by h.column_position 