--liquibase formatted sql
				
--changeset CHANDRAMANI:SP_YED_SALES_WITH_PRICING_TBL_LOAD_3 runOnChange:true failOnError:true endDelimiter:""
--comment metadata type reference table
-----------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-25
--DESCRIPTION:Stored Proc to load YED_SALES_WITH_PRICING Table from the view 
--SUPPLY_CHAIN.YED_SALES_WITH_PRICING_EV
--Frequency - Daily once
-----------------------------------------------------------------

CREATE OR REPLACE PROCEDURE SUPPLY_CHAIN.SP_YED_SALES_WITH_PRICING_TBL_LOAD()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '

BEGIN

TRUNCATE TABLE SUPPLY_CHAIN.YED_SALES_WITH_PRICING;

INSERT INTO SUPPLY_CHAIN.YED_SALES_WITH_PRICING
SELECT * FROM SUPPLY_CHAIN.YED_SALES_WITH_PRICING_EV;

INSERT INTO SUPPLY_CHAIN.JOB_LOG VALUES(CURRENT_DATE, ''SP_YED_SALES_WITH_PRICING_TBL_LOAD'', ''COMPLETE'', CURRENT_TIME, '''');
return ''success'';

exception
  when statement_error then
    insert into SUPPLY_CHAIN.EXCEPTIONS(SCHEMA, STORED_PROCEDURE, ERROR_CODE, ERROR_MSG,TIME_STAMP,RESOLVED) 
	VALUES(''SUPPLY_CHAIN'', ''SP_YED_SALES_WITH_PRICING_TBL_LOAD'', :sqlcode, ''Error message is :  '' ||  :sqlerrm, CURRENT_TIMESTAMP, 0);
    return ''Fail'';
  when expression_error then
    insert into SUPPLY_CHAIN.EXCEPTIONS(SCHEMA, STORED_PROCEDURE, ERROR_CODE, ERROR_MSG,TIME_STAMP,RESOLVED) 
	VALUES(''SUPPLY_CHAIN'', ''SP_YED_SALES_WITH_PRICING_TBL_LOAD'', :sqlcode, ''Error message is :  '' ||  :sqlerrm, CURRENT_TIMESTAMP, 0);
    return ''Fail'';
  when other then
    insert into SUPPLY_CHAIN.EXCEPTIONS(SCHEMA, STORED_PROCEDURE, ERROR_CODE, ERROR_MSG,TIME_STAMP,RESOLVED) 
	VALUES(''SUPPLY_CHAIN'', ''SP_YED_SALES_WITH_PRICING_TBL_LOAD'', :sqlcode, ''Error message is :  '' ||  :sqlerrm, CURRENT_TIMESTAMP, 0);
    return ''Fail'';

END;
';
