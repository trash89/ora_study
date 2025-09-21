-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Support script for version specific Oracle logic (oracle 9i)
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. Do not execute this script
-- 
-- Revision history
-- 
Rem    MODIFIED   (MM/DD/YY)
Rem    ctong       12/06/11  - bug 13430265: Exclude hidden column from uk_curs
Rem    msingams    06/10/11  - bug-11841862: Remove BIGFILE logic for rowid

--  05/24/2011 - SMIJATOV
--    12550561: DDL script doesn't compile on oracle 10.1
--  01/28/2011 - SRDJAN
--    OS-BUG-10394085: Improve performance of ALL supp log query
--  01/19/2011 - AJADAMS
--    OS-BUG-11073816
--    Added errorIsUserCancel no-op for Oracle 9i
--  01/18/2011 - SRDJAN
--    OS-BUG-11067769: unique index doesn't consider system generated cols (such as for function indexes)
--  01/19/2011 - AJADAMS
--    OS-BUG-11073816
--    Added errorIsUserCancel no-op for Oracle 9i
--  12/15/2010 - SRDJAN
--    OS-BUG-10326012 : if table has ONLY securefile lobs (encrypted), do not use TDE
--  12/02/10 - JW
--    OS-BUG-10364034
--    Added function ddlora_getAllColsLogging().
--
--  6/24/10 - SRDJAN
--    OS-BUG-9801097: Optimize DDL processing performance across the board
-- 08/19/2010 - SRDJAN
--    OS-BUG-9430216: TDE support for Oracle
--  06/12/09 - JW
--    OS-9228
--    Filter out invalidated keys (including primary key) in 
--    CURSOR uk_curs.
--
--  01/06/2009 - SRDJAN
--	  OS-8388: BIN$ objects that are not of system origin cause extract to abend
--  11/24/08 - SRDJAN
--	  OS-8142: installation issue with oracle 9
--  03/27/08 - SRDJAN
--	  FP 17821: add more error handling
--  05/23/07 - SRDJAN
--      Oracle version (9i) specific PL/SQL code
--


/*
FUNCTION ggsuser.ddlora_getErrorStack RETURNS VARCHAR2
Get error stack (modules and line numbers), however not applicable for 9
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_getErrorStack 
RETURN VARCHAR2
IS
BEGIN
	RETURN 'Error stack is avalaible only on Oracle 10.1 and above';
END;
/


/* 
FUNCTION ggsuser.errorIsUserCancel RETURNS BOOLEAN
Get 2nd error on stack.  Returns 0 if only top level error exists.
Error stack is not available on Oracle 9i.
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_errorIsUserCancel
RETURN BOOLEAN
IS
BEGIN
        RETURN FALSE;
END;
/
show errors


/*
FUNCTION ggsuser.ddlora_getBinObjectCount RETURNS NUMBER
Get number of objects in RECYCLEBIN that fit the name found
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_getBinObjectCount 
RETURN NUMBER
IS	
BEGIN	
	RETURN 0;  -- no objects as there is no recycle bin in oracle 9
END;
/
show errors

/*
FUNCTION ggsuser.ddlora_getAllColsLogging RETURNS NUMBER
Determine if owner.table has all column logging for supp logging.
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_getAllColsLogging (
                                                             pobjid NUMBER)
RETURN NUMBER IS        
BEGIN
    RETURN 0;  -- no ALL COLUMN LOGGING available for oracle 9.
END;
/

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


/*
PROCEDURE ggsuser.ddlora_getLobs 
Compute LOB properties for a column and store them to marker table
param[in] POWNER                           VARCHAR2                owner of table with lob column
param[in] PTABLE                           VARCHAR2                name of table with lob column
param[in] TRUENAME                         VARCHAR2                name of lob column
*/
CREATE OR REPLACE PROCEDURE "&gg_user".ddlora_getLobs (
                                                             powner VARCHAR2,
                                                             ptable VARCHAR2,
                                                             trueName VARCHAR2,
                                                             colNum IN NUMBER)
IS  
	
BEGIN
    RETURN;
END;
/
show errors

