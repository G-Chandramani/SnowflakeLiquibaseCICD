--liquibase formatted sql
				
--changeset CHANDRAMANI:METADATA_RICEF_REFERENCE_TBL_1 runOnChange:true failOnError:true
--comment metadata type reference table
create TABLE IF NOT EXISTS METADATA_RICEF_REFERENCE_TBL (
	RICEF_ID VARCHAR(16777216) COMMENT 'Groups of extracts. Stands for Reports/Interfaces/Conversions/Enhancements/Forms',
	DATASOURCE VARCHAR(16777216) COMMENT 'BODS Extract Structure'
)COMMENT='RICEF to Data Source relationship'
;