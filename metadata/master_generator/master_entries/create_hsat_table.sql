DELETE FROM mtd.master_generator
WHERE generator_type = 'create_hsat_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'create_hsat_table',
'DROP TABLE if exists <schema_name>.<table_name>;'+
'CREATE TABLE <schema_name>.<table_name> (
	<hub_table_name>_hk		VARCHAR(32)		NOT NULL, 
	load_cycle_seq			INT				NOT NULL,
	record_source			VARCHAR(100)	NOT NULL,
	insert_dts				DATETIME		NOT NULL DEFAULT GETDATE(),
	changed_by				VARCHAR(100)	NOT NULL,
    delete_ind		    	TINYINT			NOT NULL DEFAULT 0,
	<column_statement_list>   
)
;
ALTER TABLE <schema_name>.<table_name>
ADD CONSTRAINT pk_<table_name> PRIMARY KEY (<hub_table_name>_hk)
;
CREATE UNIQUE INDEX ui_<table_name> ON <schema_name>.<table_name> (load_cycle_seq, <column_ui_list>)
;')