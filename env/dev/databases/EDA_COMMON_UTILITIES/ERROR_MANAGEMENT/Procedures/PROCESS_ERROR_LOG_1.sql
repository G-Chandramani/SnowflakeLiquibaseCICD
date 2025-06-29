--liquibase formatted sql
				
--changeset CHANDRAMANI:PROCESS_ERROR_LOG_1 runOnChange:true failOnError:true endDelimiter:""
--comment procedure for adding error logs into the log table

CREATE OR REPLACE PROCEDURE "PROCESS_ERROR_LOG"(
    "P_SOLUTION" VARCHAR(16777216), 
    "P_CONTEXT" VARCHAR(16777216), 
    "P_SOURCE_NAME" VARCHAR(16777216), 
    "P_SOURCE_MESSAGE" VARCHAR(16777216), 
    "P_DATABASE" VARCHAR(16777216), 
    "P_SCHEMA" VARCHAR(16777216), 
    "P_OBJECT_TYPE" VARCHAR(16777216), 
    "P_OBJECT_NAME" VARCHAR(16777216), 
    "P_SQLCODE" NUMBER(38,0), 
    "P_SQLERRM" VARCHAR(16777216), 
    "P_SQLSTATE" VARCHAR(16777216)
)

RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
P_INSERT_DATETIME timestamp_ntz(9);
COMMAND VARCHAR; 
BEGIN
    //generates a timestamp for the log
    P_INSERT_DATETIME := CURRENT_TIMESTAMP();
    //logs data into table
    INSERT INTO ERROR_LOG VALUES
    (:P_SOLUTION,:P_CONTEXT,:P_SOURCE_NAME,:P_SOURCE_MESSAGE,:P_DATABASE,:P_SCHEMA,:P_OBJECT_TYPE,:P_OBJECT_NAME,:P_SQLCODE,:P_SQLERRM,:P_SQLSTATE,:P_INSERT_DATETIME);
    //build out file name
    let file_name varchar := REPLACE(CONCAT(:P_DATABASE,'_',:P_SCHEMA,'_',:P_OBJECT_NAME,'_',:P_CONTEXT,'_',TO_CHAR(:P_INSERT_DATETIME,'YYYYMMDDHHMISS'),'.json'),' ','_');
    //build out a command to create a json file in the stage with the contents of the freshly inserted log and the generated filename
    command := CONCAT(
        'COPY INTO @snowflake_error_log_egress/', :file_name, ' FROM ',
        '( SELECT OBJECT_CONSTRUCT_KEEP_NULL(*) AS CONTENT FROM ERROR_LOG WHERE',
        ' SOLUTION ',IFF(:P_SOLUTION IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOLUTION,'$$')),' AND',
        ' CONTEXT ',IFF(:P_CONTEXT IS NULL,$$IS NULL$$,CONCAT('= $$',:P_CONTEXT,'$$')),' AND',
        ' SOURCE_NAME ',IFF(:P_SOURCE_NAME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOURCE_NAME,'$$')),' AND',
        ' SOURCE_MESSAGE ',IFF(:P_SOURCE_MESSAGE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOURCE_MESSAGE,'$$')),' AND',
        ' DATABASE ',IFF(:P_DATABASE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_DATABASE,'$$')),' AND',
        ' SCHEMA ',IFF(:P_SCHEMA IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SCHEMA,'$$')),' AND',
        ' OBJECT_TYPE ',IFF(:P_OBJECT_TYPE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_OBJECT_TYPE,'$$')),' AND',
        ' OBJECT_NAME ',IFF(:P_OBJECT_NAME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_OBJECT_NAME,'$$')),' AND',
        ' SQLCODE ',IFF(:P_SQLCODE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLCODE,'$$')),' AND',
        ' SQLERRM ',IFF(:P_SQLERRM IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLERRM,'$$')),' AND',
        ' SQLSTATE ',IFF(:P_SQLSTATE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLSTATE,'$$')),' AND',
        ' INSERT_DATETIME ',IFF(:P_INSERT_DATETIME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_INSERT_DATETIME,'$$')),')',
        ' FILE_FORMAT = ( TYPE = JSON COMPRESSION = NONE );'
        );
    //execute the command
    execute IMMEDIATE (:command);
    //return an "all good"
    return 'Error has been logged and pushed to EDA_SNOWFLAKE_ERROR_SNS';
END;



/**************************************************************** ;
declare
    P_SOLUTION VARCHAR DEFAULT 'General Error Log And Alert Development' ; 
    P_CONTEXT VARCHAR DEFAULT 'RUNTIME' ; 
    P_SOURCE_NAME VARCHAR DEFAULT 'Object Build Test' ; 
    P_SOURCE_MESSAGE VARCHAR DEFAULT 'I apparently did somethin\'' ; 
    P_DATABASE VARCHAR DEFAULT 'A_DATABASE' ; 
    P_SCHEMA VARCHAR DEFAULT 'A_SCHEMA' ; 
    P_OBJECT_TYPE VARCHAR DEFAULT 'TABLE' ; 
    P_OBJECT_NAME VARCHAR DEFAULT 'A_TABLE' ; 
    P_SQLCODE NUMBER(38,0) DEFAULT 0; 
    P_SQLERRM VARCHAR DEFAULT NULL ; 
    P_SQLSTATE VARCHAR DEFAULT NULL;
    P_INSERT_DATETIME timestamp_ntz(9);
    command varchar;
begin 
    P_INSERT_DATETIME := CURRENT_TIMESTAMP();
    
    INSERT INTO ERROR_LOG VALUES
    (:P_SOLUTION,:P_CONTEXT,:P_SOURCE_NAME,:P_SOURCE_MESSAGE,:P_DATABASE,:P_SCHEMA,:P_OBJECT_TYPE,:P_OBJECT_NAME,:P_SQLCODE,:P_SQLERRM,:P_SQLSTATE,:P_INSERT_DATETIME);

    let file_name varchar := REPLACE(CONCAT(:P_DATABASE,'_',:P_SCHEMA,'_',:P_OBJECT_NAME,'_',:P_CONTEXT,'_',TO_CHAR(:P_INSERT_DATETIME,'YYYYMMDDHHMISS'),'.json'),' ','_');
    
    command := CONCAT(
        'COPY INTO @snowflake_error_log_egress/', :file_name, ' FROM ',
        '( SELECT OBJECT_CONSTRUCT_KEEP_NULL(*) AS CONTENT FROM ERROR_LOG WHERE',
        ' SOLUTION ',IFF(:P_SOLUTION IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOLUTION,'$$')),' AND',
        ' CONTEXT ',IFF(:P_CONTEXT IS NULL,$$IS NULL$$,CONCAT('= $$',:P_CONTEXT,'$$')),' AND',
        ' SOURCE_NAME ',IFF(:P_SOURCE_NAME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOURCE_NAME,'$$')),' AND',
        ' SOURCE_MESSAGE ',IFF(:P_SOURCE_MESSAGE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SOURCE_MESSAGE,'$$')),' AND',
        ' DATABASE ',IFF(:P_DATABASE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_DATABASE,'$$')),' AND',
        ' SCHEMA ',IFF(:P_SCHEMA IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SCHEMA,'$$')),' AND',
        ' OBJECT_TYPE ',IFF(:P_OBJECT_TYPE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_OBJECT_TYPE,'$$')),' AND',
        ' OBJECT_NAME ',IFF(:P_OBJECT_NAME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_OBJECT_NAME,'$$')),' AND',
        ' SQLCODE ',IFF(:P_SQLCODE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLCODE,'$$')),' AND',
        ' SQLERRM ',IFF(:P_SQLERRM IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLERRM,'$$')),' AND',
        ' SQLSTATE ',IFF(:P_SQLSTATE IS NULL,$$IS NULL$$,CONCAT('= $$',:P_SQLSTATE,'$$')),' AND',
        ' INSERT_DATETIME ',IFF(:P_INSERT_DATETIME IS NULL,$$IS NULL$$,CONCAT('= $$',:P_INSERT_DATETIME,'$$')),')',
        ' FILE_FORMAT = ( TYPE = JSON COMPRESSION = NONE );'
        );
        
    execute IMMEDIATE (:command);
    return command;
end;
**************************************************************** */