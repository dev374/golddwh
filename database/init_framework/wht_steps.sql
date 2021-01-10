

	DROP TABLE if exists [dbo].[wht_steps]
	GO


 /* =========================================
   Author:		Miko³aj Paszkowski
   Create date: 2020-08-31
   Verison:     2020-08-31	v.1.0		Initial version
	
   ========================================== */

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[wht_steps](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[job_id] SMALLINT NOT NULL,
	[step_name] [varchar](100) NOT NULL,
	[step_seq_nr] SMALLINT NULL,
	[active] [bit] NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[wht_steps] ADD  DEFAULT ((0)) FOR [active]
GO

/****** Initial insert    Script Date: 21.02.2020 12:26:40 *****

ALTER TABLE [dbo].[wht_steps] ALTER COLUMN [job_id] SMALLINT NOT NULL
*/

INSERT INTO dbo.wht_steps (job_id, [step_name], [step_seq_nr], [active]) 
SELECT (SELECT TOP 1 id FROM wht_jobs ORDER BY id asc), name, 100 * ROW_NUMBER() over (order by name asc), 1 
FROM sys.procedures WHERE name like 'sp%'
