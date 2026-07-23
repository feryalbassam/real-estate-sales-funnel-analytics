CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @Start_time DATETIME , @End_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME;
    BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=============================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '=============================';
		SET @Start_time = GETDATE();
		PRINT'#TRUNCATING THE TABLE bronze.leads ';
		TRUNCATE TABLE bronze.leads;
		PRINT'#INSERTING THE DATA INTO bronze.leads ';
		BULK INSERT bronze.leads
		FROM 'C:\Users\adamb\Desktop\files (1)\Leads.csv'
		WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				ROWTERMINATOR = '0x0a',	
				TABLOCK
		);
		SET @End_time = GETDATE();
		PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
		PRINT '---------------------';

		SET @Start_time = GETDATE();
		PRINT'#TRUNCATING THE TABLE bronze.customers ';
		TRUNCATE TABLE bronze.customers;
		PRINT'#INSERTING THE DATA INTO bronze.customer';
		BULK INSERT bronze.customers
		FROM 'C:\Users\adamb\Desktop\files (1)\Customers.csv'
		WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				ROWTERMINATOR = '0x0a',
				TABLOCK
		);
		SET @End_time = GETDATE();
		PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
		PRINT '---------------------';

		PRINT'#TRUNCATING THE TABLE bronze.properties';
		TRUNCATE TABLE bronze.properties ;
		PRINT'#INSERTING THE DATA INTO bronze.properties';
		BULK INSERT bronze.properties
		FROM 'C:\Users\adamb\Desktop\files (1)\Properties.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @End_time = GETDATE();
		PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
		PRINT '---------------------';

		PRINT'#TRUNCATING THE TABLE bronze.agent';
		TRUNCATE TABLE bronze.agents ;
		PRINT'#INSERTING THE DATA INTO bronze.agent';
		BULK INSERT bronze.agents
		FROM 'C:\Users\adamb\Desktop\files (1)\Agents.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @End_time = GETDATE();
		PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
		PRINT '---------------------';

		PRINT'#TRUNCATING THE TABLE bronze.sales';
		TRUNCATE TABLE bronze.sales ;
		PRINT'#INSERTING THE DATA INTO bronze.sales';
		BULK INSERT bronze.sales
		FROM 'C:\Users\adamb\Desktop\files (1)\Sales.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @End_time = GETDATE();
		PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
		PRINT '---------------------';

		SET @batch_end_time = GETDATE();
		PRINT '===================================';
		PRINT 'LOADING BRONZE LAYER IS COMPLETED'; 
		PRINT 'TOTAL LOAD DURATION:'+CAST(DATEDIFF(SECOND ,@batch_start_time , @batch_end_time )AS NVARCHAR)+'SECONDS';
	END TRY
	BEGIN CATCH
	    PRINT '============================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZER LAYER';
		PRINT 'ERROR MESSAGE'+ ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE'+ CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE'+ CAST (ERROR_STATE() AS NVARCHAR);
	    PRINT '============================================';
	END CATCH
END

EXEC bronze.load_bronze