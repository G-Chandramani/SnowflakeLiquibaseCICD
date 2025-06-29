--liquibase formatted sql
				
--changeset CHANDRAMANI:METADATA_DDL_VW_1 runOnChange:true failOnError:true
--comment metadata type reference table
create or replace view METADATA_DDL_VW(
	TABLE_NAME COMMENT 'Target Table Name',
	DDL COMMENT 'Data Definition Language Statement For Target Table'
) COMMENT='Processing of view METADATA_SUMMARY_VW to generate a DDL per entity represented in table METADATA_STORE_TBL'
 as
SELECT
TABLE_NAME,
concat(
	concat('CREATE OR REPLACE TABLE "',TABLE_NAME,'" ( \n'),
    listagg(
    	concat(
            case when CONTAINS(FIELDNAME,'/') then '"' ELSE '' end ,    
            FIELDNAME, 
            case when CONTAINS(FIELDNAME,'/') then '"' ELSE '' end,
            ' ',
            SNOWFLAKE_TYPE,
            case         	
                WHEN SNOWFLAKE_TYPE = 'VARCHAR' THEN CONCAT('(',FIELD_LENGTH,')')                
                WHEN SNOWFLAKE_TYPE = 'NUMBER' THEN CONCAT('(',FIELD_LENGTH,',',DECIMAL_PRECISION,')')
                WHEN SNOWFLAKE_TYPE = 'DECIMAL' THEN CONCAT('(38,',DECIMAL_PRECISION,')')
                ELSE ''
            end,
            ' COMMENT \'',
            REPLACE( IFNULL( FIELD_DESCRIPTION , ' ' ),$$'$$,$$\'$$ ),
            '\','
        )
    ,'\n') WITHIN GROUP (ORDER BY ORDINAL_POSITION),
    CONCAT(
        '\nEXTRACT_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT \'Time Stamp Of SAP Extraction\',',
        '\nINSERT_DATETIME TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT \'Time Stamp Of Row Insert\'',
        ') \nCOMMENT = \'',IFNULL( TABLE_DESCRIPTION , ' ' ),'\';'
    )
) as DDL
from METADATA_SUMMARY_VW
GROUP BY TABLE_NAME, TABLE_DESCRIPTION
order by TABLE_NAME;