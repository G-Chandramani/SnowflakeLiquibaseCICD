--liquibase formatted sql
				
--changeset CHANDRAMANI:GRADESTAR_STAGE_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the base schema for GRADESTAR
CREATE SCHEMA IF NOT EXISTS GRADESTAR_STAGE;