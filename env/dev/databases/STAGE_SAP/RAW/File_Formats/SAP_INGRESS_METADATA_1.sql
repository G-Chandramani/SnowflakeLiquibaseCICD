--liquibase formatted sql
				
--changeset CHANDRAMANI:SAP_INGRESS_METADATA_1 runOnChange:true failOnError:true
--comment csv file format for sap metadata
CREATE OR REPLACE FILE FORMAT SAP_INGRESS_METADATA
	TYPE = csv
	SKIP_HEADER = 1
	DATE_FORMAT = 'YYYY.MM.DD'
	ESCAPE = '\\'
	FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
	COMPRESSION = gzip
;