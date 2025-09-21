-- Copyright (C) 2005, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Clear GoldenGate DDL Replication Trace file
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
--
-- 2. First parameter must be the name of GoldenGate schema (where DDL replication is installed)
-- 
--    For example:
--    SQL> @ddl_cleartrace GGSUSER
--
--
-- Revision history
-- 
--  05/23/07 - SRDJAN
--		DDL Replication release
--

col gg_user new_value gg_user
prompt 
prompt Clear DDL replication trace file
prompt
prompt Please enter GoldenGate schema name (schema for GoldenGate database objects).
prompt NOTE: GoldenGate schema must be created prior to running this script.
prompt
accept gg_user prompt 'Enter GoldenGate schema name (read above first):'
prompt

@params
SET termout OFF
SELECT upper('&gg_user') AS gg_user FROM dual;

SET termout ON
exec "&gg_user".clear_trace;


