--liquibase formatted sql

--changeset CHANDRAMANI:PROCESS_STAGING_2 runOnChange:true failOnError:true endDelimiter:""
--comment PROCESS_STAGING procedure
CREATE OR REPLACE PROCEDURE PROCESS_STAGING(TABLE_NAME VARCHAR,DATABASE VARCHAR, SESSION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
declare
    key_cc_count number;
    staging_command varchar;
    output object;
    start_time timestamp_ntz(9);
    end_time timestamp_ntz(9);
begin

    let view_identifier varchar := concat(:DATABASE,'.INFORMATION_SCHEMA.COLUMNS');

    -- View with Custom (manual) Metadata joined with SAP BODS export metadata
    let metadata_view varchar := concat(:DATABASE,'.RAW.METADATA_OVERRIDE_VW');

    start_time := current_timestamp();

    -- Do we have at least one key column and the Change Capture columns?
    SELECT COUNT(*)
	INTO :key_cc_count
	FROM RAW.METADATA_OVERRIDE_VW V1
	WHERE DATASOURCE = :TABLE_NAME
    AND FIELDNAME = 'DI_OPERATION_TYPE'
    AND EXISTS (
    	SELECT DISTINCT DATASOURCE
    	FROM RAW.METADATA_OVERRIDE_VW
    	WHERE DATASOURCE = V1.DATASOURCE
    	AND KEYFLAG = 'X');
        
    IF (:key_cc_count > 0) THEN
        -- This case will handle the follwoing condition
        -- Condition 1: Change Enabled  table load with known keys
        -- Resulting operation: 
        -- If a new row doesn't match an existing row, a new row is added with the current date time and the DI_OPERATION_TYPE 
        -- If a new row matches an existing row, the existing row current date time is updated (re-initialized rows can cause this case)
        WITH SELECTIONS AS
        (
        SELECT  
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME IS NOT NULL 
                        AND B.COLUMN_NAME != 'DI_SEQUENCE_NUMBER' 
                        AND B.COLUMN_NAME != 'DI_OPERATION_TYPE' 
                        AND B.COLUMN_NAME != 'ODQ_CHANGEMODE' 
                        AND B.COLUMN_NAME != 'ODQ_ENTITYCNTR' 
                        AND B.COLUMN_NAME != 'EXTRACT_TIMESTAMP' 
                        AND B.COLUMN_NAME != 'INSERT_DATETIME' THEN CONCAT('T."',A.COLUMN_NAME,'" = S."',A.COLUMN_NAME,'"')
                    ELSE '~'
                END 
                ,' AND ') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS JOIN_COLS,
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME IS NOT NULL THEN CONCAT('T."',A.COLUMN_NAME,'"')
                    ELSE CONCAT('NULL AS ','"',A.COLUMN_NAME,'"') --'~' 
                END 
                ,', ') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS SELECTIONS,
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME IS NOT NULL THEN CONCAT('S."',A.COLUMN_NAME,'"')
                    ELSE CONCAT('NULL AS ','"',A.COLUMN_NAME,'"') --'~' 
                END 
                ,', ') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS INSERTS
        FROM identifier(:view_identifier) AS A 
        LEFT OUTER JOIN identifier(:view_identifier) AS B 
            ON B.TABLE_NAME = A.TABLE_NAME 
            AND B.COLUMN_NAME = A.COLUMN_NAME 
        LEFT OUTER JOIN identifier(:metadata_view) AS C
            ON A.TABLE_NAME = C.DATASOURCE
            AND A.COLUMN_NAME = C.FIELDNAME
        WHERE A.TABLE_SCHEMA = 'STAGE' AND A.TABLE_NAME = :TABLE_NAME AND B.TABLE_SCHEMA = 'RAW'
        )
        SELECT CONCAT(
            'MERGE INTO ',:DATABASE,'.STAGE."',:TABLE_NAME,'" T\n',
            'USING ( SELECT * FROM ',:DATABASE,'.RAW."',:TABLE_NAME,'" WHERE EXTRACT_TIMESTAMP = ',$$'@'$$,' ) S\n',
            'ON\n',
    		REPLACE(REPLACE(JOIN_COLS, '~ AND '), 'AND ~'),
	        ' AND (T."DI_OPERATION_TYPE" = S."DI_OPERATION_TYPE" \n',
            ' OR (S."DI_OPERATION_TYPE" = ''X'' \n',
	        ' AND T."DI_OPERATION_TYPE" = ''I'') \n',
            ' OR (S."DI_OPERATION_TYPE" = ''I'' \n',
	        ' AND T."DI_OPERATION_TYPE" = ''X'')) \n',
    		'WHEN MATCHED\n',
            ' AND T."EXTRACT_TIMESTAMP" < S."EXTRACT_TIMESTAMP"\n',
            '    THEN UPDATE SET T."EXTRACT_TIMESTAMP" = S."EXTRACT_TIMESTAMP"\n',
    		' WHEN NOT MATCHED\n',
    		'	THEN INSERT (\n',
    		REPLACE(SELECTIONS , '~, '),
    		') VALUES (\n',
    		REPLACE(INSERTS , '~, '),
    		')'
        )
        into :staging_command
        FROM SELECTIONS;
    ELSE
        -- This case will handle both of the follwoing conditions
        -- Condition 1: Full table load without known keys
        -- Condition 2: Full table load with known keys
        -- Resulting operation: 
        -- If a new row doesn't match an existing row, a new row is added with the current date time
        -- If a new row matches an existing row, the existing row current date time is updated
        WITH SELECTIONS AS
        (
        SELECT  
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME = 'EXTRACT_TIMESTAMP' THEN '~'
    				WHEN B.COLUMN_NAME = 'INSERT_DATETIME' THEN '~'
                    WHEN B.COLUMN_NAME IS NOT NULL THEN CONCAT('T."',A.COLUMN_NAME,'" = S."',A.COLUMN_NAME,'"')
                    ELSE ''
                END 
                ,' AND ') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS JOIN_COLS,
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME IS NOT NULL THEN CONCAT('"',A.COLUMN_NAME,'"')
                    ELSE CONCAT('NULL AS ','"',A.COLUMN_NAME,'"') 
                END 
                ,', \n') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS SELECTIONS,
            LISTAGG(
                CASE 
                    WHEN B.COLUMN_NAME IS NOT NULL THEN CONCAT('S."',A.COLUMN_NAME,'"')
                    ELSE CONCAT('NULL AS ','"',A.COLUMN_NAME,'"') 
                END 
                ,', \n') WITHIN GROUP (ORDER BY A.ORDINAL_POSITION) AS INSERTS
        FROM identifier(:view_identifier) AS A 
        LEFT OUTER JOIN identifier(:view_identifier) AS B ON B.TABLE_NAME = A.TABLE_NAME AND B.COLUMN_NAME = A.COLUMN_NAME 
        WHERE A.TABLE_SCHEMA = 'STAGE' AND A.TABLE_NAME = :TABLE_NAME AND B.TABLE_SCHEMA = 'RAW'
        )
        SELECT CONCAT(
            'MERGE INTO ',:DATABASE,'.STAGE."',:TABLE_NAME,'" T\n',
            'USING ( SELECT * FROM ',:DATABASE,'.RAW."',:TABLE_NAME,'" WHERE EXTRACT_TIMESTAMP = ',$$'@'$$,' ) S\n',
            'ON\n',
    		REPLACE(JOIN_COLS , 'AND ~'),
            ' WHEN MATCHED\n',
            ' AND T."EXTRACT_TIMESTAMP" < S."EXTRACT_TIMESTAMP"\n',
            '    THEN UPDATE SET T."EXTRACT_TIMESTAMP" = S."EXTRACT_TIMESTAMP"\n',
            ' WHEN NOT MATCHED\n',
    		'	THEN INSERT (\n',
            SELECTIONS,
    		') VALUES (\n',
    		INSERTS,
    		')'
        )
        into :staging_command
        FROM SELECTIONS;
    END IF;

    let table_identifier varchar := concat(:DATABASE,'.RAW."',:TABLE_NAME,'"');

    let extract_timestamp_list RESULTSET := (
    	select distinct EXTRACT_TIMESTAMP from identifier(:table_identifier) order by EXTRACT_TIMESTAMP
    );
    
    let an_extract_timestamp CURSOR FOR extract_timestamp_list;
    let final_command varchar;

    FOR an_extract_timestamp IN extract_timestamp_list DO
        final_command := replace(:staging_command,'@',an_extract_timestamp.EXTRACT_TIMESTAMP);
        execute immediate (final_command);
    END FOR;

    -- Execute the constructed merge statement
    

    output := object_construct(:TABLE_NAME,object_construct('STAGING','SUCCESS'));
    end_time := current_timestamp();
    if(:SESSION_ID is not null) then
        insert into ZZINGESTION_SESSION_LOG
        SELECT :SESSION_ID,:table_name,null,'STAGING_RAW_DATA','SUCCESS',:output,:start_time,:end_time;
    end if;
    return to_varchar(output);

    EXCEPTION

    WHEN OTHER THEN
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        output := object_construct(:TABLE_NAME,object_construct('STAGING','FAIL','SQLCODE',:SQLCODE,'SQLERRM',:SQLERRM,'SQLSTATE',:SQLSTATE));
        end_time := current_timestamp();
        if(:SESSION_ID is not null) then
            insert into ZZINGESTION_SESSION_LOG
            SELECT :SESSION_ID,:table_name,null,'STAGING_RAW_DATA','FAIL',:output,:start_time,:end_time;
        end if;
        return to_varchar(output);
end;