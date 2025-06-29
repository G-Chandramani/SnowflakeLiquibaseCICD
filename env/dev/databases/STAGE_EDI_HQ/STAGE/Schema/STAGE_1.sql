--liquibase formatted sql
				
--changeset CHANDRAMANI:STAGE_1 runOnChange:true failOnError:true
--comment create the base schema for STAGE
CREATE SCHEMA IF NOT EXISTS STAGE;