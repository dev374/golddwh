with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from[adf].[dat_kunden_hist]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from [adf].[dat_nach_k]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from [adf].[dat_zaehler_historie]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from  [adf].[meta_hsat_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from  [adf].[meta_hub_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from  [adf].[meta_lnk_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from   [adf].[meta_lsat_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from   [adf].[meta_pit_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from   [adf].[meta_ref_mapping]
)
delete from cte
where row_num > 1
GO

with cte as (
	select 
	*,
	row_number() over (
		partition by hash_diff
		order by hash_diff) row_num
	from   [adf].[meta_lsat_status_mapping]
)
delete from cte
where row_num > 1

