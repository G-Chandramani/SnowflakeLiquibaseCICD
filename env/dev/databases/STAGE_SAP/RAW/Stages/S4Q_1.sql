--liquibase formatted sql
				
--changeset CHANDRAMANI:S4Q_1 runOnChange:true failOnError:true
--comment S4Q stage
CREATE OR REPLACE STAGE RAW.S4Q
URL = 's3://vsk-landing-prod-dominodata-boomi-firefly/STAGE_SAP/sap-s4q/'
STORAGE_INTEGRATION = SNOWFLAKE_PROJECT_DATA;