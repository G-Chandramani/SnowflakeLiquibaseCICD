--liquibase formatted sql
				
--changeset CHANDRAMANI:STAGE_PROCESSING_1 runOnChange:true failOnError:true
--comment create the base schema for STAGE_PROCESSING
CREATE SCHEMA IF NOT EXISTS STAGE_PROCESSING;