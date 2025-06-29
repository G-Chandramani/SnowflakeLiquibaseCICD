--liquibase formatted sql
				
--changeset CHANDRAMANI:CSV_AND_TABLE_COLUMNS_MATCH_1 runOnChange:true failOnError:true endDelimiter:""
--comment validate that the CSV and table columns match
CREATE OR REPLACE PROCEDURE CSV_AND_TABLE_COLUMNS_MATCH(stage varchar, file_path varchar, database_name varchar, schema_name varchar, table_name varchar, file_format varchar, file_delimiter varchar, exclude_file_columns array, exclude_table_columns array)
RETURNS BOOLEAN
LANGUAGE SQL
EXECUTE AS CALLER
as
declare
    result boolean;
    header_line varchar;
    sql_command varchar;
BEGIN    
    /*****************************************************************************************
        This procedure will tell you us if a CSV (or flat) file in a stage matches the columns
        of a target table.
        In order to do answer this question we need a few things:    
            stage varchar : Path (DB.SCHEMA.NAME) of stage to pick up file for comparison
            file_path varchar : Full path inside stage (folders/filename) of file for comparison
            database_name varchar : Database where comparison table is in
            schema_name varchar : Stage where comparison table is in 
            table_name varchar : Name of table to compare with 
            file_format varchar : Path (DB.SCHEMA.NAME) of stage to pick up file for comparison.
                                  The file format must have:
                                    -a field delimiter different than the delimiter that will be used in file
                                    -an escape character different than the one that will be used for file
                                    -any compression used in the files
                                    -the same record delimiter as will be used in file
            file_delimiter : Actual delimiter used in in file
            exclude_file_columns array : Array created with ARRAY_CONSTRUCT() containing file column names to disregard in the comparison.
                                         When not necessary pass an empty array. 
            exclude_table_columns array : Array created with ARRAY_CONSTRUCT() containing table column names to disregard in the comparison.
                                          When not necessary pass an empty array.
     *****************************************************************************************/
    sql_command := concat('create or replace temporary table header_line_temp_table AS select ', CHR(36), '1 as header_line from @',
                  :stage,
                  '( file_format=>\'',:file_format,'\', pattern=>\'',:file_path,'\')',
                  ' limit 1;'
                  );
    execute immediate (sql_command);
    select header_line into :header_line FROM header_line_temp_table limit 1;
    drop table header_line_temp_table;

    create or replace temporary table file_schema AS
    select the_split.value as COLUMN_NAME, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as ORDINAL_POSITION 
    from table(SPLIT_TO_TABLE(:header_line,:file_delimiter)) as the_split
    where  not (array_contains(the_split.value::variant,:exclude_file_columns));

    let table_schema_source varchar := concat(:database_name,'.INFORMATION_SCHEMA.COLUMNS');
    create or replace temporary table table_schema AS
    select column_name, ROW_NUMBER() OVER (ORDER BY ORDINAL_POSITION) as ORDINAL_POSITION 
    from identifier(:table_schema_source) 
    where table_schema = :schema_name and TABLE_NAME = :table_name and not (array_contains(column_name::variant,:exclude_table_columns));

    with
    schema_compare as (
        select A.column_name as ACN, a.ordinal_position  as AOP, B.column_name as BCN, b.ordinal_position as BOP
        from table_schema as A 
        full outer join file_schema as B on A.column_name = B.COLUMN_name and A.ordinal_position = B.ordinal_position
    )
    select CASE WHEN count(*) = 0 THEN TRUE ELSE FALSE END INTO :result from schema_compare where ACN is null or BCN is null;

    drop table file_schema;
    drop table table_schema;
    return result;
END;