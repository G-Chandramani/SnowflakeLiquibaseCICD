--liquibase formatted sql
				
--changeset CHANDRAMANI:YED_SALES_1 runOnChange:true failOnError:true
--comment Task for UAT

CREATE OR REPLACE TASK YEDSALES_INGEST
  WAREHOUSE = SAPR2
  SCHEDULE = 'USING CRON * * * * * UTC'
  AS
  CALL RAW.INGEST_YED_SALES(TRUE);

  alter task YEDSALES_INGEST resume;

  grant operate on task YEDSALES_INGEST() to role DATA_ENGINEER;