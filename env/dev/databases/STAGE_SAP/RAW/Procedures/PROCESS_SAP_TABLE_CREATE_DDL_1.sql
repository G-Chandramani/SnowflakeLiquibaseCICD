--liquibase formatted sql
				
--changeset CHANDRAMANI:PROCESS_SAP_TABLE_CREATE_DDL_1 runOnChange:true failOnError:true endDelimiter:""
--comment PROCESS_SAP_TABLE_CREATE_DDL procedure
CREATE OR REPLACE PROCEDURE PROCESS_SAP_TABLE_CREATE_DDL(TABLE_NAME VARCHAR,DATABASE VARCHAR,SCHEMA VARCHAR, SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 
declare     
    the_ddl varchar default null;   
    output object;
    start_time timestamp_ntz(9);
    end_time timestamp_ntz(9);
    step varchar;
    not_a_table_ddl exception (-20003,'Provided table_name not in metadata');  
begin
    start_time := current_timestamp();
    if(SCHEMA = 'RAW') THEN 
        step := 'TABLE_CREATION';
    ELSE
        step := 'STAGE_TABLE_MAINTENANCE';
    END IF;

    let view_identifier varchar := concat(:DATABASE,'.RAW.METADATA_DDL_VW');
    
    SELECT DDL into :the_ddl from identifier(:view_identifier) WHERE TABLE_NAME = :TABLE_NAME;
    
    if (:the_ddl is null) then 
        raise not_a_table_ddl;
    else
        the_ddl := replace(:the_ddl,$$CREATE OR REPLACE TABLE "$$,concat($$CREATE OR REPLACE TABLE $$,:DATABASE,$$.$$,:SCHEMA,$$."$$));
        execute immediate (the_ddl);
        output := object_construct(:TABLE_NAME,object_construct('TABLE_CREATION','SUCCESS'));    
        end_time := current_timestamp();
        if(:SESSION_ID is not null) then         
            insert into ZZINGESTION_SESSION_LOG 
            SELECT :SESSION_ID,:table_name,null,:step,'SUCCESS',:output,:start_time,:end_time;
        end if;        
        return to_varchar(output);
    end if;

    EXCEPTION

    WHEN OTHER THEN
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        output := object_construct(:TABLE_NAME,object_construct('TABLE_CREATION','FAIL','SQLCODE',:SQLCODE,'SQLERRM',:SQLERRM,'SQLSTATE',:SQLSTATE));
        end_time := current_timestamp();
        if(:SESSION_ID is not null) then             
            insert into ZZINGESTION_SESSION_LOG 
            SELECT :SESSION_ID,:table_name,null,:step,'FAIL',:output,:start_time,:end_time;
        end if;
        return to_varchar(output);
end;