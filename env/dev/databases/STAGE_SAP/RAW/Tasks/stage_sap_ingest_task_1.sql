--liquibase formatted sql
				
--changeset CHANDRAMANI:stage_sap_ingest_task_1 runOnChange:true failOnError:true
--comment Task for GO LIVE

CREATE OR REPLACE TASK stage_sap_ingest_task
  WAREHOUSE = DATA_ENGINEER_WH
  SCHEDULE = 'USING CRON * * * * * UTC'
  AS
  call RAW.INGESTION_MANUAL_LAUNCHER('s4p', TRUE, NULL);

  alter task stage_sap_ingest_task resume;

  grant operate on task stage_sap_ingest_task() to role DATA_ENGINEER;