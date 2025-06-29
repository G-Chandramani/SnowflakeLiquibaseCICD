--liquibase formatted sql
				
--changeset CHANDRAMANI:CSV_COLUMN_DISCOVERY_1 runOnChange:true failOnError:true
--comment csv file format for doing discovery work
CREATE OR REPLACE FILE FORMAT CSV_COLUMN_DISCOVERY
	FIELD_DELIMITER = '@'
	ESCAPE = '\\'
	COMPRESSION = GZIP
;