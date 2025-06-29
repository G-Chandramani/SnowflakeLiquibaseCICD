--liquibase formatted sql
				
--changeset CHANDRAMANI:STAGING_BASE_LOGIC_2 runOnChange:true failOnError:true endDelimiter:""
--comment STAGING_BASE_LOGIC procedure
CREATE OR REPLACE PROCEDURE STAGING_BASE_LOGIC(SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    stage_table_compare_query_id varchar;
    current_operation_details object;
    column_compare_query_id VARCHAR;
    column_summary_query_id VARCHAR;
    procedure_result_id VARCHAR;
    validation_counter number;
    output varchar;
BEGIN 
 with RAW_TABLES as
    (
        select DISTINCT B.TABLE_NAME
        from ZZINGESTION_SESSION_LOG AS A 
        INNER JOIN INFORMATION_SCHEMA.TABLES AS B ON B.TABLE_NAME = A.TABLE_NAME
        WHERE B.TABLE_SCHEMA = 'RAW' AND A.STEP = 'FILE_INGESTION' AND RESULT = 'SUCCESS' AND A.SESSION_ID = :session_id
        ORDER BY TABLE_NAME
    ),
    STAGE_TABLES as
    (
        select B.TABLE_NAME
        from METADATA_MATCH_PATTERNS_VW AS A 
        INNER JOIN INFORMATION_SCHEMA.TABLES AS B ON B.TABLE_NAME = A.TABLE_NAME
        WHERE B.TABLE_SCHEMA = 'STAGE'
        ORDER BY TABLE_NAME
    )
    select  DISTINCT CASE WHEN A.TABLE_NAME IS NULL THEN B.TABLE_NAME ELSE A.TABLE_NAME END AS TABLE_NAME, 
            CASE WHEN A.TABLE_NAME IS NOT NULL AND B.TABLE_NAME IS NOT NULL THEN 'IN BOTH' 
                 WHEN A.TABLE_NAME IS NOT NULL AND B.TABLE_NAME IS     NULL THEN 'IN RAW'
            END AS EVAL 
            from RAW_TABLES AS A
            LEFT OUTER JOIN STAGE_TABLES AS B ON B.TABLE_NAME = A.TABLE_NAME            
            ORDER BY TABLE_NAME;
    
    stage_table_compare_query_id := last_query_id();

    select COUNT(*) into :validation_counter FROM TABLE(RESULT_SCAN(:stage_table_compare_query_id)) where EVAL = 'IN RAW';
    
    if (validation_counter > 0) then
        select object_construct(
            'create_staging_table',
            array_agg(
                object_construct(
                    'TABLE_NAME', TABLE_NAME,
                    'DATABASE', CURRENT_DATABASE(),
                    'SCHEMA','STAGE',
                    'SESSION_ID',:session_id
                )
            )
        )
        into :current_operation_details 
        FROM TABLE(RESULT_SCAN(:stage_table_compare_query_id))
        where EVAL = 'IN RAW';

        call PROCESS_TABLE_OPERATION(:current_operation_details);

        procedure_result_id := last_query_id();

        INSERT INTO ZZINGESTION_SESSION_LOG
        select SESSION_ID,TABLE_NAME,FILENAME,STEP,RESULT,
                OBJECT_CONSTRUCT('PYTHON_OUTPUT',OUTPUT),
                TO_TIMESTAMP_NTZ(STEP_START,'YYYYMMDDHHMISS.FF3' ),
                TO_TIMESTAMP_NTZ(STEP_END,'YYYYMMDDHHMISS.FF3' )
            FROM TABLE(RESULT_SCAN(:procedure_result_id))
            WHERE RESULT = 'FAIL';
        
        current_operation_details := null;         

    end if;

    with RAW_columns as
    (
        select B.TABLE_NAME, B.ordinal_position, B.COLUMN_NAME 
        from TABLE(RESULT_SCAN(:stage_table_compare_query_id)) AS A 
        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS B ON B.TABLE_NAME = A.TABLE_NAME
        WHERE A.EVAL = 'IN BOTH' AND B.TABLE_SCHEMA = 'RAW'
        ORDER BY TABLE_NAME, ORDINAL_POSITION 
    ),
    STAGE_columns as
    (
        select B.TABLE_NAME, B.ordinal_position, B.COLUMN_NAME 
        from TABLE(RESULT_SCAN(:stage_table_compare_query_id)) AS A 
        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS B ON B.TABLE_NAME = A.TABLE_NAME
        WHERE A.EVAL = 'IN BOTH' AND B.TABLE_SCHEMA = 'STAGE'
        ORDER BY TABLE_NAME, ORDINAL_POSITION 
    )
    select  CASE WHEN A.TABLE_NAME IS NULL THEN B.TABLE_NAME ELSE A.TABLE_NAME END AS TABLE_NAME, 
            CASE WHEN A.COLUMN_NAME IS NOT NULL THEN A.COLUMN_NAME ELSE B.COLUMN_NAME END AS COLUMN_NAME,
            CASE WHEN A.COLUMN_NAME IS NOT NULL AND B.COLUMN_NAME IS NOT NULL THEN 'BOTH' 
                    WHEN A.COLUMN_NAME IS NOT NULL AND B.COLUMN_NAME IS     NULL THEN 'IN RAW'
                    WHEN A.COLUMN_NAME IS     NULL AND B.COLUMN_NAME IS NOT NULL THEN 'IN STAGE'
            END AS EVAL 
    from RAW_COLUMNS AS A
    FULL OUTER JOIN STAGE_COLUMNS AS B ON B.TABLE_NAME = A.TABLE_NAME AND B.COLUMN_NAME = A.COLUMN_NAME       
    ORDER BY TABLE_NAME, COLUMN_NAME ;

    column_compare_query_id := LAST_QUERY_ID();

    with COLUMN_COUNT_NOT_IN_RAW AS
    (
        SELECT DISTINCT TABLE_NAME FROM table(result_scan(:column_compare_query_id)) WHERE EVAL != 'IN RAW'
    ),
    COLUMN_COUNT_IN_RAW AS
    (
        SELECT DISTINCT TABLE_NAME FROM table(result_scan(:column_compare_query_id)) WHERE EVAL  = 'IN RAW'
    )
    SELECT A.TABLE_NAME,
           CASE WHEN B.TABLE_NAME IS NULL THEN 'UP TO DATE' ELSE 'HAS UPDATES' END AS EVAL
    FROM COLUMN_COUNT_NOT_IN_RAW AS A 
    LEFT OUTER JOIN COLUMN_COUNT_IN_RAW AS B ON B.TABLE_NAME = A.TABLE_NAME;
    
    column_summary_query_id := LAST_QUERY_ID();
    
    insert into ZZINGESTION_SESSION_LOG    
    select :session_id,TABLE_NAME,NULL,'STAGE_TABLE_MAINTENANCE','SUCCESS',
    object_construct(TABLE_NAME,object_construct('STAGE_TABLE_MAINTENCE','SUCCESS','FEEDBACK','Table is up to date')),
    current_timestamp(),current_timestamp()
    FROM table(result_scan(:column_summary_query_id))
    WHERE EVAL = 'UP TO DATE';

    SELECT COUNT(*) INTO :validation_counter FROM table(result_scan(:column_summary_query_id)) WHERE EVAL = 'HAS UPDATES';
    
    if (validation_counter > 0) then
        WITH UPDATE_PIECES AS
        (
            select B.TABLE_NAME, ARRAY_AGG(B.COLUMN_NAME) AS COLUMNS_TO_ADD
            FROM table(result_scan(:column_summary_query_id)) AS A
            INNER JOIN table(result_scan(:column_compare_query_id)) AS B ON B.TABLE_NAME = A.TABLE_NAME
            WHERE A.EVAL = 'HAS UPDATES' AND B.EVAL = 'IN RAW'
            GROUP BY B.TABLE_NAME
        )
        select object_construct(
            'update_tables',
            array_agg(
                object_construct(
                    'TABLE_NAME', TABLE_NAME,
                    'SESSION_ID',:session_id,
                    'DATABASE',current_database(),
                    'COLUMNS_TO_ADD',COLUMNS_TO_ADD
                )
            )
        )
        into :current_operation_details
        FROM UPDATE_PIECES;

        call PROCESS_TABLE_OPERATION(:current_operation_details);
        procedure_result_id := last_query_id();

        INSERT INTO ZZINGESTION_SESSION_LOG
        select SESSION_ID,TABLE_NAME,FILENAME,STEP,RESULT,
                OBJECT_CONSTRUCT('PYTHON_OUTPUT',OUTPUT),
                TO_TIMESTAMP_NTZ(STEP_START,'YYYYMMDDHHMISS.FF3' ),
                TO_TIMESTAMP_NTZ(STEP_END,'YYYYMMDDHHMISS.FF3' )
            FROM TABLE(RESULT_SCAN(:procedure_result_id))
            WHERE RESULT = 'FAIL';
    end if;

    --procedure_result_id := last_query_id();
    with files_with_success_tables as
        (
            select DISTINCT TABLE_NAME
            from ZZINGESTION_SESSION_LOG
            WHERE SESSION_ID = :SESSION_ID AND STEP = 'STAGE_TABLE_MAINTENANCE' AND RESULT = 'SUCCESS'
        )
        select count(*) into :validation_counter from files_with_success_tables;
    if (validation_counter > 0) then
        select object_construct(
            'stage_raw_data',
            array_agg(
                object_construct(
                    'TABLE_NAME', TABLE_NAME,
                    'SESSION_ID',:session_id,
                    'DATABASE',current_database()
                )
            )
        ) into :current_operation_details 
        from ZZINGESTION_SESSION_LOG
        WHERE SESSION_ID = :SESSION_ID AND STEP = 'STAGE_TABLE_MAINTENANCE' AND RESULT = 'SUCCESS';

        call PROCESS_TABLE_OPERATION(:current_operation_details);

        procedure_result_id := last_query_id();

        INSERT INTO ZZINGESTION_SESSION_LOG
        select SESSION_ID,TABLE_NAME,FILENAME,STEP,RESULT,
                OBJECT_CONSTRUCT('PYTHON_OUTPUT',OUTPUT),
                TO_TIMESTAMP_NTZ(STEP_START,'YYYYMMDDHHMISS.FF3' ),
                TO_TIMESTAMP_NTZ(STEP_END,'YYYYMMDDHHMISS.FF3' )
            FROM TABLE(RESULT_SCAN(:procedure_result_id))
            WHERE RESULT = 'FAIL';
        --error
    end if;

    select count(*) into :validation_counter from ZZINGESTION_SESSION_LOG where SESSION_ID = :session_id and RESULT = 'FAIL';

    if (validation_counter > 0) then 
        output := 'COMPLETE WITH ERRORS';
    else
        output := 'COMPLETE';
    end if;
    
    return output;
EXCEPTION

    WHEN OTHER THEN
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;

        call ${UtilitiesDatabaseName}.ERROR_MANAGEMENT.PROCESS_ERROR_LOG(
            'SAP_STAGE',
            'RUNTIME',
            'Data Staging',
            concat('Problem while executing data staging with log session id: ',:session_id),
            CURRENT_DATABASE(),
            'STAGE',
            'Procedure',
            'STAGING_BASE_LOGIC',
            :this_sqlcode,:this_sqlerrm,:this_sqlstate
            );
        return 'FAILURE';

END;