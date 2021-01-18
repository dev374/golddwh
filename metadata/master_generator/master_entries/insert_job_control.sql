/****** Script for SelectTopNRows command from SSMS  *****
SELECT TOP (1000) [id]
      ,[generator_type]
      ,[core]
      ,[insert_dts]
  FROM [mtd].[master_generator]
  */

DECLARE @generator_type varchar(100) = 'insert_job_control';

DELETE FROM mtd.master_generator
WHERE generator_type = @generator_type;

INSERT INTO mtd.master_generator (
	[generator_type]
    ,[core]
    ,[insert_dts])
VALUES (@generator_type,
'DELETE FROM mtd.job_control
WHERE schema_name = ''<schema_name>'' AND table_name = ''<table_name>'';
INSERT INTO mtd.job_control (system_type,job_type,schema_name,table_name,sql_1,sql_2)
VALUES (
	''db'',''<job_type>'',''<schema_name>'',''<table_name>'',
	''
	select getdate();
	'',
	null
);
', getdate());
