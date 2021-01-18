DELETE FROM mtd.master_generator
WHERE generator_type = 'sp_drop_hsat_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'sp_drop_hsat_table',
'
DROP PROCEDURE if exists [dbo].[sp_insert_<table_name>];
')
GO

DELETE FROM mtd.master_generator
WHERE generator_type = 'sp_insert_hsat_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'sp_insert_hsat_table',
'
/* =============================================
   Author:		Generic by Mikołaj Paszkowski
   Create date: 2021-01-15
   Version:     2021-01-15	v.1.0	Initial version

   ========================================== */
CREATE PROCEDURE [dbo].[sp_insert_<table_name>]
				( @run_id NVARCHAR(8) = ''12345678'' )
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
        ,@Error_SPECIFICS       SQL_VARIANT     = NULL
	DECLARE
		 @step_name				VARCHAR(100),
		 @result_message		VARCHAR(max)	= NULL,
		 @start_dttm			DATETIME		= GETDATE(),
		 @end_dttm				DATETIME		= NULL,
		 @duration				INT				= NULL,
		 @row_cnt				INT				= 0,
		 @step_uid				UNIQUEIDENTIFIER = NEWID();
	/* -- ============================================= */		 
	SELECT @run_id = COALESCE(@run_id, convert(varchar,@@SPID))
	SELECT @step_name = OBJECT_NAME(@@PROCID)	
	/* -- =============================================
	-- Start step: Initialize job step */
	EXEC @step_uid = dbo.whs_jobstep_init @step_name, @run_id, @step_uid = @step_uid
	/* -- ============================================= */
	PRINT N''sp step uid: '' + convert(nvarchar(max), @step_uid) + '' sp_rdv_insert_<table_name>''

	INSERT INTO <schema_name>.<table_name> 
		(<hub_table_name>_hk, load_cycle_seq, record_source, insert_dts, changed_by, 
		<column_ui_list>)
	SELECT 
		<hub_table_name>_hk,
		1,
		''Step name '' + @step_name + '''',
		@start_dttm,
		@run_id,
		g.<column_ui_list> 
	FROM <stg_schema_name>.<stg_table_name> g
	INNER JOIN adf.meta_hsat_mapping t
	  ON t.table_name = ''<table_name>''
	  AND t.active_ind = 1
	LEFT JOIN <schema_name>.<table_name> u 
	  ON g.<hub_table_name>_hk = u.<hub_table_name>_hk
	WHERE u.<hub_table_name>_hk IS NULL

	SET @row_cnt = @@ROWCOUNT
	/* -- ============================================= 
	-- End step: Handle output */
	PRINT ''sp finish. count: @row_cnt''
	EXEC dbo.whs_jobstep_finish @step_name, @run_id, @start_dttm, @row_cnt, @step_uid
	RETURN 0;
	/* -- ============================================= */

END TRY
BEGIN CATCH
	/* End step: Update steps  Handle ERROR  */
	PRINT N''sp catch''

	SELECT @end_dttm = GETDATE()
		  ,@duration = DATEDIFF(second, @start_dttm, @end_dttm)
		  ,@result_message = ''Step: '' + @step_name + '' FAILED '';
    
	SELECT
	     @Error_NUMBER      = ERROR_NUMBER()
        ,@Error_PROC        = ERROR_PROCEDURE()
        ,@Error_SEV         = ERROR_SEVERITY()
        ,@Error_STATE       = ERROR_STATE()
        ,@Error_LINE        = ERROR_LINE()
        ,@Error_MSG         = ERROR_MESSAGE()
        ,@Error_COUNT       = @Error_COUNT + 1
        ,@row_cnt           = 0
        ,@end_dttm          = GETDATE()

	UPDATE t
	   SET  row_cnt			= @row_cnt,
		    comment			= @result_message,
		    end_dttm		= @end_dttm,
		    duration		= @duration,
		    result			= 1,
			[error_number]	= @Error_NUMBER,
			[error_msg]		= @Error_MSG,
			[error_line]	= @Error_LINE,
			[error_proc]	= @Error_PROC,
			[error_sev]		= @Error_SEV,
			[error_state]	= @Error_STATE,
			[error_count]	= @Error_COUNT 
	  FROM dbo.wht_steps_log t
	 WHERE t.id = @step_uid 
	
	PRINT convert(varchar(100), @Error_MSG)

END CATCH;
')