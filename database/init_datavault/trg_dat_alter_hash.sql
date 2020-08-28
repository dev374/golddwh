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

	DECLARE @i TINYINT,
			@tabcnt TINYINT = 1,
			@sql NVARCHAR(max)
	DECLARE @coltohash TABLE (
		object_id BIGINT, 
		tabname VARCHAR(100),
		schemaname VARCHAR(100),
		colname VARCHAR (100), 
		colorderid INT
	)
	DECLARE @tabtohash TABLE (
		id TINYINT,
		altersql VARCHAR(max),
		schemaname VARCHAR(100),
		tabname VARCHAR(100),
		concatcols NVARCHAR (max) 
	)

	INSERT INTO @coltohash
	SELECT c.object_id, t.name as tabname, s.name as schemaname, c.name as colname, column_id as colorderid 
	FROM sys.columns c
	JOIN sys.tables t ON t.object_id = c.object_id
	JOIN sys.schemas s ON t.schema_id = s.schema_id
	WHERE c.object_id in (
		SELECT t.object_id FROM sys.tables t
	)
	AND lower(s.name) like 'adf'
	AND lower(t.name) not like 'xx%'
	AND lower(t.name) not like 'meta_%'
	ORDER BY column_id
	

	
	SELECT @sql = N'SELECT CONCAT(' + 
					STRING_AGG(h.colname, ',') WITHIN GROUP (ORDER BY colorderid) + 
					') FROM ' + h.schemaname + '.' + h.tabname
	FROM @coltohash h
	GROUP BY h.schemaname, h.tabname
	--SELECT @sql
	
	INSERT INTO @tabtohash
	SELECT
		ROW_NUMBER() over (order by tabname) as id,
		'ALTER TABLE ' + schemaname + '.' + tabname + concatcols as altersql,
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
		WHERE lower(h.tabname) not in (SELECT tabname FROM @coltohash c WHERE c.colname like '%hash%')
		GROUP BY h.schemaname, h.tabname
	) x
	
	SELECT @tabcnt = COUNT(DISTINCT tabname) FROM @tabtohash
	WHILE @tabcnt > 0
	BEGIN
		SELECT @sql = altersql FROM @tabtohash WHERE id = @tabcnt
		EXEC sp_executesql @sql
		SET @tabcnt -= 1
	END

END
GO

ENABLE TRIGGER [trg_dat_alter_hash] ON DATABASE
GO

