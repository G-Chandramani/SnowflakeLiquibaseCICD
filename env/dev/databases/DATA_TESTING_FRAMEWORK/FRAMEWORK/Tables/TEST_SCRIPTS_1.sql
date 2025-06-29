--liquibase formatted sql
				
--changeset CHANDRAMANI:TEST_SCRIPTS_1 runOnChange:true failOnError:true
--comment test script details
create TABLE IF NOT EXISTS TEST_SCRIPTS (
	TEST_ID NUMBER(38,0) NOT NULL autoincrement COMMENT 'Auto assigned ID',
	TEST_NAME VARCHAR(16777216) NOT NULL COMMENT '{REQUIRED} Simple but descriptive name for the test',
	TEST_DESCRIPTION VARCHAR(16777216) COMMENT 'Description and/or details of the test case',
	TEST_CLASS VARCHAR(16777216) COMMENT 'Test grouping (Best if all class groups are also grouped by their Schema Name)',
	TEST_TYPE VARCHAR(16777216) NOT NULL COMMENT '{REQUIRED} Values: PROC, SCRIPT to identify how it will be executed',
	PROC_NAME VARCHAR(16777216) COMMENT 'Format: <SCHEMA>.<PROC_NAME>. Must be in the DATA_TESTING_FRAMEWORK_<ENV> databas and... Must have a value if the TEST_TYPE = \"PROC\"',
	SOURCE_SCRIPT VARCHAR(16777216) COMMENT 'Must return only one column and one row (singleton). Must have a value if the TEST_TYPE = \"SCRIPT\". Use {ENV} for the database <ENV> suffix for dynamic environment assignment',
	TARGET_SCRIPT VARCHAR(16777216) COMMENT 'Must return only one column and one row (singleton). Must have a value if the TEST_TYPE = \"SCRIPT\". Use {ENV} for the database <ENV> suffix for dynamic environment assignment',
	COMPARISON_OPERATOR VARCHAR(16777216) COMMENT 'Operator that is used to evaluate the comparison with the test (EQ, NE, GT, LT, GE, LE, ????) Must have a value if the TEST_TYPE = \"SCRIPT\"',
	CREATE_TS TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'When the record was created. Default current_timestamp()',
	CREATED_BY VARCHAR(16777216) DEFAULT CURRENT_USER() COMMENT 'Active user when the record was created. Default current_user()'
)COMMENT='Contains the metadata needed to execute test cases with the FRAMEWORK.SP_EXECUTE_TEST_SCRIPT procedure'
;