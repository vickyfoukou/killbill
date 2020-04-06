/* SQL server doesn't have any object called serial, so first we want to create a new type alias for serial based on the int type */

DROP TYPE IF EXISTS serial;
CREATE TYPE serial FROM int NOT NULL;

/* override the last_insert_id method to return the @@IDENTITY value as intended for SQL server */
CREATE OR ALTER FUNCTION last_insert_id() RETURNS bigint AS
    BEGIN
        DECLARE @Result bigint;
        SELECT @Result = @@IDENTITY
        RETURN @Result
    END

/*We need a function/procedure that will alter the serial field of a given table to add an identity property to it since the serial fields require to be incremental in nature */

IF OBJECT_ID ('update_serial_column', 'P') IS NOT NULL
    DROP PROCEDURE update_serial_column;

CREATE OR ALTER PROCEDURE update_serial_column
    @Table nvarchar(255), @Column varchar(255)
    AS
        DECLARE @tsql varchar(500)
        SET @tsql = 'ALTER TABLE [' + @Table + '] DROP COLUMN [' + @Column + ']'
        SELECT @tsql
        SET @tsql = 'ALTER TABLE [' + @Table + '] ADD [' + @Column +'] serial identity(1,1)'
        SELECT @tsql
    END

CREATE TRIGGER update_serial_column
    ON DATABASE
    FOR CREATE_TABLE
    AS
        DECLARE @table nvarchar(255);
        DECLARE @column nvarchar(255);
        SELECT @table = OBJECT_NAME(parent_object_id) FROM sys.objects WHERE sys.objects.name = OBJECT_NAME(@@PROCID)
        SELECT @column = c.name from sys.columns c join sys.types t on c.user_type_id=t.user_type_id where c.object_id=OBJECT_ID(@table) AND TYPE_NAME(c.USER_TYPE_ID)="serial"
        EXEC update_serial_column @Table = @table , @Column = @column
    END
