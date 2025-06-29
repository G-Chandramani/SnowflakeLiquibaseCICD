--liquibase formatted sql
				
--changeset CHANDRAMANI:SAP_INGRESS_1 runOnChange:true failOnError:true
--comment sap csv file format
CREATE OR REPLACE FILE FORMAT SAP_INGRESS
	TYPE = csv
	FIELD_DELIMITER = '||'
	SKIP_HEADER = 1
	DATE_FORMAT = 'YYYY.MM.DD'
	ESCAPE = '\\'
	FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
	COMPRESSION = gzip
;