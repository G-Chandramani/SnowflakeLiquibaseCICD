--liquibase formatted sql
				
--changeset CHANDRAMANI:SUPPLY_CHAIN_1 runOnChange:true failOnError:true
--comment create the base schema for SUPPLY_CHAIN
CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN;