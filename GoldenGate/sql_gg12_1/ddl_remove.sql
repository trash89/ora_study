-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Remove Oracle GoldenGate DDL Replication trigger and package
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
-- 
--    For example:
--    SQL> @ddl_remove 
--
--
-- Revision history
-- 
Rem    MODIFIED   (MM/DD/YY)
Rem    smijatov    07/22/11  - bug-11073786: update oracle product naming
Rem    smijatov    07/22/11  - bug-bug 12713108: GTT tables not dropped
Rem    msingams    06/10/11  - bug-11841862: Remove BIGFILE logic for rowid

-- 05/13/2010 - SRDJAN
--   OS-BUG-9686024 - DDL_REMOVE SCRIPT FAILS SOMETIMES IF DB SERVER USES NET AUTH  
-- 04/15/2009 - SRDJAN
--   No ticket: make sure all objects dropped
--
-- 08/20/07 - SRDJAN
--   FP 15733 
--   Proper clean up of DDL objects on installation removal
--
-- 1/16/07 - SRDJAN
--   First milestone release
--   Support for object versioning
--

define setup_error_code  = '-20783' -- error code in custom error codes space for raising application error
col gg_user new_value gg_user
col ddl_hist_table_alt new_value ddl_hist_table_alt
prompt 
prompt DDL replication removal script.
prompt WARNING: this script removes all DDL replication objects and data. 
prompt
prompt You will be prompted for the name of a schema for the Oracle GoldenGate database objects.
prompt NOTE: The schema must be created prior to running this script.
prompt
accept gg_user prompt 'Enter Oracle GoldenGate schema name:'

prompt Working, please wait ...
prompt Spooling to file ddl_remove_spool.txt

set termout off
set feedback off
-- do not show substitutions in progress
set verify off 
spool ddl_remove_spool.txt
store set 'ddl_remove_set.txt' replace

SELECT upper('&gg_user') as gg_user from dual;


@params

SELECT upper('&ddl_hist_table') || '_ALT' AS ddl_hist_table_alt FROM dual;

set termout on
-- can't use constant for variable in sqlplus
-- check if user has privileges, if not, exit with message
WHENEVER SQLERROR EXIT
variable isdba VARCHAR2(30)
variable sysdba_message VARCHAR2 (2000)
BEGIN
    :sysdba_message := chr(10) || 'Oracle GoldenGate DDL Replication removal: ' || chr(10) ||
                                 '*** Currently logged user does not have SYSDBA privileges, or not logged AS SYSDBA! ' || chr(10) ||
                                 '*** Please login as SYSDBA.' || chr(10);

    SELECT sys_context('userenv','ISDBA') INTO :isdba FROM DUAL; -- use network method  for isdba determination

    IF :isdba <> 'TRUE' THEN
                raise_application_error (&setup_error_code,
                                 :sysdba_message);
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 :sysdba_message);
END;
/
WHENEVER SQLERROR CONTINUE

set termout on


SET TERMOUT OFF
-- disable trigger 
alter trigger sys .&ddl_trigger_name disable;

-- drop trigger if existed
drop trigger sys .&ddl_trigger_name;


drop procedure "&gg_user".create_trace;
    
drop procedure "&gg_user".trace_put_line;
                   

drop procedure "&gg_user".initial_setup;
    
drop function "&gg_user".ddlora_getBinObjectCount;    
    
drop function "&gg_user".ddlora_getErrorStack;

drop package "&gg_user".DDLVersionSpecific;

drop package "&gg_user".DDLReplication;

drop sequence "&gg_user".&ddl_sequence;

drop table "&gg_user".&ddl_hist_table;

drop table "&gg_user".&setup_table;

drop table "&gg_user".&ddl_hist_table_alt;
drop table "&gg_user".&ddl_dump_tables;
drop table "&gg_user".&ddl_dump_columns;
drop table "&gg_user".&ddl_dump_log_groups;
drop table "&gg_user".&ddl_dump_partitions;
drop table "&gg_user".&ddl_dump_primary_keys; 
truncate table "&gg_user".GGS_STICK;
drop table "&gg_user".GGS_STICK;
truncate table "&gg_user".GGS_TEMP_COLS;
drop table "&gg_user".GGS_TEMP_COLS;
truncate table "&gg_user".GGS_TEMP_UK;
drop table "&gg_user".GGS_TEMP_UK;
SET TERMOUT ON

spool off
set verify on
set termout on
set feedback on

prompt 
prompt Script complete.
