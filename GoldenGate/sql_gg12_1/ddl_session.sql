--
-- GoldenGate Software
-- Copyright 2009
-- San Francisco, CA, USA
-- All rights reserved.
--
-- Program description:
-- Support script for proceeding with DDL installation in case of other sessions active
-- DO NOT RUN THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. Do not execute this script
-- 
-- Revision history
--
--  06/25/2009 - SRDJAN
--    OS-6683: Initial version

col check_sess new_value check_sess

SET TERMOUT ON
-- Ask for proceeding
prompt
prompt To proceed, enter yes. To stop installation, enter no.
prompt
accept check_sess prompt 'Enter yes or no:'
prompt

SET termout OFF

SELECT upper('&check_sess') AS check_sess FROM dual;

SET termout ON
-- check if user entered yes
WHENEVER SQLERROR EXIT
BEGIN
    IF upper('&check_sess') <> 'YES' THEN
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** User cancelled installation.' || chr(10));
    END IF;
END;
/
WHENEVER SQLERROR CONTINUE
SET termout OFF
