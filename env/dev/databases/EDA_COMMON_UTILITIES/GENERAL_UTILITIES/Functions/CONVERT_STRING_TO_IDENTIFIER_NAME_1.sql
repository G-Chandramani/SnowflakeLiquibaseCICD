--liquibase formatted sql

--changeset CHANDRAMANI:CONVERT_STRING_TO_IDENTIFIER_NAME_1 runOnChange:true failOnError:true endDelimiter:""
--comment removes all special chars from a string so it can be used as an object name in snowflake such as a table name
create or replace FUNCTION CONVERT_STRING_TO_IDENTIFIER_NAME(INPUT_STRING varchar)
RETURNS varchar
LANGUAGE JAVASCRIPT
AS
$$
    var output = INPUT_STRING;

    // remove any basic special characters
    var chars_to_remove = ['.', '\'', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '=', '+', '~', '"', '<', '>', ',', '?', ';', ':', '\\', '/', '[', ']', '{', '}', '`']; 

    for( var i = 0; i < chars_to_remove.length; i++ )
    {
        output = output.replaceAll(chars_to_remove[i], '');
    }
    
    // these characters need replacement with underscore:'_' (order is important)
    chars_to_remove = [' ', '__', '-']; 

    for( var i = 0; i < chars_to_remove.length; i++ )
    {
        output = output.replaceAll(chars_to_remove[i], '_');
    }
    
    return output;
$$
;


