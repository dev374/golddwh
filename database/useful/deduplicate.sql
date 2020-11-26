with cte as (
	select 
	*,
	row_number() over (
		partition by table_name, column_name
		order by table_name, column_name) row_num
	from adf.meta_ref_mapping
)
delete from cte
where row_num > 1