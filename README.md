# Project golddwh
Scalable Data Warehouse project using Data Vault 2.0

## How to start DWH on a new account?

### Install 
git clone https://github.com/dev374/golddwh.git

Steps:
1. Azure setup: SQL Server, Databases, Datafactory
2. DWH Framework install on SQL Server
3. Understand datamodel and collect sources
4. Edit metadata and run generators
6. ETL setup with generated code 
7. Automate & Tweak

### Azure setup
Go to /install/init_resources and edit the config.json file, to setup resources and storage configuration.
Log in to the Azure account via powershell and let script generate cli commands.

### DWH Framework
Create frameworks for SQL jobs and logging system.
Go to /database/init_framework and run all scripts against the SQL database.

## Development mode
Check file DEV.txt in /doocumentation folder
