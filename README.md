# ulid.schema

This is a fork of https://github.com/rmalayter/ulid-mssql in the format required by the schema package manager.

Install with [schema pm](https://github.com/muxmuse/schema)
``` bash
schema install ssh://git@github.com/muxmuse/ulid.schema.git v0.1.0
```

Original README:

# ulid-mssql

Implementation of ULID generator For Microsoft SQL Server

Based on JavaScript implementation at https://github.com/alizain/ulid

A ULID is a Universally **U**nique **L**exicographically Sortable **ID**entifier. Basically it's a GUID (or UUID) that "sorts well" which is important for indexes databases and data structures. However, it still has a large _random_ component which makes ulids "unguessable" and allows for ULID generation at any tier of the application, or even in different applications, with negligible probability of collisions (1 in 2<sup>-80</sup> for IDs that were generated _during the same milisecond_).

The format of a ULID is based on a 48-bit timestamp in milseconds, plus 80 bits of cryptographically generated random data, totaling 128 bits, which is the same size as a UUID.

There is also a string-based format for ULID, which is based on a modified base32 character set and is 26 characters in length. This presents a nice user-friendly way to display a ULID in URLs or even applications.

In Microsoft SQL Server, the `UNIQUEIDENTIFIER` type is used for storing UUIDs. Typically these are generated with the `NEWID()` function or `NEWSEQUENTIALID()` as a column default. Strangely, SQL Server sorts UUIDs in an unexpected way; the _last_ 48 bits are sorted first as a big-endian binary unit, followed by other components bits as _little-endian_ chunks.

This implementation generates `UNIQUEIDENTIFER` outputs that work well with SQL Servers sorting of ULID, using this code:
```
SELECT dbo.ulid()  --returns a ULID that sorts well in Microsoft SQL Server as a UNIQUEIDENTIFIER
--outputs '3A4EB25F-081F-C814-D218-015CA764E292'
```
There is also a string version, which is signficantly slower due to the base32 encoding that is performed (string manipulation in SQL databases isn't the fastest):
```
SELECT dbo.ulidStr()  --returns a string-encoded ULID that also sorts well in Microsoft SQL Server as a VARCHAR
--outputs '05EAESDVVA3VAF8RHPDXZYWF6W'
```
Performance on MSSQL 2014 with all service packs on my Dell E5740 laptop (output of tests.sql):
```
CRYPT_GEN_RANDOM+SYSUTCDATETIME component GENERATION TEST: 
     ids/sec: 367631
ulid() as UNIQUEIDENTIFIER GENERATION TEST: 
     ids/sec: 78119.9
newid() as UNIQUEIDENTIFIER GENERATION TEST: 
     ids/sec: 594870
ulidStr() as NVARCHAR GENERATION TEST: 
     ids/sec: 7554.73
ulid_seeded() as UNIQUEIDENTIFIER GENERATION TEST: 
     ids/sec: 97270.2
ulid() as primary key INSERTION TEST: 
     rows/sec: 28999.7
     avg_fragmentation_in_percent: 32.5901
newid() as primary key INSERTION TEST: 
     rows/sec: 61424.5
     avg_fragmentation_in_percent: 99.5643
newsquentialid() as primary key INSERTION TEST: 
     rows/sec: 68488.5
     avg_fragmentation_in_percent: 0
ulidStr() as primary key INSERTION TEST: 
     rows/sec: 6055.82
     avg_fragmentation_in_percent: 44.2871
```
Note the low index fragmentation of `dbo.ulid()` versus `newid()`. This is despite the fact that `tests.sql` generates thousands of ULIDs _during the same milisecond_; in real applications the index fragmentation generated by using `dbo.ulid()` in place of `newid()` should be near zero, as ULID generation will be spread out over time.
