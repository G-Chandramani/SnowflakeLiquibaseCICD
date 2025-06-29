--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_APQCDETAILS_S3_STAGE_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the base stage for GRADESTAR_APQCDETAILS
CREATE OR REPLACE STAGE GRADESTAR_APQCDETAILS_S3_STAGE
storage_integration = SNOWFLAKE_PROJECT_DATA
url = 's3://vsk-landing-prod-dominodata-boomi-firefly/GradeStar/APQCDETAILS/'; 
