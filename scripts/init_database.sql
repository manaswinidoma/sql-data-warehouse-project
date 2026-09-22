/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script sets up the 'DataWarehouse' database. It first checks if it already 
    exists — if it does, it gets deleted and created again from scratch. It also 
    creates three schemas inside the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will delete the whole 'DataWarehouse' database if it already 
    exists, and everything in it will be lost for good. Make sure you have a backup 
    before running this.
*/

-- Terminate any active connections to the database first
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'DataWarehouse' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS "DataWarehouse";

CREATE DATABASE "DataWarehouse";

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;


