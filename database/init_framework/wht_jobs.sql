
DROP TABLE if exists wht_jobs

/****** Object:  Table [dbo].[wht_jobs]    Script Date: 21.02.2020 12:26:40 *****

*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_jobs](
	[id] [int] IDENTITY(100,1) NOT NULL,
	[job_name] [varchar](100) NOT NULL,
	[job_description] [varchar](100) NULL,
	[active] [bit] NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[wht_jobs] ADD  DEFAULT ((0)) FOR [active]
GO

/****** Initial insert    Script Date: 21.02.2020 12:26:40 ******/
SET IDENTITY_INSERT dbo.wht_jobs ON
INSERT INTO dbo.wht_jobs (id, job_name, job_description,active) VALUES (-1, 'Invalid job name', ' This marks missing or invalid job',1)
SET IDENTITY_INSERT dbo.wht_jobs OFF

INSERT INTO dbo.wht_jobs (job_name, job_description,active) VALUES ('TEST_JOB', ' Testing etl job nr 1',1)


