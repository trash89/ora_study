-- Copyright (C) 2006, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Disable GoldenGate DDL Replication trigger
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
--    SQL> @ddl_disable
--
--
-- Revision history
-- 
--  05/23/07 - SRDJAN
--		DDL Replication release
--


-- do not show substitutions in progress: uncomment the following line
SET verify OFF 

@params


-- disable trigger
ALTER TRIGGER sys.&ddl_trigger_name DISABLE;

SET verify ON
