--liquibase formatted sql
				
--changeset CHANDRAMANI:INGEST_METADATA_FILE_2 runOnChange:true failOnError:true endDelimiter:""
--comment INGEST_METADATA_FILE procedure loads SAP BODS metadata into snowflake to support data ingestion
CREATE OR REPLACE PROCEDURE INGEST_METADATA_FILE(source varchar)
RETURNS object
LANGUAGE SQL
EXECUTE AS CALLER
AS declare
    file_name varchar default 'ZMETADATAJOIN.csv.gz';        
    kms_key varchar default '3e296b8b-84e6-4bfb-8880-87a946f291e2';
    output object;
    no_file_to_process exception (-20001,'No file found in ingress stage'); 
BEGIN
    let file_count NUMBER DEFAULT 0;
    execute immediate ( concat( $$select count(distinct METADATA$FILENAME) as FILE_COUNT from @$$,:source,
                                $$ where METADATA$FILENAME = 'sap-$$,:source,$$/$$,:file_name,$$'$$ ) );

    SELECT DISTINCT FILE_COUNT INTO :FILE_COUNT FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    if (file_count = 0) then 
    	// raise custom error code that no files were found
        raise no_file_to_process;
    end if;

    let the_selection varchar;
    select DISTINCT listagg(             
        concat( 
                CASE WHEN COLUMN_NAME = 'INSERT_DATETIME' THEN 'CURRENT_TIMESTAMP()'
                ELSE CONCAT('    $',ordinal_position) END
            ,$$ AS "$$,COLUMN_NAME,$$"$$)
        ,', \n') WITHIN GROUP (ORDER BY ORDINAL_POSITION) as SELECTION
    into :the_selection
    from INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'METADATA_STORE_TBL' AND TABLE_SCHEMA = 'RAW'
    group by TABLE_NAME;

    let ingest_command varchar;
    ingest_command := 
    CONCAT(
        $$copy into METADATA_STORE_TBL from ($$,'\n  SELECT\n',
        the_selection,'\n',
        $$  FROM @$$,:source, 
        '\n',$$)$$,'\n',$$PATTERN = 'sap-$$,:source,$$/$$,:file_name,$$' FILE_FORMAT = ( format_name = SAP_INGRESS_METADATA )$$,'\n',
        $$encryption = (type = 'AWS_SSE_KMS' kms_key_id = '$$,:kms_key,$$')$$
       );
    
    TRUNCATE TABLE METADATA_STORE_TBL;    

    execute immediate (ingest_command);
    
    output := object_construct('METADATA_INGEST','SUCCESS');    
    return output;  

    EXCEPTION

    WHEN OTHER THEN
        // When an error happens it will be caught by this handler and capture the error environment variables.
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        output := object_construct('TABLE_NAME','METADATA_STORE_TBL','SQLCODE',:SQLCODE,'SQLERRM',:SQLERRM,'SQLSTATE',:SQLSTATE);
        return output;    
end;