-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Removal script for Oracle GoldenGate Marker table
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as the Oracle GoldenGate Schema from the same directory where SQL scripts
--    are located. 
-- 
--
-- Example of usage:
--
--      SQL> @marker_remove
--
--
-- Revision history
--  07/22/11 - SMIJATOV
--      bug 11073786: update Oracle product naming 
--  05/23/07 - SRDJAN
--		DDL Replication release with marker support

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

col gg_user new_value gg_user
prompt 
prompt Marker removal script. 
prompt WARNING: this script removes all marker objects and data.
prompt
prompt You will be prompted for the name of a schema for the Oracle GoldenGate database objects.
prompt NOTE: The schema must be created prior to running this script.

prompt
accept gg_user prompt 'Enter Oracle GoldenGate schema name:'



SET termout OFF
-- do not show substitutions in progress
SET verify OFF 
spool marker_remove_spool.txt
STORE SET 'marker_remove_set.txt' REPLACE
SELECT upper('&gg_user') AS gg_user FROM dual;


@params


SET termout ON
-- verify logged user privileges
WHENEVER SQLERROR EXIT
variable curr_user_name VARCHAR2(30)
BEGIN
    SELECT 
        username
    INTO
        :curr_user_name
    FROM v$pwfile_users 
    WHERE username = sys_context('USERENV', 'CURRENT_USER') AND SYSDBA = 'TRUE';
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Currently logged user does not have SYSDBA privileges! ' || chr(10) ||
                                 '*** Please login as SYSDBA.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

SET termout ON

-- sequence used to populate seqNo column of marker table
DROP SEQUENCE "&gg_user"."&marker_sequence";
-- marker table creation SQL
DROP TABLE "&gg_user"."&marker_table_name";

spool OFF
SET verify ON
SET termout ON

prompt 
prompt Script complete.
