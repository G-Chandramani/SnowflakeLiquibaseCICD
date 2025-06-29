--liquibase formatted sql
				
--changeset CHANDRAMANI:RAW_PROCESSING_1 runOnChange:true failOnError:true
--comment create the base schema for RAW_PROCESSING
CREATE SCHEMA IF NOT EXISTS RAW_PROCESSING;