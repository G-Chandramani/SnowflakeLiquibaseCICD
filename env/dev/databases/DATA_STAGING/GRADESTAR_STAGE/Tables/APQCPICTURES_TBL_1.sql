--liquibase formatted sql
				
--changeset CHANDRAMANI:APQCPICTURES_TBL_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the stage table for GRADESTAR_APQCPICTURES
CREATE OR REPLACE TABLE APQCPICTURES_TBL (
FILEPATH VARCHAR(16777216),
Id VARCHAR(16777216),
APQCHeaderId VARCHAR(16777216),
UserId VARCHAR(16777216),
Comment VARCHAR(16777216),
FileName VARCHAR(16777216),
IsActive NUMBER(38, 0),
RowVersion VARCHAR(16777216),
CreatedDate TIMESTAMP_NTZ(9),
LastModifiedDate TIMESTAMP_NTZ(9),
INSERT_DATETIME TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP()
);