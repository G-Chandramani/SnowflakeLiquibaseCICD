--liquibase formatted sql
				
--changeset CHANDRAMANI:PROCESS_TABLE_OPERATION_2 runOnChange:true failOnError:true endDelimiter:""
--comment PROCESS_TABLE_OPERATION procedure
CREATE OR REPLACE PROCEDURE PROCESS_TABLE_OPERATION(TABLE_OPERATION OBJECT)
RETURNS TABLE(
    SESSION_ID VARCHAR,
	TABLE_NAME VARCHAR,
	FILE_NAME VARCHAR,
    STEP VARCHAR,
    RESULT VARCHAR, 
    OUTPUT VARCHAR , 
	STEP_START VARCHAR,
	STEP_END VARCHAR
    )
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
EXECUTE AS CALLER
AS $$
from multiprocessing import cpu_count
from threading import current_thread
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
import json

def main(session, table_operation):

    global my_session
    my_session = session
    results = None
    if 'ingest_files' in table_operation:
        results = perform_table_operation('ingest_files', table_operation['ingest_files']) 
    if 'create_tables' in table_operation:
        results = perform_table_operation('create_tables', table_operation['create_tables']) 
    if 'create_staging_table' in table_operation:
        results = perform_table_operation('create_staging_table', table_operation['create_staging_table']) 
    if 'update_tables' in table_operation:
        results = perform_table_operation('update_tables', table_operation['update_tables']) 
    if 'stage_raw_data' in table_operation:
        results = perform_table_operation('stage_raw_data', table_operation['stage_raw_data']) 
        
     
    df = session.create_dataframe(results, schema=["SESSION_ID","TABLE_NAME","FILENAME","STEP","RESULT","OUTPUT","STEP_START","STEP_END"])    
    return df

def perform_table_operation(operation, table_operation_parameter_list):
    results = []
    list_length = len(table_operation_parameter_list)
    max_workers = cpu_count() * 10
    if (list_length < max_workers ):
        max_workers = list_length
    
    tasks = set()

    with ThreadPoolExecutor(max_workers=max_workers) as tpe:        
        for table_operation_parameter_set in table_operation_parameter_list:
            if operation == 'create_tables':
                tasks.add(
                    tpe.submit(
                        create_table,
                        table_operation_parameter_set=table_operation_parameter_set,
                    )
                )
            if operation == 'ingest_files':
                tasks.add(
                    tpe.submit(
                        ingest_file,
                        table_operation_parameter_set=table_operation_parameter_set,
                    )
                )
            if operation == 'create_staging_table':
                tasks.add(
                    tpe.submit(
                        create_staging_table,
                        table_operation_parameter_set=table_operation_parameter_set,
                    )
                )
            if operation == 'update_tables':
                tasks.add(
                    tpe.submit(
                        update_table,
                        table_operation_parameter_set=table_operation_parameter_set,
                    )
                )
            if operation == 'stage_raw_data':
                tasks.add(
                    tpe.submit(
                        stage_data,
                        table_operation_parameter_set=table_operation_parameter_set,
                    )
                )
            
        for future in as_completed(tasks):            
            results.append(future.result())
    return results

def create_table(table_operation_parameter_set):
    try:
        command = "CALL RAW.PROCESS_SAP_TABLE_CREATE_DDL('"
        command = command + table_operation_parameter_set['TABLE_NAME']
        command = command + "', '"
        command = command + table_operation_parameter_set['DATABASE']
        command = command + "', '"
        command = command + table_operation_parameter_set['SCHEMA']
        command = command + "', '"
        command = command + table_operation_parameter_set['SESSION_ID']
        command = command + "')"
        step_start = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        my_session.sql(command).collect()
        step_end = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'TABLE_CREATION',
                    'SUCCESS',
                    'SUCCESS',
                    step_start,
                    step_end]
        
    except Exception as e:
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'TABLE_CREATION',
                    'FAIL',
                    'Error while creating table '+ table_operation_parameter_set['TABLE_NAME'] +':'+str(e),
                    step_start,
                    step_end]
    return output

def ingest_file(table_operation_parameter_set):
    try:
        command = "CALL RAW.PROCESS_SAP_TABLE_INGEST("
        command = command + " '" + table_operation_parameter_set['TABLE_NAME'] +"',"
        command = command + " '"  + table_operation_parameter_set['FILENAME'] +"',"
        command = command + " '" + table_operation_parameter_set['SOURCE']+"',"
        command = command + " '" + table_operation_parameter_set['KMS_KEY']+"',"
        command = command + " "  + str(table_operation_parameter_set['REMOVE_STAGE_FILES'])+","
        command = command + " '" + table_operation_parameter_set['SESSION_ID'] +"'"
        command = command + ")"

        step_start = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        my_session.sql(command).collect()
        step_end = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    table_operation_parameter_set['FILENAME'],
                    'FILE_INGESTION',
                    'SUCCESS',
                    'SUCCESS',
                    step_start,
                    step_end]

    except Exception as e:        
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    table_operation_parameter_set['FILENAME'],
                    'FILE_INGESTION',
                    'FAIL',
                    'Error while processing file '+ table_operation_parameter_set['FILENAME'] +':'+str(e),
                    step_start,
                    step_end]
    return output

def create_staging_table(table_operation_parameter_set):
    try:
        command = "CALL RAW.PROCESS_SAP_TABLE_CREATE_DDL('"
        command = command + table_operation_parameter_set['TABLE_NAME']
        command = command + "', '"
        command = command + table_operation_parameter_set['DATABASE']
        command = command + "', '"
        command = command + table_operation_parameter_set['SCHEMA']
        command = command + "', '"
        command = command + table_operation_parameter_set['SESSION_ID']
        command = command + "')"
        step_start = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        my_session.sql(command).collect()
        step_end = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGE_TABLE_MAINTENANCE',
                    'SUCCESS',
                    'SUCCESS',
                    step_start,
                    step_end
                ]
        
    except Exception as e:
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGE_TABLE_MAINTENANCE',
                    'FAIL',
                    'Error while creating table '+ table_operation_parameter_set['TABLE_NAME'] +':'+str(e),
                    step_start,
                    step_end]
    return output

def update_table(table_operation_parameter_set):
    try:
        command = "CALL RAW.PROCESS_STAGE_TABLE_UPDATE('"
        command = command + table_operation_parameter_set['TABLE_NAME']
        command = command + "', '"
        command = command + table_operation_parameter_set['DATABASE'] + "', "
        command = command + "ARRAY_CONSTRUCT('"
        command = command + "', '".join(table_operation_parameter_set['COLUMNS_TO_ADD'])
        command = command + "'), '" + table_operation_parameter_set['SESSION_ID']
        command = command + "')"
        step_start = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        my_session.sql(command).collect()
        step_end = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGE_TABLE_MAINTENANCE',
                    'SUCCESS',
                    'SUCCESS',
                    step_start,
                    step_end
        ]
        
    except Exception as e:
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGE_TABLE_MAINTENANCE',
                    'FAIL',
                    'Error while creating table '+ table_operation_parameter_set['TABLE_NAME'] +':'+str(e),
                    step_start,
                    step_end]
    return output

def stage_data(table_operation_parameter_set):
    try:
        command = "CALL RAW.PROCESS_STAGING('"
        command = command + table_operation_parameter_set['TABLE_NAME']
        command = command + "', '"
        command = command + table_operation_parameter_set['DATABASE']
        command = command + "', '"
        command = command + table_operation_parameter_set['SESSION_ID']
        command = command + "')"
        step_start = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        my_session.sql(command).collect()
        step_end = (datetime.now()).strftime("%Y%m%d%H%M%S.%f")
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGING_RAW_DATA',
                    'SUCCESS',
                    'SUCCESS',
                    step_start,
                    step_end]
        
    except Exception as e:
        output = [
                    table_operation_parameter_set['SESSION_ID'],
                    table_operation_parameter_set['TABLE_NAME'],
                    '',
                    'STAGING_RAW_DATA',
                    'FAIL',
                    'Error while creating table '+ table_operation_parameter_set['TABLE_NAME'] +':'+str(e),
                    step_start,
                    step_end]
    return output
$$;