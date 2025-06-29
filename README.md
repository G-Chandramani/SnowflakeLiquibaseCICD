# Snowflake Data Analytics Database Project

The Snowflake Data Analytics Database Project (https://github.com/LambWestonIT/{REPO_NAME}) project contains [AWS Step Functions](https://aws.amazon.com/step-functions) used for preparing Snowflake Data Analytics Database Project data for ingestion into SnowFlake.

## Getting Started

### Prerequisites
* [GIT](https://git-scm.com/) - Source Control
* [Liquibase Docker Image](https://github.com/liquibase/docker) - Serverless fully contained container with Snowflake jdbc drivers
* [Liquibase](https://docs.liquibase.com) - An an open-source database schema change management solution that enables you to manage revisions of your database changes. Image is contained in Docker. 
* [Snowflake](https://www.snowflake.com/) - Target database for the project is Snowflake. Snowflake documentation can be found at https://docs.snowflake.com/en/index.html.

##Liquibase Setup
## Database liquibase.changelog.xml Structure
The changesets will execute in the order they are included in the master changelog file.  This means a changeset must follow the changesets on which it depends.  The current recommended order is:
1. Schema changesets
2. Table changesets
3. View changesets
4. Function changesets

There are two different types of changesets:
1. Those that will be run once and should never be modified.
2. Those that will be run every time and should have changes made directly to the existing changelog file.

Changesets that should only ever be run once would include *USER* operations, *ROLE* operations, *SCHEMA* operations and *TABLE* operations.

Changesets that should be run every time would include *VIEW* operations, *FUNCTION* operations. 

## Changeset Numbering
```
0.1 = USER initial changeset
1.0 = ROLE initial changeset
2.0 = SCHEMA initial changeset
3.0 = master_schema TABLE initial changeset
4.0 = master_schema VIEW runAlways changeset
5.0 = master_schema FUNCTION runAlways changeset
```
Additional run once changeset numbers should be the initial changeset number with a *.X* appended.  Where X is incremental.
EX:
```
1.0 is the first additional changeset to the ROLE operations
1.1 is the second additional changeset to the ROLE operations
```

## Run Once Changeset - Best Practice
Run once changesets should be an sql file located in the appropriate *changelogs* directory.
If the change is project related, then the file should include the task number (e.g. Jira ID) or equivalent.
If the change is operations related, then the file name should reference a service ticket number (e.g. ServiceNow request or incident ID).
The filename should be *originating_id-<< changeset_number >>.sql*.
The file must start with:
```sql
--liquibase formatted sql

--changeset <<author_name>>:<<changeset_number>>-<<changeset_title>> runOnChange:false failOnError:false
```
The file should be included in the changelog master immediately below the preceding changeset.
EX:
```xml
<include file="/dev/database/data_analytics/mp1970.sql"/>
<include file="/dev/database/data_analytics/req2039.sql"/>
<include file="/dev/database/data_analytics/inc60302.sql"/>
<include file="/dev/database/data_analytics/data_analytics_runalways.sql"/>
```

## Modify Run Once Changeset - Best Practice
If you modify a run once changeset, then set the "runOnChange" parameter to "unOnChange:true" and update the changeset number. If you fail to update the changeset number
the operation will fail.

## Run Every Time Changeset - Best Practice
**_FIRST_** - verify that the needed changeset files do not already exist, if they do, just modify them.
Run every time changesets should have an xml file located in the appropriate *changelogs* directory and an sql file located in the appropriate *sql* directory.

The xml file should look like:
```xml
<?xml version="1.1" encoding="UTF-8" standalone="no"?>
<databaseChangeLog
  xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                      http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">

  <!-- ************** create database and schema ************** -->
  <include file="/changelogs/tables/changelog-1.0.sql"/>
  <!-- ************** create table ************** -->
  <include file="/changelogs/tables/changelog-1.1.sql"/>

</databaseChangeLog>

```
The *runAlways* attribute tells Liquibase to always execute this changeset.
The *<validCheckSum>ANY</validCheckSum>* sub-tag tells Liquibase not to validate the changeset's checksum.  Otherwise modifications to the files will cause validation to fail and prevent all remaining changesets from executing.
The xml file should be included in the changelog master with similar run every time changesets.
EX:
```xml
<include file="/changelogs/views/changelog-1.0.xml"/>
```

The sql file filename should be named to easily identify what types of changes are being made.
- The sql file should contain only sql and may contain comments.
- Every CREATE should either be CREATE OR REPLACE or immediately preceded by a DROP _____ IF EXISTS.
- Always assume the object you are creating/updating simultaneously exists and does not exist at the same time.

## Modify Run Every Time Changeset - Best Practice
- Change whatever you need to change and add whatever you need to add to the sql file, but the xml file probably does not need to be modified.
- Every CREATE should either be CREATE OR REPLACE or immediately preceded by a DROP _____ IF EXISTS.
- Every static data INSERT should be preceded by a TRUNCATE TABLE.
- Always assume the object you are creating/updating simultaneously exists and does not exist at the same time.


## Local Development
###Docker Image

### Manual Setup

1. Download the snowflake JDBC jar driver. https://search.maven.org/classic/#search%7Cga%7C1%7Csnowflake-jdbc
2. Download liquibase. Currently tested with version 3.5.3. https://download.liquibase.org/download/?frm=n
3. Install Liquibase
```bash
brew install liquibase
```
4. Set the Liquibase location env var
```bash
export LIQUIBASE_HOME=/usr/local/opt/liquibase/libexec
```
5. Copy snowflake JDBC jar to the repo root folder
    - All the .jar files will be ignored by git (check .gitignore)
8. Create a *liquibase.properties* file in the root directory of this repo (All .properties files will automatically be ignored by Git)
```
driver=net.snowflake.client.jdbc.SnowflakeDriver
url=jdbc:snowflake://<<account_name>>.snowflakecomputing.com/?db=<<snowflake_dev_database_name>>&database=<<target_db_name>>&schema=DEPLOYMENT&warehouse=<<warehouse_name>>
username: <<your_snowflake_devusername>>
password: <<your_snowflake_dev_password>>
changeLogFile=<<local_path>>changelog-master.xml
logLevel=debug
liquibaseSchemaName: DEPLOYMENT
classpath=snowflake-jdbc-3.9.1.jar

```
11. Run Liquibase
w/o modifying the DB:
```bash
liquibase validate
```
Modify the DB:
```bash
liquibase update
```
	
## Deployment
The git commit strategy for this repository is to commit directly to the trunk main branch. There is no creation of features branches. The reason for this
is that in database development, feature branches tend to be long-running. This is because the process for production deployment of
code can be delayed by project and user acceptance dependencies. These long-running feature branches can create unnecessary inter-object
pull request dependencies which results in complex cherry-picking to move into an upper environment.

In the direct to trunk strategy, the deployment pipeline up environments is managed through directories inside the repository. The 
directory is as follows:
/env/<<environment_short_name>>/database/<<database_name>>

To promote a set of changes from one environment to another simply involves the following steps:
1. copy the SQL files that contain the select changes from the environment folder and paste them into target folder
2. Update target database liquibase.changelog.xml to include new sql files
3. Commit changes to git.  

## Github Environments
There are github environments defined for each target database environment. This may be extended to include environments for target Snowflake
accounts and databases. The environments contain Github secrets to store snowflake schema manager username and password variables. If these require a change,
they should be updated at the environment level. 
The environment is also referenced in the action .yaml to manage deployments into an environment.

### Github Actions
There are github actions defined to manage the deployment in a commit to trunk strategy. All actions refer to the specific Github Environment name
in their job. The inclusion of the environment tells Github to use secrets at the environment level if they exist. If the secret does
not exists, then Github will for the secret at the repository level and finally at the organization level.

### Github Action Filters
A GitHub action is triggered when a commit is made to a file located under a specific directory filter. The filter is based on the
repository folder structure of <<environment_short_name>>/database. The following is an example of this filter:
  push:
    branches: [ main ]
    paths: '**/dev/databases/**'
	
If a new environment is added to Snowflake, then a new action should be created for that environment.

## TODO

## Troubleshooting

## Caveats

## References
1. http://www.liquibase.org/documentation/index.html
1. https://medium.com/@Python_Primer/how-i-used-liquibase-and-cloudformation-to-version-and-instrument-my-rds-db-6915e73d8c88
