--liquibase formatted sql
				
--changeset CHANDRAMANI:APQCHEADERS_TBL_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the raw table for GRADESTAR_APQCHEADERS
CREATE OR REPLACE TABLE APQCHEADERS_TBL (
FILEPATH VARCHAR(16777216),
Id VARCHAR(16777216),
Plant VARCHAR(16777216),
TemplateName VARCHAR(16777216),
ScaleTicketNumber VARCHAR(16777216),
GradeDocumentNumber VARCHAR(16777216),
DocumentDate VARCHAR(16777216),
CorrectionNumber NUMBER(38, 0),
Grower VARCHAR(16777216),
Contract VARCHAR(16777216),
Field VARCHAR(16777216),
Variety VARCHAR(16777216),
Location1Level1 VARCHAR(16777216),
Location1Level2 VARCHAR(16777216),
Location1Level3 VARCHAR(16777216),
Location2Level1 VARCHAR(16777216),
Location2Level2 VARCHAR(16777216),
Location2Level3 VARCHAR(16777216),
IsActive NUMBER(38, 0),
RowVersion VARCHAR(16777216),
CreatedDate TIMESTAMP_NTZ(9),
LastModifiedDate TIMESTAMP_NTZ(9),
CropYear NUMBER(38, 0),
INSERT_DATETIME TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP()
);