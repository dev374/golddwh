/*

	DROP TABLE if exists [dbo].[wht_error_log]
	GO

*/
 /* =========================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-12-20
   Verison:     2020-12-20	v.1.0		Initial version
	
   ========================================== */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_error_log](
	[id] UNIQUEIDENTIFIER NOT NULL, -- IDENTITY(1000,1) NOT NULL,
	[job_id] INT NULL,
	[run_id] nvarchar(8) NULL,
	[step_id] [UNIQUEIDENTIFIER] NOT NULL,
	[comment] [varchar](max) NULL,
	[error_dttm] [datetime] NOT NULL,
	[error_number] INT NULL,
    [error_msg] NVARCHAR(4000) NULL,  
    [error_line] INT NULL,             
    [error_proc] NVARCHAR(128) NULL,
    [error_sev] INT NULL,
    [error_state] INT NULL,
    [error_count] INT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[wht_error_log] ADD  DEFAULT ((GETDATE())) FOR [error_dttm]
GO


