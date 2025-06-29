--liquibase formatted sql
				
--changeset CHANDRAMANI:INGEST_YED_SALES_1 runOnChange:true failOnError:true endDelimiter:""
--comment INGEST_YED_SALES procedure

CREATE OR REPLACE PROCEDURE "INGEST_YED_SALES"("REMOVE_STAGE_FILES" BOOLEAN)
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS declare
    row_count_total integer default 0;
    file_count int default 0;
    no_file_to_process exception (-20001,'No file found in ingress stage'); 
begin
	
    select count(distinct METADATA$FILENAME) into file_count from @EDI_HQ_INGRESS
    where METADATA$FILENAME LIKE 'edi-hq/YEDSALES_%.DAT';

    if (file_count > 0) then 
    
        TRUNCATE TABLE YED_SALES;

        COPY INTO YED_SALES
        FROM 
        (
            SELECT 
                TRIM(SUBSTR($1,1,3)) as RedistID,
                TRIM(SUBSTR($1,4,9)) as Customer,
                TRIM(SUBSTR($1,13,12)) as Date,
                TRIM(SUBSTR($1,25,13)) as ItemID,
                TRIM(SUBSTR($1,38,6)) as Cases,
                TRIM(SUBSTR($1,44,8)) as InvoiceNo,
                TRIM(SUBSTR($1,52,25)) as CustName,
                TRIM(SUBSTR($1,77,50)) as CustAddr,
                TRIM(SUBSTR($1,127,20)) as CustCityState,
                TRIM(SUBSTR($1,147,5)) as CustZipCode,
                TRIM(SUBSTR($1,152,25)) as BillToName,
                TRIM(SUBSTR($1,177,50)) as BillToAddr,
                TRIM(SUBSTR($1,227,20)) as BillToCityState,
                TRIM(SUBSTR($1,247,5)) as BillToZipCode,
                TRIM(SUBSTR($1,252,30)) as BuyGroup,
                TRIM(SUBSTR($1,282,9)) as Broker,
                METADATA$FILENAME as FileName,
                current_timestamp() as INSERT_DATETIME
            from @EDI_HQ_INGRESS
        )
        PATTERN = 'edi-hq/YEDSALES_.*.DAT' 
        FILE_FORMAT = ( format_name = YED_SALES );

        if (remove_stage_files) then
            remove @EDI_HQ_INGRESS pattern = 'edi-hq/YEDSALES_.*.DAT';
        end if; 

        select count(*) into row_count_total from YED_SALES;

        if (row_count_total > 0) then 

            MERGE INTO ${EDIHQDatabaseName}.STAGE.YED_SALES as tgt USING (
                select 
                    REDISTID,
                    CUSTOMER,
                    DATE,
                    ITEMID,
                    CASES,
                    INVOICENO,
                    CUSTNAME,
                    CUSTADDR,
                    CUSTCITYSTATE,
                    CUSTZIPCODE,
                    BILLTONAME,
                    BILLTOADDR,
                    BILLTOCITYSTATE,
                    BILLTOZIPCODE,
                    BUYGROUP,
                    BROKER,
                    FILENAME,
                    INSERT_DATETIME
                from ${EDIHQDatabaseName}.RAW.YED_SALES 
            ) AS src 
            ON 
                tgt.REDISTID = src.REDISTID AND
                tgt.CUSTOMER = src.CUSTOMER AND
                tgt.DATE = src.DATE AND
                tgt.ITEMID = src.ITEMID AND
                tgt.CASES = src.CASES AND
                tgt.INVOICENO = src.INVOICENO AND
                tgt.CUSTNAME = src.CUSTNAME AND
                tgt.CUSTADDR = src.CUSTADDR AND
                tgt.CUSTCITYSTATE = src.CUSTCITYSTATE AND
                tgt.CUSTZIPCODE = src.CUSTZIPCODE AND
                tgt.BILLTONAME = src.BILLTONAME AND
                tgt.BILLTOADDR = src.BILLTOADDR AND
                tgt.BILLTOCITYSTATE = src.BILLTOCITYSTATE AND
                tgt.BILLTOZIPCODE = src.BILLTOZIPCODE AND
                tgt.BUYGROUP = src.BUYGROUP AND
                tgt.BROKER = src.BROKER
            WHEN NOT MATCHED THEN INSERT (
                REDISTID,
                CUSTOMER,
                DATE,
                ITEMID,
                CASES,
                INVOICENO,
                CUSTNAME,
                CUSTADDR,
                CUSTCITYSTATE,
                CUSTZIPCODE,
                BILLTONAME,
                BILLTOADDR,
                BILLTOCITYSTATE,
                BILLTOZIPCODE,
                BUYGROUP,
                BROKER,
                FILENAME,
                INSERT_DATETIME
            ) VALUES (
                src.REDISTID,
                src.CUSTOMER,
                src.DATE,
                src.ITEMID,
                src.CASES,
                src.INVOICENO,
                src.CUSTNAME,
                src.CUSTADDR,
                src.CUSTCITYSTATE,
                src.CUSTZIPCODE,
                src.BILLTONAME,
                src.BILLTOADDR,
                src.BILLTOCITYSTATE,
                src.BILLTOZIPCODE,
                src.BUYGROUP,
                src.BROKER,
                src.FILENAME,
                src.INSERT_DATETIME
            );

        end if;    

    end if;

    return 'Total Rows ingested: ' || sqlrowcount || ' from ' || file_count || ' file(s)';    
end;
