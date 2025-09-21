-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Support script for version specific Oracle logic (oracle 10g)
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. Do not execute this script
-- 
-- Revision history
-- 
--  12/06/2011 - CTONG
--    bug 13430265: Exclude hidden column from uk_curs
--  01/18/2011 - SRDJAN
--    OS-BUG-11067769: unique index doesn't consider system generated cols (such as for function indexes)
-- 12/15/2010 - SRDJAN
--    OS-BUG-10326012 : if table has ONLY securefile lobs (encrypted), do not use TDE
-- 05/20/2010 - SRDJAN
--    OS-BUG-9421334: remove RECYCLEBIN OFF requirement from Oracle 11 db and extract 
--  06/12/09 - JW
--    OS-9228
--    Filter out invalidated keys (including primary key) in 
--    CURSOR uk_curs.
--
--  6/24/10 - SRDJAN
--    OS-BUG-9801097: Optimize DDL processing performance across the board
--  11/10/08 - SRDJAN
--    OS-8020: Use correct key in respect to RELY and ENABLE
--  10/24/08 - SRDJAN
--    OS-7879: Calculate UDT correctly and use it correctly in UK as well
--  10/22/08 - SRDJAN
--    OS-7835: UK are now calculated based on nullable/virtual property with first alphabetical key taken
--  04/29/08 - SRDJAN
--	  FP 18116: using high performance queries in DDL trigger
--  03/27/08 - SRDJAN
--	  FP 17821: add more error handling
--  10/05/07 - SRDJAN
--    FP 16267: ignore BIN$ objects in case recycle bin is accidentally enabled. Make sure recyclebin is disabled
--  08/15/07 - SRDJAN
--      Fixed Recyclebin installation problems
--  05/23/07 - SRDJAN
--      Oracle 10g specific support code
--


@ddl_ora10upCommon.sql


CREATE OR REPLACE PACKAGE "&gg_user".DDLVersionSpecific AS
--  unique keys
CURSOR uk_curs (powner IN VARCHAR2, ptable IN VARCHAR2) IS
    SELECT key.key_name index_name, 
                    key.column_name,
                    key.descend 
               FROM (SELECT c.constraint_name key_name, 
                            c.column_name column_name, 
                            c.position position,
                            'ASC' descend  
                       FROM dba_cons_columns c 
                      WHERE c.owner = powner 
                        AND c.table_name = ptable 
                        AND c.constraint_name in ( 
                              SELECT con1.name 
                                FROM sys.user$ user1, 
                                     sys.user$ user2, 
                                     sys.cdef$ cdef, 
                                     sys.con$ con1, 
                                     sys.con$ con2, 
                                     sys.obj$ obj1, 
                                     sys.obj$ obj2 
                              WHERE user1.name = powner 
                                 AND obj1.name = ptable 
                                 AND cdef.type# = 3 
                                 AND bitand(cdef.defer, 36) = 4 
                                 AND (cdef.type# = 5 OR 
                                      cdef.enabled is not null) 
                                 AND con2.owner# = user2.user#(+) 
                                 AND cdef.robj# = obj2.obj#(+) 
                                 AND cdef.rcon# = con2.con#(+) 
                                 AND obj1.owner# = user1.user# 
                                 AND cdef.con# = con1.con# 
                                 AND cdef.obj# = obj1.obj#) 
                      AND EXISTS ( 
                          SELECT 'x' 
                            FROM dba_tab_columns t 
                           WHERE t.owner = c.owner 
                             AND t.table_name = c.table_name 
                             AND t.column_name = c.column_name) 
                      UNION 
                      SELECT i.index_name key_name, 
                             c.column_name column_name, 
                             c.column_position position,
                             c.descend descend 
                        FROM dba_indexes i, 
                             dba_ind_columns c 
                       WHERE i.table_owner = powner  
                         AND i.table_name = ptable  
                         AND i.uniqueness = 'UNIQUE' 
                         AND i.owner = c.index_owner 
                         AND i.index_name = c.index_name 
                         AND ptable = c.table_name 
                         AND powner = c.table_owner
                         AND i.index_name in ( 
                              SELECT index_name 
                                FROM dba_indexes 
                               WHERE table_owner = powner  
                                 AND table_name = ptable  
                                 AND uniqueness = 'UNIQUE') 
                         AND i.index_name not in ( 
                              SELECT c.constraint_name 
                                FROM dba_cons_columns c 
                              WHERE c.owner = powner  
                                 AND c.table_name = ptable  
                                 AND c.constraint_name IN ( 
                                      SELECT c1.name 
                                        FROM sys.user$ u1, 
                                             sys.user$ u2, 
                                             sys.cdef$ d, 
                                             sys.con$ c1, 
                                             sys.con$ c2, 
                                             sys.obj$ o1, 
                                             sys.obj$ o2 
                                       WHERE u1.name = powner  
                                         AND o1.name = ptable  
                                         AND d.type# in (2, 3)
                                         AND (d.defer is NULL OR d.defer = 0 OR bitand(d.defer, 36) = 4) 
                                         AND (d.type# = 5 OR 
                                              d.enabled is not null) 
                                         AND c2.owner# = u2.user#(+) 
                                         AND d.robj# = o2.obj#(+) 
                                         AND d.rcon# = c2.con#(+) 
                                         AND o1.owner# = u1.user# 
                                         AND d.con# = c1.con# 
                                         AND d.obj# = o1.obj#) 
                                         AND EXISTS ( 
                                              SELECT 'X' 
                                                FROM dba_tab_columns t 
                                               WHERE t.owner = c.owner 
                                                 AND t.table_name = c.table_name 
                                                 AND t.column_name = c.column_name)) 
                      AND EXISTS ( 
                          SELECT 'x' 
                            FROM dba_tab_columns t 
                           WHERE t.owner = powner
                             AND t.table_name = ptable
                             AND t.column_name = c.column_name) 
             ) KEY 
             ORDER BY key.key_name, 
                      key.position; 
                      
	--  unique keys all keys
    CURSOR uk_curs_all_keys (powner IN VARCHAR2, ptable IN VARCHAR2) IS
       SELECT key.key_name index_name, 
            key.column_name ,
            key.descend 
       FROM (SELECT c.constraint_name key_name, 
                    c.column_name column_name, 
                    c.position position,
                    'ASC' descend  
               FROM dba_cons_columns c 
              WHERE c.owner = powner 
                AND c.table_name = ptable 
                AND c.constraint_name in ( 
                      SELECT con1.name 
                        FROM sys.user$ user1, 
                             sys.user$ user2, 
                             sys.cdef$ cdef, 
                             sys.con$ con1, 
                             sys.con$ con2, 
                             sys.obj$ obj1, 
                             sys.obj$ obj2 
                      WHERE user1.name = powner 
                         AND obj1.name = ptable 
                         AND cdef.type# = 3 
                         AND con2.owner# = user2.user#(+) 
                         AND cdef.robj# = obj2.obj#(+) 
                         AND cdef.rcon# = con2.con#(+) 
                         AND obj1.owner# = user1.user# 
                         AND cdef.con# = con1.con# 
                         AND cdef.obj# = obj1.obj#) 
                AND EXISTS ( 
                      SELECT 'x' 
                        FROM dba_tab_columns t 
                       WHERE t.owner = c.owner 
                         AND t.table_name = c.table_name 
                         AND t.column_name = c.column_name) 
              UNION 
              SELECT i.index_name key_name, 
                     c.column_name column_name, 
                     c.column_position position ,
                     c.descend descend  
                FROM dba_indexes i, 
                     dba_ind_columns c                    
               WHERE i.table_owner = powner  
                 AND i.table_name = ptable  
                 AND i.uniqueness = 'UNIQUE' 
                 AND i.owner = c.index_owner 
                 AND i.index_name = c.index_name 
                 AND i.table_name = c.table_name                  
                 AND i.index_name in ( 
                      SELECT index_name 
                        FROM dba_indexes 
                       WHERE table_owner = powner  
                         AND table_name = ptable                           
                         AND uniqueness = 'UNIQUE') 
                 AND NOT EXISTS ( 
                      SELECT c.constraint_name 
                        FROM dba_cons_columns c 
                      WHERE c.owner = powner  
                         AND c.table_name = ptable  
                         AND c.constraint_name IN ( 
                              SELECT c1.name 
                                FROM sys.user$ u1, 
                                     sys.user$ u2, 
                                     sys.cdef$ d, 
                                     sys.con$ c1, 
                                     sys.con$ c2, 
                                     sys.obj$ o1, 
                                     sys.obj$ o2 
                               WHERE u1.name = powner  
                                 AND o1.name = ptable  
                                 AND d.type# = 3 
                                 AND c2.owner# = u2.user#(+) 
                                 AND d.robj# = o2.obj#(+) 
                                 AND d.rcon# = c2.con#(+) 
                                 AND o1.owner# = u1.user# 
                                 AND d.con# = c1.con# 
                                 AND d.obj# = o1.obj#) 
                                 AND EXISTS ( 
                                      SELECT 'X' 
                                        FROM dba_tab_columns t 
                                       WHERE t.owner = c.owner 
                                         AND t.table_name = c.table_name 
                                         AND t.column_name = c.column_name)) 
                 AND (EXISTS ( 
                      SELECT 'x' 
                        FROM dba_tab_columns t 
                       WHERE t.owner = powner 
                         AND t.table_name = ptable 
                         AND t.column_name = c.column_name)
                         OR c.descend = 'DESC' ) 
     ) KEY 
     ORDER BY key.key_name, 
              key.position; 
    
END DDLVersionSpecific;
/
show errors

/*
PROCEDURE ggsuser.ddlora_getLobs 
Compute LOB properties for a column and store them to marker table
param[in] POWNER                           VARCHAR2                owner of table with lob column
param[in] PTABLE                           VARCHAR2                name of table with lob column
param[in] TRUENAME                         VARCHAR2                name of lob column
*/
CREATE OR REPLACE PROCEDURE "&gg_user".ddlora_getLobs (
                                                             powner IN VARCHAR2,
                                                             ptable IN VARCHAR2,
                                                             trueName IN VARCHAR2,
                                                             colNum IN NUMBER)
IS  
BEGIN
	RETURN;
END;
/
show errors


    
SET TERMOUT ON
-- check if recycle bin is off for Oracle 10g only
WHENEVER SQLERROR EXIT
variable recycleval VARCHAR2(30)
variable errm VARCHAR2 (2000)
BEGIN
	:errm := chr(10) || 'GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** RECYCLEBIN must be turned off.' || chr(10) ||
                                 '*** For 10gr2, set RECYCLEBIN in parameter file to OFF. For 10gr1, set _RECYCLEBIN in parameter file to FALSE. Then restart database and installation.' || chr(10);
	SELECT 
		value 
	INTO
		:recycleval
	FROM v$parameter 	
	WHERE name='recyclebin' OR name='_recyclebin';
    
    IF  upper(:recycleval) <> 'OFF' AND upper(:recycleval) <> 'FALSE'
    THEN
		raise_application_error (&setup_error_code, :errm);
	END IF;		
	
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, :errm);
END;
/
WHENEVER SQLERROR CONTINUE


SET TERMOUT OFF

SET HEAD ON
