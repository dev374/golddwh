          /****** Object:  StoredProcedure [dbo].[whs_log_load]    Script Date: 10.03.2020 11:02:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE if exists [dbo].[whs_log_load]
GO

/* =============================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-02-20
   Verison:     2020-03-05	v.1.0		Initial version
				2020-03-10	v.1.1		Improvements
				2020-03-23	v.1.2		Added table_name, size and row count

   ========================================== */
CREATE PROCEDURE [dbo].[whs_log_load]
				( @run_id NVARCHAR(max), -- pipeline run id
				  @pipeline_name NVARCHAR(100) = NULL, -- pipeline name
				  @file_name NVARCHAR(100) = NULL, -- file name
				  @start_dttm NVARCHAR(100) = NULL, -- load start
				  @action NVARCHAR(100) = NULL -- start or finish
				)
AS
BEGIN TRY
	SET NOCOUNT ON;
    DECLARE
		 @Error_NUMBER          INT             = NULL
        ,@Error_MSG             NVARCHAR(4000)  = NULL
        ,@Error_LINE            INT             = NULL
        ,@Error_PROC            NVARCHAR(128)   = NULL
        ,@Error_SEV             INT             = NULL
        ,@Error_STATE           INT             = NULL
        ,@Error_COUNT           INT             = 0
	DECLARE
		 @na					VARCHAR(10)		= 'Unknown',
		 @result_message		VARCHAR(max)	= NULL,
		 @start_dttm2			DATETIME		= NULL,
		 @end_dttm				DATETIME		= NULL,
		 @duration				INT				= NULL

	-- =============================================
	-- Make start date
	IF (@start_dttm is NULL)
		SELECT @start_dttm2 = GETDATE()
	ELSE
		SELECT @start_dttm2 = TRY_CAST(LEFT(@start_dttm, 22) as datetime);
	
	-- Calculate end date
	IF (@end_dttm is NULL)   
	BEGIN
		SET @end_dttm = GETDATE();
		SELECT @duration = CONVERT(int, ISNULL(DATEDIFF(second, @start_dttm2, @end_dttm), -1)),
			   @result_message = 'Load of ' + ISNULL(@file_name, @na) + ' ' + @action;
	END

	-- Action when START
	IF (@action like '%START%' OR @action = '1')
		INSERT INTO [dbo].[wht_loads_log]
				   ([run_id]
				   ,[pipeline_name]
				   ,[file_name]
				   ,[table_name]
				   ,[table_size_MB]
				   ,[row_count]
				   ,[load_start_dttm]
				   ,[load_end_dttm]
				   ,[duration]
				   ,[load_desc]
				   ,[error_msg]
				   ,[error_number]
				   )
			 SELECT
				   @run_id
				   ,ISNULL(@pipeline_name, @na)
				   ,ISNULL(@file_name, @na)
				   ,@na
				   ,null
				   ,null
				   ,@start_dttm2
				   ,null
				   ,@duration
				   ,@result_message
				   ,null
				   ,null
	
	-- Action when COMPLETED
	ELSE

		DECLARE @table_name VARCHAR(100) = NULL
		DECLARE @table_schema_name VARCHAR(100) = NULL
		DECLARE @cnt_sql VARCHAR(100) = NULL
		DECLARE @cnt_rows TABLE (cnt INT NULL)
		DECLARE @table_size NUMERIC(18,2) = NULL

		-- Calculate table name
		select @table_schema_name = s.name + '.' + t.name,
			   @table_name = t.name
		from sys.tables t 
		join sys.schemas s on t.schema_id = s.schema_id
		where t.name like '%' + @file_name + '%'

		-- Calculate rows
		SELECT @cnt_sql = 'SELECT count(1) FROM ' + @table_schema_name

		INSERT INTO @cnt_rows(cnt)
		EXEC sp_sqlexec @cnt_sql      -- SELECT cnt FROM @cnt_rows

		-- Calculate table size
			SELECT
				@table_size = CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(18, 2)) 
				--CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB
			FROM
				sys.tables t
			INNER JOIN
				sys.indexes i ON t.OBJECT_ID = i.object_id
			INNER JOIN
				sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
			INNER JOIN
				sys.allocation_units a ON p.partition_id = a.container_id
			LEFT OUTER JOIN
				sys.schemas s ON t.schema_id = s.schema_id
			WHERE
				t.NAME LIKE @table_name
				AND t.is_ms_shipped = 0
				AND i.OBJECT_ID > 255
			GROUP BY
				t.Name, s.Name, p.Rows

		/*
		-------- SELECT variables to use -------- 
		SELECT @table_name AS TableName, 
			   cnt AS TotalRows, 
			   @table_size AS TotalSpaceMB
		FROM @cnt_rows
	    */

		UPDATE t
		SET		
			[table_name] = @table_schema_name,
			[table_size_MB] = @table_size,
			[row_count] = (SELECT cnt FROM  @cnt_rows),
			[load_end_dttm] = @end_dttm,
			[duration] = CONVERT(int, ISNULL(DATEDIFF(second, [load_start_dttm], @end_dttm), -1)),
			[load_desc] = @result_message
		FROM [dbo].[wht_loads_log] t
		WHERE [run_id] = @run_id

	-- =============================================
END TRY
BEGIN CATCH
	-- End step: Handle ERROR

	SELECT @result_message = 'Load logging for ' + ISNULL(@file_name, @na) + ': ' + @run_id + ' FAILED ';

	SELECT
	     @Error_NUMBER      = ERROR_NUMBER()
        ,@Error_PROC        = ERROR_PROCEDURE()
        ,@Error_SEV         = ERROR_SEVERITY()
        ,@Error_STATE       = ERROR_STATE()
        ,@Error_LINE        = ERROR_LINE()
        ,@Error_MSG         = ERROR_MESSAGE()
        ,@Error_COUNT       = @Error_COUNT + 1
        ,@end_dttm          = GETDATE();

	UPDATE t
	   SET  load_desc		= @result_message,
		    load_end_dttm	= @end_dttm,
		    duration		= @duration,
			[error_msg]		= @Error_MSG,
			[error_number]	= @Error_NUMBER
	  FROM [dbo].[wht_loads_log] t
	 WHERE t.run_id = @run_id


END CATCH
GO