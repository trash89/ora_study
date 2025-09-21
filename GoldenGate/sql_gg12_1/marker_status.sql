-- Copyright (C) 2006, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Obtain status GoldenGate Marker Installation
-- Getting all OK is sign of successfull install
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
--    SQL> @marker_verify GGS_USER 
--
--
-- Revision history
-- 
-- 08/01/07 - SRDJAN
--      Added interactivity in addition to command line parameter
-- 1/16/07 - SRDJAN
--      First milestone release
--      Support for object versioning
--


col gg_user new_value gg_user
@params

prompt Please enter the name of a schema for the GoldenGate database objects:
SET termout OFF
define mypar=&1
SELECT upper('&mypar') AS gg_user FROM dual;

SET termout ON
prompt Setting schema name to &gg_user


-- do not show substitutions in progress
SET verify OFF 
SET feedback OFF 

-- verify objects are in place

SELECT decode(COUNT(*), 1, 'OK','FAILED: Table does not exist   ') "MARKER TABLE"
FROM all_tables WHERE owner = '&gg_user' AND table_name = '&marker_table_name';


SELECT decode(COUNT(*), 1, 'OK','FAILED: Sequence does not exist') "MARKER SEQUENCE"
FROM all_sequences WHERE sequence_owner = '&gg_user' AND sequence_name = '&marker_sequence';


undefine 1

SET verify ON
SET feedback ON
