--liquibase formatted sql
				
--changeset CHANDRAMANI:METADATA_DATATYPE_REFERENCE_TBL_1 runOnChange:true failOnError:true
--comment metadata type reference table
create or replace view METADATA_MATCH_PATTERNS_VW(
	TABLE_NAME COMMENT 'Target Table Name',
	STAGE_FILE_MATCH_PATTERN COMMENT 'Pattern to find table related files in s3 stage',
	DATASOURCE COMMENT 'BODS Extract Structure',
	SEGMENT COMMENT 'For Hierarchy Datasets Sets Table Granularity'
) as
SELECT DISTINCT
	TABLE_NAME,
    CONCAT(REPLACE(REPLACE (TABLE_NAME,'/','_'),'$','_'),'_V.*.csv.gz') AS STAGE_FILE_MATCH_PATTERN,
    DATASOURCE,
    SEGMENT
FROM METADATA_SUMMARY_VW
ORDER BY TABLE_NAME;