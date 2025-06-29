--liquibase formatted sql
				
--changeset CHANDRAMANI:DROP_ALL_SAP_TABLES_1 runOnChange:true failOnError:true endDelimiter:""
--comment DROP_ALL_SAP_TABLES procedure
-- IMPORTANT: this procedure is for development and test only and should not be promoted to PROD
CREATE OR REPLACE PROCEDURE "DROP_ALL_SAP_TABLES"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS 
declare
    the_schema varchar default 'RAW';
begin
	let actionable_table_list RESULTSET := ( 
    select distinct B.TABLE_NAME from RAW.METADATA_MATCH_PATTERNS_VW AS A
    INNER JOIN INFORMATION_SCHEMA.TABLES AS B ON B.TABLE_NAME = A.TABLE_NAME
    WHERE B.TABLE_SCHEMA = :the_schema
    order by TABLE_NAME
    );
    let actionable_table CURSOR FOR actionable_table_list;

    FOR actionable_table IN actionable_table_list DO    	
        let table_name varchar := actionable_table.table_name;
        execute immediate ('DROP TABLE ' || the_schema || '."' || table_name || '";');         
    END FOR;
    return 'Dropped all SAP tables in this schema';
end;