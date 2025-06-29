--liquibase formatted sql
				
--changeset CHANDRAMANI:ERROR_LOG_EGRESS_1 runOnChange:true failOnError:true
--comment creation of error log EGRESS SCHEMA
CREATE OR REPLACE STAGE SNOWFLAKE_ERROR_LOG_EGRESS
URL = 's3://vsk-landing-prod-dominodata-boomi-firefly/integration/snowflake_error_log_egress/'
STORAGE_INTEGRATION = SNOWFLAKE_PROJECT_DATA;
