--liquibase formatted sql
				
--changeset CHANDRAMANI:INGRESS_BUCKET_1 runOnChange:true failOnError:true
--comment INGRESS_BUCKET stage
CREATE OR REPLACE STAGE RAW.S4U
URL = 's3://vsk-landing-prod-dominodata-boomi-firefly/STAGE_SAP/sap-s4u/'
STORAGE_INTEGRATION = SNOWFLAKE_PROJECT_DATA;