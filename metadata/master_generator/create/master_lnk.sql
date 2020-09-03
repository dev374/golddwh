DELETE FROM mtd.master_generator
WHERE generator_type = 'create_lnk_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
 'create_lnk_table',
 'CREATE TABLE <schema_name>.<table_name> (
	<column_name>_hk		VARCHAR(32)		NOT NULL, 
	load_cycle_seq			INT				NOT NULL,
	record_source			VARCHAR(100)	NOT NULL,
	insert_dts				DATETIME		NOT NULL DEFAULT GETDATE(),
	changed_by				VARCHAR(100)	NOT NULL,
	<column_statement_list>   
)

ALTER TABLE <schema_name>.<table_name>
ADD CONSTRAINT PK_<column_name> PRIMARY KEY (<column_name>_hk)

CREATE UNIQUE INDEX UI_<column_name> ON <schema_name>.<table_name> (
<column_list> 
)

GO')