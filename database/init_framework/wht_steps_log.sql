

/****** Object:  Table [dbo].[wht_steps_log]    Script Date: 21.02.2020 12:18:24 *****
DROP TABLE if exists [dbo].[wht_steps_log]
GO
*/

/****** Object:  Table [dbo].[wht_steps_log]    Script Date: 21.02.2020 12:18:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_steps_log](
	[id] uniqueidentifier NOT NULL, -- IDENTITY(1000,1) NOT NULL,
	[job_id] INT NULL,
	[job_name] varchar(100) NULL,
	[step_id] [int] NOT NULL,
	[step_name] [varchar](100) NOT NULL,
	[step_seq_nr] [int] NOT NULL,
	[run_id] nvarchar(8) NOT NULL,
	[row_cnt] [int] NULL,
	[comment] [varchar](max) NULL,
	[start_dttm] [datetime] NOT NULL,
	[end_dttm] [datetime] NULL,
	[duration] [int] NULL,
	[result] [bit] NOT NULL,
	[error_number] INT NULL,
    [error_msg] NVARCHAR(4000) NULL,  
    [error_line] INT NULL,             
    [error_proc] NVARCHAR(128) NULL,
    [error_sev] INT NULL,
    [error_state] INT NULL,
    [error_count] INT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[wht_steps_log] ADD  DEFAULT ((NEWID())) FOR [id]
ALTER TABLE [dbo].[wht_steps_log] ADD  DEFAULT ((0)) FOR [result]
GO


