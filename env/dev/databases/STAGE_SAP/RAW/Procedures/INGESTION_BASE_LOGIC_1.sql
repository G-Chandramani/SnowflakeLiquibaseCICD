--liquibase formatted sql
				
--changeset CHANDRAMANI:INGESTION_BASE_LOGIC_2 runOnChange:true failOnError:true endDelimiter:""
--comment INGESTION_BASE_LOGIC procedure manages SAP file ingestion for all S4 BODS extractions
CREATE OR REPLACE PROCEDURE INGESTION_BASE_LOGIC(SAP_SOURCE VARCHAR,REMOVE_STAGE_FILES BOOLEAN, KMS_KEY VARCHAR,TABLE_FILTER_ARRAY ARRAY,SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS 
declare    
    source varchar default 's4r';
    stage_scan_command varchar;
    stage_scan_query_id varchar;
    procedure_result_id varchar;
    current_operation_details OBJECT;
    validation_counter number;
    output varchar ;    
    no_files_to_ingest exception (-20001,'No file found in ingress stage');
    no_tables_passed_validation exception (-20002,'No tables will support ingest'); 
    no_tables_were_updated exception (-20003,'All tables errored out');
begin    
    
    -- sap_source is an optional parameter, each environment will have a default    

    if (sap_source is not null) then
        source := :sap_source;
    end if;

    call INGEST_METADATA_FILE(:source);
    -- this step will scan the source's stage for files tied to SAP tables
    -- it will also scan the files for an array of its headers
    -- if an array of table names is provided, it will filter by those tables only
    stage_scan_command := concat(
        $$select B.TABLE_NAME, A.METADATA$FILENAME AS FILENAME, parse_json(to_varchar(split(A.$1,'||'))) as column_array$$,'\n',
        $$from @$$,:source,$$ (file_format=>'CSV_COLUMN_DISCOVERY', pattern=>'sap-$$,:source,$$/.*.csv.gz') as A$$,'\n',
        $$INNER JOIN METADATA_MATCH_PATTERNS_VW B ON A.METADATA$FILENAME RLIKE concat('sap-$$,:source,$$/',B.stage_file_match_pattern)$$,'\n',
        $$WHERE METADATA$FILE_ROW_NUMBER = 1$$,
        CASE WHEN table_filter_array is null THEN 
                '\n' 
             ELSE 
                CONCAT('\nAND TABLE_NAME IN ',REPLACE(REPLACE(REPLACE(TO_VARCHAR(:table_filter_array),'[','('),']',')'),'"',$$'$$),'\n')
             END,
        $$ORDER BY TABLE_NAME, FILENAME$$
    );
    
    execute immediate (:stage_scan_command);
    -- since this is a dynamic execution we're saving the query ID
    -- for multiple uses
    stage_scan_query_id := LAST_QUERY_ID();    

    -- count the distinct tables with files so, if there are none, we can raise an error
    select count(distinct TABLE_NAME) into :validation_counter from TABLE(RESULT_SCAN(:stage_scan_query_id));

    if ( validation_counter = 0 ) then
      raise no_files_to_ingest;
    end if;
    
    -- breaks down the header column array extracted from the files and
    -- identifies discrepancies between the files and the metadata structures
    -- and reports errors to the log
    with file_header_extract as
    (
        select * from TABLE(RESULT_SCAN(:stage_scan_query_id))
    ),
    file_columns as
    (
        select TABLE_NAME, FILENAME,flattened.index+1 as ordinal_position, flattened.value as fieldname 
        from file_header_extract,table(flatten(file_header_extract.column_array)) flattened
        ORDER BY TABLE_NAME,FILENAME, ORDINAL_POSITION 
    ),
    column_compare as
    (
        select  A.TABLE_NAME, FILENAME,
                A.FIELDNAME AS FILE_FIELDNAME,  A.ORDINAL_POSITION AS FILE_ORDINAL_POSITION, 
                B.FIELDNAME AS TABLE_FIELDNAME, B.ORDINAL_POSITION AS TABLE_ORDINAL_POSITION,
                equal_null(A.FIELDNAME,B.FIELDNAME) as column_eval
        from file_columns AS A
        LEFT OUTER JOIN METADATA_SUMMARY_VW AS B ON B.TABLE_NAME = A.TABLE_NAME AND B.ORDINAL_POSITION = A.ORDINAL_POSITION
        ORDER BY TABLE_NAME,FILENAME, FILE_ORDINAL_POSITION 
    ),
    first_error as
    (
        select TABLE_NAME, FILENAME, MIN(FILE_ORDINAL_POSITION) AS FIRST_ERROR
        FROM COLUMN_COMPARE
        WHERE  COLUMN_EVAL = FALSE
        GROUP BY TABLE_NAME, FILENAME
    )
    select :SESSION_ID, A.TABLE_NAME, A.FILENAME, 'VALIDATION','FAIL',
    OBJECT_CONSTRUCT(
        'TABLE_NAME',A.TABLE_NAME,
        'FILENAME',A.FILENAME,
        'FIRST_COLUMN_NUMBER_IN_ERROR',A.FIRST_ERROR,
        'FILE_FIELDNAME',B.FILE_FIELDNAME,
        'TABLE_FIELDNAME',B.TABLE_FIELDNAME
    ),
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
    FROM FIRST_ERROR AS A INNER JOIN COLUMN_COMPARE AS B ON B.TABLE_NAME = A.TABLE_NAME AND B.FILENAME = A.FILENAME AND B.FILE_ORDINAL_POSITION = A.FIRST_ERROR;

    INSERT INTO ZZINGESTION_SESSION_LOG
    select * from TABLE(RESULT_SCAN(last_query_id()));

    -- checks if any tables passed validation
    WITH tables_in_scope as
    (
        select distinct TABLE_NAME 
        FROM TABLE(RESULT_SCAN(:stage_scan_query_id))
        WHERE TABLE_NAME NOT IN (
            SELECT DISTINCT TABLE_NAME FROM ZZINGESTION_SESSION_LOG
            WHERE SESSION_ID = :SESSION_ID AND STEP = 'VALIDATION' AND RESULT = 'FAIL'
        )
    ) 
    select count(*) into :validation_counter from tables_in_scope;

    if ( validation_counter = 0 ) then
        raise no_tables_passed_validation;
    end if;

    -- construct the object to pass on to the python operation orchestrator for table creation
    WITH tables_in_scope as
    (
        select distinct TABLE_NAME 
        FROM TABLE(RESULT_SCAN(:stage_scan_query_id))
        WHERE TABLE_NAME NOT IN (
            SELECT DISTINCT TABLE_NAME FROM ZZINGESTION_SESSION_LOG
            WHERE SESSION_ID = :SESSION_ID AND STEP = 'VALIDATION' AND RESULT = 'FAIL'
        )
    ) 
    select object_construct(
        'create_tables',
        array_agg(
            object_construct(
                'TABLE_NAME', TABLE_NAME,
                'DATABASE', CURRENT_DATABASE(),
                'SCHEMA','RAW',
                'SESSION_ID',:session_id
            )
        )
    )
    into :current_operation_details FROM tables_in_scope;

    call PROCESS_TABLE_OPERATION(:current_operation_details);

    procedure_result_id := last_query_id();

    INSERT INTO ZZINGESTION_SESSION_LOG
    select SESSION_ID,TABLE_NAME,FILENAME,STEP,RESULT,OBJECT_CONSTRUCT('PYTHON_OUTPUT',OUTPUT),TO_TIMESTAMP_NTZ(STEP_START,'YYYYMMDDHHMISS.FF3' ),TO_TIMESTAMP_NTZ(STEP_END,'YYYYMMDDHHMISS.FF3' )
        FROM TABLE(RESULT_SCAN(:procedure_result_id))
        WHERE RESULT = 'FAIL';
    
    current_operation_details := null; 
    -- files in scope will be files for successful table creations
    with files_with_success_tables as
    (
        select DISTINCT B.TABLE_NAME, B.FILENAME
        from ZZINGESTION_SESSION_LOG as A
        inner join TABLE(RESULT_SCAN(:stage_scan_query_id)) as B on B.TABLE_NAME = A.TABLE_NAME 
        WHERE SESSION_ID = :SESSION_ID AND STEP = 'TABLE_CREATION' AND RESULT = 'SUCCESS'
    )
    select count(*) into :validation_counter from files_with_success_tables;

    if ( validation_counter = 0 ) then
      raise no_tables_were_updated;
    end if;

    -- construct the object to pass on to the python operation orchestrator for file ingestion
    select 
        object_construct( 
            'ingest_files',
            array_agg(
                object_construct(
                    'TABLE_NAME',A.TABLE_NAME,
                    'FILENAME',B.FILENAME,
                    'SOURCE',:source,
                    'KMS_KEY',:kms_key,
                    'REMOVE_STAGE_FILES',:remove_stage_files,
                    'SESSION_ID',:session_id
                )
            )
        )
    INTO :current_operation_details
    from ZZINGESTION_SESSION_LOG as A
    inner join TABLE(RESULT_SCAN(:stage_scan_query_id)) as B on B.TABLE_NAME = A.TABLE_NAME 
    WHERE SESSION_ID = :SESSION_ID AND STEP = 'TABLE_CREATION' AND RESULT = 'SUCCESS';
    
    call PROCESS_TABLE_OPERATION(:current_operation_details);

    procedure_result_id := last_query_id();

    INSERT INTO ZZINGESTION_SESSION_LOG
    select SESSION_ID,TABLE_NAME,FILENAME,STEP,RESULT,OBJECT_CONSTRUCT('PYTHON_OUTPUT',OUTPUT),TO_TIMESTAMP_NTZ(STEP_START,'YYYYMMDDHHMISS.FF3' ),TO_TIMESTAMP_NTZ(STEP_END,'YYYYMMDDHHMISS.FF3' )
        FROM TABLE(RESULT_SCAN(:procedure_result_id))
        WHERE RESULT = 'FAIL';

    select count(*) into :validation_counter from ZZINGESTION_SESSION_LOG where SESSION_ID = :SESSION_ID and RESULT = 'FAIL';

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
            'Raw Data Ingestion',
            concat('Problem while executing raw data ingestion with log session id: ',:session_id),
            CURRENT_DATABASE(),
            'RAW',
            'Procedure',
            'INGESTION_BASE_LOGIC',
            :this_sqlcode,:this_sqlerrm,:this_sqlstate
            );
        return 'FAILURE';
end;