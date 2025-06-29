--liquibase formatted sql
			
--changeset CHANDRAMANI:SALEDAY_TBL_MV_1 runOnChange:true failOnError:true
--comment metadata type reference table

------------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-01
--DESCRIPTION: MV On Fall back pricing data  
------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW SUPPLY_CHAIN.SALEDAY_TBL_MV AS
SELECT * FROM ${UnstructuredDatabaseName}.SALEDAY.SALEDAY_TBL; --Parameter configured in liquibase.changelog.xml file