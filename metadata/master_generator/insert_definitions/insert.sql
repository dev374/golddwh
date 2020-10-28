select 
	replace(
		replace(
			replace(g.core,
				--replace( '<column_ui_list>', h.column_name), 
			'<job_type>', 'insert_'+h.table_name)
		, '<table_name>', h.table_name) 
	, '<schema_name>', h.schema_name 
	)
from [mtd].[master_generator] g
cross join adf.data_model_mapping h
where generator_type = 'insert_job_control'
order by h.ordinal_position 
