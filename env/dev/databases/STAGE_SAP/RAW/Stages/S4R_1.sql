--liquibase formatted sql
				
--changeset CHANDRAMANI:S4R_1 runOnChange:true failOnError:true
--comment S4R stage
CREATE OR REPLACE STAGE RAW.S4R
URL = 's3://vsk-landing-prod-dominodata-boomi-firefly/STAGE_SAP/sap-s4r/'
STORAGE_INTEGRATION = SNOWFLAKE_PROJECT_DATA;