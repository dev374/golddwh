DELETE FROM mtd.master_generator
WHERE generator_type = 'create_stg_table'
GO

INSERT INTO mtd.master_generator (
 generator_type,
 core
) VALUES (
'create_stg_table',
'DROP TABLE if exists <schema_name>.<table_name>;
CREATE TABLE <schema_name>.<table_name> (
<column_statement_list>,
[hash] AS (UPPER(CONVERT([char](32),hashbytes(''MD5'',CONVERT([varchar](32),<column_name_id>)),(2))))
);  

ALTER TABLE <schema_name>.<table_name> ADD CONSTRAINT pk_<table_name> PRIMARY KEY (<column_name_id>);

CREATE UNIQUE INDEX ui_<table_name> ON <schema_name>.<table_name> (<column_name_id>);')