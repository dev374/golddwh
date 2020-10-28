DELETE FROM mtd.master_generator
WHERE generator_type = 'create_pit_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'create_pit_table',
'DROP TABLE if exists <schema_name>.<table_name>;'+
'CREATE TABLE <schema_name>.<table_name> (
	<table_name>_hk			VARCHAR(32)		NOT NULL, 
	<hub_table>_hk			VARCHAR(32)		NOT NULL, 
	snapshot_dts			TIMESTAMP		NOT NULL,
	load_cycle_seq			INT				NOT NULL,
	record_source			VARCHAR(100)	NOT NULL,
	insert_dts				DATETIME		NOT NULL DEFAULT GETDATE(),
	changed_by				VARCHAR(100)	NOT NULL,
	<column_statement_list>   
)
;
ALTER TABLE <schema_name>.<table_name>
ADD CONSTRAINT pk_<table_name> PRIMARY KEY (<table_name>_hk)
;
CREATE UNIQUE INDEX ui_<table_name> ON <schema_name>.<table_name> (<column_ui_list>)
;')
