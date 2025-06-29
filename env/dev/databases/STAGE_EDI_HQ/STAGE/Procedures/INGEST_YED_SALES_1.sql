--liquibase formatted sql
				
--changeset CHANDRAMANI:INGEST_YED_SALES_1 runOnChange:true failOnError:true
--comment metadata type reference table
-----------------------------------------------------------------
--RECEF ID: RA_R2144  
--DATE: 2023-09-25
--DESCRIPTION:Stored Proc to load INGEST_YED_SALES Table from the S3 Bucket
--STAGE."INGEST_YED_SALES(BOOLEAN)"
--Frequency - Daily once
-----------------------------------------------------------------

CREATE OR REPLACE PROCEDURE STAGE.INGEST_YED_SALES("REMOVE_STAGE_FILES" BOOLEAN)
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS 'declare
    row_count_total integer default 0;
    file_count int default 0;
    no_file_to_process exception (-20001,''No file found in ingress stage''); 
begin
	
    select count(distinct METADATA$FILENAME) into file_count from @EDI_HQ_INGRESS
    where METADATA$FILENAME RLIKE ''edi-hq/YEDSALES_.*.dat'';

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
        PATTERN = ''edi-hq/YEDSALES_.*.dat'' 
        FILE_FORMAT = ( format_name = YED_SALES );

        select count(*) into row_count_total from YED_SALES;

        if (row_count_total > 0) then 
            
            if (remove_stage_files) then
                remove @EDI_HQ_INGRESS pattern = ''edi-hq/YEDSALES_.*.dat'';
            end if; 

            call ${EDACommonUtilDatabaseName}.STAGE_PROCESSING.RAW_TO_STAGE_INCREMENTAL_LOAD(
                CURRENT_DATABASE(), ''RAW'', ''YED_SALES'', 
                CURRENT_DATABASE(), ''STAGE'', ''YED_SALES'', 
                FALSE, FALSE
            );

        end if;    

    end if;

    return ''Total Rows inserted: '' || row_count_total || '' from '' || file_count || '' file(s)'';    
end';