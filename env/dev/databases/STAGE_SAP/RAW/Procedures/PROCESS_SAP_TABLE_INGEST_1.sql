--liquibase formatted sql
				
--changeset CHANDRAMANI:PROCESS_SAP_TABLE_CREATE_DDL_2 runOnChange:true failOnError:true endDelimiter:""
--comment PROCESS_SAP_TABLE_CREATE_DDL procedure
CREATE OR REPLACE PROCEDURE PROCESS_SAP_TABLE_INGEST(TABLE_NAME VARCHAR, FILENAME VARCHAR, SOURCE VARCHAR, KMS_KEY VARCHAR, REMOVE_STAGE_FILES BOOLEAN,  SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
declare
    the_selection varchar default null;
    ingestion_command varchar;
    output object;
    start_time timestamp_ntz(9);
    end_time timestamp_ntz(9);
    not_a_table_ddl exception (-20003,'Provided table_name not in metadata');  
begin
    start_time := current_timestamp();

    select DISTINCT 
    listagg(
        concat(
            CASE WHEN SNOWFLAKE_TYPE = 'NUMBER' THEN
                    CONCAT('IFF($',ordinal_position,$$ = ' ',NULL,$$,'$',ordinal_position,')')
                 WHEN SNOWFLAKE_TYPE = 'DECIMAL' THEN
                    CONCAT('IFF($',ordinal_position,$$ = ' ',NULL,$$,'TO_DECIMAL($',ordinal_position,$$))$$)
                 WHEN SNOWFLAKE_TYPE = 'TIME' THEN
                    CONCAT('IFF($',ordinal_position,$$ = ' ',NULL,$$,'$',ordinal_position,')')
                 WHEN SNOWFLAKE_TYPE = 'DATE' THEN
                    CONCAT('IFF($',ordinal_position,$$ = ' ',NULL,$$,'TO_DATE($',ordinal_position,$$,'YYYY.MM.DD'))$$)
                 ELSE
                    CONCAT('    $',ordinal_position)
            END,           

            $$ AS "$$,FIELDNAME,$$"$$
        ),
        ', \n'
    ) WITHIN GROUP (ORDER BY ORDINAL_POSITION) as content
    into :the_selection
    FROM ${SAPDatabaseName}.RAW.METADATA_SUMMARY_VW where TABLE_NAME = :TABLE_NAME;
    
    if (:the_selection is null) then 
        raise not_a_table_ddl;
    else
        select CONCAT(
                $$copy into "$$,:TABLE_NAME,$$" from ($$,'\n  SELECT\n',
                :the_selection,
                ',\n',
                $$    TO_TIMESTAMP_NTZ('$$,REGEXP_SUBSTR(:filename,'\\d{14}'),$$','YYYYMMDDHHMISS') AS EXTRACT_TIMESTAMP,$$,'\n',
                $$    CURRENT_TIMESTAMP() as INSERT_DATETIME $$,'\n',
                $$  FROM @$$,:source, 
                '\n',$$)$$,'\n',$$PATTERN = '$$,:filename,$$' FILE_FORMAT = ( format_name = SAP_INGRESS )$$,'\n',
                $$encryption = (type = 'AWS_SSE_KMS' kms_key_id = '$$,:kms_key,$$')$$
            ) 
            into :ingestion_command;
        execute immediate (ingestion_command);
        output := object_construct(:filename,object_construct('TABLE_NAME',:table_name,'FILE_INGESTION','SUCCESS'));    
        end_time := current_timestamp();

        if (remove_stage_files) then
            execute immediate $$remove @$$ || source ||$$ pattern = '$$ || filename ||$$'$$;
        end if;   

        if(:SESSION_ID is null) then            
            return to_varchar(output);
        else 
            insert into ZZINGESTION_SESSION_LOG 
            SELECT :SESSION_ID,:table_name,:filename,'FILE_INGESTION','SUCCESS',:output,:start_time,:end_time;
        end if;

    end if;

    EXCEPTION

    WHEN OTHER THEN
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        output := object_construct(:filename,object_construct('TABLE_NAME',:table_name,'FILE_INGESTION','FAIL','SQLCODE',:SQLCODE,'SQLERRM',:SQLERRM,'SQLSTATE',:SQLSTATE));
        end_time := current_timestamp();
        if(:SESSION_ID is null) then            
            return to_varchar(output);
        else 
            insert into ZZINGESTION_SESSION_LOG 
            SELECT :SESSION_ID,:table_name,:filename,'FILE_INGESTION','FAIL',:output,:start_time,:end_time;
        end if;
end;