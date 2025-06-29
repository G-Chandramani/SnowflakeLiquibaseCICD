--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_INGEST_TASK_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the base task for GRADESTAR
CREATE OR REPLACE TASK GRADESTAR_INGEST_TASK
  WAREHOUSE = DATA_ENGINEER_WH --STAGE_PROCESSING_DEV_TEST_WH
  SCHEDULE = 'USING CRON * * * * * America/Los_Angeles'
  AS
  BEGIN
    CALL GRADESTAR_APQCDETAILS_ORCHESTRATION();
    CALL GRADESTAR_APQCHEADERS_ORCHESTRATION();
    CALL GRADESTAR_APQCPICTURES_ORCHESTRATION();
  END;
--changeset CHANDRAMANI:GRADESTAR_INGEST_TASK_2 runOnChange:true failOnError:true endDelimiter:""
--comment create the base task for GRADESTAR
ALTER TASK GRADESTAR_INGEST_TASK RESUME ; 