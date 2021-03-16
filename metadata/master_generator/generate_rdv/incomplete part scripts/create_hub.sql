SELECT -- hub
	replace(
		replace(
			replace(
				replace(g.core, '<column_ui_list>', h.column_name)
			, '<column_statement_list>', h.stg_column_name+' '+h.data_type+' NOT NULL')
		, '<table_name>', h.table_name) 
	, '<schema_name>', h.schema_name 
	)
FROM [mtd].[master_generator] g
cross join adf.meta_hub_mapping h
where generator_type = 'create_hub_table'
  and h.active_ind = 1 
