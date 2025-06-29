--liquibase formatted sql
				
--changeset CHANDRAMANI:YED_SALES_1 runOnChange:true failOnError:true
--comment metadata type reference table
create or replace TABLE YED_SALES (
RedistID VARCHAR COMMENT 'Redistributor ID',
Customer VARCHAR COMMENT 'Customer',
Date VARCHAR COMMENT 'Date',
ItemID VARCHAR COMMENT 'Item ID',
Cases VARCHAR COMMENT 'Cases',
InvoiceNo VARCHAR COMMENT 'Invoice Number',
CustName VARCHAR COMMENT 'Customer Name',
CustAddr VARCHAR COMMENT 'Customer Address',
CustCityState VARCHAR COMMENT 'Customer City/State',
CustZipCode VARCHAR COMMENT 'Customer Zip Code',
BillToName VARCHAR COMMENT 'Bill To Name',
BillToAddr VARCHAR COMMENT 'Bill To Address',
BillToCityState VARCHAR COMMENT 'Bill To City/State',
BillToZipCode VARCHAR COMMENT 'Bill To Zip Code',
BuyGroup VARCHAR COMMENT 'Buy Group',
Broker VARCHAR COMMENT 'Broker',
FileName VARCHAR COMMENT 'File Name',
INSERT_DATETIME TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'Time Stamp Of Row Insert'
)COMMENT='Redistributor Sales EDI Data';

