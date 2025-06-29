--liquibase formatted sql
				
--changeset CHANDRAMANI:FRAMEWORK_1 runOnChange:true failOnError:true
--comment create the base schema for FRAMEWORK
create schema IF NOT EXISTS FRAMEWORK; 