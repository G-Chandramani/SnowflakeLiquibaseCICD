--liquibase formatted sql
				
--changeset CHANDRAMANI:REDISTRIBUTED_SALES_EV_9 runOnChange:true failOnError:true
--comment metadata type reference table
-----------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-01
--DESCRIPTION:Redistributed sales report 
--------------------Change History (Traceability) -------------------------------
-- Defect:
-- Date:
-- Description:
---------------------------------------------------------------------------------
CREATE OR REPLACE view SUPPLY_CHAIN.REDISTRIBUTED_SALES_EV AS
SELECT DISTINCT 
a.SKEY 	     	AS   REDIS_KEY,
a.FILENAME 		AS   FILE_NAME,
a.REDISTID 		AS   LABEL,
a.REDIS_NUMBER 	AS REDIS_NUMBER,
a.BUYGROUP 		AS   BUY_GROUP,
a.BROKER 		AS	BROKER_ID,
a.CUSTOMER 		AS   CUST_NUM,
a.CUSTNAME 		AS   CUST_NAME,
a.CUSTCITYSTATE AS   CUST_CITY_STATE,
a.Brand 		AS   BRAND,
a.ITEMID 		AS	ITEM_ID,
a.TXTMD 		AS	ITEM_DESC2,
a.ProductStyle 	AS  PRODUCT_STYLE,
b.PRODUCT_LINE,
b.PRODUCT_TYPE,
b.BRAND_NAME,
b.CATEGORY,
b.SUB_CATEGORY,
b.PACK_QUANTITY,
a.INVOICENO 	AS	INVOICE_NO,
a.UPC,
a.INVOICE_DATE 	AS   INVOICE_DATE,
a.CASE_QTY 		AS   CASE_QTY,
a.WEIGHT,
a.UNIT,
a.INVOICE_PRICE,
(a.INVOICE_PRICE * a.WEIGHT ) AS TOTAL,
CASE WHEN a.AMT_TYPE <> '%' THEN (a.WEIGHT)*(a.AMOUNT/100)
     WHEN a.AMT_TYPE = '%' AND a.REDISTID = 'ALP' THEN (a.WEIGHT * a.INVOICE_PRICE)*(((a.AMOUNT/10)/100) - 0.005)
     WHEN a.AMT_TYPE = '%' AND a.REDISTID <> 'ALP' THEN (a.WEIGHT * a.INVOICE_PRICE)* ((a.AMOUNT/10)/100)
     ELSE NULL END AS BROKERAGE_ALLOWANCE,
a.PRICINGDATE AS PRICING_DATE,
a.FB_FLAG
FROM SUPPLY_CHAIN.YED_SALES_WITH_COND_CONTRACT_EV a
LEFT JOIN SUPPLY_CHAIN.MATERIAL_PROD_HIERARCHY_EV b
ON TRIM(a.ITEMID) = TRIM(LTRIM(b.MATNR,0)); 