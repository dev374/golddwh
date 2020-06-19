
DROP TABLE if exists wht_loads_log

/****** Object:  Table [dbo].[wht_loads_log]    Script Date: 21.02.2020 12:26:40 *****

*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_loads_log](
	[id] [int] IDENTITY(100,1) NOT NULL,
	[run_id] [varchar](max) NOT NULL,
	[pipeline_name] [varchar](100) NOT NULL,
	[file_name] [varchar](100) NULL,
	[table_name] [varchar](100) NULL,
	[table_size_MB] numeric(18,2) NULL,
	[row_count][int] NULL,
	[load_start_dttm] datetime NULL,
	[load_end_dttm] datetime NULL,
	[duration][int] NULL,
	[load_desc][varchar](max) NULL,
	[error_msg][varchar](max) NULL,
	[error_number][varchar](100) NULL

) ON [PRIMARY]
GO

