--liquibase formatted sql
				
--changeset CHANDRAMANI:RAW_TO_STAGE_FULL_LOAD_1 runOnChange:true failOnError:true endDelimiter:""
--comment load raw data to a tage table with a full load
CREATE OR REPLACE PROCEDURE RAW_TO_STAGE_FULL_LOAD(
    SRC_DB VARCHAR, 
    SRC_SCHEMA VARCHAR, 
    SRC_TABLE VARCHAR, 
    TGT_DB VARCHAR, 
    TGT_SCHEMA VARCHAR, 
    TGT_TABLE VARCHAR, 
    OVERRIDE_INSERT_DATETIME BOOLEAN, 
    TRUNCATE_SRC_TABLE BOOLEAN
    )
RETURNS object
LANGUAGE SQL
EXECUTE AS CALLER
AS declare
    row_count int;
    output object;
    command varchar;
    column_selections varchar;
begin
    let source_table_path varchar := concat('"',:SRC_DB,'"."',:SRC_SCHEMA,'"."',:SRC_TABLE,'"');
    let target_table_path varchar := concat('"',:TGT_DB,'"."',:TGT_SCHEMA,'"."',:TGT_TABLE,'"');
    let target_columns varchar := concat('"',:TGT_DB,'".INFORMATION_SCHEMA.COLUMNS');

    select count(*) into :row_count from identifier(:source_table_path);

    if (row_count > 0) then
        TRUNCATE TABLE identifier(:target_table_path);
        select listagg(
                        IFF(
                            COLUMN_NAME = 'INSERT_DATETIME' AND :OVERRIDE_INSERT_DATETIME, 
                            'CURRENT_TIMESTAMP() AS INSERT_DATETIME', 
                            CONCAT('"',COLUMN_NAME,'"')  
                            ),
                        ', '
                    ) WITHIN GROUP (ORDER BY ORDINAL_POSITION) 
        into :column_selections
        from identifier(:target_columns)
        WHERE TABLE_SCHEMA = (:SRC_SCHEMA) AND
            TABLE_NAME = (:SRC_TABLE);

        command := concat(
            'INSERT INTO ', target_table_path, '\n',
            'SELECT ', column_selections, '\n',
            'FROM ', source_table_path, ';'
        );

        execute immediate (:command);
    	
    	if (:TRUNCATE_SRC_TABLE) then
            TRUNCATE TABLE identifier(:source_table_path);
        end if;  
    end if;
    output := OBJECT_CONSTRUCT_KEEP_NULL(
        'SRC_DB',:SRC_DB,
        'SRC_SCHEMA',:SRC_SCHEMA,
        'SRC_TABLE',:SRC_TABLE,
        'TGT_DB',:TGT_DB,
        'TGT_SCHEMA',:TGT_SCHEMA,
        'TGT_TABLE',:TGT_TABLE,
        'TRANSFERRED_ROW_COUNT',:ROW_COUNT,
        'SOURCE_TRUNCATED',:TRUNCATE_SRC_TABLE
    );
    return output;
end;


