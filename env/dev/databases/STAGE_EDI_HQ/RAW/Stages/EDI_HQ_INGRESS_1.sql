--liquibase formatted sql
				
--changeset CHANDRAMANI:EDI_HQ_INGRESS_1 runOnChange:true failOnError:true
--comment INGRESS_BUCKET stage
CREATE OR REPLACE STAGE RAW.EDI_HQ_INGRESS
URL = 's3://vsk-landing-prod-dominodata-boomi-firefly/edi_hq/'
STORAGE_INTEGRATION = SNOWFLAKE_PROJECT_DATA
ENCRYPTION = ( TYPE = 'AWS_SSE_KMS' KMS_KEY_ID = '3eed229d-3003-4b59-9207-084779b4d9c7');