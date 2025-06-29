--liquibase formatted sql
				
--changeset raju.soankamble:GRADESTAR_RAW_1 runOnChange:true failOnError:true endDelimiter:""
--comment create the base schema for GRADESTAR
CREATE SCHEMA IF NOT EXISTS GRADESTAR_RAW;  
