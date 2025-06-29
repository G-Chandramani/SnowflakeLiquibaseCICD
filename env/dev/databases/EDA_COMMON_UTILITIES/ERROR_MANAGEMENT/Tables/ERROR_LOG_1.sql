--liquibase formatted sql
				
--changeset CHANDRAMANI:ERROR_LOG_1 runOnChange:true failOnError:true
--comment creation of error log table
create or replace TABLE ERROR_LOG (
	SOLUTION VARCHAR(16777216) COMMENT 'Solution this error belongs to',
	CONTEXT VARCHAR(16777216) COMMENT 'Is this entry for a runtime or validation error? (LOV: RUNTIME, VALIDATION)',
	SOURCE_NAME VARCHAR(16777216) COMMENT 'Log source name',
	SOURCE_MESSAGE VARCHAR(16777216) COMMENT 'Custom Message log source',
	DATABASE VARCHAR(16777216) COMMENT 'Database where the object is',
	SCHEMA VARCHAR(16777216) COMMENT 'Schema where the object is',
	OBJECT_TYPE VARCHAR(16777216) COMMENT 'Type of object: table, view, procedure, etc.',
	OBJECT_NAME VARCHAR(16777216) COMMENT 'Name of the object where the error is happening',
	SQLCODE NUMBER(38,0) COMMENT 'Exception SQL Code',
	SQLERRM VARCHAR(16777216) COMMENT 'Exception SQL Error Message',
	SQLSTATE VARCHAR(16777216) COMMENT 'Exception SQL State',
	INSERT_DATETIME TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'Timestamp of record'
)COMMENT='Table to log errors'
;