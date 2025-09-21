-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Support script for version specific Oracle logic (oracle 10g and 11g, common logic)
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. Do not execute this script
-- 
-- Revision history
--
Rem    MODIFIED   (MM/DD/YY)
Rem    msingams    06/10/11  - bug-11841862: Remove BIGFILE logic for rowid

--  08/19/2011 - SRDJAN
--    12868489: BIN$ objects are not always filtered out 
--  01/28/2011 - SRDJAN
--    OS-BUG-10394085: Improve performance of ALL supp log query
--  12/02/10 - JW
--    OS-BUG-10364034
--    Added function ddlora_getAllColsLogging().
--
--  6/24/10 - SRDJAN
--    OS-BUG-9801097: Optimize DDL processing performance across the board
-- 09/16/2010 - AJADAMS
--    OS-BUG-9830035 - AJADAMS: nested user cancel, added ddlora_getSecondaryError
-- 05/20/2010 - SRDJAN
--    OS-BUG-9421334: remove RECYCLEBIN OFF requirement from Oracle 11 db and extract
--  12/04/09 - SRDJAN
--    OS-6769: added ALLOWRECYCLEBIN to allow recyclebin on for oracle (internal param)
--  04/15/2009 - SRDJAN
--    OS-8956: make sure recyclebin is purged and disabled 
--  01/06/2009 - SRDJAN
--	  OS-8388: BIN$ objects that are not of system origin cause extract to abend
--  10/22/08 - SRDJAN
--	  Initial version (OS-7835, support for min UK columns)
--


/*
FUNCTION ggsuser.ddlora_getErrorStack RETURNS VARCHAR2
Get error stack (modules and line numbers and errors)
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_getErrorStack 
RETURN VARCHAR2
IS
	tmess VARCHAR2(&max_varchar2_size);
BEGIN
	tmess := DBMS_UTILITY.format_error_backtrace;
	IF length (tmess) > &max_varchar2_size - 5000 THEN
		tmess := SUBSTR (tmess, 5000); -- just trailing portion
	END IF;
	RETURN tmess;
END;
/

/* 
FUNCTION ggsuser.errorIsUserCancel RETURNS BOOLEAN
Get 2nd error on stack.  Returns 0 if only top level error exists
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_errorIsUserCancel
RETURN BOOLEAN
IS
        tmess                 VARCHAR2(&max_varchar2_size);
        error_is_user_cancel  BOOLEAN := FALSE;
        error_pos             INTEGER := 0;
BEGIN
        tmess := DBMS_UTILITY.format_error_stack;
        error_pos := Instr(tmess, 'ORA-01013: ', 1, 1);
        IF error_pos > 0 THEN
	    error_is_user_cancel := TRUE;
        END IF;
        RETURN error_is_user_cancel;
END;
/
show errors


/*
FUNCTION ggsuser.ddlora_getAllColsLogging RETURNS NUMBER
Determine if owner.table has all column logging for supp logging.
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_getAllColsLogging (
                                                             pobjid NUMBER)
RETURN NUMBER 
IS        
    all_log_group_exists NUMBER;
BEGIN
    BEGIN 
        SELECT COUNT(*) 
		INTO all_log_group_exists
		FROM sys.obj$ o,sys.cdef$ c 
		WHERE 
			o.obj#=pobjid 
			AND o.obj#=c.obj# 
			AND c.type#=17 
			AND rownum=1;

		EXCEPTION    			
	        WHEN OTHERS THEN
				all_log_group_exists := 0;
	END;
    RETURN all_log_group_exists;
END;
/
show errors


SET TERMOUT OFF
SET HEAD ON
-- do not check recyclebin for 11





