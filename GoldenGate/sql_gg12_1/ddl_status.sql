-- Copyright (c) 2005, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Obtain status of GoldenGate DDL Replication Installation
-- This scripts displays all relevant info in human readable form as well as analyzes it
-- to reach the final SUCCESS or FAILURE status
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
-- 
-- 2. Command line arguments (when executing from SQL*Plus)
--      &1 is GoldenGate Schema that must exist prior to executing this script
--          Notes: This parameter is mandatory. 
--          This parameter must match schema used to install marker table and DDL Replication.
--
--    For example:
--    SQL> @ddl_status GGS_USER 
--
--
-- Revision history
-- 
Rem    MODIFIED   (MM/DD/YY)
Rem    praghuna    02/21/12  - Backport praghuna_ddl_trig1 from main
Rem    msingams    06/14/11  - bug-12344560: Remove GETTABLESPACESIZE references
--  06/30/2009 - SRDJAN
--    No ticket: eliminate environment issue when executing this script standalone
--  06/09/2009 - SRDJAN
--    OS-9270: eliminate possible deadlock situation in DDL trigger
--  04/17/09 - SRDJAN
--    No ticket: add enabled/disable status of trigger
--  10/22/08 - SRDJAN
--    OS-7835: UK are now calculated based on nullable/virtual property with first alphabetical key taken
--  05/08/08 - SRDJAN
--	  FP 18116: performance: tracing can be turned off, new STAYMETADATA parameter
--  08/29/07 - SRDJAN
--		FP 15785: status will now report DDL trigger status as well (enabled/disabled)
--  08/01/07 - SRDJAN
--		FP 15507: allow end user to supply name of schema or ask for it
--  05/23/07 - SRDJAN
--		Status utility for DDL replication




col gg_user new_value gg_user
col ddl_hist_table_alt new_value ddl_hist_table_alt

@params

prompt Please enter the name of a schema for the GoldenGate database objects:
SET termout OFF
define mypar=&1
SELECT upper('&mypar') AS gg_user FROM dual;

-- ALT table is used to speed up access to metadata (all info is in metadata)
SELECT upper('&ddl_hist_table') || '_ALT' AS ddl_hist_table_alt FROM dual;


SET termout ON
prompt Setting schema name to &gg_user
SET termout OFF
SET termout ON

-- do not show substitutions in progress
SET verify OFF 
SET FEEDBACK OFF

-- Verification process checks status of each and every object
-- created by DDL replication for existance and/or errors.

-- First stage is to display this information in human readable form

prompt
prompt CLEAR_TRACE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'CLEAR_TRACE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'CLEAR_TRACE' AND TYPE = 'PROCEDURE';

prompt
prompt CREATE_TRACE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'CREATE_TRACE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'CREATE_TRACE' AND TYPE = 'PROCEDURE';


prompt
prompt TRACE_PUT_LINE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'TRACE_PUT_LINE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'TRACE_PUT_LINE' AND TYPE = 'PROCEDURE';


prompt
prompt INITIAL_SETUP STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'INITIAL_SETUP' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'INITIAL_SETUP' AND TYPE = 'PROCEDURE';


prompt
prompt DDLVERSIONSPECIFIC PACKAGE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLVERSIONSPECIFIC' AND TYPE = 'PACKAGE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLVERSIONSPECIFIC' AND TYPE = 'PACKAGE';


prompt
prompt DDLREPLICATION PACKAGE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE = 'PACKAGE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE = 'PACKAGE';

prompt
prompt DDLREPLICATION PACKAGE BODY STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE ='PACKAGE BODY'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE ='PACKAGE BODY';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL IGNORE TABLE"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_rules';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL IGNORE LOG TABLE"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_rules_log';

prompt
prompt DDLAUX  PACKAGE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX ' AND TYPE = 'PACKAGE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX ' AND TYPE = 'PACKAGE';

prompt
prompt DDLAUX PACKAGE BODY STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX' AND TYPE ='PACKAGE BODY'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX' AND TYPE ='PACKAGE BODY';

prompt
prompt SYS.DDLCTXINFO  PACKAGE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE';

prompt
prompt SYS.DDLCTXINFO  PACKAGE BODY STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE BODY'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE BODY';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL HISTORY TABLE"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_hist_table';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL HISTORY TABLE(1)"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_hist_table_alt';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL DUMP TABLES"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_tables';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL DUMP COLUMNS"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_columns';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL DUMP LOG GROUPS"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_log_groups';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL DUMP PARTITIONS"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_partitions';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "DDL DUMP PRIMARY KEYS"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_primary_keys';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Sequence does not exist    ') "DDL SEQUENCE"
FROM dba_sequences WHERE sequence_owner = '&gg_user' AND sequence_name = '&ddl_sequence';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "GGS_TEMP_COLS"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = 'GGS_TEMP_COLS';

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist       ') "GGS_TEMP_UK"
FROM dba_tables WHERE owner = '&gg_user' AND table_name = 'GGS_TEMP_UK';


prompt
prompt DDL TRIGGER CODE STATUS:
SELECT substr(to_char(a.line) || '/' || to_char(a.position), 1, 10) "Line/pos", a.text "Error" 
FROM dba_errors a, dual WHERE owner = 'SYS' AND name = '&ddl_trigger_name' AND TYPE = 'TRIGGER' 
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors a, dual WHERE owner = 'SYS' AND name = '&ddl_trigger_name' AND TYPE = 'TRIGGER' ;

SELECT decode(COUNT(*), 1, 'OK','FAILED: Trigger not found          ') "DDL TRIGGER INSTALL STATUS"
FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = '&ddl_trigger_name';

SELECT RPAD (status, 35, ' ')  "DDL TRIGGER RUNNING STATUS"
FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = '&ddl_trigger_name';


SELECT substr (VALUE, 1, 35) "STAYMETADATA IN TRIGGER" 
FROM "&gg_user"."&setup_table" 
WHERE property = 'DDL_STAYMETADATA';

SELECT substr (VALUE, 1, 35) "DDL TRIGGER SQL TRACING" 
FROM "&gg_user"."&setup_table" 
WHERE property = 'DDL_SQL_TRACING';


SELECT substr (VALUE, 1, 35) "DDL TRIGGER TRACE LEVEL" 
FROM "&gg_user"."&setup_table" 
WHERE property = 'DDL_TRACE_LEVEL';

SELECT VALUE || '/' || '&trace_file' "LOCATION OF DDL TRACE FILE"
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;



-- finally, analyze the information for SUCCESS or FAILURE 

prompt
prompt Analyzing installation status...
prompt
variable finalRes VARCHAR2(1000)
exec :finalRes := "&gg_user".ddlora_verifyDDL ();

SELECT :finalRes "STATUS OF DDL REPLICATION" FROM dual;

undefine 1

SET verify ON
SET FEEDBACK ON
