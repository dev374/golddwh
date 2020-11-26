-- Remote querying ===========================================================

-- 1. Create Databases
CREATE DATABASE OriginDB(EDITION='Standard', Service_Objective='S0'); --dbdwh
CREATE DATABASE RemoteDB(EDITION='Basic', Service_Objective='Basic'); --dbstg

-- 2: Create a SQL Login in the logical server's master database (Use MASTER database)
CREATE LOGIN remoteusr WITH PASSWORD='StrongPassword123$%^'; -- Please add a stronger password!

-- 3: Create a SQL User in the remote database (Use RemoteDB)
CREATE USER remoteusr FOR LOGIN remoteusr;

-- 4: Create a Master Key in the Origin Database (Use OriginDB/dbdwh)
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Credentials123!' -- Add a stronger password!

-- 5: Create a Database Scoped Credential in the origin database
-- IDENTITY: It's the user that we created in RemoteDB from the "remoteusr" SQL Login.
-- SECRET: It's the password you assigned the SQL Login when you created it.
CREATE DATABASE SCOPED CREDENTIAL AppCredential WITH IDENTITY = 'remoteusr', SECRET='StrongPassword123$%^';

-- 6: Creating the external data source - in the origin database
CREATE EXTERNAL DATA SOURCE RemoteDatabase
WITH
(
TYPE=RDBMS,
LOCATION='sqlsrvdwh.database.windows.net', 
DATABASE_NAME='RemoteDB',
CREDENTIAL= AppCredential
);

-- 7: CREATE TABLE RemoteTable
CREATE TABLE RemoteTable
(
ID INT IDENTITY PRIMARY KEY,
NAME VARCHAR(20) NOT NULL,
LASTNAME VARCHAR(30) NOT NULL,
CEL VARCHAR(12) NOT NULL,
EMAIL VARCHAR(60) NOT NULL,
USERID INT
);

-- 8: Create the external table in the origin database
CREATE EXTERNAL TABLE RemoteTable
(
ID INT,
NAME VARCHAR(20) NOT NULL,
LASTNAME VARCHAR(30) NOT NULL,
CEL VARCHAR(12) NOT NULL,
EMAIL VARCHAR(60) NOT NULL,
USERID INT
)
WITH
(
DATA_SOURCE = RemoteDatabase
);

-- 9: Granting the RemoteDB user SELECT permissions on RemoteTable (Use RemoteDB)
GRANT SELECT ON [RemoteTable] TO remoteusr;

-- 10: Inserting data in RemoteTable
INSERT INTO [RemoteTable] (Name, LastName, Cel, Email, UserId) VALUES
('Vlad', 'Borvski', '91551234567', 'email3@contoso.com', 5),
('Juan', 'Galvin', '95551234568', 'email2@contoso.com', 5),
('Julio', 'Calderon', '95551234569', 'email1@contoso.net',1),
('Fernando', 'Cobo', '86168999', 'email0@email.com', 5);

-- 11: Querying the remote table from OriginDB
SELECT COUNT(*) FROM RemoteTable;

-- 12: Executing an external stored procedure:
exec sp_execute_remote
N'sqldustyeqtest.sqldustyeq2', -- — This is the external data source name…
N'get_CustomerCount' -- — This is the external procedure…

-- 13: Executing a TSQL statement:
exec sp_execute_remote
N'RemoteDatabase', -- — This is the external data source name…
N'Select COUNT(*) FROM RemoteTable' -- — This is the TSQL statement