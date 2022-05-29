-- ============================================================================
-- IMPORTANT LICENSE INFORMATION
-- ----------------------------------------------------------------------------
-- THIS FILE IS A MODIFIED VERSION OF THE FILE test.sql AS PUBLISHED BY THE 
-- ORIGINAL AUTHORS.
-- SEE README.md FOR DETAILS ABOUT THIS FORK.
--
-- Changes:
-- - The referenced schema was changed from dbo to ulid
--
-- ----------------------------------------------------------------------------

/* tests for ulid functions */
SET NOCOUNT ON

DECLARE @st DATETIME2(7)
DECLARE @et DATETIME2(7)
DECLARE @c INT
DECLARE @cmax INT
DECLARE @frag FLOAT
DECLARE @tuid UNIQUEIDENTIFIER
DECLARE @tbin BINARY (16)
DECLARE @tstr CHAR(26)
DECLARE @tdt DATETIME2

--number of rows used in tests
SET @cmax = 25000
--component generation test
SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	SET @tbin = CRYPT_GEN_RANDOM(10)
	SET @tdt = SYSUTCDATETIME()
	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()

PRINT 'CRYPT_GEN_RANDOM+SYSUTCDATETIME component GENERATION TEST: '
PRINT '     ids/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))

--ulid as UNIQUEIDENTIFIER generation test
SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	SET @tuid = ulid.ulid()
	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()

PRINT 'ulid() as UNIQUEIDENTIFIER GENERATION TEST: '
PRINT '     ids/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))

--newid as UNIQUEIDENTIFIER generation test
SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	SET @tuid = newid()
	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()

PRINT 'newid() as UNIQUEIDENTIFIER GENERATION TEST: '
PRINT '     ids/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))

--ulid as NVARCHAR generation test
SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	SET @tstr = ulid.ulidStr()
	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()

PRINT 'ulidStr() as NVARCHAR GENERATION TEST: '
PRINT '     ids/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))

--ulid_seeded generation test
SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	SET @tuid = ulid.ulid_seeded(SYSUTCDATETIME(),CRYPT_GEN_RANDOM(10))
	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()

PRINT 'ulid_seeded() as UNIQUEIDENTIFIER GENERATION TEST: '
PRINT '     ids/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))

--ulid as UNIQUEIDENTIFIER insert test
CREATE TABLE #t (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t (
		pk
		,d
		)
	VALUES (
		ulid.ulid()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t'), NULL, NULL, NULL)
		)

PRINT 'ulid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t

--newid as UNIQUEIDENTIFIER test
CREATE TABLE #t2 (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t2 (
		pk
		,d
		)
	VALUES (
		NEWID()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t2'), NULL, NULL, NULL)
		)

PRINT 'newid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t2

--newsequentialID as UNIQUEIDENTIFIER test
CREATE TABLE #t3 (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED DEFAULT(newsequentialid())
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t3 (
		pk
		,d
		)
	VALUES (
		DEFAULT
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t2'), NULL, NULL, NULL)
		)

PRINT 'newsquentialid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t3

--newidStr() as primary key test
CREATE TABLE #t4 (
	pk CHAR(26) PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t4 (
		pk
		,d
		)
	VALUES (
		ulid.ulidStr()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t4'), NULL, NULL, NULL)
		)

PRINT 'ulidStr() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000000 / DATEDIFF(microsecond, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t4
