-- Copyright (c) 2005, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Installation script for GoldenGate Security Role
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as the SYSDBA user from the same directory where SQL scripts
--    are located. 
-- 
-- 2. This script drops role first. Make sure you don't have role named after gg_role parameter from params.sql already!
--    Otherwise specify different name there.
--
--
-- Example of usage:
--
--      SQL> @role_setup
--
--
-- Revision history
--
--  03/04/2011 - SRDJAN
--     bug 9428942: rework sequences on target side, add cycle sequences, add FLUSH SEQUENCE to GGSCI
--	09/10/08 - SRDJAN
--		OS-6033: fix privilege issue in DDL role
--
--  05/23/07 - SRDJAN
--      Security setup to make access to marker, DDL etc. easier
--

SET termout OFF
-- do not show substitutions in progress
SET verify OFF 

col gg_user new_value gg_user
col ddl_hist_table_alt new_value ddl_hist_table_alt

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error
@params

SET termout ON 

prompt 
prompt GGS Role setup script
prompt
prompt This script will drop and recreate the role &gg_role
prompt To use a different role name, quit this script and then edit the params.sql script to change the gg_role parameter to the preferred name. (Do not run the script.)
prompt
prompt You will be prompted for the name of a schema for the GoldenGate database objects.
prompt NOTE: The schema must be created prior to running this script.
prompt NOTE: Stop all DDL replication before starting this installation.
prompt
accept gg_user prompt 'Enter GoldenGate schema name:'

spool role_setup_spool.txt
STORE SET 'role_setup_set.txt' REPLACE

SET termout OFF

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
                                 chr(10) || 'GoldenGate Marker setup: ' || chr(10) ||
                                 '*** Cannot find user &gg_user' || chr(10) ||
                                 '*** Please enter existing user name.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

SET termout OFF

prompt
prompt Using &gg_user as a GoldenGate schema name.
prompt


SELECT upper('&ddl_hist_table') || '_ALT' AS ddl_hist_table_alt FROM dual;
-- set up the role
DROP ROLE &gg_role;
CREATE ROLE &gg_role;
GRANT SELECT, DELETE ON "&gg_user"."&marker_table_name" TO &gg_role;
GRANT SELECT, DELETE ON "&gg_user"."&ddl_hist_table" TO &gg_role;
GRANT SELECT, DELETE ON "&gg_user"."&ddl_hist_table_alt" TO &gg_role;

-- names of objects used for SHOW in GGSCI
define ddl_dump_tables = 'GGS_DDL_OBJECTS' -- name of DDL dump objects tables
define ddl_dump_columns = 'GGS_DDL_COLUMNS' -- name of DDL dump objects columns
define ddl_dump_log_groups = 'GGS_DDL_LOG_GROUPS' -- name of DDL dump log groups
define ddl_dump_partitions = 'GGS_DDL_PARTITIONS' -- name of DDL dump partitions
define ddl_dump_primary_keys = 'GGS_DDL_PRIMARY_KEYS' -- name of DDL dump primary keys

-- setup up security for above tables
GRANT SELECT, INSERT, DELETE ON "&gg_user"."&ddl_dump_tables" TO &gg_role;
GRANT SELECT, INSERT, DELETE ON "&gg_user"."&ddl_dump_columns" TO &gg_role;
GRANT SELECT, INSERT, DELETE ON "&gg_user"."&ddl_dump_log_groups" TO &gg_role;
GRANT SELECT, INSERT, DELETE ON "&gg_user"."&ddl_dump_partitions" TO &gg_role;
GRANT SELECT, INSERT, DELETE ON "&gg_user"."&ddl_dump_primary_keys" TO &gg_role;
-- the following will be ok only if sequences installed, but no matter if they are not
GRANT EXECUTE ON "&gg_user".replicateSequence TO &gg_role;
GRANT EXECUTE ON "&gg_user".updateSequence TO &gg_role;

spool OFF
SET verify ON
SET termout ON

prompt
prompt Role setup script complete


prompt 
prompt Grant this role to each user assigned to the Extract, GGSCI, and Manager processes, by using the following SQL command:
prompt
prompt     GRANT &gg_role TO <loggedUser>
prompt
prompt where <loggedUser> is the user assigned to the GoldenGate processes.


