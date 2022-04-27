/**
TO-DO LIST DB

1) List

2) Items

3) SP Functionality: Add, Update, Soft delete

**/

USE master
GO

/******************************* CREATE DATABASE ******/
IF DB_ID('TODO') IS NOT NULL
	DROP DATABASE TODO
GO

CREATE DATABASE TODO
GO 

USE TODO
GO

/******************************* CREATE TABLES ********/
CREATE TABLE List(
	ListID int IDENTITY(1,1) NOT NULL,
	UserID int NOT NULL,
	ListDescription varchar(100) NOT NULL,
	CONSTRAINT PK_List PRIMARY KEY CLUSTERED (
	ListID ASC
 )
)
GO

CREATE TABLE Items(
	ItemID int IDENTITY(1,1) NOT NULL,
	UserID int NOT NULL,
	ListID int NOT NULL,
	ItemDescription VARCHAR(150) NOT NULL,
	DueDate smalldatetime NOT NULL,
	isDone	BIT NOT NULL DEFAULT 0,
	isImportant BIT NOT NULL DEFAULT 0,
	isDeleted BIT NOT NULL DEFAULT 0,
 CONSTRAINT PK_Item PRIMARY KEY CLUSTERED (
	ItemID ASC
 )
)
GO

CREATE TABLE ErrorTable (
	errorID			INT				PRIMARY KEY		IDENTITY,
	ERROR_PROCEDURE	VARCHAR(200)	NULL,
	ERROR_LINE		INT				NULL,
	ERROR_MESSAGE	VARCHAR(500)	NULL,
	PARAMETERS		VARCHAR(MAX)	NULL,
	USER_NAME		VARCHAR(100)	NULL,
	ERROR_NUMBER	INT				NULL,
	ERROR_SEVERITY	INT				NULL,
	ERROR_STATE		INT				NULL,
	ERROR_DATE		DATETIME		NOT NULL	DEFAULT(GETDATE()),
	FIXED_DATE		DATETIME		NULL
)
GO

/******************************* CREATE VIEWS *********/


/******************************* STORED PROCEDURES ****/

------------------------------------------------------------
	CREATE PROCEDURE spRecordError
		@params	VARCHAR(MAX) = NULL
	AS BEGIN SET NOCOUNT ON
		INSERT INTO ErrorTable
			SELECT
				 ERROR_PROCEDURE()	
				,ERROR_LINE()		
				,ERROR_MESSAGE()	
				,@params		
				,ORIGINAL_LOGIN()		
				,ERROR_NUMBER()	
				,ERROR_SEVERITY()	
				,ERROR_STATE()		
				,GETDATE()		
				,NULL	
	END
	GO
-------------------------------------------------------- Add

CREATE PROCEDURE spList_Add
	@UserID int,
	@ListDescription varchar(100)

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF(@UserID <= 0)
					THROW 80000, 'Invalid UserID Supplied', 1
				IF EXISTS (SELECT NULL FROM List WHERE ListDescription = @ListDescription)
					THROW 80001, 'List already exists', 1
				
				INSERT INTO List(UserID,
								 ListDescription) VALUES
								(@UserID,
								 @ListDescription)

			END TRY 
			BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@UserID]			  = 	@UserID,		 
						[@ListDescription]    = 	@ListDescription
						 
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
	GO

CREATE PROCEDURE spItem_Add
	@ListID				int ,
	@ItemDescription	VARCHAR(150),
	@DueDate			VARCHAR(25),
	@isImportant		BIT

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF(@ListID <= 0)
					THROW 80000, 'Invalid ListID Supplied', 1
				IF EXISTS (SELECT NULL FROM Item WHERE ItemDescription = @ItemDescription)
					THROW 80001, 'Item already exists', 1
				IF( CAST(@DueDate AS smalldatetime) < GETDATE())
					THROW 80006, 'Invaild Due Date', 1
				INSERT INTO Item(	ListID	,		
									ItemDescription,
									DueDate		,
									isImportant	
								) VALUES
								(	@ListID			   ,
									@ItemDescription	,
									CAST(@DueDate		as smalldatetime)	,
									@isImportant)
			END TRY 
			BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@ListID	]		= 	@ListID	 ,
						[@ItemDescription]  = 	@ItemDescription	 ,
						[@DueDate		]	=	@DueDate		 ,
						[@isImportant	]	=	@isImportant	
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
	GO

	/*
	Testing: 
	spInvoices_Add -122, '989319-457',
	'2015-12-08 00:00:00', 3813.3300, 3813.3300, 0.0000, 3, '2016-01-08 00:00:00', '2016-01-07 00:00:00'

	SELECT * FROM ErrorTable
	*/



-- ======================================= Update
CREATE PROCEDURE spList_Update
	@ListID int,
	@UserID int,
	@ListDescription varchar(100)

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS (SELECT NULL FROM List WHERE ListID = @ListID)
					THROW 70000, 'Cannot update unexisted List', 1
				
				UPDATE List
				SET		ListDescription		= 	@ListDescription 
								
				WHERE	ListID			= @ListID

			END TRY 
			BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@ListID]			= 	@ListID			 ,
						[@UserID]			= 	@UserID		 ,
						[@ListDescription]	=	@ListDescription		 
						
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
	GO


CREATE PROCEDURE spItem_Update
	@ItemID				int ,
	@ItemDescription	VARCHAR(150),
	@DueDate			VARCHAR(25),
	@isDone				BIT,
	@isImportant		BIT

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS (SELECT NULL FROM Item WHERE ItemID = @ItemID)
					THROW 70000, 'Cannot update unexisted List', 1
				IF( CAST(@DueDate AS smalldatetime) < GETDATE())
					THROW 80006, 'Invaild Due Date', 1
				/** may check for null to skip filling out field **/
				UPDATE	Item
				SET		ItemDescription		= 	@ItemDescription,
						DueDate				= CAST(@DueDate		as smalldatetime),
						isDone				= @isDone,
						isImportant			= @isImportant
								
				WHERE	ItemID			= @ItemID

			END TRY 
			BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@ItemID	]		= 	@ItemID	 ,
						[@ItemDescription]  = 	@ItemDescription	 ,
						[@DueDate		]	=	@DueDate	,	
						[@isDone]			=   @isDone,
						[@isImportant	]	=	@isImportant		 
						
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
	GO



--========================================== Soft Delete
 CREATE PROCEDURE spList_Delete
		@ListID	int
    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				UPDATE List
				SET		isDeleted			= 	1
				WHERE	ListID			= @ListID
			END TRY BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@ListID]		=	@ListID		 
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END


--================================================
CREATE PROCEDURE spItem_Delete
	@ItemID	int
    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				UPDATE Item
				SET		isDeleted			= 	1
				WHERE	ItemID			= @ItemID
			END TRY BEGIN CATCH
				IF( @@trancount > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						[@ItemID]		=	@ItemID		 
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
