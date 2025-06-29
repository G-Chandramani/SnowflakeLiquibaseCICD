--liquibase formatted sql
				
--changeset CHANDRAMANI:INGESTION_MANUAL_LAUNCHER_2 runOnChange:true failOnError:true endDelimiter:""
--comment INGESTION_MANUAL_LAUNCHER procedure entry point for manual trigger of SAP ingestion (testing or manual re-loads)
CREATE OR REPLACE PROCEDURE INGESTION_MANUAL_LAUNCHER(sap_source VARCHAR, remove_stage_files boolean,TABLE_FILTER_ARRAY ARRAY)
RETURNS OBJECT
LANGUAGE SQL
EXECUTE AS CALLER
AS 
declare    
    kms_key VARCHAR default '3e296b8b-84e6-4bfb-8880-87a946f291e2';
    session_id VARCHAR;    
    call_output varchar;
    final_output object;
    set_session_command varchar;
begin       
    
    select CONCAT('USE SCHEMA ',PROCEDURE_CATALOG,'.',PROCEDURE_SCHEMA) into :set_session_command from information_schema.procedures where procedure_name = 'INGESTION_MANUAL_LAUNCHER';
    execute immediate(:set_session_command);
    
    session_id := to_varchar(current_timestamp(),'YYYYMMDDHHMISS');
    CALL ${SAPDatabaseName}.RAW.INGESTION_BASE_LOGIC(:sap_source, :remove_stage_files, :kms_key, :TABLE_FILTER_ARRAY, :session_id) into :call_output;
    if (call_output != 'FAILURE') then
        CALL ${SAPDatabaseName}.RAW.STAGING_BASE_LOGIC(:session_id) into :call_output;
    end if;

    CALL SUBMIT_LOG_ERRORS(:session_id);
    
    select object_construct('PROCESSING_OUTPUT',:call_output,'SESSION_ID',:session_id) into :final_output;
    return final_output;

end;
