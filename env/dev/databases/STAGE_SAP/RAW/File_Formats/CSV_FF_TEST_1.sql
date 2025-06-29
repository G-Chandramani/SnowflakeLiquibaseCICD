--liquibase formatted sql
				
--changeset CHANDRAMANI:CSV_FF_TEST_1 runOnChange:true failOnError:true
--comment csv file format with trimming of spaces
CREATE OR REPLACE FILE FORMAT CSV_FF_TEST
	TRIM_SPACE = TRUE
;