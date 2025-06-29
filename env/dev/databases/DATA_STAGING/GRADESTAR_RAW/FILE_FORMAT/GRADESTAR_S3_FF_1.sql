--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_S3_FF_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the base file format for GRADESTAR
CREATE OR REPLACE FILE FORMAT GRADESTAR_S3_FF
  type = 'CSV'
  FIELD_DELIMITER = '||' 
  SKIP_HEADER = 1;  
  