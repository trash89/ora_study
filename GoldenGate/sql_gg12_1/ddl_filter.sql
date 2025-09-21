-- $Header: oggcore/OpenSys/redist/SQLScripts/ddl_filter.sql /main/2 2011/10/13 13:00:55 smijatov Exp $
-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Filtering function for Oracle GoldenGate DDL replication
-- You can write code where 'computer retVal here' comment is.
-- Do not change the rest unless consulted with Oracle first.
-- This code must compute string 'INCLUDE' or 'EXCLUDE' into retVal variable.
-- If it computes 'EXCLUDE', DDL will be excluded from processing
-- and vice versa. You can use input parameters to determine if
-- it will be included or not.
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- Customizing this file requires recompilation of it (DDL trigger does not need be recompiled).
-- Use with caution. Ignoring DDL operations may cause malfunction of DDL replication.
-- You are responsible for proper functioning of the code you write.
-- WARNING: restrict filtering of DDL only to user-DDLs (DDLs you actually execute).
-- Filtering system related (or implied) DDLs without Oracle's approval
-- may cause issues.
-- Note: always run @ddl_status prior to compiling this script, and after compiling it.
--
-- To run:
-- @ddl_filter schema_name
-- where schema_name is schema where Oracle GoldenGate DDL objects are installed
--
-- Revision history
-- 
-- 09/26/2010 - SRDJAN
--    12989410: Added DDL text 
-- 06/22/2010 - SRDJAN
--    OS-BUG-9801097: Initial revision


set verify off
col gg_user new_value gg_user

@params
SELECT upper('&1')  AS gg_user  FROM dual;


/*
FUNCTION filterDDL RETURNS VARCHAR2
This function by default returns 'INCLUDE'. If modified, DDL trigger must be recompiled
with NORMAL option. Once modified by non-Oracle personnel, it is no longer supported by Oracle.

param[in] STMT                           VARCHAR2                up to 32K of le ading DDL text
param[in] ORA_OWNER                      VARCHAR2                owner of DDL object
param[in] ORA_NAME                       VARCHAR2                name of DDL object
param[in] ORA_OBJTYPE                    VARCHAR2                type of DDL object (table, index etc)
param[in] ORA_OPTYPE                     VARCHAR2                optype of DDL (create, alter etc)

return 'INCLUDE' or 'EXCLUDE'. If 'INCLUDE', DDL will be processed for DDL replication, not so if 'EXCLUDE'
*/

CREATE OR REPLACE FUNCTION "&gg_user".filterDDL (	
    stmt IN VARCHAR2,
	ora_owner IN VARCHAR2,
	ora_name IN VARCHAR2,
	ora_objtype IN VARCHAR2,
	ora_optype IN VARCHAR2
)
RETURN VARCHAR2
IS
retVal VARCHAR2(&name_size);
errorMessage VARCHAR2(&message_size); 
BEGIN
		
    retVal := 'INCLUDE';

	--
	--
	--  DO NOT CUSTOMIZE BEFORE THIS COMMENT
	--
	--


	-- CUSTOMIZE HERE: compute retVal here. It must be either 'INCLUDE' or 'EXCLUDE'.
    -- if it is 'EXCLUDE', DDL will be excluded from DDL trigger processing
    -- and vice versa. Use input parameters to this function to perform this
    -- computation.
    --
    --
                                                    
    --
    --
    -- DO NOT CUSTOMIZE AFTER THIS COMMENT   
    --
    --
	
	IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDL', 'Returning ' || retVal || ' from filterDDL');
        END IF;
	RETURN retVal;    
	
	EXCEPTION 
    WHEN OTHERS THEN 
        errorMessage := 'filterDDL:' || SQLERRM; 
        dbms_output.put_line (errorMessage);
        RAISE;
END;
/
show errors
