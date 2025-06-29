--liquibase formatted sql
				
--changeset CHANDRAMANI:METADATA_DATATYPE_REFERENCE_TBL_1 runOnChange:true failOnError:true
--comment metadata type reference table
create TABLE IF NOT EXISTS METADATA_DATATYPE_REFERENCE_TBL (
	SAP_TYPE VARCHAR(16777216) COMMENT 'Datatype In SAP',
	SNOWFLAKE_TYPE VARCHAR(16777216) COMMENT 'Datatype In Snowflake',
	DESCRIPTION VARCHAR(16777216) COMMENT 'Datatype Description',
	OVERRIDE_TABLE VARCHAR(16777216),
	OVERRIDE_COLUMN VARCHAR(16777216)
)COMMENT='Datatype conversion for SAP data'
;