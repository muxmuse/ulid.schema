-- ============================================================================
-- IMPORTANT LICENSE INFORMATION
-- ----------------------------------------------------------------------------
-- THIS FILE IS A MODIFIED VERSION OF THE FILE ulid.sql AS PUBLISHED BY THE 
-- ORIGINAL AUTHORS.
-- SEE README.md FOR DETAILS ABOUT THIS FORK.
--
-- Changes:
-- - GRANT EXECUTE statemens have beed removed
-- - name changed from ulid.sql to install.sql
-- - Check for existence and separate create/alter statements have been replaced
--     with statements in install.sql and uninstall.sql 
-- - All objects are created in schema ulid instead of dbo
-- - tabs replaced by spaces
-- - add functions ulid.encodeUlid and ulid.decodeUlid
-- ----------------------------------------------------------------------------

CREATE VIEW [ulid].[ulid_view]
WITH SCHEMABINDING
AS
SELECT SYSUTCDATETIME() AS dt
    ,CRYPT_GEN_RANDOM(10) AS rnd
GO

CREATE FUNCTION [ulid].[ulid] ()
RETURNS UNIQUEIDENTIFIER
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @rnd BINARY (10)
    DECLARE @dt DATETIME2
    DECLARE @di BIGINT

    SELECT TOP 1 @dt = dt
        ,@rnd = rnd
    FROM ulid.ulid_view

    SET @di = DATEDIFF(hour, CAST('1970-01-01 00:00:00' AS DATETIME2), @dt)
    SET @di = (@di * 60) + DATEPART(minute, @dt)
    SET @di = (@di * 60) + DATEPART(second, @dt)
    SET @di = (@di * 1000) + DATEPART(ms, @dt)

    RETURN CAST(@rnd + SUBSTRING(CAST(@di AS BINARY (8)), 3, 6) AS UNIQUEIDENTIFIER)
END
GO

CREATE FUNCTION [ulid].[ulid_varbinary_16] ()
RETURNS varbinary(16)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @rnd BINARY (10)
    DECLARE @dt DATETIME2
    DECLARE @di BIGINT

    SELECT TOP 1 @dt = dt
        ,@rnd = rnd
    FROM ulid.ulid_view

    SET @di = DATEDIFF(hour, CAST('1970-01-01 00:00:00' AS DATETIME2), @dt)
    SET @di = (@di * 60) + DATEPART(minute, @dt)
    SET @di = (@di * 60) + DATEPART(second, @dt)
    SET @di = (@di * 1000) + DATEPART(ms, @dt)

    RETURN SUBSTRING(CAST(@di AS BINARY (8)), 3, 6) + @rnd
END
GO

CREATE FUNCTION [ulid].[base32CrockfordEnc] (
    @x VARBINARY(max)
    ,@pad INT = 1
    )
RETURNS VARCHAR(max)
WITH SCHEMABINDING
AS
BEGIN
    /* modified BASE32 encoding as definied by Crockford at http://www.crockford.com/wrmg/base32.html */
    DECLARE @p INT
    DECLARE @c BIGINT
    DECLARE @s BIGINT
    DECLARE @q BIGINT
    DECLARE @t BIGINT
    DECLARE @o VARCHAR(max)
    DECLARE @op VARCHAR(8)
    DECLARE @alpha CHAR(32)

    SET @alpha = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
    SET @o = ''
    SET @p = DATALENGTH(@x) % 5 --encode with 40-bit blocks

    IF @p <> 0
        SET @x = @x + SUBSTRING(0x0000000000, 1, 5 - @p)
    SET @c = 0

    WHILE @c < DATALENGTH(@x)
    BEGIN
        SET @s = 0
        SET @t = CAST(SUBSTRING(@x, @c + 1, 5) AS BIGINT)
        SET @op = ''

        WHILE @s < 8
        BEGIN
            SET @q = @t % 32
            SET @op = SUBSTRING(@alpha, @q + 1, 1) + @op
            SET @t = @t / 32
            SET @s = @s + 1
        END

        SET @o = @o + @op
        SET @c = @c + 5
    END

    DECLARE @padc CHAR(1)

    --padding section
    SET @padc = CASE 
            WHEN @pad IS NULL
                OR @pad = 1
                THEN '='
            ELSE ''
            END
    SET @o = CASE 
            WHEN @p = 1
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 6) + REPLICATE(@padc, 6)
            WHEN @p = 2
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 4) + REPLICATE(@padc, 4)
            WHEN @p = 3
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 3) + REPLICATE(@padc, 3)
            WHEN @p = 4
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 1) + REPLICATE(@padc, 1)
            ELSE @o
            END

    RETURN LTRIM(RTRIM(@o))
END
GO

CREATE FUNCTION [ulid].[base32CrockfordDec] (@x VARCHAR(max))
RETURNS VARBINARY(max)
WITH SCHEMABINDING
AS
BEGIN
    /* RFC 4648 compliant BASE32 decoding function, takes varchar data to decode as only parameter*/
    DECLARE @p INT
    DECLARE @c BIGINT
    DECLARE @s BIGINT
    DECLARE @q BIGINT
    DECLARE @t BIGINT
    DECLARE @o VARBINARY(max)
    DECLARE @alpha CHAR(32)

    SET @alpha = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
    SET @o = CAST('' AS VARBINARY(max))
    SET @p = 0 --initialize padding character count
        --we can strip off padding characters since BASE32 is unambiguous without them
    SET @x = REPLACE(@x, '=', '')
    SET @p = DATALENGTH(@x) % 8 --encode with 40-bit blocks

    IF @p <> 0
        SET @x = @x + SUBSTRING('00000000', 1, 8 - @p)
    SET @x = UPPER(@x)
    SET @x = REPLACE(@x, 'I', '1')
    SET @x = REPLACE(@x, 'O', '0')
    SET @c = 1

    WHILE @c < DATALENGTH(@x) + 1
    BEGIN
        SET @s = 0
        SET @t = 0

        WHILE @s < 8 --accumulate 8 characters (40 bits) at a time in a bigint
        BEGIN
            SET @t = @t * 32
            SET @t = @t + (CHARINDEX(SUBSTRING(@x, @c, 1), @alpha, 1) - 1)
            SET @s = @s + 1
            SET @c = @c + 1
        END

        SET @o = @o + SUBSTRING(CAST(@t AS BINARY (8)), 4, 5)
    END

    --remove padding section
    SET @o = CASE 
            WHEN @p = 2
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 4)
            WHEN @p = 4
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 3)
            WHEN @p = 5
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 2)
            WHEN @p = 7
                THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 1)
            ELSE @o
            END

    RETURN @o
END
GO

CREATE FUNCTION [ulid].[ulidStr] ()
RETURNS VARCHAR(100)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @temp BINARY (16)

    SET @temp = CAST(ulid.ulid() AS BINARY (16))

    RETURN [ulid].[base32CrockfordEnc](SUBSTRING(@temp, 11, 6) + SUBSTRING(@temp, 1, 10), 0)
END
GO

CREATE FUNCTION [ulid].[ulid_seeded] (
    @dt DATETIME2
    ,@rnd BINARY (10)
    )
RETURNS UNIQUEIDENTIFIER
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @di BIGINT

    SET @di = DATEDIFF(hour, CAST('1970-01-01 00:00:00' AS DATETIME2), @dt)
    SET @di = (@di * 60) + DATEPART(minute, @dt)
    SET @di = (@di * 60) + DATEPART(second, @dt)
    SET @di = (@di * 1000) + DATEPART(ms, @dt)

    RETURN CAST(@rnd + SUBSTRING(CAST(@di AS BINARY (8)), 3, 6) AS UNIQUEIDENTIFIER)
END
GO

CREATE FUNCTION [ulid].[decodeUlid](@u VARCHAR(26)) 
RETURNS VARBINARY(16)
WITH SCHEMABINDING
AS BEGIN
    RETURN CASE WHEN @u IS NULL THEN NULL ELSE CAST(RIGHT(ulid.base32CrockfordDec('000000' + @u), 16) as VARBINARY(16)) END
END
GO

CREATE FUNCTION [ulid].[encodeUlid](@u VARBINARY(16))
RETURNS VARCHAR(26)
WITH SCHEMABINDING
AS BEGIN
    RETURN CASE WHEN @u IS NULL THEN NULL ELSE RIGHT(ulid.base32CrockfordEnc(0x00000000 + @u, 0), 26) END
END
