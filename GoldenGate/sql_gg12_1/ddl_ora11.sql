-- Copyright (c) 2006, 2011, Oracle and/or its affiliates. 
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
--  11/09/2011 - CTONG
--    bug 13255581: Fix ddlora_getLobs
--  01/18/2011 - SRDJAN
--    OS-BUG-11067769: unique index doesn't consider system generated cols (such as for function indexes)
--  12/15/2010 - SRDJAN
--    OS-BUG-10326012 : if table has ONLY securefile lobs (encrypted), do not use TDE
--  6/24/10 - SRDJAN
--    OS-BUG-9801097: Optimize DDL processing performance across the board
--  06/12/09 - JW
--    OS-9228
--    Filter out invalidated keys (including primary key) in 
--    CURSOR uk_curs.
--
--  11/10/08 - SRDJAN
--    OS-8020: Use correct key in respect to RELY and ENABLE
--  10/24/08 - SRDJAN
--    OS-7879: Calculate UDT correctly and use it correctly in UK as well
--  10/22/08 - SRDJAN
--    OS-7835: Initial version and UK are now calculated based on nullable/virtual property with first alphabetical key taken
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
                                 AND visibility != 'INVISIBLE'
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
                    c.position position ,
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
                         AND visibility != 'INVISIBLE'
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
Compute LOB properties for a column and store them to marker table.
Column must be a lob column or an XML/ADT column with a child lob column,
or ORA-1403 will be raised.
param[in] POWNER         VARCHAR2    owner of table with lob column
param[in] PTABLE         VARCHAR2    name of table with lob column
param[in] TRUENAME       VARCHAR2    name of lob column or XML/ADT top column
*/
CREATE OR REPLACE PROCEDURE "&gg_user".ddlora_getLobs (
                                                             powner IN VARCHAR2,
                                                             ptable IN VARCHAR2,
                                                             trueName IN VARCHAR2,
                                                             colNum IN NUMBER)
IS  
    lobEncrypt VARCHAR2(&name_size);
    lobCompress VARCHAR2(&name_size);
    lobDedup VARCHAR2(&name_size);     
    errorMessage VARCHAR2(&message_size);    
BEGIN
    BEGIN
        -- bug 13255581: dba_lobs uses fully qualified column name.
        -- This query can be simplified further if sys.lob$ is used instead,
        -- or if column number is used instead of column name.
        SELECT max(decode(l.encrypt, 'NO', 0, 'NONE', 0, 1)) isEnc,
               max(decode(l.compression, 'NO', 0, 'NONE', 0, 1)) isComp,
               max(decode(l.deduplication, 'NO', 0, 'NONE', 0, 1)) isDedup
          INTO lobEncrypt, lobCompress, lobDedup
          FROM dba_tab_cols c, dba_tab_cols tc, dba_lobs l
          WHERE c.owner = tc.owner AND c.table_name = tc.table_name 
            AND c.owner = l.owner AND c.table_name = l.table_name
            AND c.column_id = tc.column_id AND c.qualified_col_name = l.column_name
            AND c.owner = powner AND c.table_name = ptable AND tc.column_name= trueName;	

    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'get LOB info, error: ' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage);
            RAISE;
    END;
    DDLReplication.insertToMarker (DDLReplication.DDL_HISTORY, '', '', 
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_ENCRYPT, to_char (colNum), trueName, lobEncrypt, 
                                   DDLReplication.ITEM_WHOLE) ||
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_DEDUP, to_char (colNum), trueName, lobDedup, 
                                   DDLReplication.ITEM_WHOLE) ||
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_COMPRESS, to_char (colNum), trueName, lobCompress, 
                                   DDLReplication.ITEM_WHOLE) 
                                   , DDLReplication.ADD_FRAGMENT);
    RETURN;
END;
/
show errors

