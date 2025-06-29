--liquibase formatted sql
				
--changeset CHANDRAMANI:ZZINGESTION_SESSION_LOG_1 runOnChange:true failOnError:true
--comment ingestion session log
create TABLE IF NOT EXISTS ZZINGESTION_SESSION_LOG (
    SESSION_ID VARCHAR COMMENT 'Session ID',
	TABLE_NAME VARCHAR COMMENT 'Target Table Name',    
	FILE_NAME VARCHAR COMMENT 'File name that matches the pattern for ingestion in AWS S3',
    STEP VARCHAR COMMENT 'Ingestion Step',
    RESULT VARCHAR COMMENT 'Step Result', 
    OUTPUT OBJECT COMMENT 'Step Processing Output', 
	STEP_START TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'Start of Step',
	STEP_END TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'End of Step'
)COMMENT='Ingestion Step Log'
;