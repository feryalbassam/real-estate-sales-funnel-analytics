USE master;
GO
-- Drop and recreate the 'RealEstateDW' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RealEstateDW')
BEGIN
    ALTER DATABASE RealEstateDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RealEstateDW;
END;
GO
-- Step 1: Create the database
CREATE DATABASE RealEstateDW;
GO

-- Step 2: Switch context into the new database
USE RealEstateDW;
GO

-- Step 3: Create one schema per Medallion layer
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
