--liquibase formatted sql

--changeset CHANDRAMANI:CORRECT_DATE_VALUE_1 runOnChange:true failOnError:true endDelimiter:""
--comment CORRECT_DATE_VALUE procedure
CREATE OR REPLACE FUNCTION "CORRECT_DATE_VALUE"("V_INPUT" VARCHAR(16777216))
RETURNS DATE
LANGUAGE SQL
AS                     
SELECT CASE WHEN (TRY_TO_DATE(v_input,'YYYY.MM.DD') IS NOT NULL) = 'TRUE' 
       THEN TO_DATE(CONCAT(SPLIT_PART(v_input,'.',1),'-',SPLIT_PART(v_input,'.',-2),'-',SPLIT_PART(v_input,'.',-1)))
       WHEN (TRY_TO_DATE(v_input,'YYYY-MM-DD') IS NOT NULL) = 'TRUE' THEN TO_DATE(v_input)
       WHEN TRY_CAST(v_input AS DATE) IS NULL THEN '1970-01-01'
       ELSE TRY_CAST(v_input AS DATE) END 
from (select v_input as v_input from dual)
;