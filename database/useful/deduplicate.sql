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

 -- SQL Server  FROM [adf].[meta_hub_mapping]
WITH cte AS (
		SELECT 
			table_name,
			column_name,
			ROW_NUMBER() OVER (
				PARTITION BY 
					table_name, 
					column_name
				ORDER BY 
					active_ind desc
			) row_num
		 FROM 
			[adf].[meta_hub_mapping]
	)
DELETE FROM cte
WHERE row_num > 1

-- check after deletion
SELECT * FROM [adf].[meta_hub_mapping]
-- COMMIT

-- ROLLBACK