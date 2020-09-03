-- ===========================================================
-- Create generator master table
-- ===========================================================
IF EXISTS(
  SELECT *
    FROM sys.tables
   WHERE name = N'master_generator'
     --AND parent_class_desc = N'DATABASE'
)
	DROP TABLE if exists mtd.master_generator
GO

CREATE TABLE mtd.master_generator (
	id int IDENTITY (1,1) NOT NULL,
	generator_type VARCHAR(100) NOT NULL,
	core VARCHAR(MAX) NOT NULL,
	insert_dts DATETIME DEFAULT GETDATE(),
	CONSTRAINT pk_master_generator PRIMARY KEY (generator_type)
)
GO

/*
ALTER TABLE mtd.master_generator ADD DEFAULT (GETDATE()) FOR insert_dts
GO

DROP TABLE if exists mtd.master_generator
GO
*/



/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) *
  FROM [mtd].[master_generator]