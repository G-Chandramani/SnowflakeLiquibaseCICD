--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_APQCPICTURES_COPYINTO_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the copyinto procedure for GRADESTAR_APQCPICTURES
CREATE OR REPLACE PROCEDURE GRADESTAR_APQCPICTURES_COPYINTO()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS
BEGIN
  COPY INTO APQCPICTURES_TBL (
    FILEPATH,
    Id,
    APQCHeaderId,
    UserId,
    Comment,
    FileName,
    IsActive,
    RowVersion,
    CreatedDate,
    LastModifiedDate
  )
  from (select metadata$filename, t.$1, t.$2, t.$3, t.$4, CONCAT('\\',t.$5), t.$6, t.$7, TO_TIMESTAMP(t.$8,'YYYY-MM-DD HH:MI:SS.FF3'), TO_TIMESTAMP(t.$9,'YYYY-MM-DD HH:MI:SS.FF3') from @GRADESTAR_APQCPICTURES_S3_STAGE/ t)
    FILE_FORMAT = (FORMAT_NAME = GRADESTAR_S3_FF);

  return 'GRADESTAR_APQCPICTURES_COPYINTO Completed';
END;