--liquibase formatted sql
				
--changeset CHANDRAMANI:GENERAL_UTILITIES_1 runOnChange:true failOnError:true
--comment create the base schema for GENERAL_UTILITIES
CREATE SCHEMA IF NOT EXISTS GENERAL_UTILITIES;