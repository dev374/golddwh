
/*

	DROP TABLE if exists [dbo].[wht_jobs_log]
	GO

*/

 /* =========================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-08-31
   Verison:     2020-08-31	v.1.0		Initial version
	
   ========================================== */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_jobs_log](
	[id] INT IDENTITY(1000,1) NOT NULL,
	[job_id] INT NOT NULL,
	[job_name] varchar(100) NOT NULL,
	[run_id] VARCHAR(100) NOT NULL,
	[step_current] [smallint] NOT NULL,
	[step_cnt] [smallint] NOT NULL,
	[comment] [varchar](max) NULL,
	[start_dttm] [datetime] NOT NULL,
	[end_dttm] [datetime] NULL,
	[duration] [int] NULL,
	[result] [bit] NOT NULL,
	[error_number] INT NULL,
    [error_msg] NVARCHAR(4000) NULL,  
    [error_in_step] INT NULL,             
    [error_sql] NVARCHAR(1000) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[wht_jobs_log] ADD  DEFAULT ((0)) FOR [result]
GO


