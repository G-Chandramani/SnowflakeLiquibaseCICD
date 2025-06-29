--liquibase formatted sql
				
--changeset CHANDRAMANI:ERROR_MANAGEMENT_1 runOnChange:true failOnError:true
--comment create the base schema for ERROR_MANAGEMENT
CREATE SCHEMA IF NOT EXISTS ERROR_MANAGEMENT;