-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Installation script for Oracle GoldenGate Marker table
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as the Oracle GoldenGate Schema from the same directory where SQL scripts
--    are located. 
-- 
-- 2. This script drops marker table first, so all previous data is lost, use caution if not the first time installation
--
--
-- Example of usage:
--
--      SQL> @marker_setup
--
--
-- Revision history
--  07/22/11 - SMIJATOV
--      bug 11073786: update Oracle product naming
--  02/13/08 - SRDJAN
--      No ticket: add index to marker table for much faster DUMP and debugging
--  05/23/07 - SRDJAN
--      DDL Replication initial release with Marker initial release
--

col gg_user new_value gg_user

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

prompt 
prompt Marker setup script
prompt
prompt You will be prompted for the name of a schema for the Oracle GoldenGate database objects.
prompt NOTE: The schema must be created prior to running this script.
prompt NOTE: Stop all DDL replication before starting this installation.
prompt
accept gg_user prompt 'Enter Oracle GoldenGate schema name:'
prompt




SET termout OFF
-- do not show substitutions in progress
SET verify OFF 
SET feedback OFF 
spool marker_setup_spool.txt
STORE SET 'marker_setup_set.txt' REPLACE


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
                                 chr(10) || 'Oracle GoldenGate Marker setup: ' || chr(10) ||
                                 '*** Cannot find user &gg_user' || chr(10) ||
                                 '*** Please enter existing user name.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE



SET termout OFF

prompt
prompt Using &gg_user as a Oracle GoldenGate schema name.
prompt


@params


-- make sure user can do what we need it to
GRANT CONNECT, RESOURCE, DBA TO &gg_user;

-- sequence used to populate seqNo column of marker table
DROP SEQUENCE "&gg_user"."&marker_sequence";
CREATE SEQUENCE "&gg_user"."&marker_sequence"
INCREMENT BY 1
CACHE 500
MAXVALUE 9999999999999999999999999999
CYCLE;

-- marker table creation SQL
DROP TABLE "&gg_user"."&marker_table_name";
CREATE TABLE "&gg_user"."&marker_table_name" (
                                               seqNo NUMBER NOT NULL, -- sequence number
                                               fragmentNo NUMBER NOT NULL, -- fragment number (message divided into fragments)
                                               optime CHAR(19) NOT NULL, -- time of operation
                                               TYPE VARCHAR2 (100) NOT NULL, -- type of marker
                                               SUBTYPE VARCHAR2 (100) NOT NULL, -- subtype of marker
                                               marker_text VARCHAR2 (4000) NOT NULL, -- fragment text (message divided into fragments numbered with fragmentNo)
                                               PRIMARY KEY (optime, seqNo, fragmentNo)
                                               );

CREATE INDEX "&gg_user"."&marker_index" ON "&gg_user"."&marker_table_name" (seqNo, fragmentNo);

spool OFF
SET verify ON
SET termout ON
SET feedback ON

prompt
prompt Marker setup table script complete, running verification script...
@marker_status &gg_user

prompt 
prompt Script complete.

