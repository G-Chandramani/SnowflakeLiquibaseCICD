--liquibase formatted sql
				
--changeset CHANDRAMANI:YED_SALES_EV_1 runOnChange:true failOnError:true
--comment metadata type reference table

------------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-01
--DESCRIPTION: MV On Yed sales table data from EDI  
------------------------------------------------------------------

CREATE OR REPLACE MATERIALIZED VIEW SUPPLY_CHAIN.YED_SALES_MV AS
SELECT DISTINCT 
a.FILENAME,
a.REDISTID,
a.BUYGROUP,
a.BROKER,
a.CUSTNAME,
a.CUSTOMER,
a.CUSTADDR,
a.CUSTCITYSTATE,
LTRIM(a.ITEMID, '0') AS ITEMID,
a.INVOICENO,
a.DATE AS INVOICE_DATE,
LTRIM(a.CASES, '0')  as CASE_QTY
FROM ${EDIHQDatabaseName}.STAGE.YED_SALES a --Parameter configured in liquibase.changelog.xml file