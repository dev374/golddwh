-- ===========================================================
-- Create generator master table
-- ===========================================================
IF EXISTS(
  SELECT *
    FROM sys.tables
   WHERE name = N'job_control'
     --AND parent_class_desc = N'DATABASE'
)
	DROP TABLE if exists mtd.job_control
GO

CREATE TABLE mtd.job_control (
	id int IDENTITY (1,1) NOT NULL,
	system_type VARCHAR(100) NOT NULL,
	job_type VARCHAR(100) NOT NULL,
	schema_name VARCHAR(100) NOT NULL,
	job_name VARCHAR(100) NOT NULL,
	sql_1 VARCHAR(MAX) NOT NULL,
	sql_2 VARCHAR(MAX) NULL,
	sql_3 VARCHAR(MAX) NULL,
	insert_dts DATETIME DEFAULT GETDATE(),
	CONSTRAINT pk_job_control PRIMARY KEY (generator_type)
)
GO

/*
ALTER TABLE mtd.job_control ADD DEFAULT (GETDATE()) FOR insert_dts
GO

DROP TABLE if exists mtd.job_control
GO
*/



/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) *
  FROM [mtd].[job_control]