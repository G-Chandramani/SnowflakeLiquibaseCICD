--liquibase formatted sql
				
--changeset CHANDRAMANI:EXCEPTIONS_1 runOnChange:true failOnError:true
--comment metadata type reference table
-----------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-25
--DESCRIPTION:EXCEPTIONS Table to capture exceptions of procs 
-----------------------------------------------------------------
create or replace TABLE SUPPLY_CHAIN.EXCEPTIONS (
	SCHEMA VARCHAR(100),
	STORED_PROCEDURE VARCHAR(100),
	ERROR_CODE VARCHAR(50),
	ERROR_MSG VARCHAR(5000),
	TIME_STAMP TIMESTAMP_NTZ(9),
	RESOLVED NUMBER(38,0),
	RESOLVED_DATETIME TIMESTAMP_NTZ(9),
	RESOLVED_BY VARCHAR(100)
);