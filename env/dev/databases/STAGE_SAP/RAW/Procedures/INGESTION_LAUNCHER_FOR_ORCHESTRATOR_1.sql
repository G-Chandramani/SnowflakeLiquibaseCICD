--liquibase formatted sql
				
--changeset CHANDRAMANI:INGESTION_LAUNCHER_FOR_ORCHESTRATOR_2 runOnChange:true failOnError:true endDelimiter:""
--comment INGESTION_LAUNCHER_FOR_ORCHESTRATOR procedure entry point for Redwood to trigger SAP ingestion
CREATE OR REPLACE PROCEDURE INGESTION_LAUNCHER_FOR_ORCHESTRATOR()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS 
declare    
    sap_source VARCHAR default 's4r';
    remove_stage_files BOOLEAN default TRUE;
    kms_key VARCHAR default '3e296b8b-84e6-4bfb-8880-87a946f291e2';
    session_id VARCHAR;    
    output varchar ;
    set_session_command varchar;
begin       
    
    select CONCAT('USE SCHEMA ',PROCEDURE_CATALOG,'.',PROCEDURE_SCHEMA) into :set_session_command from information_schema.procedures where procedure_name = 'INGESTION_LAUNCHER_FOR_ORCHESTRATOR';
    execute immediate(:set_session_command);
    
    session_id := to_varchar(current_timestamp(),'YYYYMMDDHHMISS');
    CALL INGESTION_BASE_LOGIC(:sap_source, :remove_stage_files, :kms_key, null, :session_id) into :output;
    if (output != 'FAILURE') then
        CALL STAGING_BASE_LOGIC(:session_id) into :output;
    end if;
    CALL SUBMIT_LOG_ERRORS(:session_id);

    return output;
end;