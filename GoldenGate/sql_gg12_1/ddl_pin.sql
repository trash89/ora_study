-- Copyright (C) 2006, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Pin GoldenGate DDL Replication code
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
-- 
-- 2. Command line arguments (when executing from SQL*Plus)
--    None
--
--    For example:
--    SQL> @ddl_pin GGS_USER
--
--   Note: dmbs_shared_pool system package must be installed before running this script
--   Note: this script should be invoked as part of database startup
--
-- Revision history
-- 
--  05/23/07 - SRDJAN
--      Pin package in memory for performance
--


-- do not show substitutions in progress: uncomment the following line
SET verify OFF 

@params


exec dbms_shared_pool.keep('&1 .DDLReplication', 'P'); 
exec dbms_shared_pool.keep('&1 .trace_put_line', 'P'); 
exec dbms_shared_pool.keep('SYS. &ddl_trigger_name', 'R'); 

SET verify ON
