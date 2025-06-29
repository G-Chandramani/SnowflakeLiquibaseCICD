--liquibase formatted sql
				
--changeset CHANDRAMANI:YED_SALES_EV_4 runOnChange:true failOnError:true
--comment metadata type reference table
-----------------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-01
--DESCRIPTION: Yed Sales Data from EDI 
--------------------Change History (Traceability) -------------------------------
-- 2023-10-04 Changed weight logic as (YS.CASE_QTY * MAT.NTGEW) as WEIGHT
-- Defect:#5092
-- Date:2023-10-04
-- Description:Lbs are not being calculated correctly by the report.  
-- Cases are being duplicated insetad.  Calculation of Lbs x Price to then calculate 
-- brokerage cannot work until the Lbs issues is fixed.  Connected to scripts 42762 and 42764
--INC0428517 - Removed leading zeroes from case quantity column
---------------------------------------------------------------------------------
create OR REPLACE view SUPPLY_CHAIN.YED_SALES_EV AS
WITH YS AS
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
a.ITEMID,
a.INVOICENO,
a.INVOICE_DATE,
TRY_CAST(a.CASE_QTY AS INTEGER) as CASE_QTY
FROM SUPPLY_CHAIN.YED_SALES_MV  a
),

MAT AS
(
SELECT DISTINCT LTRIM(a.MATNR, '0') AS MATNR,--a.NTGEW  as Weight,
a.GEWEI as Unit,a.NTGEW, a.ZMM_PRODH3 as Brand,
a.ZMM_PRODH4 AS ProductStyle,d.UMREZ,d.UMREN, b.MEINH,b.EAN11 AS UPC, c.TXTMD
FROM STAGE."0MATERIAL_ATTR" a
LEFT JOIN 
(SELECT DISTINCT LTRIM(MATNR, '0') AS MATNR,MEINH, EAN11 FROM STAGE."0MAT_UNIT_ATTR" WHERE NUMTP = 'UC') b 
on a.MATNR = b.MATNR
LEFT JOIN 
(SELECT DISTINCT LTRIM(MATNR, '0') AS MATNR,UMREZ,UMREN FROM STAGE."0MAT_UNIT_ATTR" WHERE MEINH = 'CS') d 
on a.MATNR = d.MATNR
LEFT JOIN ( SELECT DISTINCT MATNR,TXTMD FROM STAGE."0MATERIAL_TEXT" WHERE SPRAS = 'E') c
on a.MATNR = c.MATNR 
order by LTRIM(a.MATNR, '0') 
),

REDIS AS
(
SELECT DISTINCT a.IDNUMBER,a.PARTNER PARTNER --,b.PARTNER PARTNER_S
FROM 
(
SELECT DISTINCT IDNUMBER, PARTNER FROM STAGE."0BP_ID_ATTR" 
WHERE TYPE = 'ZBUP10'  AND IDNUMBER NOT LIKE '%1'
)  a
LEFT JOIN 
(
SELECT DISTINCT IDNUMBER, PARTNER FROM STAGE."0BP_ID_ATTR" 
WHERE TYPE = 'ZBUP10'  AND IDNUMBER NOT LIKE '%1'
UNION 
SELECT DISTINCT LEFT(IDNUMBER,LENGTH(IDNUMBER)-1) IDNUMBER,PARTNER FROM STAGE."0BP_ID_ATTR"
WHERE TYPE = 'ZBUP10' AND IDNUMBER LIKE '%1'
) b
on a.IDNUMBER = b.IDNUMBER
)

SELECT  
YS.FILENAME,
YS.REDISTID,
YS.BUYGROUP,
YS.BROKER,
YS.CUSTNAME,
YS.CUSTOMER,
YS.CUSTADDR,
YS.CUSTCITYSTATE,
YS.ITEMID,
YS.INVOICENO,
YS.INVOICE_DATE,
YS.CASE_QTY,
MAT.MATNR,
CASE WHEN (MAT.UMREZ IS NULL OR MAT.UMREN IS NULL) THEN YS.CASE_QTY
     ELSE YS.CASE_QTY * (MAT.UMREZ/MAT.UMREN) END AS WEIGHT,
MAT.Unit,
MAT.Brand,
MAT.ProductStyle,
MAT.MEINH,
MAT.UPC, 
MAT.TXTMD,
P.PARTNER REDIS_NUMBER 
FROM YS
LEFT JOIN REDIS P 
ON YS.REDISTID = P.IDNUMBER 
LEFT JOIN MAT
ON YS.ITEMID = MAT.MATNR;