--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_APQCHEADERS_COPYINTO_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the copyinto procedure for GRADESTAR_APQCHEADERS
CREATE OR REPLACE PROCEDURE GRADESTAR_APQCHEADERS_COPYINTO()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS
BEGIN
  COPY INTO APQCHEADERS_TBL (
    FILEPATH,
    Id,
    Plant, 
    TemplateName, 
    ScaleTicketNumber, 
    GradeDocumentNumber, 
    DocumentDate, 
    CorrectionNumber, 
    Grower, 
    Contract, 
    Field, 
    Variety, 
    Location1Level1, 
    Location1Level2, 
    Location1Level3, 
    Location2Level1, 
    Location2Level2, 
    Location2Level3, 
    IsActive, 
    RowVersion, 
    CreatedDate, 
    LastModifiedDate, 
    CropYear
  )
  from (select metadata$filename, t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7, t.$8, t.$9, t.$10, 
        t.$11, t.$12, t.$13, t.$14, t.$15, t.$16, t.$17, t.$18, t.$19, TO_TIMESTAMP(t.$20,'YYYY-MM-DD HH:MI:SS.FF3'), 
        TO_TIMESTAMP(t.$21,'YYYY-MM-DD HH:MI:SS.FF3'), t.$22 from @GRADESTAR_APQCHEADERS_S3_STAGE/ t)
    FILE_FORMAT = (FORMAT_NAME = GRADESTAR_S3_FF);

  return 'GRADESTAR_APQCHEADERS_COPYINTO Completed';
END;