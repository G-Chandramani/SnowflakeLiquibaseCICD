--liquibase formatted sql
				
--changeset CHANDRAMANI:PROCESS_STAGE_TABLE_UPDATE_1 runOnChange:true failOnError:true endDelimiter:""
--comment PROCESS_STAGE_TABLE_UPDATE procedure
CREATE OR REPLACE PROCEDURE PROCESS_STAGE_TABLE_UPDATE(TABLE_NAME VARCHAR,DATABASE VARCHAR, COLUMNS_TO_ADD ARRAY, SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 
declare         
    alter_command varchar;
    output object;
    start_time timestamp_ntz(9);
    end_time timestamp_ntz(9);        
begin
    let view_identifier varchar := concat(:DATABASE,'.RAW.METADATA_SUMMARY_VW');
    
    start_time := current_timestamp();

    select
    concat(
        'alter table ',
        :DATABASE,'.STAGE."',:TABLE_NAME,'" \nADD',
        listagg(
            concat(
                '"',FIELDNAME,'" ',
                SNOWFLAKE_TYPE,
                case         	
                    WHEN SNOWFLAKE_TYPE = 'VARCHAR' THEN CONCAT('(',FIELD_LENGTH,')')                
                    WHEN SNOWFLAKE_TYPE = 'NUMBER' THEN CONCAT('(',FIELD_LENGTH,',',DECIMAL_PRECISION,')')
                    WHEN SNOWFLAKE_TYPE = 'DECIMAL' THEN CONCAT('(38,',DECIMAL_PRECISION,')')
                    ELSE ''
                end,
                ' default NULL'
            )
            ,', \n') WITHIN GROUP (ORDER BY ORDINAL_POSITION)
    )
    into :alter_command
    from identifier(:view_identifier) 
    where table_name = :table_name and 
          fieldname in (
            select value FROM TABLE(FLATTEN(input=>parse_json(to_varchar(:columns_to_add))))
          );
    execute immediate (alter_command);
    output := object_construct(:TABLE_NAME,object_construct('TABLE_MAINTENANCE','SUCCESS'));    
    end_time := current_timestamp();
    if(:SESSION_ID is not null) then         
        insert into ZZINGESTION_SESSION_LOG 
        SELECT :SESSION_ID,:table_name,null,'STAGE_TABLE_MAINTENANCE','SUCCESS',:output,:start_time,:end_time;
    end if;        
    return to_varchar(output);

    EXCEPTION

    WHEN OTHER THEN
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        output := object_construct(:TABLE_NAME,object_construct('TABLE_MAINTENANCE','FAIL','SQLCODE',:SQLCODE,'SQLERRM',:SQLERRM,'SQLSTATE',:SQLSTATE));
        end_time := current_timestamp();
        if(:SESSION_ID is not null) then             
            insert into ZZINGESTION_SESSION_LOG 
            SELECT :SESSION_ID,:table_name,null,'STAGE_TABLE_MAINTENANCE','FAIL',:output,:start_time,:end_time;
        end if;
        return to_varchar(output);
end;