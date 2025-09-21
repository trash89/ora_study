-- Copyright (C) 2006, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Set Tracing Level for GoldenGate DDL Replication trigger
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
--
--    For example:
--    SQL> @ddl_tracelevel
--
--    Note:	supported trace levels are 0, 1, 2 (higher number more info)
--
-- Revision history
-- 
--  05/08/08 - SRDJAN
--	  FP None: verify that user and tracelevel are acceptable values
--  05/23/07 - SRDJAN
--      DDL Replication release
--

SET verify OFF 
col gg_user new_value gg_user

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

prompt 
prompt Set DDL replication trace level script. 
prompt
prompt Please enter GoldenGate schema name (schema for GoldenGate database objects).
prompt NOTE: GoldenGate schema must be created prior to running this script.
prompt
accept gg_user prompt 'Enter GoldenGate schema name (read above first):'
prompt
accept gg_trace_level prompt 'Please enter trace level:'

SET termout OFF


spool ddl_trace_setup_spool.txt
STORE SET 'ddl_trace_setup_set.txt' REPLACE
@params


SELECT upper('&gg_user') AS gg_user FROM dual;

SET termout ON

-- check if entered user name exists
WHENEVER SQLERROR EXIT
variable user_name VARCHAR2(30)
BEGIN
    SELECT 
        username
    INTO
        :user_name
    FROM all_users
    WHERE username = '&gg_user';
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Cannot find user &gg_user' || chr(10) ||
                                 '*** Please enter existing user name.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

-- check if trace level correct
WHENEVER SQLERROR EXIT
variable trace_l NUMBER
BEGIN
	IF upper (to_char ('&gg_trace_level')) <> 'NONE' THEN		
		:trace_l := to_number (to_char ('&gg_trace_level'));
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL tracelevel setup:' || chr(10) ||
                                 '*** Tracelevel must be number 0 or higher, or NONE' || chr(10) ||
                                 '*** Please enter valid tracelevel.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE
SET termout OFF

DELETE FROM "&gg_user"."&setup_table" WHERE property = 'DDL_TRACE_LEVEL';
INSERT INTO "&gg_user"."&setup_table" (
    property,
    VALUE)
VALUES 
    (
    'DDL_TRACE_LEVEL',
    to_char ('&gg_trace_level'));

COMMIT WORK;

spool OFF
SET verify ON
SET termout ON
prompt
prompt Script complete, running verification script...

-- show that is' changed
@ddl_status &gg_user


