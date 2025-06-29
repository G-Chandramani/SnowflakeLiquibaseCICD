--liquibase formatted sql
				
--changeset CHANDRAMANI:SUBMIT_LOG_ERRORS_2 runOnChange:true failOnError:true endDelimiter:""
--comment SUBMIT_LOG_ERRORS procedure
CREATE OR REPLACE PROCEDURE SUBMIT_LOG_ERRORS(session_id VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 
begin    
	let error_list RESULTSET := (
    	select * from zzingestion_session_log WHERE SESSION_ID = :SESSION_ID AND RESULT = 'FAIL'
    );    
    let an_error CURSOR FOR error_list;
    let the_step varchar;
    let the_table_name varchar;
    let the_OUTPUT OBJECT;
    
    LET the_schema varchar;
    FOR an_error IN error_list DO
        the_step := an_error.STEP;
        the_table_name := an_error.TABLE_NAME;
        the_OUTPUT := an_error.OUTPUT;
        
        the_schema := IFF(STARTSWITH(THE_STEP, 'STAG'),'STAGE','RAW');        

        call ${UtilitiesDatabaseName}.ERROR_MANAGEMENT.PROCESS_ERROR_LOG(
            'SAP_STAGE',
            'RUNTIME',
            concat('Problem while doing ',:THE_STEP,' with log session id: ',:session_id),
            concat('\n',to_varchar(:THE_OUTPUT)),
            CURRENT_DATABASE(),
            :the_schema,
            'TABLE',
            :THE_TABLE_NAME,
            NULL,NULL,NULL
        );
    END FOR;            
end;
