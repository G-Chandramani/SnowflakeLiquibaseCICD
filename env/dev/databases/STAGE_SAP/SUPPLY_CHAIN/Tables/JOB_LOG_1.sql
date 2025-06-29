--liquibase formatted sql
				
--changeset CHANDRAMANI:JOB_LOG_1 runOnChange:true failOnError:true
--comment metadata type reference table
-----------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-25
--DESCRIPTION:Log Table to capture exceptions of procs 
-----------------------------------------------------------------
create or replace TABLE SUPPLY_CHAIN.JOB_LOG (
	LOAD_DATE DATE,
	COMPONENT VARCHAR(100),
	STATUS VARCHAR(50),
	LOAD_TIME TIME(9),
	MSG VARCHAR(5000)
);