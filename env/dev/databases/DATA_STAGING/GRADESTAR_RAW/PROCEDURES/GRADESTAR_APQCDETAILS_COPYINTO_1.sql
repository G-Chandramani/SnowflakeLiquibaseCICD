--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_APQCDETAILS_COPYINTO_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the copyinto procedure for GRADESTAR_APQCDETAILS
CREATE OR REPLACE PROCEDURE GRADESTAR_APQCDETAILS_COPYINTO()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS
BEGIN
  COPY INTO APQCDETAILS_TBL (
    FILEPATH,
    Id,
    APQCHeaderId,
    Value,
    ValuePercent,
    Code,
    ShortName,
    FullName,
    SortName,
    ExternalId,
    IdForLookup,
    IsActive,
    RowVersion,
    CreatedDate,
    LastModifiedDate,
    TabName
  )
  from (select metadata$filename, t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7, t.$8, t.$9, t.$10, 
        t.$11, t.$12, TO_TIMESTAMP(t.$13, 'YYYYMMDD HHMISS.FF3'), TO_TIMESTAMP(t.$14, 'YYYYMMDD HHMISS.FF3'), t.$15 from @GRADESTAR_APQCDETAILS_S3_STAGE/ t)
    FILE_FORMAT = (FORMAT_NAME = GRADESTAR_S3_FF);

  return 'GRADESTAR_APQCDETAILS_COPYINTO Completed';
END;