-- ===========================================================
-- Create database ddl trigger template for Azure SQL Database
-- ===========================================================
-- Drop the database ddl trigger if it already exists
IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'trg_dat_alter_hash'
     AND parent_class_desc = N'DATABASE'
)
	DROP TRIGGER trg_dat_alter_hash ON DATABASE
GO

CREATE TRIGGER trg_dat_alter_hash ON DATABASE
	FOR CREATE_TABLE
AS
--IF IS_MEMBER ('db_owner') = 0
--BEGIN
--   PRINT 'You must ask your DBA to drop or alter tables!'
--   ROLLBACK TRANSACTION
--END
--ELSE
BEGIN



	DECLARE @i tinyint
	DECLARE @sql NVARCHAR(max)
	DECLARE @coltohash TABLE (
		object_id bigint, 
		tabname varchar(100),
		schemaname varchar(100),
		colname varchar (100), 
		colorderid int
	)
	DECLARE @tabtohash TABLE (
		schemaname varchar(100),
		tabname varchar(100),
		concatcols nvarchar (max) 
	)

	INSERT INTO @coltohash
	SELECT c.object_id, t.name as tabname, s.name as schemaname, c.name as colname, column_id as colorderid 
	FROM sys.columns c
	JOIN sys.tables t ON t.object_id = c.object_id
	JOIN sys.schemas s ON t.schema_id = s.schema_id
	WHERE c.object_id in (
		SELECT t.object_id FROM sys.tables t --WHERE name like 'dat_%'
	)
	AND s.name like 'adf'
	ORDER BY column_id
	
	SELECT @sql = N'SELECT CONCAT(' + 
					STRING_AGG(h.colname, ',') WITHIN GROUP (ORDER BY colorderid) + 
					') FROM ' + h.schemaname + '.' + h.tabname
	FROM @coltohash h
	GROUP BY h.schemaname, h.tabname
	--SELECT @sql
	
	INSERT INTO @tabtohash
	SELECT
		schemaname,
		tabname,
		concatcols
	FROM (
		SELECT  h.schemaname as schemaname,
				h.tabname as tabname,
				N' ADD Hash as ' +
					'(UPPER(CONVERT(char(32), HASHBYTES(''MD5'', '+
						'CONCAT(' + STRING_AGG(h.colname, ',') WITHIN GROUP (ORDER BY colorderid) + ') '+
					'), 2)))' as concatcols
		FROM @coltohash h
		GROUP BY h.schemaname, h.tabname
	) x

	SELECT'ALTER TABLE ' + schemaname + '.' + tabname + concatcols
	FROM @tabtohash
	
	EXEC sp_executesql @sql

END
GO

