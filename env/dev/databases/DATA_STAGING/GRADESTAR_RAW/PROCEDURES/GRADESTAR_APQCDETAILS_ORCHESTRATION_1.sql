--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_APQCDETAILS_ORCHESTRATION_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the orchestration procedure for GRADESTAR_APQCDETAILS
CREATE OR REPLACE PROCEDURE GRADESTAR_APQCDETAILS_ORCHESTRATION()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    CURRENT_STEP VARCHAR;
BEGIN
    CURRENT_STEP := 'COPYINTO RAW TABLE';
    CALL GRADESTAR_APQCDETAILS_COPYINTO();

    CURRENT_STEP := 'MOVING FROM RAW TO STAGE';
    CALL EDA_COMMON_UTILITIES.STAGE_PROCESSING.RAW_TO_STAGE_INCREMENTAL_LOAD(CURRENT_DATABASE(), 'GRADESTAR_RAW', 'APQCDETAILS_TBL', CURRENT_DATABASE(), 'GRADESTAR_STAGE', 'APQCDETAILS_TBL', TRUE, TRUE);
    
    CURRENT_STEP := 'CLEANING STAGE TABLE TO MAINTAIN 2 YEARS OF DATA';
    CALL DELETE_GREATERTHAN_TWO_YRS(CURRENT_DATABASE(), 'GRADESTAR_STAGE', 'APQCDETAILS_TBL', 'LastModifiedDate');
    
    CURRENT_STEP := 'CLEARING EXTERNAL STAGE';
    REMOVE @GRADESTAR_APQCDETAILS_S3_STAGE/;
    

    RETURN 'GRADESTAR_APQCDETAILS_ORCHESTRATION completed'; 

    EXCEPTION

    WHEN OTHER THEN
        -- When an error happens it will be caught by this handler and capture the error environment variables.
        let this_sqlcode varchar := SQLCODE;
        let this_sqlerrm  varchar := SQLERRM;
        let this_sqlstate varchar := SQLSTATE;
        -- It will send the information to the Error Management Solution for logging and alerting
        call EDA_COMMON_UTILITIES_DEV.ERROR_MANAGEMENT.PROCESS_ERROR_LOG(
            'GRADESTAR',
            'RUNTIME',
            'APQCDETAILS Intake',
            'Problem while ' || :current_step,
            CURRENT_DATABASE(),
            'GRADESTAR_RAW',
            'Procedure',
            'GRADESTAR_APQCDETAILS_ORCHESTRATION',
            :this_sqlcode,
            :this_sqlerrm,
            :this_sqlstate
            );
        raise;
END;