--liquibase formatted sql
				
--changeset CHANDRAMANI:RAW_1 runOnChange:true failOnError:true
--comment create the base schema for RAW
CREATE SCHEMA IF NOT EXISTS RAW;