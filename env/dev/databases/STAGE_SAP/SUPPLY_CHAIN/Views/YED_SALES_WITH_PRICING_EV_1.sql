
--liquibase formatted sql
				
--changeset CHANDRAMANI:YED_SALES_WITH_PRICING_EV_3 runOnChange:true failOnError:true
--comment metadata type reference table
------------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-01
--DESCRIPTION: Joining Yed sales data with Pricing history on sold to party and Material 
--considering pricing date from pricing history where Invoice date near to pricing date  
--------------------Change History (Traceability) -------------------------------
-- Defect:
-- Date:
-- Description:
---------------------------------------------------------------------------------
CREATE OR REPLACE view SUPPLY_CHAIN.YED_SALES_WITH_PRICING_EV AS

SELECT * FROM 
(
-- Considering max pricing date from available pricing dates for SOLD TO PARTY, MATERIAL and INVOICE DATE
SELECT *,ROW_NUMBER() OVER (PARTITION BY SOLDTOPARTY,MATERIAL,INVOICE_DATE ORDER BY PRICINGDATE DESC) AS RN FROM 
(
SELECT *,CASE WHEN PRICINGDATE > INVOICE_DATE THEN 0 ELSE 1 END AS FLAG FROM  -- filtering out future Pricing dates 
(
SELECT 
a.FILENAME,
a.REDISTID,
a.BUYGROUP,
a.BROKER,
a.CUSTNAME,
a.CUSTOMER,
a.CUSTADDR,
a.CUSTCITYSTATE,
TRIM(a.ITEMID) ITEMID, -- This field is having spaces in it, Used TRIM To Remove spaces 
a.INVOICENO,
a.CASE_QTY,
a.MATNR,
a.Weight,
a.Unit,
a.Brand,
a.ProductStyle,
a.UPC, 
a.TXTMD,
a.REDIS_NUMBER,
PH.MATERIAL,
PH.SOLDTOPARTY,
PH.INVOICE_PRICE,
PH.FLAG AS FB_FLAG,
TO_DATE(SUBSTRING(a.INVOICE_DATE, 1, 4) || '-' || SUBSTRING(a.INVOICE_DATE, 5, 2) || '-' || SUBSTRING(a.INVOICE_DATE, 7, 2), 'YYYY-MM-DD') AS INVOICE_DATE,
PH.PRICINGDATE
FROM SUPPLY_CHAIN.YED_SALES_EV  a
LEFT JOIN SUPPLY_CHAIN.PRICING_WITH_HISTORY_EV PH
ON a.REDIS_NUMBER = PH.SOLDTOPARTY AND TRIM(a.ITEMID) = TRIM(PH.MATERIAL) -- Using Trim as Itemid and MATERIAL Have spaces in it 
WHERE PRICINGDATE IS NOT NULL 
)
WHERE FLAG = 1
))
WHERE RN = 1

UNION 

SELECT DISTINCT 
a.FILENAME,
a.REDISTID,
a.BUYGROUP,
a.BROKER,
a.CUSTNAME,
a.CUSTOMER,
a.CUSTADDR,
a.CUSTCITYSTATE,
TRIM(a.ITEMID) ITEMID,  -- Using Trim as Itemid and MATERIAL Have spaces in it 
a.INVOICENO,
a.CASE_QTY,
a.MATNR,
a.Weight,
a.Unit,
a.Brand,
a.ProductStyle,
a.UPC, 
a.TXTMD,
a.REDIS_NUMBER,
NULL AS MATERIAL,
NULL AS SOLDTOPARTY,
NULL AS INVOICE_PRICE,
NULL AS FB_FLAG,
TO_DATE(SUBSTRING(a.INVOICE_DATE, 1, 4) || '-' || SUBSTRING(a.INVOICE_DATE, 5, 2) || '-' || SUBSTRING(a.INVOICE_DATE, 7, 2), 'YYYY-MM-DD') AS INVOICE_DATE,
NULL AS PRICINGDATE,
'99' AS FLAG,
'99' AS RN
FROM SUPPLY_CHAIN.YED_SALES_EV  a
WHERE (a.REDIS_NUMBER,TRIM(a.ITEMID)) NOT IN ( SELECT DISTINCT SOLDTOPARTY,TRIM(MATERIAL) FROM SUPPLY_CHAIN.PRICING_WITH_HISTORY_EV) 
;
