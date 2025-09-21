-- $Header: oggcore/OpenSys/redist/SQLScripts/ddl_setup.sql /st_oggcore_11.2.1/15 2012/08/01 11:51:29 mcusson Exp $
--
-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Installation script for Oracle GoldenGate DDL Replication trigger and package
-- REFER TO ORACLE GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
-- 
--    For example:
--    SQL> @ddl_setup
--
-- 3. IMPORTANT: When executing this script, all sessions issuing DDL must close and reconnect (including Oracle GoldenGate
--    ones such as Replicat), or error 6508 (could not find program unit being called) may occur and DDL operation
--    may fail. This is  because of a known Oracle bug #2747350. Another potential workaround is to try to execute DDL
--    operation more than once (however it is not guaranteed to work, because of the previously mentioned bug).
--
-- Revision history
-- 
Rem    MODIFIED   (MM/DD/YY)
Rem    mcusson     07/30/12  - Backport mcusson_bug-14126438 from
Rem    smijatov    07/14/12  - Backport smijatov_bug-14229808 from main
Rem    yuyao       07/02/12  - Backport yuyao_bug-14158453 from main
Rem    ajadams     06/14/12  - Backport ajadams_bug-13738843 from main
Rem    ajadams     06/12/12  - Backport ajadams_bug-13563425 from main
Rem    sijenki     05/14/12  - Backport sijenki_bug-13916074 from main
Rem    ajadams     05/08/12  - Backport ajadams_bug-13922380 from main
Rem    smijatov    03/30/12  - Backport smijatov_ddlrep106 from main
Rem    smijatov    03/20/12  - Backport smijatov_bug-13825904 from main
Rem    smijatov    03/11/12  - Backport smijatov_b13685003 from main
Rem    binsong     03/01/12  - Backport binsong_bug-13703011 from main
Rem    praghuna    02/21/12  - Backport praghuna_ddl_trig1 from main
Rem    yuyao       02/13/12  - Backport yuyao_bug-13581563 from main
Rem    yuyao       02/13/12  - Backport yuyao_bug-13332747 from main
Rem    smijatov    03/09/12  - Bug-13829169: CREATE DDLs cause problems with object id query
Rem    binsong     02/28/12  - Bug-13703011: insertToMarker gathers as much data as possible before 
Rem                            flush to the table to improve the performance.
Rem    yuyao       01/31/12  - Bug-13332747. Check for table created with
Rem                            nologging option.
Rem    yuyao       01/26/12  - Bug-13581563. Add function to check for compress
Rem                            clause of iot.
Rem    yoshbaba    01/25/12  - bug 13604267: Multi byte DDL is corrupted at boundary.
Rem    ctong       01/11/12  - bug 13582187: CONTINUE statement illegal in 10g
Rem    praghuna    01/04/12  - performance improvement changes
Rem    jennwei     01/03/12 - BUG 13555120: disallow primary key with 
Rem                           nonvalidated + norely + enbled to be used as key, 
Rem                           even with ALLOWNONVALIDATEDKEYS parameter.
Rem    ctong       12/06/11  - bug 13430265: Exclude hidden column from pk_curs
Rem    msingams    12/02/11  - bug 13443106: param NULL check removeSQLComments
Rem    msingams    11/20/11  - bug 12918536: Handle 0 length for utl_raw.substr
Rem    msingams    11/15/11  - bug 12918536: Handle Multibyte characters
Rem    ctong       11/04/11  - bug 13255581: Fix xmltype table queries
Rem    sijenki     11/02/11  - bug-13032000: add java_name_size to accommodate java names
Rem    smijatov    10/24/11  - bug 12949550: add flag for NOT NULL DEFAULT
Rem    msingams    10/20/11  - bug 11829998: Handle ggs_ddl_trace.log path linux
Rem    smijatov    09/23/11  - bug 12989410: Fix issue with recyclebin DDL inter rupt
Rem    ctong       10/07/11  - fix getObjectTableType
Rem    smijatov    08/23/11  - bug 12881026: Get table owner/name for synonyms
Rem    smijatov    08/19/11  - bug-12868489: BIN$ objects are not always filtered out
Rem    abrown      08/05/11  - bug 12540758: Eliminate setup option NORMAL
Rem    smijatov    07/22/11  - bug 11073786: update Oracle product naming
Rem    smijatov    07/15/11  - bug-12659457: Rework TRANDATA in all products 
Rem                            to use objid only
Rem    msingams    06/14/11  - bug-12344560: Remove GETTABLESPACESIZE references
Rem    msingams    06/10/11  - bug-11841862: Remove BIGFILE logic for rowid
Rem    smijatov    05/24/11  - bug 12550561: DDL setup does not work on oracle 10.1
Rem    ctong       05/16/11  - Add XML-OR support for Xout
Rem    praghuna    05/02/11  - bug 11833474: removeSQLComments.multibyte chars
Rem    msingams    03/30/11  - DDL upgrade: check for locks on OGG metadata
Rem    msingams    04/29/11  - OS-BUG-12413213: Remove v$lock_type as Oracle9
Rem                            does not have this view.

--  03/04/2011 - SRDJAN
--    bug 9428942: rework sequences on target side, add cycle sequences, add FLUSH SEQUENCE to GGSCI
--  03/01/2011 - SRDJAN
--    bug 11701654: Add tracing for DDL on TDE
--  01/28/2011 - SRDJAN
--    OS-BUG-10394085: Improve performance of ALL supp log query
--  01/18/2011 - SRDJAN
--    OS-BUG-11067769: unique index doesn't consider system generated cols (such as for function indexes)

--  01/05/10 - OMIAN
--    Bug 10402114 Ignore objects with names starting with 'OGGQT$' and 'AQ$' as these are related
--    to the queue object created for RMAN integration.
--  12/15/2010 - SRDJAN
--    OS-BUG-10326012 : if table has ONLY securefile lobs (encrypted), do not use TDE
--  12/02/10 - SRDJAN
--    OS-BUG-10364074: call to dbms_session causes 'insufficient privilege' in caller
--  12/02/10 - JW
--    OS-BUG-10364034
--    Added function ddlora_getAllColsLogging().
--  11/15/10 - AJADAMS
--    Add support for ALLKEYS (schema) level supplemental logging
--  6/24/10 - SRDJAN
--    OS-BUG-9801097: Optimize DDL processing performance across the board
-- 10/20/10 - GS
--   OS-BUG-10185049 : VARRAYs are not supported with DDL replication
--
-- 10/04/2010 - SRDJAN
--    OS-BUG-10127630 : pass to extract information about ALL trandata 
--
-- 09/27/2010 - GS
--    OS-BUG-10063075: query the ts# as well to correctly identify the table when checking for compression
-- 09/16/2010 - AJADAMS
--    OS-BUG-9830035 - nested user cancel, added _ddl_cause_user_nested_cancel
-- 08/09/2010 - SRDJAN
-- OS-BUG-10004671 - TRANDATA RELATED DDL APPEARS MULTIPLE TIMES WHEN USING DDLOPTIONS GETREPLICATES
-- 08/02/2010 - JW
--    OS-BUG-9959047 - Added global parameter ALLOWNONVALIDATEDKEYS to allow the usage of nonvalidated primary key.
-- 07/14/2010 - SRDJAN
--    OS-BUG-9904304: Trigger produces wrong key when there are multiple unique indexes (and no primary key)
-- 07/29/2010 - SRDJAN
--    OS-BUG-9430216: TDE support for Oracle
-- 05/26/2010 - SRDJAN
--    OS-BUG-9713268  - remove NOCACHE for DDL sequence as it may cause RAC contention with many DDLs
-- 05/25/2010 - SRDJAN
--    OS-BUG-9643886 - rework the same bug a bit for defensive coding to avoid numeric overflow
-- 05/20/2010 - SRDJAN
--    OS-BUG-9421334: remove RECYCLEBIN OFF requirement from Oracle 11 db and extract 
-- 04/29/2010 - SRDJAN
--    OS-BUG-9643886 - double-dash comment not followed by new line in DDL, removing comments fails
-- 04/29/2010 - SRDJAN
--    OS-BUG-9649434 - Handle multibyte DDL text properly when writing to marker
-- 04/23/2010 - SRDJAN
--    OS-BUG-9580250 - Add NLS support for DDL (NLS settings replicate for DDL)
-- 01/11/10 - SRDJAN
--    OS-9951: clean up DDL and marker records before ignoring DDL (in case of catastrophic failure)
--    OS-6943: Mine DDL session schema log and use it in ER
-- 11/19/09 - SRDJAN
--    No ticket: added a bit more tracing
-- 10/02/09 - JW, SRDJAN
--   OS-9214, OS-9602: Fixing improper reuse of file_def in generic hashes for this ticket
--  08/25/09 - SRDJAN
--    OS-9214: Excluding secondary objects in Oracle in both DML and DDL
--  08/1/2009 - SRDJAN
--    OS-9213: integrate missed changes for index ops when object id is not found correctly (fixed previously)
--  07/17/2009 - SRDJAN
--    OS-9370: DDL without text is ignored
--  06/30/2009 - SRDJAN
--    OS-9270: eliminate additional deadlock possibility due to Oracle's internal issue
--  06/09/2009 - SRDJAN
--    OS-9270: eliminate possible deadlock situation in DDL trigger
--  06/19/2009 - SRDJAN
--    OS-9213: CREATE/DROP index may provide incorrect data to extract; ALTER index is counted as unmapped scope by the replicat
--    No ticket (part of OS-9214): excluding secondary objects (for example in spatial indexes)
--  06/19/2009 - SRDJAN
--    OS-6683: Existing Oracle sessions may cause ORA-6508. Checking for current sessions and explicit warning added.
--  06/16/2009 - SRDJAN
--    OS-9234: Oracle produces 'binary' DDL record associated with previous user-DDL record, to be ignored
--  06/08/2009 - SRDJAN
--	  OS-9198: Correct trigger behavior in PRIMARY, LOGICAL/PHYSICAL standby, and mode of operation
--  05/01/2009 - SRDJAN
--    No ticket: fix installation problem that happens sometimes in ddlora_getTablespaceSize with INITIALSETUP
--  04/15/2009 - SRDJAN
--    OS-8956: make sure recyclebin is purged and disabled
--    No ticket: fixed issue with comments in CREATE INDEX, object owner/name is incorrect
--  04/10/2009 - SRDJAN
--    OS-8853: UDT, function based cols
--  03/27/2009 - SRDJAN
--    No ticket: similar as for OS-8805/5451, ignoring system objects caused some objects to go through which shouldnt'
--    because secondary DDL got through even though primary one didn't (related to DDL wildcarding featue for ER)
--  03/19/2009 - SRDJAN
--    OS-8805: filter out domain index objects (secondary object in domain index DDLs)
--    OS-5451: filter out extra journal DDL when rebuilding online indexes
--  03/16/2009 - SRDJAN
--    OS-8463: DDL for cluster table
--  03/11/09 - SRDJAN
--    OS-8515: Verify that DDL for object tables is not replicated
--  02/09/2009 - SRDJAN
--    OS-8584: same columns used in multiple unique keys causes trigger error in metadata generation
--  02/02/2009 - SRDJAN
--    OS-8517: TABLESPACE DDL is blocked when done by SYS or similar users.
--  02/02/2009 - SRDJAN
--    OS-5079: support large DDL (up to 2Mb in size) for Oracle
--  01/19/2009 - SRDJAN
--    OS-5781: DDL for IOT 
--  01/06/2009 - SRDJAN
--    OS-8388: BIN$ objects that are not of system origin cause extract to abend
--  11/26/08 - SRDJAN
--    OS-8370: UDT table is not processed correctly sometimes
--  11/26/08 - SRDJAN
--    No ticket: improve reporting on real data types
--  11/19/08 - SRDJAN
--    OS-8094: exclude MLOG$ and RUPD$ tables (temps for materialized view logs)
--  11/10/08 - SRDJAN
--    OS-8020: Use correct key in respect to RELY and ENABLE
--  10/24/08 - SRDJAN
--    OS-7879: Calculate UDT correctly and use it correctly in UK as well
--  10/24/08 - SRDJAN
--    OS-7848: Do not check password file, only permissions for trigger setup
--  10/23/08 - SRDJAN
--    OS-7849, OS-7850: Check for compression table/partitions and check for validity of constraints
--  10/22/08 - SRDJAN
--    OS-7835: UK are now calculated based on nullable/virtual property with first alphabetical key taken
--  09/26/08 - SRDJAN
--    OS-7608: Data properties not calculated correctly, refactor so that DDL and DML do the same
--  09/26/08 - SRDJAN
--      OS-7748: Module info is not preserved with DDL op
--  09/26/08 - SRDJAN
--      TSI-407: DDL trigger self-dead locks
--  09/22/08 - SRDJAN
--      OS 7656: DDL trigger locks objects in CREATE INDEX
--  06/10/08 - SRDJAN
--    OS-5680: support for PUBLIC SYNONYMS DDL
--  06/02/08 - SRDJAN
--      FP 17971: use ISDBA as well to determine dba privs
--  06/02/08 - SRDJAN
--      FP 18346: multibyte DDL was not processed correctly (extract limit is in bytes, not characters), size processed in bytes now
--  05/08/08 - SRDJAN
--      FP 18116: performance: granting privilege that's not granted by default (dmbs_session)
--  05/08/08 - SRDJAN
--      FP 18116: performance: tracing can be turned off, new STAYMETADATA parameter
--  04/29/08 - SRDJAN
--      FP 18116: using high performance queries in DDL trigger
--    No ticket: added new tracing facility for DDL trigger
--  03/27/08 - SRDJAN
--      FP 17941: for now we don't support xml type. We will add it back.
--  03/27/08 - SRDJAN
--      FP 17821: add more error handling
-- 03/26/2008 - SRDJAN
--    FP 17624, No ticket: consolidate escape chars; handle dup errors only with alternative ids (17624); comment for garbage marker data
-- 03/24/2008 - SRDJAN
--    FP 17784: checking for oracle servererror (no ora_sql_txt), possible cause of 6502 and 3113
-- 03/13/2008 - SRDJAN
--    FP 17628: added safeguard for cleaning up (which shouldn't really affect production, only QA of product)
-- 03/10/2008 - SRDJAN
--    FP 17628 - user cancellation is not handled properly (extract abends)
--    FP None - when concurrent muplitple DDLs occur on the same table (some failing) trigger fails in getTableInfo
--  03/05/08 - SRDJAN
--    FP 17556: near 32K DDL breaks replication (UBS)
--  03/05/08 - SRDJAN
--    FP 17226: verify that current user not only has SYSDBA privs, but actually uses it (logged as SYSDBA)
--    Also improve installation check function to check for _ALT table. Fix typo in tracing.
--  01/03/08 - SRDJAN
--    FP 17054: verify sql statement is under 32K. Also fix SCN problem with background jobs.
--  10/09/07 - SRDJAN
--    FP 16317 : trigger failing when space low in oracle home
--  10/05/07 - SRDJAN
--    FP 16267: ignore BIN$ objects in case recycle bin is accidentally enabled. Make sure recyclebin is disabled
--  10/05/07 - SRDJAN
--    FP 16261: include path in trace file info when trigger reports an error
--  09/28/07 - SRDJAN
--    FP 16186
--    DISABLE/ENABLE primary key will now have effect on file_def. This covers all object resolution in all products (including DDL)
--  09/26/07 - SRDJAN
--    No ticket: removed 'at' sign in comments to clear up spool output
--  09/17/07 - YY
--    FP 15725 - Addition hardening on ddl_hist_table_alt table.
--  09/06/07 - SRDJAN
--    No ticket: DROP INDEX in partitioned table causes incomplete metadata text
--  09/05/07 - SRDJAN
--    FP 15761: CREATE/DROP UNIQUE INDEX properly updates trandata in ADDTRANDATA option (added uniqueness flag for INDEX)
--  08/27/07 - SRDJAN
--      No ticket: Support for large number of columns (very large metadata)
--  08/20/07 - SRDJAN
--      FP 15725 - Harden DDL installation not to allow dropping vital objects and checking if marker/DDL package are correct
--  08/10/07 - SRDJAN
--      FP 15475 - CREATE INDEX must have comments removed for proper DDL processing 
--  07/31/07 - SRDJAN
--      FP 15518 - fixing PL/SQL compilation/warning issues
--  05/23/07 - SRDJAN
--      DDL replication initial version
--

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

-- do not show substitutions in progress
SET verify OFF 
SET FEEDBACK OFF

prompt 
prompt Oracle GoldenGate DDL Replication setup script
prompt 
prompt Verifying that current user has privileges to install DDL Replication...


-- check if user has privileges, if not, exit with message
WHENEVER SQLERROR EXIT
variable isdba VARCHAR2(30)
variable sysdba_message VARCHAR2 (2000)
BEGIN
    :sysdba_message := chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Currently logged user does not have SYSDBA privileges, or not logged AS SYSDBA! ' || chr(10) ||
                                 '*** Please login as SYSDBA.' || chr(10);

    SELECT sys_context('userenv','ISDBA') INTO :isdba FROM DUAL; -- use network method  for isdba determination

    IF :isdba <> 'TRUE' THEN
                raise_application_error (&setup_error_code,
                                 :sysdba_message);
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 :sysdba_message);
END;
/
WHENEVER SQLERROR CONTINUE


SET TERMOUT ON

col gg_user new_value gg_user
col enc_table new_value enc_table
col enc_schema new_value enc_schema
col gg_mode new_value gg_mode
col paramname new_value paramname
col ddl_hist_table_alt new_value ddl_hist_table_alt

-- User showtime
prompt
prompt You will be prompted for the name of a schema for the Oracle GoldenGate database objects.
prompt NOTE: For an Oracle 10g source, the system recycle bin must be disabled. For Oracle 11g and later, it can be enabled.
prompt NOTE: The schema must be created prior to running this script.
prompt NOTE: Stop all DDL replication before starting this installation.
prompt
accept gg_user prompt 'Enter Oracle GoldenGate schema name:'

Rem Fix for bug 12540758: Disable user specifiable installation options
Rem Leave references in place as may wish to re-enable for future releases.
Rem prompt
Rem prompt You will be prompted for the mode of installation.
Rem prompt To install or reinstall DDL replication, enter INITIALSETUP
Rem prompt To upgrade DDL replication, enter NORMAL
Rem accept gg_mode prompt 'Enter mode of installation:'
define gg_mode = 'INITIALSETUP'

prompt 
prompt Working, please wait ...
prompt Spooling to file ddl_setup_spool.txt


prompt

SET TERMOUT OFF
SET HEAD OFF

-- All the global parameters are set
@params

SET TERMOUT ON
-- Check for sessions that hold locks on Oracle Golden Gate metadata tables ...
prompt Checking for sessions that are holding locks on Oracle Golden Gate metadata tables ...
SET TERMOUT OFF
variable numLocks NUMBER
SELECT upper('&gg_user') AS gg_user FROM dual;
WHENEVER SQLERROR EXIT
BEGIN
  SELECT COUNT(*)
  INTO :numLocks
  FROM gv$lock l, dba_objects o, gv$session s, gv$process p
  WHERE l.id1 = o.object_id  
    AND o.owner = '&gg_user'
    AND s.inst_id = l.inst_id
    AND s.sid = l.sid
    AND s.inst_id = p.inst_id
    AND s.paddr = p.addr
    AND (instr (s.program, '&_skip_lock_check') = 0
        OR instr (s.program, '&_skip_lock_check') IS NULL);
END;
/

SET TERMOUT ON
SET HEAD OFF
SELECT decode( :numLocks, 0, 
               'Check complete.', 
               'The following sessions are holding ' || to_char(:numLocks) ||
                 ' locks on objects owned by &gg_user :'
             ) FROM DUAL;

SET LINESIZE 120
SET HEAD ON    
SELECT 
  s.inst_id,
  s.sid,
  s.serial#,
  substr(s.osuser,1,8) os_user,
  substr(s.username,1,10) username,
  substr(p.spid,1,9) pid,
  substr(s.program,1,32) program
FROM 
  dba_objects o, 
  gv$lock l, 
  gv$session s,
  gv$process p
WHERE o.owner = '&gg_user'
  AND l.id1 = o.object_id  
  AND s.inst_id = l.inst_id
  AND s.sid = l.sid
  AND s.inst_id = p.inst_id
  AND s.paddr = p.addr
ORDER BY
  s.inst_id, s.sid, s.serial#, p.spid;

prompt
prompt

SET HEAD OFF
SELECT decode( :numLocks, 0, 
               '', 
               'Details of locks being held:'
             ) FROM DUAL;
SET HEAD ON
SET TERMOUT ON
SELECT 
  s.inst_id,
  s.sid,
  s.serial#,
  substr(o.object_name,1,16) object_locked,
  rpad(l.type,9) lock_type
FROM 
  dba_objects o, 
  gv$session s,
  gv$lock l 
WHERE o.owner = '&gg_user'
  AND l.id1 = o.object_id  
  AND s.inst_id = l.inst_id
  AND s.sid = l.sid
ORDER BY
  s.inst_id, s.sid, s.serial#;

prompt
prompt
BEGIN
  IF :numLocks > 0 THEN
    raise_application_error( &setup_error_code, 
      chr(10) || 'Oracle GoldenGate DDL Replication setup:' || chr(10) ||
        '*** Disconnect all sessions that are holding locks on Oracle Golden'||
        'Gate metadata tables, and retry.' );
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE
SET TERMOUT OFF
SET HEAD OFF



-- disable bogus warnings 
ALTER SESSION SET plsql_warnings = 'DISABLE:7204';

-- disable trigger to avoid recursion
ALTER TRIGGER sys .&ddl_trigger_name DISABLE;

SELECT upper('&gg_user') AS gg_user FROM dual;
SELECT upper('&gg_mode') AS gg_mode FROM dual;

-- ALT table is used to speed up access to metadata (all info is in metadata)
SELECT upper('&ddl_hist_table') || '_ALT' AS ddl_hist_table_alt FROM dual;

-- get db version
variable oversion VARCHAR2(100)
variable ocompat VARCHAR2(100)
exec dbms_utility.db_version (:oversion, :ocompat); 
SELECT 'ddl_ora' || 
    decode (substr (:oversion, 1, instr (:oversion, '.', 1)), '9.', '9.sql', '10.', '10.sql', '11.sql') AS paramname FROM dual;

-- check if SYS.ENC$ exists
WHENEVER SQLERROR EXIT
variable enc_cnt  NUMBER
BEGIN
    SELECT COUNT(*) 
    INTO :enc_cnt
    FROM sys.obj$ o
    WHERE o.name='ENC$' and o.owner# = 0;

    IF :enc_cnt = 0 AND ('&_skip_create_objects' = 'FALSE' AND '&_skip_lock_check' IS NULL) THEN
        -- fake sys.enc$ (for oracle 9 and 10.1), must not be written into
    	BEGIN
    	EXECUTE IMMEDIATE ('DROP TABLE "&gg_user"."ENCDUMMY$" ');
    	EXCEPTION 
    	    WHEN OTHERS THEN 
    		NULL;
    	END;
        EXECUTE IMMEDIATE ('CREATE TABLE "&gg_user"."ENCDUMMY$" ' ||
    	 '(    "OBJ#" NUMBER,' ||
    	 '     "OWNER#" NUMBER,' ||
    	 '     "MKEYID" VARCHAR2(64),' ||
    	 '     "ENCALG" NUMBER,' ||
    	 '     "INTALG" NUMBER,' ||
    	 '     "COLKLC" RAW(2000),' ||
    	 '     "KLCLEN" NUMBER,' ||
    	 '     "FLAG" NUMBER' ||
    	 ')');
   END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || SQLERRM || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

-- get proper ENC$ table (dummy for ora9 and 10.1)
SELECT decode (to_char(:enc_cnt), '0', 'ENCDUMMY$', 'ENC$') AS enc_table FROM dual; 
SELECT decode (to_char(:enc_cnt), '0', '&gg_user', 'SYS') AS enc_schema FROM dual; 
SET termout ON


-- check if entered user name exists
WHENEVER SQLERROR EXIT
variable user_name VARCHAR2(30)
BEGIN
    SELECT 
        username
    INTO
        :user_name
    FROM dba_users
    WHERE username = '&gg_user';
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Cannot find user &gg_user' || chr(10) ||
                                 '*** Please enter existing user name.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE


-- get gg_user's default tablespace
WHENEVER SQLERROR EXIT
variable gg_user_default_tablespace VARCHAR2(30);
BEGIN
    SELECT
        default_tablespace
    INTO
        :gg_user_default_tablespace
    FROM dba_users
    WHERE username = '&gg_user';
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error (&setup_error_code,
                                 chr(10) || SQLERRM || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE


-- was gg_user's default tablespace created with AUTOEXTEND ON?
WHENEVER SQLERROR EXIT
variable is_autoextend_on NUMBER;
BEGIN
    SELECT
        count(*)
    INTO
        :is_autoextend_on
    FROM dba_data_files
    WHERE tablespace_name = :gg_user_default_tablespace AND 
          autoextensible = 'YES';
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error (&setup_error_code,
                                 chr(10) || SQLERRM || chr(10));
END;
/

SELECT decode( :is_autoextend_on, 0,
               'WARNING: Tablespace ' ||
               :gg_user_default_tablespace ||
               ' does not have AUTOEXTEND enabled.',
               ''
             ) FROM DUAL;

WHENEVER SQLERROR CONTINUE

-- check if gg_user has its own tablespace
WHENEVER SQLERROR EXIT
variable num_users_on_tbs NUMBER;
declare
    env_allow_shared_tbs VARCHAR2(5);
BEGIN
    SELECT
        count(*)
    INTO
        :num_users_on_tbs
    FROM dba_users
    WHERE default_tablespace = :gg_user_default_tablespace;

    IF :num_users_on_tbs > 1 THEN

        IF '&allow_shared_tablespace' <> 'TRUE' THEN

            env_allow_shared_tbs := 'FALSE';
            IF '&paramname' <> 'ddl_ora9.sql' THEN
                execute immediate 
                    'begin dbms_system.get_env(''ALLOW_SHARED_TABLESPACE'', :1); end;' 
                    using out env_allow_shared_tbs;
            END IF;

            IF env_allow_shared_tbs IS NULL OR env_allow_shared_tbs <> 'TRUE' THEN

                raise_application_error (&setup_error_code, chr(10)
                                         ||'Oracle GoldenGate DDL Replication setup: '
                                         || chr(10)
                                         || '*** Please move &gg_user to its own tablespace'
                                         || chr(10) );
            END IF;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error (&setup_error_code,
                                 chr(10) || SQLERRM || chr(10));
END;
/


SELECT decode( :num_users_on_tbs, 1, '',
               'WARNING: Other users are sharing the ' ||
               :gg_user_default_tablespace ||
               ' tablespace that must be dedicated to &gg_user.'
             ) FROM DUAL;

WHENEVER SQLERROR CONTINUE


-- check if marker and ddl hist table installed
WHENEVER SQLERROR EXIT
variable numof NUMBER
BEGIN
    SELECT 
        COUNT(*)
    INTO
        :numof
    FROM dba_objects
    WHERE owner = '&gg_user' AND object_name = '&marker_table_name'  AND object_type = 'TABLE';
    IF :numof <> 1 THEN
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Marker table not found, please run marker_setup.sql first' || chr(10) );
    END IF;
    IF '&gg_mode' = 'NORMAL' THEN
        SELECT 
            COUNT(*)
        INTO
            :numof
        FROM dba_objects
        WHERE owner = '&gg_user' AND object_name = upper('&ddl_hist_table')  AND object_type = 'TABLE';
        IF :numof <> 1 THEN
            raise_application_error (&setup_error_code, 
                                     chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                     '*** NORMAL mode of installation chosen, but DDL history table not found, probably need to use INITIALSETUP' || chr(10) );
        END IF;
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || SQLERRM || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

-- check if ddl replication package is one (there are not 2 of them)
WHENEVER SQLERROR EXIT
variable numof NUMBER
variable ownerof VARCHAR2(300)
BEGIN
    SELECT 
        COUNT(*)
    INTO
        :numof
    FROM dba_objects
    WHERE object_name = 'DDLREPLICATION' AND object_type = 'PACKAGE';
    
    IF :numof = 1 AND '&gg_mode' = 'INITIALSETUP' THEN
        SELECT 
            upper(owner)
        INTO
            :ownerof
        FROM dba_objects
        WHERE object_name = 'DDLREPLICATION' AND object_type = 'PACKAGE';
        IF :ownerof <> '&gg_user' THEN
            raise_application_error (&setup_error_code, 
                                     chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                     '*** INITIALSETUP used, but DDLREPLICATION package exists under different schema (' || :ownerof ||
                                     '). Please use ddl_remove.sql to remove DDL installation from that schema first' || chr(10) );
        END IF;
    END IF;
    
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || SQLERRM || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE


-- check if INITIALSETUP or NORMAL is entered
WHENEVER SQLERROR EXIT
variable opt NUMBER
BEGIN
    SELECT 
        decode ('&gg_mode', 'INITIALSETUP', 1, 'NORMAL', 2, 3)
    INTO
        :opt
    FROM dual;
    IF :opt = 3 THEN
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Not a proper value for mode (INITIALSETUP or NORMAL)' || chr(10) ||
                                 '*** Please try again.' || chr(10));
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'Oracle GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Not a proper value for mode (INITIALSETUP or NORMAL)' || chr(10) ||
                                 '*** Please try again.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE


-- announce start of installation
prompt
prompt Using &gg_user as a Oracle GoldenGate schema name.
prompt


SET termout OFF
spool ddl_setup_spool.txt
STORE SET 'ddl_setup_set.txt' REPLACE


SET termout ON
prompt Working, please wait ...
SET termout OFF

-- drop trigger if existed
DROP TRIGGER sys .&ddl_trigger_name;


-- make sure user has privileges necessary
GRANT SELECT ON "&enc_schema"."&enc_table" TO "&gg_user"; 
GRANT EXECUTE ON UTL_FILE TO "&gg_user";
GRANT SELECT ON sys.v_$database TO "&gg_user";
GRANT SELECT ON dba_lobs TO "&gg_user";
GRANT ALTER SESSION TO "&gg_user";
GRANT SELECT ON nls_session_parameters TO "&gg_user";
GRANT EXECUTE ON dbms_session TO  "&gg_user";
GRANT SELECT ON sys.seq$ TO "&gg_user";
GRANT SELECT ON sys.user$ TO "&gg_user";
GRANT SELECT ON sys.cdef$ TO "&gg_user";
GRANT SELECT ON sys.ccol$ TO "&gg_user";
GRANT SELECT ON sys.con$ TO "&gg_user";
GRANT SELECT ON sys.obj$ TO "&gg_user";
GRANT SELECT ON sys.col$ TO "&gg_user";
GRANT SELECT ON sys.coltype$ TO "&gg_user";
GRANT SELECT ON sys.tab$ TO "&gg_user";
GRANT SELECT ON sys.tabpart$ TO "&gg_user";
GRANT SELECT ON sys.tabsubpart$ TO "&gg_user";
GRANT SELECT ON sys.hist_head$ TO "&gg_user";
GRANT SELECT ON sys.seg$ TO "&gg_user";
GRANT SELECT ON sys.opqtype$ TO "&gg_user";
GRANT SELECT ON sys.dba_synonyms TO "&gg_user";
GRANT SELECT ON sys.dba_constraints TO "&gg_user";
GRANT SELECT ON sys.dba_cons_columns TO "&gg_user";
GRANT SELECT ON sys.dba_objects TO "&gg_user";
GRANT SELECT ON sys.dba_clusters TO "&gg_user";
GRANT SELECT ON sys.dba_clu_columns  TO "&gg_user";
GRANT SELECT ON sys.dba_log_groups TO "&gg_user";
GRANT SELECT ON sys.v_$parameter TO "&gg_user";
GRANT SELECT ON sys.v_$session TO "&gg_user";
GRANT SELECT ON sys.v_$transaction TO "&gg_user";
GRANT SELECT ON sys.v_$instance TO "&gg_user";
GRANT SELECT ON sys.ind$ TO "&gg_user";
GRANT SELECT ON dba_indexes TO "&gg_user";
GRANT SELECT ON dba_ind_columns TO "&gg_user";
GRANT SELECT ON dba_constraints TO "&gg_user";
GRANT SELECT ON dba_recyclebin TO "&gg_user";
GRANT SELECT ON dba_tab_columns TO "&gg_user";
GRANT SELECT ON dba_tab_cols TO "&gg_user";
GRANT SELECT ON dba_objects TO "&gg_user";
GRANT SELECT ON dba_log_group_columns TO "&gg_user";
GRANT SELECT ON dba_users TO "&gg_user";
GRANT SELECT ON dba_triggers TO "&gg_user";
GRANT SELECT ON dba_objects TO "&gg_user";
GRANT SELECT ON dba_tablespaces TO "&gg_user";
GRANT SELECT ON dba_tab_partitions TO "&gg_user";
GRANT SELECT ON dba_tab_subpartitions TO "&gg_user";
GRANT SELECT ON dba_triggers TO "&gg_user";
GRANT SELECT ON dba_errors TO "&gg_user";
GRANT SELECT ON dba_tables TO "&gg_user";
GRANT SELECT ON dba_object_tables TO "&gg_user";
GRANT SELECT ON dba_sequences TO "&gg_user";
GRANT CREATE ANY DIRECTORY TO "&gg_user";
GRANT DROP ANY DIRECTORY TO "&gg_user";

@&paramname

SET termout OFF
@ddl_filter &gg_user


define errC ='ERRORS detected in installation of DDL Replication software components'
define sucC ='SUCCESSFUL installation of DDL Replication software components'

/*
FUNCTION ggsuser.ddlora_verifyDDL RETURNS VARCHAR2
This function checks if installation was successful and returns appropriate string for user perusal

return human readable string saying OK or ERROR (with a bit more context with it)
*/
CREATE OR REPLACE FUNCTION "&gg_user".ddlora_verifyDDL 
RETURN VARCHAR2
IS
someErr NUMBER;
trigStat VARCHAR2(&max_status_size);
BEGIN
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLORA_GETERRORSTACK' AND TYPE = 'FUNCTION';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (1.1)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'CREATE_TRACE' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (2)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'TRACE_PUT_LINE' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (3)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'FILE_SEPARATOR' AND TYPE = 'FUNCTION';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (3.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'INITIAL_SETUP' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (4)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLORA_GETLOBS' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (4.1)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLORA_GETALLCOLSLOGGING' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (4.2)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (5)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLVERSIONSPECIFIC' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (5.1)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLREPLICATION' AND TYPE ='PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (6)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_rules';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (6.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_rules_log';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (6.2)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (6.3)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = '&gg_user' AND name = 'DDLAUX' AND TYPE = 'PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (6.4)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' 6.5)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN '&errC' || ' (6.6)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_hist_table';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (7)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&enc_schema' AND table_name = '&enc_table';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (7.0)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_hist_table' || '_ALT';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (7.1)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_tables';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (8)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_columns';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (9)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_log_groups';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (A)';
    END IF;
    
    SELECT COUNT(*) INTO someErr 
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_partitions';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (B)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = '&ddl_dump_primary_keys';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (C)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = 'GGS_TEMP_COLS';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (C1)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = '&gg_user' AND table_name = 'GGS_TEMP_UK';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (C2)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_sequences WHERE sequence_owner = '&gg_user' AND sequence_name = '&ddl_sequence';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (D)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_errors a, dual WHERE owner = 'SYS' AND name = '&ddl_trigger_name' AND TYPE = 'TRIGGER' ;
    IF someErr <> 0 THEN
        RETURN '&errC' || ' (E)';
    END IF;
    
    SELECT COUNT(*) INTO someErr
    FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = '&ddl_trigger_name';
    IF 0 = someErr THEN
        RETURN '&errC' || ' (F)';
    END IF;
    
    SELECT status INTO  trigStat 
    FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = '&ddl_trigger_name';
    
    IF trigStat <> 'ENABLED' THEN
        RETURN 'WARNING: DDL Trigger is NOT enabled. ' || '&sucC';
    ELSE
        RETURN '&sucC';
    END IF;
    
    
END;
/
show errors

/*
FUNCTION ggsuser.file_separator RETURNS CHAR
This function returns the file path separator.
remarks This function is global of nature.
*/
CREATE OR REPLACE FUNCTION "&gg_user".file_separator
RETURN CHAR 
IS 
dump_dir VARCHAR2(&file_name_size); 
errorMessage VARCHAR2(&message_size);
fileSeparator CHAR := '/';
BEGIN
    
    SELECT VALUE INTO dump_dir 
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;
    
      IF instr(dump_dir,'/') > 0 THEN
        fileSeparator := '/';
      ELSIF instr(dump_dir,'\') > 0 THEN
        fileSeparator := '\';
      END IF;

      RETURN fileSeparator;
END file_separator;
/
show errors


/*
PROCEDURE ggsuser.create_trace
Creates tracing environment for DDL replication
remarks All tracing code is outside package because we must trace package creation as well
*/
CREATE OR REPLACE PROCEDURE "&gg_user".create_trace IS 
dump_dir VARCHAR2(&file_name_size); 
errorMessage VARCHAR2(&message_size);
BEGIN
    
    SELECT VALUE INTO dump_dir 
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;
    
    EXECUTE IMMEDIATE 'create or replace directory &trace_directory as ''' || dump_dir || ''''; 
    
EXCEPTION 
    WHEN OTHERS THEN 
        errorMessage := 'create_trace: ' || ':' || SQLERRM; 
        dbms_output.put_line (errorMessage);
        RAISE;
END create_trace;
/
show errors


/*
PROCEDURE ggsuser.clear_trace
Clears trace file
remarks All tracing code is outside package because we must trace package creation as well
see ddl_cleartrace.sql
*/
CREATE OR REPLACE PROCEDURE "&gg_user".clear_trace 
IS
output_file utl_file.file_type;
errorMessage VARCHAR2(&message_size);
BEGIN
    
    utl_file.fremove ('&trace_directory', '&trace_file'); 
EXCEPTION 
    WHEN OTHERS THEN
        IF SQLCODE <>  - 29283 THEN -- avoid 'file not found' 
            errorMessage := 'trace_put_line: ' || ':' || SQLERRM; 
            RAISE;
        END IF;
END clear_trace;
/
show errors

/*
PROCEDURE ggsuser.trace_put_line
Writes data to trace file. Data can be of any size as proper splitting is done. 
param[in] OPER                           VARCHAR2                message identifier (scope)
param[in] MESSAGE                        VARCHAR2                message itself
remarks All tracing code is outside package because we must trace package creation as well
*/
CREATE OR REPLACE PROCEDURE "&gg_user".trace_put_line (
                                                        oper VARCHAR2,
                                                        message VARCHAR2)
IS
output_file utl_file.file_type;
errorMessage VARCHAR2(&message_size);
total_fragments NUMBER;
line_size NUMBER;
prepLine VARCHAR2(&message_size);
i NUMBER;
BEGIN
    
    output_file := utl_file.fopen ('&trace_directory', '&trace_file', 'A', max_linesize => &max_varchar2_size);
    prepLine := 'SESS ' || USERENV('SESSIONID') || '-' || 
    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') || ' : ' || oper || ' : ';
    utl_file.put (output_file, prepLine);
    line_size := &output_line_size - lengthb (prepLine) - 1;
    total_fragments := lengthb (message) / line_size + 1;
    IF total_fragments * line_size = lengthb (message) THEN
        total_fragments := total_fragments - 1;
    END IF;
    
    -- line cannot be bigger than approx 1000 bytes so split it up other        
    FOR i IN 1..total_fragments LOOP 
        utl_file.put_line (output_file, substrb (message, (i - 1) * line_size + 1, line_size));
    END LOOP;
    
    utl_file.fCLOSE (output_file);
EXCEPTION 
    WHEN OTHERS THEN 
        --
        -- If tracing fails, trigger *will not* fail:
        --
        -- closing file can cause an error too, so it's all in vain if we don't check
        BEGIN
            utl_file.fCLOSE (output_file);
        EXCEPTION 
            WHEN OTHERS THEN 
                NULL;
        END;
        errorMessage := 'trace_put_line: ' || ':' || SQLERRM; 
        -- we will not raise error here, probably out of space
        -- we will sacrifice tracing capability for trigger continuing to work
        -- othewise we would do:
        -- RAISE;
        NULL;
END trace_put_line;
/
show errors



/*
PROCEDURE ggsuser.initial_setup
Create objects necessary for tracing, GGSCI/SHOW, support indexes etc (all support objects)
remarks This code is outside package because it creates objects used by it
*/
CREATE OR REPLACE PROCEDURE "&gg_user".initial_setup IS 
dump_dir VARCHAR2(&file_name_size);
errorMessage VARCHAR2(&message_size);
BEGIN
    
    IF '&gg_mode' = 'INITIALSETUP' AND ('&_skip_create_objects' = 'FALSE' AND '&_skip_lock_check' IS NULL) THEN 
        BEGIN
         execute immediate 'DROP TABLE "&gg_user"."&ddl_rules"';
        EXCEPTION WHEN OTHERS THEN
         null;
        END;
        BEGIN 
            execute immediate 'CREATE TABLE "&gg_user"."&ddl_rules"'||
              ' ( SNO NUMBER PRIMARY KEY, '||
              ' OBJ_NAME VARCHAR2(200),OWNER_NAME VARCHAR2(200),' ||
              ' BASE_OBJ_NAME VARCHAR2(200), BASE_OWNER_NAME VARCHAR2(200),'||
              ' BASE_OBJ_PROPERTY NUMBER, OBJ_TYPE NUMBER,'||
              ' COMMAND VARCHAR2(50),'||
              ' INCLUSION NUMBER)';

        EXCEPTION 
            WHEN OTHERS THEN 
                dbms_output.put_line(SQLERRM);
                errorMessage := 'Creating &ddl_rules table' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END; 

        BEGIN
         execute immediate 'DROP TABLE "&gg_user"."&ddl_rules_log"';
        EXCEPTION WHEN OTHERS THEN
         null;
        END;
        BEGIN 
            execute immediate 'CREATE TABLE "&gg_user"."&ddl_rules_log"'||
              ' ( SNO NUMBER , '||
              ' OBJ_NAME VARCHAR2(200),OWNER_NAME VARCHAR2(200),' ||
              ' BASE_OBJ_NAME VARCHAR2(200), BASE_OWNER_NAME VARCHAR2(200),'||
              ' BASE_OBJ_PROPERTY NUMBER, OBJ_TYPE NUMBER,'||
              ' COMMAND VARCHAR2(50))';

        EXCEPTION 
            WHEN OTHERS THEN 
                dbms_output.put_line(SQLERRM);
                errorMessage := 'Creating &ddl_rules_log table' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END; 
       
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."GGS_TEMP_COLS"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping temp cols table' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        BEGIN            
            EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE "&gg_user"."GGS_TEMP_COLS" (' ||
            'seqNo            NUMBER NOT NULL, ' ||
            'colName        VARCHAR2(&name_size), ' ||
            'nullable          NUMBER, ' ||
            'virtual          NUMBER, ' ||
            'udt            NUMBER, ' ||
            'isSys          NUMBER, ' ||
            'primary key (seqNo, colName) ' ||
            ') on commit preserve rows';

        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating temp col table' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END; 
        
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."GGS_TEMP_UK"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping temp uk table' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        BEGIN            
            EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE "&gg_user"."GGS_TEMP_UK" (' ||
            'seqNo            NUMBER NOT NULL, ' ||
            'keyName        VARCHAR2(&name_size), ' ||
            'colName        VARCHAR2(&name_size), ' ||
            'nullable       NUMBER, ' ||            
            'virtual           NUMBER, ' ||            
            'udt            NUMBER, ' ||            
            'isSys            NUMBER, ' ||            
            'primary key (seqNo, keyName, colName) ' ||
            ') on commit preserve rows';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating temp uk table' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END;
        
        BEGIN
			EXECUTE IMMEDIATE 'TRUNCATE TABLE "&gg_user"."GGS_STICK"';
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."GGS_STICK"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping temp stick table' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END; 
        BEGIN            
            EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE "&gg_user"."GGS_STICK" (' ||
            'property            VARCHAR2(&name_size) NOT NULL, ' ||
            'value			 VARCHAR2(&name_size), ' ||            
            'primary key (property)' ||
            ') on commit preserve rows';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating temp stick table' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END; 
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&setup_table"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping trace setup table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        BEGIN            
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&setup_table" (' ||
            'property        VARCHAR2(&name_size), ' ||
            'value          VARCHAR2 (&frag_size), ' ||
            'constraint &setup_table' || '_ukey unique (property) ' ||
            ')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''DDL_TRACE_LEVEL'',' ||
            '''0'')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''DDL_SQL_TRACING'',' ||
            '''0'')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''_USEALLKEYS'',' ||
            '''0'')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''ALLOWNONVALIDATEDKEYS'',' ||
            '''0'')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''_LIMIT32K'',' ||
            '''0'')';
            EXECUTE IMMEDIATE 'insert into "&gg_user"."&setup_table" (' ||
            ' property,' ||
            ' value)' ||
            'values ( ' ||
            '''DDL_STAYMETADATA'',' ||
            '''OFF'')';
            
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating trace setup table: ' || ':' || SQLERRM; 
                raise_application_error (&trigger_error_code, errorMessage || ':' || SQLERRM);
        END; 
        
        "&gg_user".create_trace; 
        "&gg_user".trace_put_line ('DDL', 'Initial setup starting'); 
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE "&gg_user"."&ddl_sequence"'; 
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 2289 THEN -- do not exist error is ok
                    errorMessage := 'Dropping DDL sequence: ' || ':' || SQLERRM;
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE SEQUENCE "&gg_user"."&ddl_sequence" ' ||
            'INCREMENT BY 1 ' ||            
            'CACHE 500 ' ||            
            'MINVALUE 1 ' ||
            'MAXVALUE 9999999999999999999999999999 CYCLE';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL sequence: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_hist_table_alt"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL history table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END; 
        BEGIN
            -- reason for both altObjectId and objectId being primary key
            -- is performance. Oracle would have to fetch objectId as data (separate read)
            -- this way it only uses index
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_hist_table_alt" (' ||
            'altObjectId		NUMBER, ' ||
            'objectId	NUMBER, ' ||
            'optime			CHAR(&time_size) NOT NULL)';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDLALT history table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        BEGIN
            -- reason for both altObjectId and objectId being primary key
            -- is performance. Oracle would have to fetch objectId as data (separate read)
            -- this way it only uses index
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table_alt' || '_u1" ON  ' ||
            '"&gg_user"."&ddl_hist_table_alt" (' ||            
            'objectId, altObjectId)'; 
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDLALT history table unique index: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        BEGIN            
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table_alt' || '_u2" ON  ' ||
            '"&gg_user"."&ddl_hist_table_alt" (' ||            
            'optime)'; 
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDLALT history table unique index: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END;         
        BEGIN
            -- reason for both altObjectId and objectId being primary key
            -- is performance. Oracle would have to fetch objectId as data (separate read)
            -- this way it only uses index
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table_alt' || '_u3" ON  ' ||
            '"&gg_user"."&ddl_hist_table_alt" (' ||            
            'altObjectId, objectId)'; 
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDLALT history table unique index: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_hist_table"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL history table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END; 
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_hist_table" (' ||
            'seqNo            NUMBER NOT NULL, ' ||
            'objectId        NUMBER, ' ||
            'dataObjectId    NUMBER, ' ||
            'ddlType        VARCHAR2(&type_size), ' ||
            'objectName        VARCHAR2(&name_size), ' ||
            'objectOwner    VARCHAR2(&name_size), ' ||
            'objectType     VARCHAR2(&type_size), ' ||
            'fragmentNo        NUMBER NOT NULL, ' ||
            'optime            CHAR(&time_size) NOT NULL, ' ||
            'startSCN        NUMBER, ' || 
            'metadata_text        VARCHAR2 (&frag_size) NOT NULL, ' || 
            'auditcol            VARCHAR2 (&audit_size) ' ||
            ')';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i1" on "&gg_user"."&ddl_hist_table" (seqno, fragmentNo)';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i2"  on "&gg_user"."&ddl_hist_table" (objectid, startSCN, fragmentNo)';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i3"  on "&gg_user"."&ddl_hist_table" (startSCN, fragmentNo)';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i4"  on "&gg_user"."&ddl_hist_table" (objectName, objectOwner, objectType, startSCN, fragmentNo)';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i5"  on "&gg_user"."&ddl_hist_table" (optime)';
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user"."&ddl_hist_table' || '_i6"  on "&gg_user"."&ddl_hist_table" (startSCN, auditcol, fragmentNo)';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL history table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        BEGIN
            EXECUTE IMMEDIATE 'CREATE INDEX "&gg_user".&ddl_hist_table' || '_index1 ON "&gg_user"."&ddl_hist_table" (' || 
            'objectId)';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL history table index: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END;
        
        -- create debugging tables for DUMPDDL purposes
        -- no indexes, user can create indexes if needed, probably not
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_dump_columns"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL dump columns table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_dump_columns" (' ||
            'seqNo            NUMBER NOT NULL, ' ||
            'name    varchar2(&name_size),' ||
            'pos    number,' ||
            'type    varchar2(&type_size),' ||
            'length    number,' || 
            'isnull    varchar2(&valid_size),' ||
            'prec    number,' ||
            'scale    number,' || 
            'charsetid    varchar2(&charsetid_size),' ||
            'charsetform    varchar2(&charsetform_size),' ||
            'segpos    number,' ||
            'altname    varchar2(&name_size),' || 
            'alttype    varchar2(&type_size),' ||
            'altprec    number,' || 
            'altcharused    varchar2(&charused_size),' ||
            'altxmltype    varchar2(&xmltype_size)' || 
            ')';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL dump columns table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_dump_log_groups"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL dump log groups table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_dump_log_groups" (' ||
            'seqNo            NUMBER NOT NULL, ' || 
            'column_name    varchar2(&name_size) ' || 
            ')';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL dump log groups table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_dump_partitions"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL dump partitions table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_dump_partitions" (' ||
            'seqNo            NUMBER NOT NULL, ' || 
            'partition_id    number ' || 
            ')';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL dump parititions table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_dump_primary_keys"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL dump primary keys table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_dump_primary_keys" (' ||
            'seqNo            NUMBER NOT NULL, ' || 
            'column_name    varchar2(&name_size) ' || 
            ')';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL dump primary keys table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "&gg_user"."&ddl_dump_tables"';
        EXCEPTION 
            WHEN OTHERS THEN 
                IF SQLCODE !=  - 942 THEN
                    errorMessage := 'Dropping DDL dump table: ' || ':' || SQLERRM; 
                    "&gg_user".trace_put_line ('DDL', errorMessage); 
                    RAISE;
                END IF;
        END;
        
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE "&gg_user"."&ddl_dump_tables" (' ||
            'seqNo            NUMBER NOT NULL, ' ||
            'optime            CHAR(&time_size) NOT NULL, ' || 
            'marker_table    varchar2 (&name_size),' ||
            'marker_seq        number,'||
            'start_scn        number,' ||
            'optype            varchar2(&type_size),' ||
            'objtype        varchar2(&type_size),' || 
            'db_blocksize    number,' ||
            'objowner        varchar2(&name_size),' ||
            'objname        varchar2(&name_size),' ||
            'objectid        number, ' || 
            'master_owner    varchar2(&name_size),' ||
            'master_name    varchar2(&name_size),' ||
            'data_objectid    number, ' ||
            'valid            varchar2(&valid_size),' || 
            'cluster_cols    number,' ||
            'log_group_exists    varchar2(&bool_size),' ||
            'subpartition        varchar2(&bool_size),' ||
            'partition    varchar2(&bool_size),' ||
            'primary_key    varchar2(&name_size),' ||
            'total_cols    number,' ||
            'cols_count    number,' ||
            'ddl_statement   CLOB' || 
            ')';
        EXCEPTION 
            WHEN OTHERS THEN 
                errorMessage := 'Creating DDL dump table: ' || ':' || SQLERRM; 
                "&gg_user".trace_put_line ('DDL', errorMessage); 
                RAISE;
        END; 
        
        
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        errorMessage := 'initial_setup: ' || ':' || SQLERRM; 
        "&gg_user".trace_put_line ('DDL', errorMessage); 
        RAISE;
END initial_setup;
/
show errors


/* 
At this point we have support structures/tracing
Execute initial setup (creation of support objects)
and proceed to package setup
*/


exec "&gg_user".initial_setup;
exec "&gg_user".trace_put_line ('DDL', 'STARTING DDL REPLICATION SETUP');


/*
DDL Replication package declaration
*/

CREATE OR REPLACE PACKAGE "&gg_user".DDLReplication AS
    
    /*
    Note about naming convention for constants:
    MD (metadata) constants    
    MK (marker) constants
    NOTE: constant strings can be of any length up to 9(for example 'A1' or 'B2')
    NOTE: constant string cannot start with a digit
    NOTE: constant string cannot contain comma 
    they are shortened to one byte or two bytes to produce less bulky output and save space in history tables
    */

    tversion CONSTANT VARCHAR2 (200) := '$Id: ddl_setup.sql /st_oggcore_11.2.1/15 2012/08/01 11:51:29 mcusson Exp $ ';
    
    -- metadata columns
    -- IMPORTANT: when adding new ones, add them to tracing reporting routines
    MD_TAB_USERID CONSTANT VARCHAR2 (3) := 'A1';
    MD_COL_NAME CONSTANT VARCHAR2 (3) := 'A2';
    MD_COL_NUM CONSTANT VARCHAR2 (3) := 'A3';
    MD_COL_SEGCOL CONSTANT VARCHAR2 (3) := 'A4';
    MD_COL_TYPE CONSTANT VARCHAR2 (3) := 'A5';
    MD_COL_LEN CONSTANT VARCHAR2 (3) := 'A6';
    MD_COL_ISNULL CONSTANT VARCHAR2 (3) := 'A7';
    MD_COL_PREC CONSTANT VARCHAR2 (3) := 'A8';
    MD_COL_SCALE CONSTANT VARCHAR2 (3) := 'A9';
    MD_COL_CHARSETID CONSTANT VARCHAR2 (3) := 'B1';
    MD_COL_CHARSETFORM CONSTANT VARCHAR2 (3) := 'A';
    MD_COL_ALT_NAME CONSTANT VARCHAR2 (3) := 'C';
    MD_COL_ALT_TYPE CONSTANT VARCHAR2 (3) := 'D';
    MD_COL_ALT_PREC CONSTANT VARCHAR2 (3) := 'E';
    MD_COL_ALT_CHAR_USED CONSTANT VARCHAR2 (3) := 'F';
    MD_COL_ALT_XML_TYPE CONSTANT VARCHAR2 (3) := 'G';
    MD_TAB_COLCOUNT CONSTANT VARCHAR2 (3) := 'H';
    MD_TAB_DATAOBJECTID CONSTANT VARCHAR2 (3) := 'I';
    MD_TAB_CLUCOLS CONSTANT VARCHAR2 (3) := 'J';
    MD_TAB_TOTAL_COL_NUM CONSTANT VARCHAR2 (3) := 'K';
    MD_TAB_LOG_GROUP_EXISTS CONSTANT VARCHAR2 (3) := 'L';
    MD_COL_ALT_LOG_GROUP_COL CONSTANT VARCHAR2 (3) := 'M';
    MD_TAB_VALID CONSTANT VARCHAR2 (3) := 'N';
    MD_TAB_SUBPARTITION CONSTANT VARCHAR2 (3) := 'O';
    MD_TAB_PARTITION CONSTANT VARCHAR2 (3) := 'P';
    MD_TAB_PARTITION_IDS CONSTANT VARCHAR2 (3) := 'Q';
    MD_TAB_BLOCKSIZE CONSTANT VARCHAR2 (3) := 'R';
    MD_TAB_OBJECTID CONSTANT VARCHAR2 (3) := 'S';
    MD_TAB_PRIMARYKEY CONSTANT VARCHAR2 (3) := 'T'; 
    MD_TAB_PRIMARYKEYNAME CONSTANT VARCHAR2 (3) := 'V';
    MD_TAB_OWNER CONSTANT VARCHAR2 (3) := 'W';
    MD_TAB_NAME CONSTANT VARCHAR2 (3) := 'X';
    MD_TAB_OBJTYPE CONSTANT VARCHAR2 (3) := 'Y';
    MD_TAB_OPTYPE CONSTANT VARCHAR2 (3) := 'Z'; 
    MD_TAB_SCN CONSTANT VARCHAR2 (3) := 'C2';
    MD_TAB_MASTEROWNER CONSTANT VARCHAR2 (3) := 'C3'; 
    MD_TAB_MASTERNAME CONSTANT VARCHAR2 (3) := 'C4'; 
    MD_TAB_MARKERSEQNO CONSTANT VARCHAR2 (3) := 'C5'; 
    MD_TAB_MARKERTABLENAME CONSTANT VARCHAR2 (3) := 'C6'; 
    MD_TAB_DDLSTATEMENT CONSTANT VARCHAR2 (3) := 'G1'; 
    MD_TAB_BIGFILE CONSTANT VARCHAR2 (3) := 'G2'; 
    MD_TAB_ISINDEXUNIQUE CONSTANT VARCHAR2 (3) := 'G3'; 
    MD_TAB_SEQUENCEROWID CONSTANT VARCHAR2 (3) := 'G4'; 
    MD_TAB_SEQCACHE CONSTANT VARCHAR2 (3) := 'G5'; 
    MD_TAB_SEQINCREMENTBY CONSTANT VARCHAR2 (3) := 'G6'; 
    MD_TAB_IOT CONSTANT VARCHAR2 (3) := 'G7'; 
    MD_TAB_IOT_OVERFLOW CONSTANT VARCHAR2 (3) := 'G8'; 
    MD_COL_ALT_BINARYXML_TYPE CONSTANT VARCHAR2 (3) := 'G9';
    MD_COL_ALT_LENGTH CONSTANT VARCHAR2 (3) := 'G10';
    MD_TAB_CLUSTER CONSTANT VARCHAR2 (3) := 'G11'; 
    MD_TAB_CLUSTER_COLNAME CONSTANT VARCHAR2 (3) := 'G12'; 
    MD_COL_ALT_TYPE_OWNER CONSTANT VARCHAR2 (3) := 'G13';
    MD_TAB_SESSION_OWNER CONSTANT VARCHAR2 (3) := 'G14'; -- not used in trigger, used in extract only
    MD_TAB_ENC_MKEYID CONSTANT VARCHAR2 (3) := 'G15';
    MD_TAB_ENC_ENCALG CONSTANT VARCHAR2 (3) := 'G16';
    MD_TAB_ENC_INTALG CONSTANT VARCHAR2 (3) := 'G17';
    MD_TAB_ENC_COLKLC CONSTANT VARCHAR2 (3) := 'G18';
    MD_TAB_ENC_KLCLEN CONSTANT VARCHAR2 (3) := 'G19';
    MD_COL_ENC_ISENC CONSTANT VARCHAR2 (3) := 'G20';
    MD_COL_ENC_NOSALT CONSTANT VARCHAR2 (3) := 'G21'; 
    MD_COL_ENC_ISLOB CONSTANT VARCHAR2 (3) := 'G22'; 
    MD_COL_LOB_ENCRYPT CONSTANT VARCHAR2 (3) := 'G23'; 
    MD_COL_LOB_COMPRESS CONSTANT VARCHAR2 (3) := 'G24'; 
    MD_COL_LOB_DEDUP CONSTANT VARCHAR2 (3) := 'G25'; 
    MD_COL_ALT_OBJECTXML_TYPE CONSTANT VARCHAR2 (3) := 'G26';
    MD_COL_HASNOTNULLDEFAULT CONSTANT VARCHAR2 (3) := 'G27';
    MD_TAB_XMLTYPETABLE CONSTANT VARCHAR2 (3) := 'G28';

    --
    -- from now on, use G28 and on for hist
    --
    
    -- marker  constants
    MK_OBJECTID CONSTANT VARCHAR2 (3) := 'B2';
    MK_OBJECTOWNER CONSTANT VARCHAR2 (3) := 'B3';
    MK_OBJECTNAME CONSTANT VARCHAR2 (3) := 'B4';
    MK_OBJECTTYPE CONSTANT VARCHAR2 (3) := 'B5';
    MK_DDLTYPE CONSTANT VARCHAR2 (3) := 'B6';
    MK_DDLSEQ CONSTANT VARCHAR2 (3) := 'B7';
    MK_DDLHIST CONSTANT VARCHAR2 (3) := 'B8';
    MK_LOGINUSER CONSTANT VARCHAR2 (3) := 'B9';
    MK_DDLSTATEMENT CONSTANT VARCHAR2 (3) := 'C1'; 
    MK_TAB_VERSIONINFO CONSTANT VARCHAR2 (3) := 'C7'; 
    MK_TAB_VERSIONINFOCOMPAT CONSTANT VARCHAR2 (3) := 'C8'; 
    MK_TAB_VALID CONSTANT VARCHAR2 (3) := 'C9'; 
    MK_INSTANCENUMBER CONSTANT VARCHAR2 (3) := 'C10';
    MK_INSTANCENAME CONSTANT VARCHAR2 (3) := 'C11';
    MK_MASTEROWNER CONSTANT VARCHAR2 (3) := 'C12';
    MK_MASTERNAME CONSTANT VARCHAR2 (3) := 'C13';
    MK_TAB_OBJECTTABLE CONSTANT VARCHAR2 (3) := 'C14';
    MK_TAB_TOIGNORE CONSTANT VARCHAR2 (3) := 'C15'; 
    MK_TAB_NLS_PARAM CONSTANT VARCHAR2 (3) := 'C17';
    MK_TAB_NLS_VAL CONSTANT VARCHAR2 (3) := 'C18';
    MK_TAB_NLS_CNT CONSTANT VARCHAR2 (3) := 'C19';
    MK_TAB_XMLTYPETABLE CONSTANT VARCHAR2 (3) := 'C20';
    
    --
    -- IMPORTANT: when adding new constants (marker/history), add them to tracing reporting routines (trace_header_name())
    --
    
    
    -- fragment data constants
    GENERIC_MARKER CONSTANT INTEGER := 0; 
    DDL_HISTORY CONSTANT INTEGER := 1;
    BEGIN_FRAGMENT CONSTANT INTEGER := 0; 
    ADD_FRAGMENT CONSTANT INTEGER := 1; 
    END_FRAGMENT CONSTANT INTEGER := 2;
    SOLE_FRAGMENT CONSTANT INTEGER := 3;
    ADD_FRAGMENT_AND_FLUSH CONSTANT INTEGER := 4;
    
    -- itemheader constants used to store data in marker larger than 32K
    ITEM_WHOLE CONSTANT INTEGER := 0;
    ITEM_HEAD CONSTANT INTEGER := 1;
    ITEM_TAIL CONSTANT INTEGER := 2;
    ITEM_DATA CONSTANT INTEGER := 3;

    MAX_NUMCHAR_PER_CHUNK CONSTANT INTEGER := 1333;
    
    escapeChars VARCHAR2(100) := '\'',=()';     -- special chars for metadata string
    escapeCharsLen CONSTANT INTEGER :=  6; -- if changing escapeChars, change this too!!  

    -- variables for fragmenting
    current_fragment INTEGER;
    current_fragment_raw    RAW(&max_varchar2_size);
    
    -- DDL trigger constants
    triggerErrorMessage VARCHAR2(&message_size) := 'Oracle GoldenGate DDL Replication Error: Code '; 
    
    -- sequences (marker, history)
    currentMarkerSeq NUMBER;
    currentDDLSeq NUMBER;
        
    -- current object id (of the object being processed for DDL, if any, otherwise NULL)
    currentObjectId NUMBER;
    currentRowid VARCHAR2(&max_varchar2_size);
    currentDataObjectId NUMBER;
    currentObjectName VARCHAR2(&java_name_size);
    currentDDLType VARCHAR2(&type_size);
    currentObjectOwner VARCHAR2(&name_size);
    currentObjectType VARCHAR2(&type_size);
    currentMasterOwner VARCHAR2(&name_size);
    currentMasterName VARCHAR2(&name_size);
    
    errorMessage VARCHAR2(&message_size);
    
    -- Start SCN
    SCNB NUMBER;
    SCNW NUMBER;
    
    -- TDE constants
    ENC_ISENC CONSTANT NUMBER := 67108864; -- 0x04000000 hex
    ENC_ISNOSALT CONSTANT NUMBER := 536870912; -- 0x20000000  hex
    ENC_ISLOB CONSTANT NUMBER := 128; -- 0x80 hex

    -- does column have default value?
    COL_HASNOTNULLDEFAULT CONSTANT NUMBER := 1073741824; -- 0x40000000 hex

    -- OBJTABLE constants, this is referring to property bit
    OBJTAB CONSTANT NUMBER := 1;
    
    -- XMLTYPE constants, this is referring to opqtype$.flags bit
    XMLOBJECT CONSTANT NUMBER := 1;
    XMLLOB CONSTANT NUMBER := 4;
    XMLBINARY CONSTANT NUMBER := 64;
    XMLTAB CONSTANT NUMBER := 1024;
    
    -- IOT constants
    IOT CONSTANT NUMBER := 64;
    IOT_WITH_OVERFLOW CONSTANT NUMBER := 128;
    IOT_OVERFLOW_TABLE CONSTANT NUMBER := 512;
    
    -- cluster constants
    CLUSTER_TABLE CONSTANT NUMBER := 1024;
    
    deadlockDetected EXCEPTION;
    PRAGMA EXCEPTION_INIT (deadlockDetected, -60);

    -- location of trace directory
    dumpDir VARCHAR2(&file_name_size) := ''; 

    -- query from v$DATABAE
    dbQueried boolean := FALSE;

    
    inumber NUMBER := NULL;
    iname VARCHAR2(&name_size):= NULL;

    
    -- version info
    lv_version VARCHAR2(&version_size) := '';
    lv_compat VARCHAR2(&version_size) := ''; 
    lv_ora_db_block_size NUMBER := 0;
    
    -- tracing variables
    readTrace boolean := FALSE;
    trace_level NUMBER := 0; -- by default no tracing, can be 1 or 2 for more details
    sql_trace NUMBER := 0; -- by default no sql tracing, can be 0 or 1, this is for SQL TRACE (oracle's)
    useAllKeys NUMBER := 0; -- by default UKs are computed based on virtual/null, old method used all cols
    allowNonValidatedKeys NUMBER := 0; -- by default, keys need to be validated
    stay_metadata NUMBER := 0; -- by default query db and get metadata, 1 is useful for imports

    -- large DDL , max total DDL size is 2048K-someOdd bytes (2047K)
    useLargeDDL NUMBER := 1;    

    -- simulate out of space if binary length is over 32K
    -- (for example number of characters can be less but number of bytes can be more)
    stringErrorSimulate EXCEPTION;
    PRAGMA EXCEPTION_INIT (stringErrorSimulate, -6502);
    
    -- raisable errors
    -- errors which should be raised up out of the DDL trigger
    -- e.g. raisable_errors VARCHAR2(18) := '-12751-01476-12545';
    raisable_errors VARCHAR2(6) := '-12751';
    
    -- optimization variables
    ddlObjNum  NUMBER := -1;
    ddlObjType  NUMBER := -1;
    ddlBaseObjNum NUMBER := -1;
    ddlObjUserId  NUMBER := -1;
    ddlBaseObjUserId NUMBER := -1;
    ddlBaseObjProperty NUMBER := -1;

    checkSchemaTabf NUMBER := -1;

    -- cursors to obtain metadata
    
    CURSOR nls_settings IS
		SELECT parameter, value 
		FROM nls_session_parameters;
    
    
    -- get binary XML info
    CURSOR is_binary (tabObjNum IN NUMBER, tableName IN VARCHAR2, tableOwner IN VARCHAR2, colId IN NUMBER) IS 
        SELECT TYPE# FROM
            (SELECT c.type#, c.segcol# 
            FROM sys.col$ c, sys.obj$ o, sys.user$ u 
            WHERE o.owner#=u.user# AND c.obj#=o.obj# AND o.obj# = tabObjNum  
            AND col# = colId ) 
        WHERE segcol# > 0;
    
    
    --  primary key    
    CURSOR pk_curs (ptabid IN NUMBER, powner IN VARCHAR2, ptable IN VARCHAR2) IS
        SELECT c.constraint_name, 
                    c.column_name 
               FROM dba_cons_columns c 
              WHERE c.owner = powner
                AND c.table_name = ptable
                AND c.constraint_name = 
                    (SELECT c1.name 
                       FROM sys.user$ u1, 
                            sys.user$ u2, 
                            sys.cdef$ d, 
                            sys.con$ c1, 
                            sys.con$ c2, 
                            sys.obj$ o1, 
                            sys.obj$ o2 
                      WHERE o1.obj# = ptabid 
                        AND d.type# = 2 
                        AND decode(d.type#, 5, 'ENABLED', decode(d.enabled, NULL, 'DISABLED', 'ENABLED')) = 'ENABLED' 
                        AND bitand(d.defer, 36) != 0 
                        AND c2.owner# = u2.user#(+) 
                        AND d.robj# = o2.obj#(+) 
                        AND d.rcon# = c2.con#(+) 
                        AND o1.owner# = u1.user# 
                        AND d.con# = c1.con# 
                        AND d.obj# = o1.obj#) 
                AND EXISTS 
                    (SELECT 'Y' 
                       FROM dba_tab_columns 
                      WHERE owner = powner 
                        AND table_name = ptable 
                        AND column_name = c.column_name) 
             ORDER BY c.position;
    
              
    
    
    -- get column defs
    CURSOR getCols (ptabid IN NUMBER, powner IN VARCHAR2, ptable IN VARCHAR2) IS
        SELECT 
            c.name column_name, c.col# col_num, c.intcol# intcol_num,
            c.segcol# segcol_num,
            c.type# type_num, c.length, 1 - c.null$ isnull,
            c.precision# precision_num, c.scale, c.charsetid, c.charsetform, 
            decode (bitand (c.property, COL_HASNOTNULLDEFAULT), COL_HASNOTNULLDEFAULT, 'YES', 'NO') hasNotnullDefault,
            decode (bitand (c.property, ENC_ISENC), ENC_ISENC, 'YES', 'NO') isEnc,
            decode (bitand (c.property, ENC_ISNOSALT), ENC_ISNOSALT, 'YES', 'NO') isNoSalt,
            decode (bitand (c.property, ENC_ISLOB), ENC_ISLOB, 'YES', 'NO') isLob
        FROM sys.col$ c
        WHERE c.obj# = ptabid
            AND bitand (c.property, 32) = 0  -- visible columns
            ORDER BY c.col#, c.segcol#;  -- order by segcol too to eliminate cols of UDT we don't want
    
    -- get table info
    CURSOR getTable IS
        SELECT o.dataobj# data_object_id, t.clucols clucols
        FROM sys.obj$ o, sys.tab$ t
        WHERE o.obj# = DDLReplication.currentObjectId AND t.obj# = DDLReplication.currentObjectId;
    
    -- get precision     
    CURSOR getPrec (powner IN VARCHAR2, ptable IN VARCHAR2, colname IN VARCHAR2) IS
        SELECT data_type, data_type_owner, data_precision, char_used, data_length FROM dba_tab_columns 
        WHERE owner = powner AND table_name = ptable AND column_name = colname;
    
    -- get XML type info
    CURSOR getXMLStorage (powner IN VARCHAR2, ptable IN VARCHAR2, colname IN VARCHAR2) IS
        SELECT opq.flags opq_flags
        FROM dba_objects o, sys.col$ c, sys.opqtype$ opq
        WHERE o.owner = powner AND o.object_name = ptable AND o.object_type = 'TABLE'
            AND c.obj# = o.object_id AND c.obj# = opq.obj# AND opq.type = 1
            AND c.intcol# = opq.intcol# and c.name = colname;
	
    -- get alternative object id        
    CURSOR alt_objects (objName IN VARCHAR2, objOwner IN VARCHAR2, objType IN VARCHAR2) IS
        SELECT object_id
        FROM dba_objects
        WHERE object_name = objName AND
        owner = objOwner AND
        object_type = objType;
    
    -- get columns from supplemental log group        
    CURSOR loggroup_suplog (s_log_group_name IN VARCHAR2, powner IN VARCHAR2, ptable IN VARCHAR2 ) IS
        SELECT column_name
        FROM dba_log_group_columns
        WHERE log_group_name = s_log_group_name AND
            owner = powner AND
            table_name = ptable; 
    
    -- get IOT alternative IDs
    CURSOR iotAltId (objId IN NUMBER, objOwner IN VARCHAR2, objName IN VARCHAR2) IS
        SELECT i.obj# object_id  FROM sys.ind$ i, sys.obj$ o where i.bo# = objId 
              and o.obj# = i.obj#;
    
    CURSOR iotOverflowAltId (objOwner IN VARCHAR2, objName IN VARCHAR2) IS
        SELECT object_id 
            FROM dba_objects
            WHERE object_name = 
                (SELECT table_name 
                FROM dba_tables 
                WHERE
                iot_name = objName and owner = objOwner and iot_type='IOT_OVERFLOW' and rownum=1) AND
                owner = objOwner;
    
    /*
    Prototypes for package implementation

    */ 
    PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER, 
                         baseObjProperty IN NUMBER);

    PROCEDURE getObjTypeName(obj_type IN NUMBER, objtype OUT VARCHAR2) ;
    PROCEDURE getObjType(objtype IN VARCHAR2, obj_type OUT NUMBER) ;
    PROCEDURE getDDLObjInfo(objtype IN VARCHAR2, ddlevent IN VARCHAR2,
                            powner IN VARCHAR2, pobj IN VARCHAR2);

    PROCEDURE getDDLBaseObjInfo(ddlevent IN VARCHAR2,
                            pbaseowner IN VARCHAR2, pbaseobj IN VARCHAR2) ;


    PROCEDURE getKeyCols (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2);
    
    
    PROCEDURE getKeyColsUseAllKeys (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2);
    
    PROCEDURE saveSeqInfo (
                           powner IN VARCHAR2,
                           pname IN VARCHAR2,
                           optype IN VARCHAR2,
                           userid IN VARCHAR2,
                           seqCache IN NUMBER,
                           seqIncrementBy IN NUMBER,
                           toIgnore IN VARCHAR2);
    
    PROCEDURE getColDefs (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2);
    
    PROCEDURE getTableInfo (objId IN NUMBER,
                            objName IN VARCHAR2,
                            objOwner IN VARCHAR2,
                            objType IN VARCHAR2,
                            opType IN VARCHAR2,
                            userId IN VARCHAR2,
                            mowner IN VARCHAR2,
                            mname IN VARCHAR2,
                            ddlStatement IN VARCHAR2,
                            toIgnore IN VARCHAR2);
    
    PROCEDURE insertToMarker (
                              target IN INTEGER,
                              inType IN VARCHAR2,
                              inSubType IN VARCHAR2,
                              inString IN VARCHAR2,
                              markerOpType IN INTEGER
                              ); 
    
    FUNCTION itemHeader (
                         headerType IN VARCHAR2, 
                         firstKey IN VARCHAR2, 
                         secondKey IN VARCHAR2,
                         val IN VARCHAR2,
                         itemMode NUMBER)
    RETURN VARCHAR2;
    
    FUNCTION getDDLText(stmt OUT VARCHAR2) RETURN NUMBER;

    FUNCTION isRecycle(stmt IN VARCHAR2) RETURN NUMBER;
    
    PROCEDURE getVersion;
    
    PROCEDURE beginHistory; 
    PROCEDURE endHistory; 
    PROCEDURE setTracing;
    
    FUNCTION replace_string ( item       VARCHAR2,
                              searchStr  VARCHAR2,
                              replaceStr VARCHAR2 )
    RETURN VARCHAR2;

    FUNCTION escape_string (
                            item VARCHAR2,
                            itemMode NUMBER)
    RETURN VARCHAR2;
    
    PROCEDURE saveMarkerDDL (
                             objid VARCHAR2,
                             powner VARCHAR2,
                             pname VARCHAR2,
                             ptype VARCHAR2,
                             dtype VARCHAR2,
                             seq VARCHAR2,
                             histname VARCHAR2,
                             ouser VARCHAR2, 
                             objstatus VARCHAR2,
                             indexUnique VARCHAR2,
                             mowner VARCHAR2,
                             mname VARCHAR2,
                             stmt VARCHAR2,
                             toIgnore VARCHAR2);
    
    FUNCTION trace_header_name (
                                headerType VARCHAR2)
    RETURN VARCHAR2;
    
    FUNCTION removeSQLcomments (
                                stmt IN VARCHAR2)
    RETURN VARCHAR2;
    
    PROCEDURE getTableFromIndex (
                                 stmt IN VARCHAR2, 
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 table_owner OUT NOCOPY VARCHAR2, 
                                 table_name OUT NOCOPY VARCHAR2,
                                 otype OUT NOCOPY VARCHAR2);
                                 
    PROCEDURE getObjectTableType (
                                 stmt IN VARCHAR2, 
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 type_owner OUT NOCOPY VARCHAR2, 
                                 type_name OUT NOCOPY VARCHAR2,
                                 is_object OUT VARCHAR2,  
                                 is_xml OUT VARCHAR2);   
    
    PROCEDURE DDLtooLarge (stmt IN VARCHAR2,
                            ora_owner IN VARCHAR2,
                            ora_name IN VARCHAR2,
                            ora_type IN VARCHAR2,
                            sSize IN NUMBER);
    
END DDLReplication;
/
show errors package "&gg_user".DDLReplication

/*
DDL replication package body
*/
CREATE OR REPLACE PACKAGE BODY "&gg_user".DDLReplication AS
    
    /*
    FUNCTION REMOVESQLCOMMENTS RETURNS VARCHAR2
    Remove all SQL comments in DDL (or any SQL). Takes care of dash-dash and slash-star comments.
    Also 'knows' about double and single quoted strings and doesn't remove parts of string if they
    take comment form
    param[in] STMT                           VARCHAR2                SQL to decoment
    
    return de-commented SQL
    note Statement passed into this function MUST be lesser than &max_varchar2_size. The returned
    statement is NOT correct if SQL is of greater length than that size.
    */
    FUNCTION removeSQLcomments (
                                stmt IN VARCHAR2)
    RETURN VARCHAR2
    IS
    retval VARCHAR2 (&max_varchar2_size);
    -- the following (xxxStart) remember if string or comment started (0 not, 1 yes)        
    identStart NUMBER := 0;
    stringStart NUMBER := 0;
    slashStart NUMBER := 0;
    dashStart NUMBER := 0;
    beg NUMBER := 0;
    curr NUMBER := 0;
    tryExitLoop NUMBER := 0;    
    -- 11833474: We are by default in byte semantics so have
    -- space to accomodate multibyte chars.
    currChar VARCHAR2(5); 
    BEGIN    
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering removeSQLcomments()');
        END IF;

        -- Early out
        IF stmt IS NULL THEN
           return stmt;
        END IF;

        retval := '';
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
			"&gg_user".trace_put_line ('DDLTRACE1', 'Length of input ' || to_char (length(stmt)));
		END IF;
        LOOP 
            -- look for beginning of comment (slash or dash)
            -- make sure strings can contain them (those are not comments)
            -- make sure comments can contain each other 
            tryExitLoop := 1;
            beg := beg + 1;
            currChar := substr (stmt, beg, 1);
            IF '''' = currChar AND identStart = 0 AND slashStart = 0 AND dashStart = 0 THEN 
                stringStart := 1 - stringStart;
            ELSIF '"' = currChar  AND stringStart = 0 AND slashStart = 0 AND dashStart = 0 THEN
                identStart := 1 - identStart;
            ELSIF '/' = currChar  AND '*' = substr (stmt, beg + 1, 1) AND identStart = 0 AND stringStart = 0 AND dashStart = 0 THEN
                slashStart := 1; 
                tryExitLoop := 0;
            ELSIF '*' = currChar  AND '/' = substr (stmt, beg + 1, 1) THEN 
                IF slashStart <> 0 THEN 
                    beg := beg + 1;
                    slashStart := 0; 
                    tryExitLoop := 0; 
                END IF;
            ELSIF '-' = currChar  AND '-' = substr (stmt, beg + 1, 1) AND identStart = 0 AND stringStart = 0 AND slashStart = 0 THEN 
                dashStart := 1; 
                tryExitLoop := 0; 
            ELSIF CHR (10) = currChar  OR beg >= length (stmt) THEN
                IF dashStart = 0 THEN
                    retval := retval || currChar ;
                END IF;
                dashStart := 0;
                IF beg < length (stmt) THEN
					tryExitLoop := 0;
				ELSE
				    tryExitLoop := 1;
				    dashStart := 0;
				    slashStart := 0;
				    identStart := 0;
				    stringStart := 0;
				    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
						"&gg_user".trace_put_line ('DDLTRACE1', 'Found end of DDL ');
					END IF;
                END IF;                             
            END IF; 
            
            IF tryExitLoop = 1 THEN 
                IF slashStart = 0 AND dashStart = 0 THEN 
                    -- if this is not a comment, append to resulting de-commented SQL
                    retval := retval || currChar ;
                    IF beg >= length (stmt) THEN
                        EXIT;
                    END IF;
                END IF; 
            END IF;
        END LOOP;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
			"&gg_user".trace_put_line ('DDLTRACE1', 'Returning from removecomment ' || retval);
		END IF;
        RETURN retval;
        
        EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'removeSQLComments' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END removeSQLComments;

/*
   FUNCTION GETDDLTEXT
   Get text of DDL, the first 4K
   param[out] STMT VARCHAR2 DDL statement text
   return 0 if there was an error in getting the text (no text), or 1 if ok
            
   remarks This only gets the first 4K, which for many purposes is enough
           Can raise stringErrorSimulate, caller must handle.
*/
                                                                            
    FUNCTION getDDLText(stmt OUT VARCHAR2) RETURN NUMBER
    IS
        -- construct the entire text of SQL statement
        -- NOTE: last SQL statement obtained for a given transaction
        -- has the clear text of it
        sql_text ora_name_list_t;
        n INTEGER;
        sSize NUMBER;
        rawDDL   RAW(&frag_size);
        pieceRaw RAW(&frag_size);
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getDDLText()');
        END IF;

        rawDDL := '';
        n := ora_sql_txt(sql_text );
        -- Early out
        IF n IS NULL THEN
           IF "&gg_user".DDLReplication.trace_level >= 0 THEN
              "&gg_user".trace_put_line ('DDLTRACE1', 'Got NULL ddl text');
           END IF;
          RETURN 0;
        END IF;
        
        BEGIN
        -- get first 4K of statement (such as create table, index etc)
            IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                "&gg_user".trace_put_line ('DDLTRACE2', 'Got ' || to_char(n) || ' block DDL fragments.');
            END IF;
            FOR i IN 1..n LOOP
                -- retrieve a piece as raw data.
                pieceRaw := utl_raw.cast_to_raw(sql_text(i));
                IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                    "&gg_user".trace_put_line ('DDLTRACE2', 'Got DDL fragment ' || to_char(n) || 
                                                ', length = ' || to_char(utl_raw.length(pieceRaw)));
                END IF;
                -- if more than 4K, stop concatenation.
                if (utl_raw.length(pieceRaw) + utl_raw.length(rawDDL)) > ((&frag_size / 4) * 3) THEN
                    IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'DDL size reached to max. length = ' ||
                                                     to_char(utl_raw.length(rawDDL)));
                    END IF;
                    EXIT;
                END IF;
                -- concatenate a piece.
                rawDDL := utl_raw.concat(rawDDL, pieceRaw);
                IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                    "&gg_user".trace_put_line ('DDLTRACE2', 'DDL concatenated. length = ' ||
                                                 to_char(utl_raw.length(rawDDL)));
                END IF;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                -- we should not reach here, because we no longer concatenate more than 32K.
                -- this is ok, because first 32K is used for these only:
                -- 1. reporting, which always shows only first part
                -- 2. extraction (through parsing) of owner, name etc which is always in the head of DDL
                -- 3. ignoring BIN$ objects as those DDLs are not long (rena mes)
                -- so we don't care about the rest. The rest is stored in ma rker table for extract
                -- anyway (for actual replication)
            NULL;
        END;
        -- convert to VARCHAR2 type from RAW.
        stmt := utl_raw.cast_to_varchar2(rawDDL);
        IF "&gg_user".DDLReplication.trace_level >= 2 THEN
            "&gg_user".trace_put_line ('DDLTRACE2', 'Raw DDL converted to VARCHAR2. length = ' ||
                                        to_char(lengthb(stmt)) || ' , stmt = ' || stmt);
        END IF;

        -- check if multi byte DDL.
        if length(stmt) <> lengthb(stmt) THEN
            -- extract only valid character, so that we don't truncate by middle of character.
            stmt := substr(stmt, 1, length(stmt));
            IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                "&gg_user".trace_put_line ('DDLTRACE2', 'Multi byte DDL validated. length = ' ||
                                            to_char(lengthb(stmt)) || ' , stmt = ' || stmt);
            END IF;
        END IF;

        stmt := rtrim (stmt, ' ');
        -- nulls are in it from oracle!
        stmt := REPLACE (stmt, chr(0), ' ');
        RETURN 1;
    EXCEPTION
        -- this would happen if oracle error (internal ddl error, server error, 3113 etc)
        WHEN OTHERS THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Cannot obtain DDL statemen t from Oracle (2), ignoring, objtype [' || ora_dict_obj_type ||
                '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');
            IF "&gg_user".DDLReplication.sql_trace = 1 THEN
                dbms_session.set_sql_trace(false);
            END IF;
        RETURN 0;
    END;

    /*
    FUNCTION ISRECYCLE
    Determine if DDL is recycle bin
    param[in] STMT                           VARCHAR2                DDL statement text
    
    remarks Recyclebin DDLs are short (renames). This will look for BIN$ within string in
    this DDL. If found, it's recyclebin and will be ignored.
    */
    FUNCTION isRecycle(stmt IN VARCHAR2) RETURN NUMBER
    IS
        cStmt VARCHAR2(&max_varchar2_size);
        binP NUMBER;
        binE NUMBER;
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering isRecycle()');
        END IF;

        -- strip comments, so we don't find BIN$ in comments
        cStmt := removeSQLComments (substr (stmt, 1, &max_varchar2_size - 100));

        -- look for BIN$
        binP := instr(cStmt, '"BIN$', 1);
        IF binP = 0 THEN
            RETURN 0;
        END IF;
        cStmt := substr (cStmt, binP);

        -- look for closing double quote
        binE := instr(cStmt, '"', 2);
        IF binE = 0 THEN
            RETURN 0;
        END IF;

        -- found BIN$ object. We don't support user-created objects that start with
        -- BIN$
        cStmt := substr(cStmt, 2, binE-2);
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'BIN$ = [' || cStmt || ']');
        END IF;

        -- recycle bin name is BIN$<24 char id>$<ver num>, so 29th is always $
        -- and there has to be at least 30 chars.
        IF length(cStmt) < 30 THEN
            RETURN 0;
        END IF;
        IF substr(cStmt, 29, 1) = '$' THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;
    
    PROCEDURE getDDLBaseObjInfo(ddlevent IN VARCHAR2,
                            pbaseowner IN VARCHAR2, pbaseobj IN VARCHAR2) IS
   
     tobjNum NUMBER;
    BEGIN
       IF pbaseobj IS NOT NULL AND pbaseowner IS NOT NULL AND 
          ddlevent <> 'CREATE' 
       THEN
         select o.object_id , u.user# into ddlBaseObjNum , ddlBaseObjUserId 
         from  dba_objects o, sys.user$ u where
         o.object_name = pbaseobj and u.name = pbaseowner  and o.owner = u.name 
         and o.object_type = 'TABLE';
         select t.property into ddlBaseObjProperty from sys.tab$ t where
         obj# = ddlBaseObjNum;
       END IF;
       
    END getDDLBaseObjInfo;

    PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER, 
                         baseObjProperty IN NUMBER) IS
    BEGIN
    ddlObjNum  := objNum;
    ddlBaseObjNum := baseObjNum ;
    ddlObjUserId  := objUserId; 
    ddlBaseObjUserId := baseObjUserId;
    ddlBaseObjProperty := baseObjProperty;
    END;

    PROCEDURE getObjType(objtype IN VARCHAR2, obj_type OUT NUMBER) IS
    BEGIN
      select   decode(objtype, 'NEXT OBJECT', 0, 
                     'INDEX', 1, 'TABLE', 2, 'CLUSTER',
                      3, 'VIEW', 4, 'SYNONYM', 5, 'SEQUENCE',
                      6, 'PROCEDURE', 7, 'FUNCTION', 8, 'PACKAGE',
                      9, 'PACKAGE BODY', 11, 'TRIGGER',
                      12, 'TYPE', 13, 'TYPE BODY',
                      14, 'TABLE PARTITION', 19, 'INDEX PARTITION', 20, 'LOB',
                      21, 'LIBRARY', 22, 'DIRECTORY', 23, 'QUEUE',
                      24, 'JAVA SOURCE', 28, 'JAVA CLASS', 29, 'JAVA RESOURCE',
                      30, 'INDEXTYPE', 32, 'OPERATOR',
                      33, 'TABLE SUBPARTITION', 34, 'INDEX SUBPARTITION',
                      35, 'LOB PARTITION', 40, 'LOB SUBPARTITION',
                      42, 'DIMENSION',
                      43, 'CONTEXT', 44, 'RULE SET', 46, 'RESOURCE PLAN',
                      47, 'CONSUMER GROUP',
                      48, 'SUBSCRIPTION', 51, 'LOCATION',
                      52, 'XML SCHEMA', 55, 'JAVA DATA',
                      56, 'EDITION', 57, 'RULE',
                      59, 'CAPTURE', 60, 'APPLY',
                      61, 'EVALUATION CONTEXT',
                      62, 'JOB', 66, 'PROGRAM', 67, 'JOB CLASS', 68, 'WINDOW',
                      69, 'SCHEDULER GROUP', 72, 'SCHEDULE', 74, 'CHAIN',
                      79, 'FILE GROUP', 81, 'MINING MODEL', 82, 'ASSEMBLY',
                      87, 'CREDENTIAL', 90, 'CUBE DIMENSION', 92, 'CUBE',
                      93, 'MEASURE FOLDER', 94, 'CUBE BUILD PROCESS',
                      95, 'FILE WATCHER', 100, 'DESTINATION',
                      101, 'SQL TRANSLATION PROFILE',104,
                     '-1')  into obj_type from dual;

    END;

    PROCEDURE getObjTypeName(obj_type IN NUMBER, objtype OUT VARCHAR2) IS
    BEGIN
      select   
      decode(obj_type, 0, 'NEXT OBJECT', 1, 'INDEX', 2, 'TABLE', 3, 'CLUSTER',
                      4, 'VIEW', 5, 'SYNONYM', 6, 'SEQUENCE',
                      7, 'PROCEDURE', 8, 'FUNCTION', 9, 'PACKAGE',
                      11, 'PACKAGE BODY', 12, 'TRIGGER',
                      13, 'TYPE', 14, 'TYPE BODY',
                      19, 'TABLE PARTITION', 20, 'INDEX PARTITION', 21, 'LOB',
                      22, 'LIBRARY', 23, 'DIRECTORY', 24, 'QUEUE',
                      28, 'JAVA SOURCE', 29, 'JAVA CLASS', 30, 'JAVA RESOURCE',
                      32, 'INDEXTYPE', 33, 'OPERATOR',
                      34, 'TABLE SUBPARTITION', 35, 'INDEX SUBPARTITION',
                      40, 'LOB PARTITION', 41, 'LOB SUBPARTITION',
                      43, 'DIMENSION',
                      44, 'CONTEXT', 46, 'RULE SET', 47, 'RESOURCE PLAN',
                      48, 'CONSUMER GROUP',
                      51, 'SUBSCRIPTION', 52, 'LOCATION',
                      55, 'XML SCHEMA', 56, 'JAVA DATA',
                      57, 'EDITION', 59, 'RULE',
                      60, 'CAPTURE', 61, 'APPLY',
                      62, 'EVALUATION CONTEXT',
                      66, 'JOB', 67, 'PROGRAM', 68, 'JOB CLASS', 69, 'WINDOW',
                      72, 'SCHEDULER GROUP', 74, 'SCHEDULE', 79, 'CHAIN',
                      81, 'FILE GROUP', 82, 'MINING MODEL', 87, 'ASSEMBLY',
                      90, 'CREDENTIAL', 92, 'CUBE DIMENSION', 93, 'CUBE',
                      94, 'MEASURE FOLDER', 95, 'CUBE BUILD PROCESS',
                      100, 'FILE WATCHER', 101, 'DESTINATION',
                      114, 'SQL TRANSLATION PROFILE',
                     'UNDEFINED')  into objtype from dual;

    END;


    PROCEDURE getDDLObjInfo(objtype IN VARCHAR2, ddlevent IN VARCHAR2,
                            powner IN VARCHAR2, pobj IN VARCHAR2) IS
   
     tobjNum NUMBER;
    BEGIN
     BEGIN
       /* If we dont know the objno already (from ctx) then query */
       if ddlObjNum = -1 THEN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'getDDLObjInfo: objname '||pobj||' user '||powner||
                ' objtype '||ddlobjType);
        END IF;
         getObjType(objtype,ddlObjType);
--       dbms_output.put_line(ddlObjNum||'|'||ddlObjUserId||'|'||ddlObjType);
         /* Check if owner# is known and query accordingly */
--         IF ddlObjNum = -1 THEN
--           INSERT INTO "&gg_user".ddllog values (pobj, objtype, ddlevent);
--         END IF;
         IF ddlObjUserId = -1 THEN
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is -1');
            END IF;
           select o.obj#, u.user# into ddlObjNum , ddlObjUserId
           from sys.obj$ o, sys.user$ u where
           o.name = pobj and u.name = powner and o.owner# = u.user# and
           o.type# = ddlObjType and o.subname is NULL and o.remoteowner is null and o.linkname is null; -- subname is NULL means only the most recent type
         ELSE
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is '||ddlObjUserId);
            END IF;
           select o.obj#, u.user# into ddlObjNum , ddlObjUserId
           from sys.obj$ o, sys.user$ u where
           o.name = pobj and o.owner# = u.user# and u.user# = ddlObjUserId and
           o.type# = ddlObjType and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
         END IF;
        /* If obj# is known but owner is not known then populate it */
       ELSIF ddlObjUserId = -1 THEN
          IF "&gg_user".DDLReplication.trace_level >= 1 THEN
              "&gg_user".trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is  -1 and ddlObjNum is -1' );
          END IF;
          select o.owner# into ddlObjUserId from sys.obj$ o
          where o.obj# = ddlObjNum  and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
       END IF;

       IF objtype = 'TABLE' THEN
         tobjNum := ddlObjNum;
         ddlBaseObjNum := ddlObjNum;
         ddlBaseObjUserId := ddlObjUserId;

         IF ddlBaseObjProperty = -1 THEN
           IF "&gg_user".DDLReplication.trace_level >= 1 THEN
              "&gg_user".trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlBaseObjproper is -1, obj# is '||tobjNum);
           END IF;
           select t.property into ddlBaseObjProperty from sys.tab$ t where
           obj# = tobjNum;
         END IF;
       END IF;
     EXCEPTION WHEN NO_DATA_FOUND THEN
       ddlObjNum := -1;
       ddlObjUserId := -1;
       ddlBaseObjUserId := -1;
       ddlBaseObjNum := -1;
       ddlBaseObjProperty := -1;
     WHEN OTHERS THEN
       --dbms_output.put_line('getDDLObjInfo:'||SQLERRM);
      RAISE;
     END;
       
    END getDDLObjInfo;

    /*
    PROCEDURE GETTABLEFROMINDEX
    Get table owner/name referenced in CREATE INDEX
    param[in] STMT                           VARCHAR2                DDL statement test
    param[in] ORA_OWNER                      VARCHAR2                Owner of index
    param[in] ORA_NAME                       VARCHAR2                Name of index
    param[out] TABLE_OWNER                    VARCHAR2               Table owner referenced in index
    param[out] TABLE_NAME                     VARCHAR2               Table name referenced in index
    param[out] OTYPE                         VARCHAR2                TABLE or CLUSTER 
    
    remarks Reason for this pedestrian function (parsing of SQL) is that we must use Before DDL trigger
    which implies CREATEd object doesn't exist yet and can't be queried against DB. Also, name of
    base object cannot wait for extract resolution.
    */
    PROCEDURE getTableFromIndex (
                                 stmt IN VARCHAR2, 
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 table_owner OUT NOCOPY VARCHAR2, 
                                 table_name OUT NOCOPY VARCHAR2,
                                 otype OUT NOCOPY VARCHAR2) 
    IS
    
    cStmt VARCHAR2(&max_varchar2_size);
    sObj VARCHAR2(&name_size);
    lenPos1 NUMBER;
    objPos1 NUMBER;
    lenPos2 NUMBER;
    objPos2 NUMBER;
    lenPos3 NUMBER;
    objPos3 NUMBER;
    lenPos4 NUMBER;
    objPos4 NUMBER;
    lenPos NUMBER;
    objPos NUMBER;
    restP VARCHAR2(&max_varchar2_size);
    posOn NUMBER;
    tName VARCHAR2(&max_varchar2_size);
    word1 VARCHAR2(&max_varchar2_size) := '';
    word2 VARCHAR2(&max_varchar2_size) := '';
    posStart NUMBER;
    posEnd NUMBER;
    posDot NUMBER;
    
    BEGIN 
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getTableFromIndex()');
        END IF;
        
        cStmt := removeSQLComments (substr (stmt, 1, &max_varchar2_size - 100));
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Remove comments, new = [' || cStmt || ']');
        END IF;
        -- normalize text
        cStmt := REPLACE (cStmt, chr(10), ' '); 
        cStmt := REPLACE (cStmt, chr(13), ' ');
        cStmt := REPLACE (cStmt, chr(9), ' ');
        
        cStmt := upper (cStmt);
        
        -- look for index keyword first, it must be here  
        sObj := 'INDEX';
        posOn := instr (cStmt, sObj, 1);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found keyword index, position = [' || posOn || ']');
        END IF;
        
        -- find index name and get passed it
        -- try al different object name combinations that are valid
        sObj := upper(ora_name);
        objPos1 := instr (cStmt, sObj , posOn); 
        lenPos1 := length (sObj);
        
        sObj := '"' || upper(ora_name) || '"';
        objPos2 := instr (cStmt, sObj, posOn);
        lenPos2 := length (sObj);
        
        sObj := upper(ora_owner) || '.' || '"' || upper(ora_name) || '"';
        objPos3 := instr (cStmt, sObj, posOn);
        lenPos3 := length (sObj);
        
        sObj := '"' || upper(ora_owner) || '"' || '.' || '"' || upper(ora_name) || '"';
        objPos4 := instr (cStmt, sObj, posOn);
        lenPos4 := length (sObj);
        
        objPos := length (cStmt);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos1 = [' || objPos1 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos2 = [' || objPos2 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos3 = [' || objPos3 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos4 = [' || objPos4 || ']');            
        END IF;
        
        -- find valid name that comes up first
        IF objPos1 <> 0 AND objPos1 < objPos THEN
            objPos := objPos1;
            lenPos := lenPos1;
        END IF;
        IF objPos2 <> 0 AND objPos2 < objPos THEN
            objPos := objPos2;
            lenPos := lenPos2;
        END IF;
        IF objPos3 <> 0 AND objPos3 < objPos THEN
            objPos := objPos3;
            lenPos := lenPos3;
        END IF;
        IF objPos4 <> 0 AND objPos4 < objPos THEN
            objPos := objPos4;
            lenPos := lenPos4;
        END IF;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos = [' || objPos || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'lenPos = [' || lenPos || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'stmt = [' || cStmt || ']');
        END IF;
        -- now we have obj pos
        restP := substr (cStmt, objPos + lenPos);
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'object = [' || restP || ']');
        END IF;
        
        -- look for table name after ON keyword                
        sObj := ' ON';
        posOn := instr (restP, sObj, 1);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'position of ON = [' || posOn || ']');
        END IF;
        
        IF posOn <> 0 THEN
            tName := substr (restP, posOn + length (sObj));
        END IF;
        
        
        tName := trim (both ' ' FROM tName);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found position of Table name = [' || tname || ']');
        END IF;
        
        -- look out for clusters (indexing clusters)
        IF substr (upper (tName), 1, 7) = 'CLUSTER' THEN
            tName := substr (tName, 8);
            tName := trim (both ' ' FROM tName);
            otype := 'CLUSTER';
        ELSE
            otype := 'TABLE';
        END IF;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'CREATE INDEX, interim (1) = [' || tName || '], ' || ascii (substr (tName, 12, 1)));
        END IF;
        
        -- parse table name by figuring out
        -- what kind of notation is used,
        -- get owner name as well or use the same as index's
        
	-- parse index owner and index name
	-- if owner is missing, do not assume index owner is ora_owner.
            
	posStart := instr(tName, '"', 1, 1);
	posEnd := instr(tName, '"', 1, 2);
            
	IF posStart = 1 AND posEnd > 0 THEN
	  -- first word begins with quote
	  word1 := replace(substr(tName, 2, posEnd-2), ' ');
	  IF length(tName) = posEnd THEN
	    posEnd := 0;
          ELSE
            posEnd := posEnd + 1;
          END IF;
        ELSE
	  posEnd := instr(tName, ' ', 1);
	  posDot := instr(tName, '.', 1);

	  IF posEnd = 0 AND posDot = 0 THEN
	    -- no second word
	    word1 := substr(tName, 1);
	  ELSE      
	    IF (posDot > 0 AND (posDot < posEnd OR posEnd = 0)) THEN
	      posEnd := posDot;
            END IF;
	    word1 := substr(tName, 1, posEnd-1);
          END IF;
        END IF;
            
	IF posEnd > 0 THEN
	  -- there are more words
	  tName := trim(both ' ' FROM substr(tName, posEnd));
	  posDot := instr(tName, '.', 1);

	  -- to find second word, second word must begin with dot
	  IF posDot = 1 THEN
	    tName := trim(both ' ' FROM substr(tName, 2));
	    posStart := instr(tName, '"', 1, 1);
	    posEnd := instr(tName, '"', 1, 2);
            
	    IF posStart = 1 AND posEnd > 0 THEN
	      -- after trimming, second word begins with quote
	      word2 := replace(substr(tName, 2, posEnd-2), ' ');
            ELSE
	      posEnd := instr(tName, ' ', 1);
	      IF posEnd = 0 THEN
		word2 := substr(tName, 1);
              ELSE
		word2 := substr(tName, 1, posEnd-1);
	      END IF;
            END IF;
          END IF;
        END IF;
         
	IF word2 IS NULL THEN	  
	  table_owner := upper(ora_owner);
	  table_name := word1;       
	ELSE
	  table_owner := word1;
	  table_name := word2;
        END IF;

	-- index on table has '(' following the table name
	posEnd := instr(table_name, '(', 1);
	IF posEnd > 0 THEN
	  table_name := trim(both ' ' FROM substr(table_name, 1, posEnd-1));
        END IF;         
        
        EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getTableFromIndex' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END; 
    
    
    /*
    PROCEDURE GETOBJECTTABLETYPE
    Get type owner/name referenced in CREATE TABLE .. OF .. (object table)
    param[in] STMT                           VARCHAR2                DDL statement test
    param[in] ORA_OWNER                      VARCHAR2                Owner of table
    param[in] ORA_NAME                       VARCHAR2                Name of table
    param[out] TYPE_OWNER                    VARCHAR2                Type owner, in upper case 
    param[out] TYPE_NAME                     VARCHAR2                Type name, in upper case 
    param[out] IS_OBJECT                     VARCHAR2                1 if this is object type, 0 otherwise
        
    remarks Reason for this pedestrian function (parsing of SQL) is that we must use Before DDL trigger
    which implies CREATEd object doesn't exist yet and can't be queried against DB. If type_name is empty,
    this is NOT object table.
    */
    PROCEDURE getObjectTableType (
                                 stmt IN VARCHAR2, 
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 type_owner OUT NOCOPY VARCHAR2, 
                                 type_name OUT NOCOPY VARCHAR2,
                                 is_object OUT VARCHAR2,
                                 is_xml OUT VARCHAR2)
    IS
    
    cStmt VARCHAR2(&max_varchar2_size);
    sObj VARCHAR2(&name_size);
    lenPos1 NUMBER;
    objPos1 NUMBER;
    lenPos2 NUMBER;
    objPos2 NUMBER;
    lenPos3 NUMBER;
    objPos3 NUMBER;
    lenPos4 NUMBER;
    objPos4 NUMBER;
    lenPos NUMBER;
    objPos NUMBER;
    restP VARCHAR2(&max_varchar2_size);
    posOn NUMBER;
    tName VARCHAR2(&max_varchar2_size);
    word1 VARCHAR2(&max_varchar2_size) := '';
    word2 VARCHAR2(&max_varchar2_size) := '';
    posStart NUMBER;
    posEnd NUMBER;
    posDot NUMBER;
    
    BEGIN 
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getObjectTableType()');
        END IF;
        
        is_object := 'NO';
        is_xml := 'NO';
        
        cStmt := removeSQLComments (substr (stmt, 1, &max_varchar2_size - 100));
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Get object type, new = [' || cStmt || ']');
        END IF;
        
        -- normalize text
        cStmt := REPLACE (cStmt, chr(10), ' '); 
        cStmt := REPLACE (cStmt, chr(13), ' ');
        cStmt := REPLACE (cStmt, chr(9), ' ');
        
        cStmt := upper (cStmt);
        
        -- look for table keyword first, it must be here  
        sObj := 'TABLE';
        posOn := instr (cStmt, sObj, 1);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found keyword table, position = [' || posOn || ']');
        END IF;
        
        -- find table name and get passed it
        -- try al different object name combinations that are valid
        sObj := upper(ora_name);
        objPos1 := instr (cStmt, sObj , posOn); 
        lenPos1 := length (sObj);
        
        sObj := '"' || upper(ora_name) || '"';
        objPos2 := instr (cStmt, sObj, posOn);
        lenPos2 := length (sObj);
        
        sObj := upper(ora_owner) || '.' || '"' || upper(ora_name) || '"';
        objPos3 := instr (cStmt, sObj, posOn);
        lenPos3 := length (sObj);
        
        sObj := '"' || upper(ora_owner) || '"' || '.' || '"' || upper(ora_name) || '"';
        objPos4 := instr (cStmt, sObj, posOn);
        lenPos4 := length (sObj);
        
        objPos := length (cStmt);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos1 = [' || objPos1 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos2 = [' || objPos2 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos3 = [' || objPos3 || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos4 = [' || objPos4 || ']');            
        END IF;
        
        -- find valid name that comes up first
        IF objPos1 <> 0 AND objPos1 < objPos THEN
            objPos := objPos1;
            lenPos := lenPos1;
        END IF;
        IF objPos2 <> 0 AND objPos2 < objPos THEN
            objPos := objPos2;
            lenPos := lenPos2;
        END IF;
        IF objPos3 <> 0 AND objPos3 < objPos THEN
            objPos := objPos3;
            lenPos := lenPos3;
        END IF;
        IF objPos4 <> 0 AND objPos4 < objPos THEN
            objPos := objPos4;
            lenPos := lenPos4;
        END IF;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'objPos = [' || objPos || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'lenPos = [' || lenPos || ']');
            "&gg_user".trace_put_line ('DDLTRACE1', 'stmt = [' || cStmt || ']');
        END IF;
        -- now we have obj pos
        restP := substr (cStmt, objPos + lenPos);
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'object = [' || restP || ']');
        END IF;
        
        -- look for type name after OF keyword (if there is OF keyword)                
        sObj := 'OF ';
        restP := trim (both ' ' FROM restP);
        posOn := instr (restP, sObj, 1);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'position of OF = [' || posOn || ']');
        END IF;
        
        IF posOn = 1 THEN
            tName := substr (restP, posOn + length (sObj));
        ELSE
            RETURN; -- this is not object table
        END IF;
        
        
        tName := trim (both ' ' FROM tName);
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found position of Type name = [' || tName || ']');
        END IF;
        
                
	-- parse type owner and type name.
	-- if type owner is missing, do not assume type owner
	-- is ora_owner because type can be PUBLIC
        
	posStart := instr(tName, '"', 1, 1);
	posEnd := instr(tName, '"', 1, 2);
	
	IF posStart = 1 AND posEnd > 0 THEN
	  -- first word begins with quote
	  word1 := replace(substr(tName, 2, posEnd-2), ' ');
	  IF length(tName) = posEnd THEN
	    posEnd := 0;
	  ELSE
	    posEnd := posEnd + 1;
	  END IF;	  
	ELSE
	  posEnd := instr(tName, ' ', 1);
	  posDot := instr(tName, '.', 1);

	  IF posEnd = 0 AND posDot = 0 THEN
	    -- no second word
	    word1 := substr(tName, 1);
	  ELSE      
	    IF (posDot > 0 AND (posDot < posEnd OR posEnd = 0)) THEN
	      posEnd := posDot;
	    END IF;
	    word1 := substr(tName, 1, posEnd-1);
	  END IF;
	END IF;

	IF posEnd > 0 THEN
	  -- there are more words
	  tName := trim(both ' ' FROM substr(tName, posEnd));
	  posDot := instr(tName, '.', 1);

	  -- to find second word, second word must begin with dot
	  IF posDot = 1 THEN
	    tName := trim(both ' ' FROM substr(tName, 2));
	    
	    posStart := instr(tName, '"', 1, 1);
	    posEnd := instr(tName, '"', 1, 2);
	    
	    IF posStart = 1 AND posEnd > 0 THEN
	      -- after trimming, second word begins with quote
	      word2 := replace(substr(tName, 2, posEnd-2), ' ');
	    ELSE
	      posEnd := instr(tName, ' ', 1);
	      IF posEnd = 0 THEN
		word2 := substr(tName, 1);
	      ELSE
		word2 := substr(tName, 1, posEnd-1);
	      END IF;
	    END IF;
	  END IF;
	END IF;
	
	IF word2 IS NULL THEN	  
	  type_owner := '';
	  type_name := word1;       
	ELSE
	  type_owner := word1;
	  type_name := word2;
	END IF;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Type owner.name = [' || type_owner || '.' || type_name || ']');
        END IF;
        
        is_object := 'YES';

        IF type_name = 'XMLTYPE' AND (type_owner IS NULL OR type_owner = 'SYS') THEN
            is_xml := 'YES';
        END IF;
        
        EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getObjectTableType' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END; 
    
    
        
    /*
    PROCEDURE DDLTOOLARGE
    React to DDL that is too large (either 32K or 2Mb depending on what is current limit). This
    means inform extract that this DDL is too large.
    param[in] STMT                           VARCHAR2                DDL statement test (first 32K)
    param[in] ORA_OWNER                      VARCHAR2                Owner of object
    param[in] ORA_NAME                       VARCHAR2                Name of object
    param[in] ORA_TYPE                       VARCHAR2                type of object
    param[in] sSize                          NUMBER                  actual size of DDL
    
    remarks This will put IGNORESIZE: message in marker, which extract knows how to process
    Also, if there was any data in marker, it will be deleted. Note that we always make sure
    to have less than 2Mb of data in marker rows for same marker sequence, because if more, we
    won't be able to process the delete in extract.
    */
    PROCEDURE DDLtooLarge (stmt IN VARCHAR2,
                            ora_owner IN VARCHAR2,
                            ora_name IN VARCHAR2,
                            ora_type IN VARCHAR2,
                            sSize IN NUMBER)        
    IS                        
        outMessage VARCHAR2(&message_size); 
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering DDLtooLarge()');
        END IF;

                            
        -- get marker seqno, or deleting whatever was there currently
        IF "&gg_user".DDLReplication.currentMarkerSeq IS NULL THEN  -- only if marker seqno not set
            SELECT "&gg_user"."&marker_sequence".NEXTVAL INTO "&gg_user".DDLReplication.currentMarkerSeq FROM dual; 
        ELSE
            DELETE FROM "&gg_user"."&marker_table_name" WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq; 
            "&gg_user".trace_put_line ('DDL', 'Deleted ' || to_char(SQL%ROWCOUNT) || ' from marker table');
        END IF;            
        
        "&gg_user".trace_put_line ('DDL', 'Statement too large (marker seq ' || to_char("&gg_user".DDLReplication.currentMarkerSeq) ||
        ' size ' || to_char (sSize) || '), ignored  [' || substr (stmt, 1, 1000) || ']' );
        
        -- this message would be caught by extract and extract would print it out as warning (at this time)
        outMessage := 'IGNORESIZE: ' || ora_owner || '.' || ora_name || '(' || ora_type || ') ' ||
            'size (' || to_char (sSize) || ') DDL sequence [' || to_char ("&gg_user".DDLReplication.currentDDLSeq) || 
            '], marker sequence [' || to_char ("&gg_user".DDLReplication.currentMarkerSeq) ||
            '], DDL trace log file [' || "&gg_user".DDLReplication.dumpDir || "&gg_user".file_separator || '&trace_file]';
        INSERT INTO "&gg_user"."&marker_table_name" (
            seqNo,
            fragmentNo,
            optime,
            TYPE,
            SUBTYPE,
            marker_text
        )
        VALUES (
            "&gg_user".DDLReplication.currentMarkerSeq,
            0,
            TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
            'DDL',
            'DDLINFO', 
            outMessage
        ); 
    END;
    
    /*
    PROCEDURE SAVEMARKERDDL
    Write marker record to marker file. This record is periodically purged
    since extract uses log based extraction for DDL. Record is generally 
    split in 4K blocks connected by sequence number.
    
    param[in] OBJID                          VARCHAR2                object id
    param[in] POWNER                         VARCHAR2                object owner
    param[in] PNAME                          VARCHAR2                object name
    param[in] PTYPE                          VARCHAR2                object type (table, index..)
    param[in] DTYPE                          VARCHAR2                type of DDL (create, alter..)
    param[in] SEQ                            VARCHAR2                sequence number for marker to use
    param[in] HISTNAME                       VARCHAR2                ddl history table name (for extract)
    param[in] OUSER                          VARCHAR2                login user (who dunnit)
    param[in] OBJSTATUS                      VARCHAR2                object status (valid, invalid)
    param[in] INDEXUNIQUE                    VARCHAR2                INDEXUNIQUE or NO (for CREATE/DROP INDEX)
    param[in] mowner                          VARCHAR2                  master owner (base)
    param[in] mname                          VARCHAR2                  master name (base)
    param[in] STMT                           VARCHAR2                actual DDL statement
    param[in] TOIGNORE                       VARCHAR2                if YES, this DDL is written with IGNORE flag (for extract)
        
    see insertToMarker() - all data is essentially (name, value) pairs packed in strings split up in 4K chunks
    */ 
    PROCEDURE saveMarkerDDL (
                             objid VARCHAR2,
                             powner VARCHAR2,
                             pname VARCHAR2,
                             ptype VARCHAR2,
                             dtype VARCHAR2,
                             seq VARCHAR2,
                             histname VARCHAR2,
                             ouser VARCHAR2, 
                             objstatus VARCHAR2,
                             indexUnique VARCHAR2,
                             mowner VARCHAR2,
                             mname VARCHAR2,
                             stmt VARCHAR2,
                             toIgnore VARCHAR2) 
    IS 
    errorMessage VARCHAR2(&message_size);
    ddlNum NUMBER;
    ddlCur NUMBER;
    sql_text ora_name_list_t;
    pieceStmt VARCHAR2(&frag_size);
    isObjTab VARCHAR2(&type_size);
    isXMLTab VARCHAR2(&type_size);
    tableTypeOwner VARCHAR2(&type_size);
    tableTypeName VARCHAR2(&type_size);
    rawDDL RAW(&frag_size);
    pieceRaw RAW(&frag_size); 
    prop NUMBER;    
    nlsSeq NUMBER;
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering saveMarkerDDL()');
        END IF;
        
        IF iname is null or inumber is null THEN
          SELECT 
          instance_number, instance_name 
          INTO inumber, iname
          FROM sys.v_$instance;

          IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1:optim', 'Init:iname,inumber');
          END IF;
        END IF;
        
       
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', '', BEGIN_FRAGMENT);         
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDL', 'Marker seqno is '|| to_char(currentMarkerSeq));
        END IF;
        
        ddlNum := ora_sql_txt(sql_text );        

        rawDDL := '';
        ddlCur := 1;
            
        FOR i IN 1..ddlNum LOOP                
            pieceRaw := utl_raw.cast_to_raw(sql_text(i));
            IF (utl_raw.length(rawDDL) + utl_raw.length(pieceRaw)) > ((&frag_size / 4) * 3) THEN
                pieceStmt := replace_string(utl_raw.cast_to_varchar2(rawDDL), chr(0), ' ');

                -- flash out current block.
                IF ddlCur = 1 THEN
                    -- first one less then 4K is used with old parsing
                    -- note that this is ADD_FRAGMENT, above one is ADD_FRAGMENT_AND_FLUSH to make it final
                    -- (this is first of many, while above is first of one, i.e. the only one, such as short DDL)
                    insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                                    itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_HEAD),
                                    ADD_FRAGMENT); 
                    IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'Add piece of DDL (ADD_FRAGMENT - HEAD): ' || pieceStmt);
                    END IF;                 
                ELSE
                    -- for the rest, use fragments, starting with 2
                    insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                                    itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_DATA),
                                    ADD_FRAGMENT);         
                    IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'Add piece of DDL (ADD_FRAGMENT - DATA): ' || pieceStmt);
                    END IF;                 
                END IF;

                ddlCur := ddlCur + 1;
                rawDDL := '';
            END IF;
            rawDDL := utl_raw.concat(rawDDL, pieceRaw);
        END LOOP;

        -- check if remainning exists.
        IF (utl_raw.length(rawDDL) > 0) THEN
            pieceStmt := replace_string(utl_raw.cast_to_varchar2(rawDDL), chr(0), ' ');

            IF ddlCur = 1 THEN
                -- this is only DDL block writtent to.
                insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                                itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_WHOLE)
                                , ADD_FRAGMENT_AND_FLUSH); 
                IF trace_level >= 2 THEN
                    "&gg_user".trace_put_line ('DDLTRACE2', 'Add whole DDL (FRAGMENT_AND_FLUSH - WHOLE): ' || pieceStmt);
                END IF;                 
            ELSE
                -- every next one will be fetched based on fragment No (starting with 2)
                insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                                itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_TAIL)
                                , ADD_FRAGMENT_AND_FLUSH);         
                IF trace_level >= 2 THEN
                    "&gg_user".trace_put_line ('DDLTRACE2', 'Add piece of DDL (FRAGMENT_AND_FLUSH - TAIL): ' || pieceStmt);
                END IF;                 
            END IF;
        END IF;
        
        -- this data must be smaller than DDL_EXTERNAL_OVERHEAD from ddl.h
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MD_TAB_MARKERSEQNO, '', '', to_char ("&gg_user".DDLReplication.currentMarkerSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_OBJECTID, '', '', objid, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MD_TAB_SEQUENCEROWID, '', '', currentRowid, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_OBJECTOWNER, '', '', powner, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_OBJECTNAME, '', '', pname, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_MASTEROWNER, '', '', mowner, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_MASTERNAME, '', '', mname, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_OBJECTTYPE, '', '', ptype, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_DDLTYPE, '', '', dtype, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_DDLSEQ, '', '', seq, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_DDLHIST, '', '', histname, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_LOGINUSER, '', '', ouser, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_VERSIONINFO, '', '', lv_version, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_VERSIONINFOCOMPAT, '', '', lv_compat, ITEM_WHOLE) 
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_VALID, '', '', objstatus, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_INSTANCENUMBER, '', '', to_char (inumber), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_INSTANCENAME, '', '', iname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MD_TAB_ISINDEXUNIQUE, '', '', indexUnique, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        IF toIgnore = 'YES' THEN  -- do not make marker record bigger unnecessarily
            insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        END IF;
               
        isObjTab := 'NO';
        isXMLTab := 'NO';
        BEGIN                
            -- object table query
            SELECT property 
            INTO prop
            FROM sys.tab$
            WHERE obj# = objid;
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
                prop := 0;
        END;
            
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'OBJTAB prop= [' || to_char(prop) || ']');
        END IF;            
        
        IF bitand (prop, OBJTAB) = OBJTAB THEN
            isObjTab := 'YES';

            BEGIN                
                -- XMLType table query
                SELECT decode (max (bitand (flags, XMLTAB)), XMLTAB, 'YES', 'NO') 
                INTO isXMLTab
                FROM sys.opqtype$
                WHERE obj# = objid and type = 1;
            EXCEPTION 
                WHEN OTHERS THEN 
                    isXMLTab := 'NO';
            END;

            IF trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'isXMLTab = [' || isXMLTab || ']');
            END IF;

        END IF;
        
        IF ptype = 'TABLE' AND dtype = 'CREATE' THEN
            "&gg_user".DDLReplication.getObjectTableType (
                stmt, 
                powner,
                pname,
                tableTypeOwner,
                tableTypeName,
                isObjTab,
                isXMLTab);
        END IF;
        
        -- object table processing may happen here in the future (when it's supported)
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_OBJECTTABLE, '', '', isObjTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_XMLTYPETABLE, '', '', isXMLTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        nlsSeq := 0;
        FOR n IN nls_settings LOOP
			nlsSeq := nlsSeq + 1;
			insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_NLS_PARAM, to_char (nlsSeq), '', n.parameter, ITEM_WHOLE)
                        , ADD_FRAGMENT);
			insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_NLS_VAL, to_char (nlsSeq), '', n.value, ITEM_WHOLE)
                        , ADD_FRAGMENT);
			IF trace_level >= 1 THEN
				"&gg_user".trace_put_line ('DDLTRACE1', 'SaveMarkerDDL:NLS:' || n.parameter || '=' ||
					n.value);
			END IF;            
        END LOOP;
		
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', 
                        itemHeader (MK_TAB_NLS_CNT, '', '', to_char (nlsSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', '', END_FRAGMENT); 
                        
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'SaveMarkerDDL:');
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'saveMarkerDDL: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
            
    END saveMarkerDDL;
    
    /*
    FUNCTION REPLACE_STRING RETURNS VARCHAR2
    Find the search string in item string, and substitute all occurances with 
    replace string.
    param[in] ITEM         VARCHAR2   String to be processed
    param[in] SEARCHSTR    VARCHAR2   String to be searched with
    param[in] REPLACESTR   VARCHAR2   String to be replaced with
    
    return replaced string
    */
    FUNCTION replace_string ( item       VARCHAR2,
                              searchStr  VARCHAR2,
                              replaceStr VARCHAR2 )
    RETURN VARCHAR2
    IS
    head VARCHAR2 (&max_varchar2_size) := '';
    errorMessage VARCHAR2(&message_size);
    pos1 NUMBER := 1;
    pos2 NUMBER := 1;
    itemRaw RAW (&max_varchar2_size) := utl_raw.cast_to_raw(item);
    itemLen NUMBER := LENGTHB(item);
    replaceStrRaw RAW (&max_varchar2_size) := utl_raw.cast_to_raw(replaceStr);
    searchStrLen NUMBER := LENGTHB(searchStr);
    appendLen NUMBER := 0;
    BEGIN
       IF "&gg_user".DDLReplication.trace_level >= 1 THEN
          "&gg_user".trace_put_line ('DDLTRACE1', 'Entering replace_string()');
       END IF;

       -- Early out, NULL passed in
       IF item IS NULL THEN
          RETURN item;
       END IF;

       -- Find the first occurance of search string
       pos1 := INSTRB( item, searchStr );

       -- Early out, search string not found
       IF pos1 = 0 THEN
          RETURN item;
       END IF;

       -- Save item from begining till first position, into head
       head := SUBSTRB(item, 1, pos1-1);

       -- Process loop
       LOOP

         IF (pos1 + searchStrLen) > itemLen THEN
            -- 1) Search string is at the end of item
            --    Append to head:
            --    a) The replace string
            head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) || 
                                              replaceStrRaw );
            EXIT;
         ELSE
            -- Find second occurence of search string
            pos2 := INSTRB( item, searchStr, pos1 + searchStrLen );
         END IF;

         IF pos2 = 0 THEN
            -- 2) Second occurence of search string not found
            --    Append to head:
            --    a) The replace string
            --    b) The remaing item after first occurence of search string
            head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) || 
                                              replaceStrRaw             ||
                                              utl_raw.SUBSTR
                                              ( itemRaw, 
                                                pos1 + searchStrLen
                                              )
                                            );
            EXIT;
         ELSE
            
            -- Find the length of item that will be appended after replace str
            appendLen := pos2 - (pos1 + searchStrLen);

            IF appendLen = 0 THEN
              -- 3) Second occurence of search string found
              --    Append to head:
              --    a) The replace string
              head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) || 
                                                replaceStrRaw );
            ELSE
              -- 4) Second occurence of search string found
              --    Append to head:
              --    a) The replace string
              --    b) The item between first and second occurence of search str
              head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) || 
                                                replaceStrRaw             ||
                                                utl_raw.SUBSTR
                                                ( itemRaw,
                                                  pos1 + searchStrLen,
                                                  appendLen
                                                ) 
                                              );
            END IF;
            -- move forward
            pos1 := pos2;
         END IF;

       END LOOP;

       IF trace_level >= 2 THEN
           "&gg_user".trace_put_line ('DDLTRACE2', 'replace_string: head = ['
                                        || head || ']');
       END IF;
        
       RETURN head;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'replace_string: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END replace_string;
    
    /*
    FUNCTION ESCAPE_STRING RETURNS VARCHAR2
    Escape all special chars in string. This way string's start and end can be safely
    figured out (in delimited string). This is because tables and column names can have
    any character (except double quote in oracle).
    param[in] ITEM                           VARCHAR2                string to escape
    param[in] ITEMMODE                       NUMBER                  ITEM_WHOLE, ITEM_HEAD, ITEM_DATA, ITEM_TAIL
    
    return escaped string
    
    remarks see ITEM_* description under itemHeader function
    */
    FUNCTION escape_string (
                            item VARCHAR2,
                            itemMode NUMBER)
    RETURN VARCHAR2
    IS
    retVal VARCHAR2 (&max_varchar2_size);
    errorMessage VARCHAR2(&message_size);
    ec varchar2(2);
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering escape_string()');
        END IF;
        
        retVal := item;
        -- the following replacements will work since UTF-8 (multibyte) and ASCII overlap in full
        -- in other words these characters cannot appear as part of multibytes
        -- the body formatting is always there regardless of head or tail
        FOR i IN 1..escapeCharsLen LOOP
            ec := SUBSTR (escapeChars, i, 1);
            retVal := replace_string (retVal, ec, '\' || ec);
        END LOOP;
        
        -- if we need head, include head formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_HEAD THEN
            retVal := '''' || retVal;
        END IF;
        
        -- if we need tail, include tail formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_TAIL THEN
            retVal := retVal || '''';
        END IF;
        
        IF trace_level >= 2 THEN
            "&gg_user".trace_put_line ('DDLTRACE2', 'escape_string: retVal = [' || retVal || ']');
        END IF;
        
        RETURN retVal;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'escape_string: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END escape_string;
    
    /*
    PROCEDURE BEGINHISTORY
    Starts DDL history table record.
    Since record can span many rows, we have beginning fragment, fragments and ending fragment
    (this way insertToMarker knows when to stop the record)
    
    see insertToMarker
    */ 
    PROCEDURE beginHistory
    IS
    errorMessage VARCHAR2(&message_size); 
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering beginHistory()');
        END IF;
        
        insertToMarker (DDL_HISTORY, '', '', '', BEGIN_FRAGMENT); 
                
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'beginHistory: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END beginHistory;
    
    /*
    PROCEDURE SETTRACING
    Set tracing level for code based on what's in setup table.
    Tracing level (and other parameters0 are kept in setup table in form of (name,value) pairs
    Tracing level is externally set by ddl_tracelevel, we only read it here and set the tracing
    variable so tracing in PL/SQL code knows when to trace
    
    see ddl_tracelevel.sql
    */
    PROCEDURE setTracing
    IS
    errorMessage VARCHAR2(&message_size);
    tl VARCHAR2(&name_size);
    BEGIN
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = 'DDL_TRACE_LEVEL';
        
        if upper (tl) = 'NONE' THEN
            trace_level := -1;
        ELSE
            trace_level := to_number (tl);
        END IF;
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = 'DDL_STAYMETADATA';
        
        if tl = 'ON' THEN
            IF trace_level >= 0 THEN 
                "&gg_user".trace_put_line ('DDL', 'Metadata is not queried (STAYMETADATA is ON)'); 
            END IF;
            stay_metadata := 1;
        ELSE
            stay_metadata := 0;
        END IF;
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = 'DDL_SQL_TRACING';
        
        sql_trace := to_number (tl);
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = '_USEALLKEYS';
        
        useAllKeys := to_number (tl);
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = 'ALLOWNONVALIDATEDKEYS';
        
        allowNonValidatedKeys := to_number (tl);
        
        SELECT VALUE 
        INTO tl
        FROM "&gg_user"."&setup_table"
        WHERE property = '_LIMIT32K';
        
        useLargeDDL := 1 - to_number (tl);
        
        
        -- get trace file directory location to include in error message
        SELECT VALUE INTO dumpDir 
        FROM sys.v_$parameter
        WHERE name = 'user_dump_dest' ;
    
        -- we do not call set_sql_trace (false) any more, because this requires executor of
        -- DDL to have ALTER SESSION priv, which is not given
        -- we also post a note in ddl_trace_off.sql to exit that session for end of tracing
        -- to take place (otherwise was automatic until now)
        IF sql_trace = 1 THEN            
            "&gg_user".trace_put_line ('DDL', 'Turning on Oracle SQL tracing'); 
            dbms_session.set_sql_trace(true);                    
        END IF;
        
        IF useAllKeys = 1 THEN            
            "&gg_user".trace_put_line ('DDL', 'Using all keys method for UK');                     
        END IF;

        IF allowNonValidatedKeys = 1 THEN            
            "&gg_user".trace_put_line ('DDL', 'Allow non-validated keys');                     
        END IF;
        
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            "&gg_user".trace_put_line ('DDL', 'Tracing set to zero (data not found)');
            trace_level := 0;
        WHEN OTHERS THEN 
            errorMessage := 'setTracing: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END setTracing;
    
    
    /*
    PROCEDURE ENDHISTORY
    Ends DDL history table record - there must have been begin history and some
    fragments before it.
    
    remarks Extract reads these fragments as a transaction (since it's part of DDL) so no 
    actual 'end marker' is required.
    
    see insertToMarker
    */
    PROCEDURE endHistory
    IS
    errorMessage VARCHAR2(&message_size);
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering endHistory()');
        END IF;
        
        insertToMarker (DDL_HISTORY, '', '', '', END_FRAGMENT); 
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'endHistory: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END endHistory;
    
    
    /*
    PROCEDURE GETVERSION
    Get version of Oracle (true and compatability versions)
    
    remarks this is passed to extract trail records for auditing
    */ 
    PROCEDURE getVersion
    IS
    errorMessage VARCHAR2(&message_size); 
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getVersion()');
        END IF;
        IF length(lv_version) > 0 AND length(lv_compat) > 0 THEN
            RETURN; -- we already have the values
        END IF;
		BEGIN
			SELECT value INTO lv_version 
			FROM "&gg_user"."GGS_STICK"
			WHERE property = 'lv_version';
			SELECT value INTO lv_compat 
			FROM "&gg_user"."GGS_STICK"
			WHERE property = 'lv_compat';
			IF trace_level >= 1 THEN 
				"&gg_user".trace_put_line ('DDL', 'DB Version from cache:' || lv_version || 'DB Compatability Version: ' || lv_compat); 
			END IF;
			RETURN;
		EXCEPTION
			WHEN OTHERS THEN
				NULL;  -- nothing, not in cache yet
		END;
        dbms_utility.db_version (lv_version, lv_compat); 
        IF trace_level >= 1 THEN 
            "&gg_user".trace_put_line ('DDL', 'DB Version computed: ' || lv_version || 'DB Compatability Version: ' || lv_compat); 
        END IF;        
        BEGIN
			INSERT INTO "&gg_user"."GGS_STICK" (property, value)
			VALUES ('lv_version', lv_version);
			INSERT INTO "&gg_user"."GGS_STICK" (property, value)
			VALUES ('lv_compat', lv_compat);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getVersion: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END getVersion;
    
    
    /*
    FUNCTION TRACE_HEADER_NAME RETURNS VARCHAR2
    Under tracing level 2, whenever we record piece of information to DDL history table
    or marker table, we trace it. Each piece has a code: this function returns human
    readable code for abbreviated marker/history code.
    param[in] HEADERTYPE                     VARCHAR2         type of info recorded
    
    return actual human readable code for tracing purposes
    */ 
    FUNCTION trace_header_name (
                                headerType IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        IF headerType = MD_TAB_USERID THEN RETURN 'MD_TAB_USERID'; END IF;
        IF headerType = MD_COL_NAME THEN RETURN 'MD_COL_NAME'; END IF;
        IF headerType = MD_COL_NUM THEN RETURN 'MD_COL_NUM'; END IF;
        IF headerType = MD_COL_SEGCOL THEN RETURN 'MD_COL_SEGCOL'; END IF;
        IF headerType = MD_COL_TYPE THEN RETURN 'MD_COL_TYPE'; END IF;
        IF headerType = MD_COL_LEN THEN RETURN 'MD_COL_LEN'; END IF;
        IF headerType = MD_COL_ISNULL THEN RETURN 'MD_COL_ISNULL'; END IF;
        IF headerType = MD_COL_PREC THEN RETURN 'MD_COL_PREC'; END IF;
        IF headerType = MD_COL_SCALE THEN RETURN 'MD_COL_SCALE'; END IF;
        IF headerType = MD_COL_CHARSETID THEN RETURN 'MD_COL_CHARSETID'; END IF;
        IF headerType = MD_COL_CHARSETFORM THEN RETURN 'MD_COL_CHARSETFORM'; END IF;
        IF headerType = MD_COL_ALT_NAME THEN RETURN 'MD_COL_ALT_NAME'; END IF;
        IF headerType = MD_COL_ALT_TYPE THEN RETURN 'MD_COL_ALT_TYPE'; END IF;
        IF headerType = MD_COL_ALT_PREC THEN RETURN 'MD_COL_ALT_PREC'; END IF;
        IF headerType = MD_COL_ALT_CHAR_USED THEN RETURN 'MD_COL_ALT_CHAR_USED'; END IF;
        IF headerType = MD_COL_ALT_XML_TYPE THEN RETURN 'MD_COL_ALT_XML_TYPE'; END IF;
        IF headerType = MD_TAB_COLCOUNT THEN RETURN 'MD_TAB_COLCOUNT'; END IF;
        IF headerType = MD_TAB_DATAOBJECTID THEN RETURN 'MD_TAB_DATAOBJECTID'; END IF;
        IF headerType = MD_TAB_CLUCOLS THEN RETURN 'MD_TAB_CLUCOLS'; END IF;
        IF headerType = MD_TAB_TOTAL_COL_NUM THEN RETURN 'MD_TAB_TOTAL_COL_NUM'; END IF;
        IF headerType = MD_TAB_LOG_GROUP_EXISTS THEN RETURN 'MD_TAB_LOG_GROUP_EXISTS'; END IF;
        IF headerType = MD_COL_ALT_LOG_GROUP_COL THEN RETURN 'MD_COL_ALT_LOG_GROUP_COL'; END IF;
        IF headerType = MD_TAB_VALID THEN RETURN 'MD_TAB_VALID'; END IF;
        IF headerType = MD_TAB_SUBPARTITION THEN RETURN 'MD_TAB_SUBPARTITION'; END IF;
        IF headerType = MD_TAB_PARTITION THEN RETURN 'MD_TAB_PARTITION'; END IF;
        IF headerType = MD_TAB_PARTITION_IDS THEN RETURN 'MD_TAB_PARTITION_IDS'; END IF;
        IF headerType = MD_TAB_BLOCKSIZE THEN RETURN 'MD_TAB_BLOCKSIZE'; END IF;
        IF headerType = MD_TAB_OBJECTID THEN RETURN 'MD_TAB_OBJECTID'; END IF;
        IF headerType = MD_TAB_PRIMARYKEY THEN RETURN 'MD_TAB_PRIMARYKEY'; END IF;
        IF headerType = MD_TAB_PRIMARYKEYNAME THEN RETURN 'MD_TAB_PRIMARYKEYNAME'; END IF;
        IF headerType = MD_TAB_OWNER THEN RETURN 'MD_TAB_OWNER'; END IF;
        IF headerType = MD_TAB_NAME THEN RETURN 'MD_TAB_NAME'; END IF;
        IF headerType = MD_TAB_OBJTYPE THEN RETURN 'MD_TAB_OBJTYPE'; END IF;
        IF headerType = MD_TAB_OPTYPE THEN RETURN 'MD_TAB_OPTYPE'; END IF;
        IF headerType = MD_TAB_SCN THEN RETURN 'MD_TAB_SCN'; END IF;
        IF headerType = MK_OBJECTID THEN RETURN 'MK_OBJECTID'; END IF;
        IF headerType = MK_OBJECTOWNER THEN RETURN 'MK_OBJECTOWNER'; END IF;
        IF headerType = MK_OBJECTNAME THEN RETURN 'MK_OBJECTNAME'; END IF;
        IF headerType = MK_MASTEROWNER THEN RETURN 'MK_MASTEROWNER'; END IF;
        IF headerType = MK_MASTERNAME THEN RETURN 'MK_MASTERNAME'; END IF;
        IF headerType = MK_OBJECTTYPE THEN RETURN 'MK_OBJECTTYPE'; END IF;
        IF headerType = MK_DDLTYPE THEN RETURN 'MK_DDLTYPE'; END IF;
        IF headerType = MK_DDLSEQ THEN RETURN 'MK_DDLSEQ'; END IF;
        IF headerType = MK_DDLHIST THEN RETURN 'MK_DDLHIST'; END IF;
        IF headerType = MK_LOGINUSER THEN RETURN 'MK_LOGINUSER'; END IF;        
        IF headerType = MK_DDLSTATEMENT THEN RETURN 'MK_DDLSTATEMENT'; END IF;
        IF headerType = MD_TAB_MASTEROWNER THEN RETURN 'MD_TAB_MASTEROWNER'; END IF;
        IF headerType = MD_TAB_MASTERNAME THEN RETURN 'MD_TAB_MASTERNAME'; END IF;
        IF headerType = MD_TAB_MARKERSEQNO THEN RETURN 'MD_TAB_MARKERSEQNO'; END IF;
        IF headerType = MD_TAB_MARKERTABLENAME THEN RETURN 'MD_TAB_MARKERTABLENAME'; END IF;
        IF headerType = MD_TAB_DDLSTATEMENT THEN RETURN 'MD_TAB_DDLSTATEMENT'; END IF;
        IF headerType = MD_TAB_BIGFILE THEN RETURN 'MD_TAB_BIGFILE'; END IF;
        IF headerType = MK_TAB_VERSIONINFO THEN RETURN 'MK_TAB_VERSIONINFO'; END IF;
        IF headerType = MK_TAB_VERSIONINFOCOMPAT THEN RETURN 'MK_TAB_VERSIONINFOCOMPAT'; END IF;
        IF headerType = MK_TAB_VALID THEN RETURN 'MK_TAB_VALID'; END IF;
        IF headerType = MK_INSTANCENUMBER THEN RETURN 'MK_INSTANCENUMBER'; END IF;
        IF headerType = MK_INSTANCENAME THEN RETURN 'MK_INSTANCENAME'; END IF;
        IF headerType = MD_TAB_SEQUENCEROWID THEN RETURN 'MD_TAB_SEQUENCEROWID'; END IF;
        IF headerType = MD_TAB_SEQCACHE THEN RETURN 'MD_TAB_SEQCACHE'; END IF;
        IF headerType = MD_TAB_SEQINCREMENTBY THEN RETURN 'MD_TAB_SEQINCREMENTBY'; END IF;
        IF headerType = MD_TAB_IOT THEN RETURN 'MD_TAB_IOT'; END IF;
        IF headerType = MD_TAB_IOT_OVERFLOW THEN RETURN 'MD_TAB_IOT_OVERFLOW'; END IF;
        IF headerType = MD_COL_ALT_BINARYXML_TYPE THEN RETURN 'MD_COL_ALT_BINARYXML_TYPE'; END IF;
        IF headerType = MD_COL_ALT_LENGTH THEN RETURN 'MD_COL_ALT_LENGTH'; END IF;
        IF headerType = MK_TAB_OBJECTTABLE THEN RETURN 'MK_TAB_OBJECTTABLE'; END IF;
        IF headerType = MK_TAB_TOIGNORE THEN RETURN 'MK_TAB_TOIGNORE'; END IF;
        IF headerType = MK_TAB_NLS_PARAM THEN RETURN 'MK_TAB_NLS_PARAM'; END IF;
        IF headerType = MK_TAB_NLS_VAL THEN RETURN 'MK_TAB_NLS_VAL'; END IF;
        IF headerType = MK_TAB_NLS_CNT THEN RETURN 'MK_TAB_NLS_CNT'; END IF;
        IF headerType = MK_TAB_XMLTYPETABLE THEN RETURN 'MK_TAB_XMLTYPETABLE'; END IF;	
        IF headerType = MD_TAB_ENC_MKEYID THEN RETURN 'MD_TAB_ENC_MKEYID'; END IF;        
        IF headerType = MD_TAB_ENC_ENCALG THEN RETURN 'MD_TAB_ENC_ENCALG'; END IF;        
        IF headerType = MD_TAB_ENC_INTALG THEN RETURN 'MD_TAB_ENC_INTALG'; END IF;        
        IF headerType = MD_TAB_ENC_COLKLC THEN RETURN 'MD_TAB_ENC_COLKLC'; END IF;        
        IF headerType = MD_TAB_ENC_KLCLEN THEN RETURN 'MD_TAB_ENC_KLCLEN'; END IF;        
        IF headerType = MD_COL_ENC_ISENC THEN RETURN 'MD_COL_ENC_ISENC'; END IF;        
        IF headerType = MD_COL_HASNOTNULLDEFAULT THEN RETURN 'MD_COL_HASNULLDEFAULT'; END IF;        
        IF headerType = MD_COL_ENC_NOSALT THEN RETURN 'MD_COL_ENC_NOSALT'; END IF;                
        IF headerType = MD_COL_ENC_ISLOB THEN RETURN 'MD_COL_ENC_ISLOB'; END IF;                
        IF headerType = MD_COL_LOB_ENCRYPT THEN RETURN 'MD_COL_LOB_ENCRYPT'; END IF;                
        IF headerType = MD_COL_LOB_COMPRESS THEN RETURN 'MD_COL_LOB_COMPRESS'; END IF;                
        IF headerType = MD_COL_LOB_DEDUP THEN RETURN 'MD_COL_LOB_DEDUP'; END IF;                
        IF headerType = MD_COL_ALT_OBJECTXML_TYPE THEN RETURN 'MD_COL_ALT_OBJECTXML_TYPE'; END IF;
        IF headerType = MD_TAB_XMLTYPETABLE THEN RETURN 'MD_TAB_XMLTYPETABLE'; END IF;


        IF headerType = MD_TAB_SESSION_OWNER THEN RETURN 'MD_TAB_SESSION_OWNER'; END IF;        
        RETURN 'UNKNOWN';
        
    END trace_header_name;
    
    /*
    FUNCTION ITEMHEADER RETURNS VARCHAR2
    Create a name/value pair that can be simply appended to a string that will be saved to 
    either marker or DDL tables. 
    param[in] HEADERTYPE                     VARCHAR2                MD or MK constant
    param[in] FIRSTKEY                       VARCHAR2                first accesor key
    param[in] SECONDKEY                      VARCHAR2                second accessor key
    param[in] VAL                            VARCHAR2                actual value (up to 32K)
    param[in] ITEMMODE                       NUMBER                  ITEM_WHOLE, ITEM_HEAD, ITEM_TAIL, ITEM_DATA
    
    return a string value that contains all strings escaped and delimited so that simple
    concatenation of strings produced by this function is ready for persistent save
    MODE can be be ITEM_WHOLE (data with full header and footer), ITEM_HEAD (head+data), 
    ITEM_TAIL (data+tail), ITEM_DATA (just data)
    */
    FUNCTION itemHeader (headerType IN VARCHAR2, firstKey IN VARCHAR2, secondKey IN VARCHAR2, val IN VARCHAR2,
        itemMode IN NUMBER)
    RETURN VARCHAR2 
    IS
    -- note: size of retVal is in most cases limited to frag_size (4K) because it is
    -- used with ADD_FRAGMENT, however for marker string building it must be up to
    -- max size (32K), so final limit is really 32K
    retVal VARCHAR2(&max_varchar2_size);
    errorMessage VARCHAR2(&message_size);
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering itemHeader()');
        END IF;
        
        IF trace_level >= 1 THEN 
            "&gg_user".trace_put_line ('DDLTRACE1', 'itemHeader: ' || trace_header_name (headerType) ||
                                        '(key1 = [' || firstKey || '] key2 = [' || secondKey || ']) = [' || val || '], ' ||
                                        'itemMode = [' || to_char(itemMode) || ']');
        END IF;
        
        
        retVal := '';
        
        -- when head is needed, include standard DDL head formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_HEAD THEN
            IF firstKey IS NOT NULL THEN             
                retVal := ',' || headerType || '(' || escape_string (firstKey, ITEM_WHOLE) || ')';
                IF secondKey IS NOT NULL THEN
                    retVal := retVal || ',' || headerType || '(' || escape_string (secondKey, ITEM_WHOLE) || ')' || '=';
                ELSE
                    retVal := retVal || '=';
                END IF;            
            ELSE
                retVal := ',' || headerType || '=';
            END IF;
        END IF;
        
        -- actual data is always there, regardless of head or tail
        retVal := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(retVal) || 
                                            utl_raw.cast_to_raw(escape_string (val, itemMode)) );
        
        -- when tail is needed, include standard DDL tail formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_TAIL THEN
            retVal := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(retVal) || 
                                                utl_raw.cast_to_raw(',') );
        END IF;
        
        IF trace_level >= 2 THEN
            "&gg_user".trace_put_line ('DDLTRACE2', 'itemHeader: retVal = [' || retVal || ']');
        END IF;
        RETURN retVal;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'itemHeader: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END itemHeader;
    
    
    /*  
    PROCEDURE SAVESEQINFO
    Save owner, name, object id and row id (as of this SCN) of sequence 
    to be used to resolve sequence in extract when needed
    
    param[in] POWNER                         VARCHAR2     owner of sequence
    param[in] PTABLE                         VARCHAR2     name of sequence
    param[in] OPTYPE                         VARCHAR2     type of DDL
    param[in] USERID                         VARCHAR2     id of user who owns the object
    param[in] SEQCACHE                       VARCHAR2     cache value for seq
    param[in] SEQINCREMENTBY                 VARCHAR2     incrementby value for seq
    param[in] TOIGNORE                       VARCHAR2     if DDL is to be ignored in extract

    */ 
    PROCEDURE saveSeqInfo (
                           powner IN VARCHAR2, 
                           pname IN VARCHAR2,
                           optype IN VARCHAR2,
                           userid IN VARCHAR2,
                           seqCache IN NUMBER,
                           seqIncrementBy IN NUMBER,
                           toIgnore IN VARCHAR2)
    IS 
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering saveSeqInfo()');
        END IF;

        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_SEQUENCEROWID, '', '', currentRowid, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OBJECTID, '', '', to_char (currentObjectId), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_NAME, '', '', pname, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OWNER, '', '', powner, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OBJTYPE, '', '', 'SEQUENCE', ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_USERID, '', '', userid, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OPTYPE, '', '', optype, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_SEQCACHE, '', '', to_char (seqCache), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_SEQINCREMENTBY, '', '', to_char (seqIncrementBy), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        IF currentObjectId IS NOT NULL THEN
            -- object id can be NULL in CREATE statements 
            -- we don't delete alt data because it can cause deadlock. So there is more records with
            -- the same information, but that's fine because in extract we select one only. And these
            -- records can be purged with PURGEDDLHISTORYALT in manager
            BEGIN				
				-- populate alt table for resolution of partition DMLs or sequences
				-- it won't matter if there is a duplicate (altObjectId, objectId), it will be handled
				-- we will also record partitions that have been dropped (their ids won't be removed)
                -- but that's fine since those can't show up for DML any more
                INSERT INTO "&gg_user"."&ddl_hist_table_alt" (
                    altObjectId,
                    objectId,
                    optime)
                VALUES (
                    currentObjectId,
                    currentObjectId,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                );
            EXCEPTION 
                WHEN DUP_VAL_ON_INDEX THEN 
                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (5)');
                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                WHEN NO_DATA_FOUND THEN 
                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (5)');
                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                WHEN deadlockDetected THEN
                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (5)');
                NULL; -- do nothing, this means somebody else is doing this exact work!
            END;
        END IF; 
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'saveSeqInfo' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
            
    END saveSeqInfo;
    
    /*  
    PROCEDURE GETKEYCOLSUSEALLKEYS
    Add key cols to DDL history. If PK is not present, UK is tried.
    
    param[in] POWNER                         VARCHAR2     owner of table           
    param[in] PTABLE                         VARCHAR2     name of table
    
    remarks final decision what to use as PK rests with extract. This is USEALLKEYS (old) implementation
    */ 
    PROCEDURE getKeyColsUseAllKeys (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2) 
    IS 
    seq NUMBER; 
    errorMessage VARCHAR2(&message_size);
    realColName VARCHAR2(&name_size);     
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getKeyColsUseAllKeys()');
        END IF;
        
        seq := 0;
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Looking for primary key for [(' || pobjid||')'||powner || '.' || ptable || ']');
        END IF;
        
        FOR pk IN DDLReplication.pk_curs (pobjid,powner, ptable) LOOP 
            seq := seq + 1;
            IF seq = 1 THEN
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', pk.constraint_name, ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END IF;
            insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_PRIMARYKEY, to_char (seq), pk.column_name, pk.column_name, ITEM_WHOLE)
                            , ADD_FRAGMENT); 
        END LOOP; 
        
        IF seq = 0 THEN 
            seq := 0;
            FOR uk IN "&gg_user".DDLVersionSpecific.uk_curs_all_keys (powner, ptable) LOOP 
                seq := seq + 1;
                IF seq = 1 THEN
                    insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', uk.index_name, ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                END IF;
                -- find real column name if DESC used in column in index definition (oracle generates system one)
                IF uk.descend = 'DESC' THEN
                    SELECT c.default$ INTO realColName
                    FROM sys.obj$  o, sys.col$ c 
                    WHERE o.obj# = c.obj# 
                        AND c.default$ is not NULL 
                        AND o.obj# = pobjid and c.name = uk.column_name;             
                ELSE
                    realColName := uk.column_name;
                END IF;
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_PRIMARYKEY, to_char (seq), realColName, realColName, ITEM_WHOLE)
                                , ADD_FRAGMENT); 
            END LOOP; 
        END IF;
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found [' || to_char (seq) || '] columns for primary or unique key');
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getKeyColsUseAllKeys: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END getKeyColsUseAllKeys;
    
    
    
    -- get the key - either a pk, uk or none of the above
    -- param[in] powner owner of table
    -- param[in] ptable table name
    -- stores result in DDL history
    
    /*  
    PROCEDURE GETKEYCOLS
    Add key cols to DDL history. If PK is not present, UK is tried.
    
    param[in] POWNER                         VARCHAR2     owner of table           
    param[in] PTABLE                         VARCHAR2     name of table
    
    remarks final decision what to use as PK rests with extract
    */ 
    PROCEDURE getKeyCols (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2) 
    IS     
    seqPK NUMBER; 
    errorMessage VARCHAR2(&message_size); 
    colNull NUMBER;
    colVirtual NUMBER;
    colUdt NUMBER;
    colSys NUMBER;
    bestKey VARCHAR2(&name_size);
    realColName VARCHAR2(&name_size);    
    pkFound NUMBER;
    ukFound NUMBER;
    keyCount NUMBER;
    pkValid NUMBER;
    thereIsNotNullUK NUMBER;
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getKeyCols()');
        END IF;
        
        
        pkFound := 0;
        ukFound := 0;
        
       
        seqPK := 1;
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Looking for primary key for [(' || pobjid ||')'||powner || '.' || ptable || ']');
        END IF;
                 
        FOR pk IN DDLReplication.pk_curs (pobjid, powner, ptable) LOOP 
            pkFound := 1;
            IF seqPK = 1 THEN

                IF "&gg_user".DDLReplication.allowNonvalidatedKeys = 0 THEN
                    SELECT COUNT(*) INTO pkValid
                    FROM dba_constraints 
                    WHERE owner = powner AND table_name= ptable AND constraint_name = pk.constraint_name
                    AND validated='VALIDATED'
                    AND rely IS NULL
                    AND status = 'ENABLED';
                
                    IF pkValid = 0 THEN -- go look for UK if PK not valid
                        pkFound := 0;                    
                        EXIT;
                    END IF;
                END IF;

                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', pk.constraint_name, ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END IF;
            insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_PRIMARYKEY, to_char (seqPK), pk.column_name, pk.column_name, ITEM_WHOLE)
                            , ADD_FRAGMENT); 
            seqPK := seqPK + 1;
        END LOOP; 
        
        IF pkFound = 0 THEN             
            -- unique key query is now oracle version specific, part of own package
            -- we record info for keys in global temp table, so we do query only once
            FOR uk IN "&gg_user".DDLVersionSpecific.uk_curs (powner, ptable) LOOP 
                ukFound := 1;
                
                -- find real column name if DESC used in column in index definition (oracle generates system one)
                IF uk.descend = 'DESC' THEN                
                    BEGIN
                        SELECT c.default$ INTO realColName
                        FROM sys.obj$ o, sys.col$ c 
                        WHERE o.obj# = c.obj# 
                            AND c.default$ is not NULL 
                            AND o.obj# = pobjid and c.name = uk.column_name;                          
                    EXCEPTION 
                        WHEN OTHERS THEN 
                            "&gg_user".trace_put_line ('DDLTRACE', 'Error processing query (realColName, getKeyCols) ' || SQLERRM);
                            realColName := uk.column_name;        
                    END;
                ELSE
                    realColName := uk.column_name;
                END IF;
                
                -- find out if columns in key are either null or virtual or udt, no duplicates as queries primary key                
                IF trace_level >= 1 THEN
                    "&gg_user".trace_put_line ('DDLTRACE1', 'Querying index  ' || uk.index_name || ' column ' || realColName || 
                        ' obtained name ' || uk.column_name);
                END IF; 
                
                            
                -- this column must be here
                -- if not, we should stop processing
                
                BEGIN
                    SELECT nullable, virtual, udt, isSys INTO colNull, colVirtual, colUdt, colSys
                    FROM "&gg_user"."GGS_TEMP_COLS"
                    WHERE seqno = "&gg_user".DDLReplication.currentMarkerSeq AND colName=uk.column_name;

                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'Index ' || uk.index_name || ' column ' || realColName ||
                            ' colNull ' || colNull || ' colVirtual ' || colVirtual || ' colUDT ' || colUdt || ' colSys ' || colSys);
                    END IF; 

                    -- this insert should not fail as we have primary key
                    INSERT INTO "&gg_user"."GGS_TEMP_UK" (seqNo, keyName, colName, nullable, virtual, udt, isSys)
                    VALUES ("&gg_user".DDLReplication.currentMarkerSeq, uk.index_name, realColName, colNull, colVirtual, colUdt, colSys);

                EXCEPTION 
                    WHEN OTHERS THEN 
                        -- this means that probably table has primary key but not columns
                        "&gg_user".trace_put_line ('DDLTRACE', 'Warning processing query (nvu, getKeyCols), column ' || uk.column_name || SQLERRM);
                        colNull := 0;
                        colVirtual := 0;
                        colUdt := 0;
                END;
                
            END LOOP; 
            IF ukFound = 1 THEN
                BEGIN     
                
                    -- keyCount is number of unique keys that have neither null nor udt nor virtual
                    -- use SUM() to make sure GROUP BY doesn't produce multiple results
                    SELECT SUM(COUNT(*)) INTO keyCount FROM "&gg_user"."GGS_TEMP_UK" uk1 
                    WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq
                    AND NOT EXISTS  (
                        SELECT uk2.nullable FROM "&gg_user"."GGS_TEMP_UK" uk2
                        WHERE uk2.seqNo = "&gg_user".DDLReplication.currentMarkerSeq
                        AND uk2.keyName = uk1.keyName
                        AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.nullable = 1 OR uk2.isSys = 1)
                        )                    
                    GROUP BY keyName;
                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'Minimum number of good keys (1) ' || keyCount);
                    END IF; 
                    IF keyCount = 0 OR keyCount IS NULL THEN
                        SELECT SUM(COUNT(*)) INTO keyCount FROM "&gg_user"."GGS_TEMP_UK" uk1 
                        WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq                        
                        AND NOT EXISTS  (
                            SELECT uk2.virtual FROM "&gg_user"."GGS_TEMP_UK" uk2
                            WHERE uk2.seqNo = "&gg_user".DDLReplication.currentMarkerSeq
                            AND uk2.keyName = uk1.keyName
                            AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.isSys = 1)
                            )
                        GROUP BY keyName;
                        thereIsNotNullUK := 0;
                    ELSE
                        thereIsNotNullUK := 1;
                    END IF;
                        
                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'Minimum number of good keys [' || keyCount || ']');
                    END IF; 
                        
                    IF keyCount IS NOT NULL AND keyCount > 0 THEN    
                        -- find alphabetically first key which has minimum number of columns       
                        -- because of previous query, this one must return result
                        IF thereIsNotNullUK = 1 THEN
                            SELECT MIN(keyName) INTO bestKey 
                            FROM "&gg_user"."GGS_TEMP_UK"  uk1
                            WHERE 
                            NOT EXISTS (SELECT uk2.nullable FROM "&gg_user"."GGS_TEMP_UK" uk2
                                WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq
                                AND uk2.keyName = uk1.keyName
                                AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.nullable = 1 OR uk2.isSys = 1))
                            ORDER BY keyName ASC;
                        ELSE
                            SELECT MIN(keyName) INTO bestKey 
                            FROM "&gg_user"."GGS_TEMP_UK"  uk1
                            WHERE                             
                            NOT EXISTS (SELECT uk2.virtual FROM "&gg_user"."GGS_TEMP_UK" uk2
                                WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq
                                AND uk2.keyName = uk1.keyName
                                AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.isSys = 1))                            
                            ORDER BY keyName ASC;
                        END IF;
                        
                        IF trace_level >= 1 THEN
                            "&gg_user".trace_put_line ('DDLTRACE1', 'Best Index ' || bestKey);
                        END IF; 
                        
                        insertToMarker (DDL_HISTORY, '', '', 
                                        itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', bestKey, ITEM_WHOLE)
                                        , ADD_FRAGMENT);
                    
                        -- find columns for this key
                        -- we already established that there is more than 0 columns in a key (maxKeys > 0)
                        FOR ukc IN (SELECT colName FROM "&gg_user"."GGS_TEMP_UK" WHERE 
                            seqNo = "&gg_user".DDLReplication.currentMarkerSeq AND keyName = bestKey) LOOP                    
                            insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_TAB_PRIMARYKEY, to_char (seqPK), ukc.colName, ukc.colName, ITEM_WHOLE)
                                    , ADD_FRAGMENT);         
                            IF trace_level >= 1 THEN
                                "&gg_user".trace_put_line ('DDLTRACE1', 'Add column to best index ' || ukc.colName);
                            END IF; 
                            seqPK := seqPK + 1;
                        END LOOP;
                    END IF;
                EXCEPTION WHEN NO_DATA_FOUND THEN 
                    "&gg_user".trace_put_line ('DDLTRACE', 'No unique key found for for [' || powner || '.' || ptable || ']');
                END;
            END IF;
        END IF;
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Found [' || to_char (seqPK - 1) || '] columns for primary or unique key');
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getKeyCols: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END getKeyCols;
    
    
    /*
    PROCEDURE GETCOLDEFS
    Stores column information to DDL history table. Most column info is here
    (such as name, number, type, length, precision etc.) is gathered here.
    param[in] POWNER                         VARCHAR2                owner of table
    param[in] PTABLE                         VARCHAR2                name of table
    */
    
    PROCEDURE getColDefs (pobjid IN NUMBER,
                          powner IN VARCHAR2, 
                          ptable IN VARCHAR2) 
    IS 
    colCount NUMBER; 
    xmlType NUMBER;
    binaryXMLType NUMBER;
    objectXMLType NUMBER;
    ora_column_id NUMBER;
    ora_segment_column_id NUMBER;
    errorMessage VARCHAR2(&message_size);
    realType NUMBER;
    isUDT NUMBER;
    isRealColumn NUMBER;
    isEnc NUMBER;
    isLob NUMBER;
    isXMLTab VARCHAR2(&type_size);
    encMkeyid "&enc_schema"."&enc_table".MKEYID%TYPE;
    encEncAlg "&enc_schema"."&enc_table".ENCALG%TYPE;
    encIntAlg "&enc_schema"."&enc_table".INTALG%TYPE;
    encColKey VARCHAR2(&max_varchar2_size);
    encColKeyLen "&enc_schema"."&enc_table".KLCLEN%TYPE; 
    char_length NUMBER;
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getColDefs()');
        END IF;

        isEnc := 0; -- flag to track if there is TDE for table or not
        isLob := 0; -- 1 if column is LOB
        isXMLTab := 'NO';
        
        colCount := 0;
        FOR cd IN DDLReplication.getCols (pobjid, powner, ptable) LOOP 
             
            IF trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Column name [' || cd.column_name || '] , original type [' ||
                cd.type_num || ' col_num ' ||cd.col_num||']');
            END IF; 
            realType := cd.type_num; 
            isUDT := 0;
            
            -- processing of XML is done differently in extract's OCI. It checks for SQL_NTY as data type
            -- before running query. Here we will check for 'XMLTYPE' data type (as we run different queries)
            -- but it is equivalent
            xmlType := 0; -- column is not XML by default, don't run XML query if not so
            binaryXMLType := 0;
            objectXMLType := 0;
            
            isRealColumn := 0;
            FOR gp IN DDLReplication.getPrec (powner, ptable, cd.column_name) LOOP
                -- there is only one or none loop here
                -- if there is none, we don't increase column count
                -- this is because getPrec checks dba_tab_columns - if it's not there
                -- then it's hidden

             
            IF trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Precision [' || gp.data_type || '] , owner type [' || gp.data_type_owner || ' original type '||
                cd.type_num || ']');
            END IF; 
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_COL_ALT_NAME, to_char (cd.col_num), cd.column_name , cd.column_name, ITEM_WHOLE) ||
                                itemHeader (MD_COL_ALT_TYPE, to_char (cd.col_num), cd.column_name, to_char (gp.data_type), ITEM_WHOLE) || 
                                itemHeader (MD_COL_ALT_TYPE_OWNER, to_char (cd.col_num), cd.column_name, to_char (gp.data_type_owner), ITEM_WHOLE) ||                                 
                                itemHeader (MD_COL_ALT_PREC, to_char (cd.col_num), cd.column_name, to_char (gp.data_precision), ITEM_WHOLE) || 
                                itemHeader (MD_COL_ALT_CHAR_USED, to_char (cd.col_num), cd.column_name, gp.char_used, ITEM_WHOLE) ||
                                itemHeader (MD_COL_ALT_LENGTH, to_char (cd.col_num), cd.column_name, gp.data_length, ITEM_WHOLE) ||
                                itemHeader (MD_COL_ENC_ISENC, to_char (cd.col_num), cd.column_name, cd.isEnc, ITEM_WHOLE) ||
                                itemHeader (MD_COL_ENC_ISLOB, to_char (cd.col_num), cd.column_name, cd.isLob, ITEM_WHOLE) ||
                                itemHeader (MD_COL_ENC_NOSALT, to_char (cd.col_num), cd.column_name, cd.isNoSalt, ITEM_WHOLE) ||
                                itemHeader (MD_COL_HASNOTNULLDEFAULT, to_char (cd.col_num), cd.column_name, cd.hasNotnullDefault, ITEM_WHOLE) 
                                , ADD_FRAGMENT); 
                IF cd.isEnc = 'YES' THEN
                    isEnc := 1; -- now we now we'll need other TDE info for this table
                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'Col ' || cd.column_name || ' type ' || gp.data_type || ',encrypted isEnc ' || cd.isEnc || ' nosalt ' || cd.isNoSalt);
                    END IF; 
                END IF; 
              
                IF realType = 121 OR realType = 122 OR realType = 123 THEN -- UDT
                    realType := 108; -- generic UDT, can be XMLTYPE
                    xmlType := 0; -- for now, no XML, will check in next IF                    
                END IF;
                IF gp.data_type = 'XMLTYPE' THEN  -- check if this is XML
                    BEGIN
                        FOR xs IN DDLReplication.getXMLStorage (powner, ptable, cd.column_name) LOOP
                            -- if it ever gets into this loop, it's truly XML type
                            realType := 108;
                            xmlType := 1;
                            IF bitand(xs.opq_flags, XMLOBJECT + XMLLOB + XMLBINARY) = XMLOBJECT THEN
                                objectXMLType := 1; 
                            ELSIF bitand(xs.opq_flags, XMLOBJECT + XMLLOB + XMLBINARY) = (XMLLOB + XMLBINARY) THEN
                                binaryXMLType := 1;
                            END IF;
                            IF bitand(xs.opq_flags, XMLTAB) = XMLTAB THEN
                                isXMLTab := 'YES'; 
                            END IF;
                            IF trace_level >= 1 THEN
                                "&gg_user".trace_put_line ('DDLTRACE1', 'Col ' || cd.column_name || ' type ' || gp.data_type || ',XML flags [' || xs.opq_flags || ']');
                            END IF;
                        END LOOP;
                    EXCEPTION WHEN OTHERS THEN
                        errorMessage := 'getXMLStorage, error: could not determine xml storage type: ' || SQLERRM; 
                        "&gg_user".trace_put_line ('DDL', errorMessage); 
                        NULL;  
                    END;   
                END IF; 
                IF realType = 108 THEN
                    isUDT := 1;
                END IF;

                IF cd.isLob = 'YES' OR (xmlType = 1 AND objectXMLType = 0) THEN
                    "&gg_user".ddlora_getLobs (powner, ptable, cd.column_name, cd.col_num);
                END IF; 

                colCount := colCount + 1;
                isRealColumn := 1;
            END LOOP;
            
            -- when UDT is used, there are other columns (system ones) that should not
            -- be included, such as functional indexes
            IF isRealColumn = 1 THEN 
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_COL_ALT_XML_TYPE, to_char (cd.col_num), cd.column_name, to_char (xmlType), ITEM_WHOLE)
                                , ADD_FRAGMENT); 
                                
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_COL_ALT_BINARYXML_TYPE, to_char (cd.col_num), cd.column_name, to_char (binaryXMLType), ITEM_WHOLE)
                                , ADD_FRAGMENT); 
                
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_COL_ALT_OBJECTXML_TYPE, to_char (cd.col_num), cd.column_name, to_char (objectXMLType), ITEM_WHOLE)
                                , ADD_FRAGMENT); 

                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_COL_NAME, to_char (cd.col_num), cd.column_name, cd.column_name, ITEM_WHOLE) ||
                                itemHeader (MD_COL_NUM, to_char (cd.col_num), cd.column_name , to_char (cd.col_num), ITEM_WHOLE) || 
                                itemHeader (MD_COL_SEGCOL, to_char (cd.col_num), cd.column_name, to_char (cd.segcol_num), ITEM_WHOLE) || 
                                itemHeader (MD_COL_TYPE, to_char (cd.col_num), cd.column_name, to_char (realType), ITEM_WHOLE) || 
                                itemHeader (MD_COL_LEN, to_char (cd.col_num), cd.column_name, to_char (cd.length), ITEM_WHOLE) ||
                                itemHeader (MD_COL_ISNULL, to_char (cd.col_num), cd.column_name, to_char (cd.isnull), ITEM_WHOLE) || 
                                itemHeader (MD_COL_PREC, to_char (cd.col_num), cd.column_name, to_char (cd.precision_num), ITEM_WHOLE) ||
                                itemHeader (MD_COL_SCALE, to_char (cd.col_num), cd.column_name, to_char (cd.scale), ITEM_WHOLE) || 
                                itemHeader (MD_COL_CHARSETID, to_char (cd.col_num), cd.column_name, to_char (cd.charsetid), ITEM_WHOLE) ||
                                itemHeader (MD_COL_CHARSETFORM, to_char (cd.col_num), cd.column_name, to_char (cd.charsetform), ITEM_WHOLE)
                                , ADD_FRAGMENT); 
            END IF;
            
            IF trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Insert into TEMP COLS [' || cd.column_name || '], nullable ' ||
                cd.isnull || ' isvirtual ' || cd.segcol_num);
            END IF; 
            -- should always succeed, we're using pk 
            INSERT INTO "&gg_user"."GGS_TEMP_COLS" (seqNo, colName, nullable, virtual, udt, isSys)
            VALUES ("&gg_user".DDLReplication.currentMarkerSeq, cd.column_name, cd.isnull, decode (cd.segcol_num, 0, 1, 0), isUDT, 1 - isRealColumn);
            
        END LOOP; 
        
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_COLCOUNT, '', '', to_char (colCount), ITEM_WHOLE)
                        , ADD_FRAGMENT);

        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_XMLTYPETABLE, '', '', isXMLTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        IF isEnc = 1 THEN 
			/* Get TDE related data for this object IF there are encrypted columns*/
			BEGIN
				SELECT MKEYID, ENCALG, INTALG, COLKLC, KLCLEN 
				INTO encMkeyid, encEncAlg, encIntAlg, encColKey, encColKeyLen
				FROM "&enc_schema"."&enc_table"
				WHERE OBJ#=DDLReplication.currentObjectId;
				
				-- 0 is sometimes found in keys
				encMkeyid := REPLACE (encMkeyid, chr(0), ' ');  
				encColKey := REPLACE (encColKey, chr(0), ' ');          
                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'Table ' || powner || '.' || ptable || ' mkeyid ' || encMkeyid || ' encalg ' || encEncAlg || ' intalg ' || encIntAlg || ' encColKey ' || encColKey || ' encColKeyLen ' || encColKeyLen);
                    END IF; 
                insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_ENC_MKEYID, '', '', to_char (encMkeyid), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_ENC_ENCALG, '', '', to_char (encEncAlg), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_ENC_INTALG, '', '', to_char (encIntAlg), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_ENC_COLKLC, '', '', to_char (encColKey), ITEM_WHOLE)
                        , ADD_FRAGMENT);        
                insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_ENC_KLCLEN, '', '', to_char (encColKeyLen), ITEM_WHOLE)
                        , ADD_FRAGMENT);
			EXCEPTION
			WHEN NO_DATA_FOUND THEN 
				errorMessage := 'getTDEinfo, error: found enc cols, but no TDE data: ' || ':' || SQLERRM; 
				"&gg_user".trace_put_line ('DDL', errorMessage); 
				NULL; -- do nothing, we may not need to decrypt anything!!
			WHEN OTHERS THEN
				errorMessage := 'getTDEinfo, error: found enc cols, but trouble getting TDE data: ' || ':' || SQLERRM; 
				"&gg_user".trace_put_line ('DDL', errorMessage); 				
				NULL; -- do nothing, we may not need to decrypt anything!!
			END;
		END IF;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getColDefs: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE; 
    END getColDefs;
    
    -- get the table info
    -- param[in] powner owner of table
    -- param[in] ptable table name
    -- stores result in DDL history
    
    /*
    PROCEDURE GETTABLEINFO
    Store table information in DDL history table, such as number of columns, partitions etc.
    Also, general information about DDL is put in here.
    
    param[in] OBJNAME                        VARCHAR2                object name (can be index, trigger..)
    param[in] OBJOWNER                       VARCHAR2                object owner (can be index, trigger...)
    param[in] OBJTYPE                        VARCHAR2                TABLE, INDEX, TRIGGER...
    param[in] OPTYPE                         VARCHAR2                CREATE, ALTER...
    param[in] USERID                         VARCHAR2                user id of owner
    param[in] MOWNER                         VARCHAR2                base owner (of the table)
    param[in] MNAME                          VARCHAR2                base name (of the table)
    param[in] DDLSTATEMENT                   VARCHAR2                actual DDL statement text
    param[in] TOIGNORE                       VARCHAR2                if DDL is to be ignored in extract
    
    remarks ADD_FRAGMENT_AND_FLUSH is used for DDL statement  because it can be bigger than 4K, such data
    is immediatelly flushed to DDL history table
    */ 
    PROCEDURE getTableInfo (objId IN NUMBER,
                            objName IN VARCHAR2,
                            objOwner IN VARCHAR2,
                            objType IN VARCHAR2,
                            opType IN VARCHAR2,
                            userId IN VARCHAR2,
                            mowner IN VARCHAR2,
                            mname IN VARCHAR2,
                            ddlStatement IN VARCHAR2,
                            toIgnore IN VARCHAR2) 
    IS 
    num_objects NUMBER;
    unusedCols NUMBER;
    ora_column_cnt NUMBER;
    log_group_exists NUMBER;
    all_log_group_exists NUMBER;
    s_log_group_name VARCHAR2(&name_size);
    log_group_id NUMBER;
    part_id NUMBER;
    errorMessage VARCHAR2(&message_size);
    alt_obj_type VARCHAR2(&type_size);
    is_subpart NUMBER;
    is_part NUMBER;
    isCompressed NUMBER;
    isIOT VARCHAR2(&type_size);
    isIOTWithOverflow VARCHAR2(&type_size);
    prop NUMBER;
    clusterType VARCHAR2(&type_size);
    tabColsCounter NUMBER;
    check_schema_suplog NUMBER;
    check_schema_tabf NUMBER;
    schemaSuplog_cursor    INTEGER;
    ignore                 INTEGER;
    schemaSuplog_colName   VARCHAR2(30);
    fallback              NUMBER;
    BEGIN
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering getTableInfo(), object id (objId)' || objId);
        END IF;
        fallback := 0;
        
        -- !!!!! keep this record the very first one, because 
        -- it can be larger than 4K - needs to flush immediately
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_DDLSTATEMENT, '', '', ddlStatement, ITEM_WHOLE)
                        , ADD_FRAGMENT_AND_FLUSH);         
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_MARKERTABLENAME, '', '', '&gg_user' || '.' || '&marker_table_name', ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_MARKERSEQNO, '', '', to_char ("&gg_user".DDLReplication.currentMarkerSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_SCN, '', '', to_char ("&gg_user".DDLReplication.SCNB + "&gg_user".DDLReplication.SCNW * power (2, 32)), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OBJECTID, '', '', to_char (currentObjectId), ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OWNER, '', '', objOwner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_NAME, '', '', objName, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OBJTYPE, '', '', objType, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_OPTYPE, '', '', opType, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_USERID, '', '', userId, ITEM_WHOLE)
                        , ADD_FRAGMENT); 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_USERID, '', '', userId, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_MASTEROWNER, '', '', mowner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_MASTERNAME, '', '', mname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        
        BEGIN
            IF lv_ora_db_block_size = 0 THEN
                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                    "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 16');
                END IF;
                SELECT value INTO lv_ora_db_block_size
                FROM "&gg_user"."GGS_STICK"
                WHERE property = 'ora_db_block_size';
                IF trace_level >= 1 THEN 
                    "&gg_user".trace_put_line ('DDL', 'DB block size from cache ' || to_char (lv_ora_db_block_size)); 
                END IF;
            END IF;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
                    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                       "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 15');
                    END IF;
					SELECT VALUE
						INTO lv_ora_db_block_size
						FROM v$parameter
						WHERE upper(name) = 'DB_BLOCK_SIZE' AND
							VALUE IS NOT NULL; 
					INSERT INTO "&gg_user"."GGS_STICK" (property, value)
						VALUES ('ora_db_block_size', lv_ora_db_block_size);
					IF trace_level >= 1 THEN 
                        "&gg_user".trace_put_line ('DDL', 'DB block size computed ' || to_char (lv_ora_db_block_size)); 
					END IF;
				EXCEPTION
					WHEN OTHERS THEN
						NULL;
				END;
		END;
        
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_BLOCKSIZE, '', '', to_char(lv_ora_db_block_size), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        
        FOR ti IN DDLReplication.getTable LOOP 
            insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_DATAOBJECTID, '', '', to_char (ti.data_object_id), ITEM_WHOLE) ||
                            itemHeader (MD_TAB_CLUCOLS, '', '', to_char (ti.clucols), ITEM_WHOLE) 
                            , ADD_FRAGMENT); 
        END LOOP; 
        
        /* total column count */
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 14');
        END IF;
        SELECT COUNT(*)
            INTO ora_column_cnt
            FROM sys.col$ c,
                sys.tab$ t,
                sys.obj$ o
            WHERE c.obj# = o.obj# AND
                t.obj# = o.obj# AND
                o.obj# = objId AND
                bitand(t.property, 1) = 0; 
        insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_TOTAL_COL_NUM, '', '', to_char (ora_column_cnt), ITEM_WHOLE)
                        , ADD_FRAGMENT);
      
        -- first check if ALL group exists, if it does

        log_group_exists := 0; 
        all_log_group_exists := ddlora_getAllColsLogging (DDLReplication.currentObjectId); 

        IF all_log_group_exists IS NOT NULL AND all_log_group_exists > 0 THEN
            insertToMarker (DDL_HISTORY, '', '', 
                itemHeader (MD_TAB_LOG_GROUP_EXISTS, '', '', '2', ITEM_WHOLE)
                , ADD_FRAGMENT); 
        ELSE
            -- check for schema level supplemental logging
            BEGIN
                check_schema_suplog := 0;
                check_schema_tabf := 0;
                if checkSchemaTabf = -1 THEN
                  IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                     "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 13');
                  END IF;
                  SELECT count (1) 
                      INTO checkSchemaTabf 
                      FROM dba_objects o
                      WHERE o.object_name = 'LOGMNR$ALWAYS_SUPLOG_COLUMNS' AND 
                            o.object_type = 'SYNONYM' AND
                            o.status = 'VALID';
                END IF;
                check_schema_tabf := checkSchemaTabf;
                   

                IF check_schema_tabf = 1 THEN
                    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                       "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 12');
                    END IF;
                    EXECUTE IMMEDIATE 'SELECT count(1)
                                       FROM logmnr$schema_allkey_suplog 
                                       WHERE allkey_suplog = ''YES'' and 
                                             schema_name = :objOwner'
                                      INTO check_schema_suplog USING objOwner;

                    IF check_schema_suplog = 1 THEN
                        log_group_exists := 1;
                    END IF;
                END IF;
            END;

            IF log_group_exists = 0 THEN
                s_log_group_name := 'GGS_' || to_char (DDLReplication.currentObjectId);
                 IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                    "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 11');
                 END IF;
                 select count(*) into log_group_exists 
                 from sys.obj$ o, sys.cdef$ c, sys.con$ oc 
                 where o.obj# = objId and o.obj# = c.obj# and 
                 c.con# = oc.con# and oc.name = s_log_group_name and 
                        ROWNUM = 1;
            END IF;
	        
            insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_LOG_GROUP_EXISTS, '', '', to_char (log_group_exists), ITEM_WHOLE)
                        , ADD_FRAGMENT); 

        END IF;
	    
        -- at this time log_group_name is the correct one (it exists)
        IF log_group_exists > 0 THEN
              IF check_schema_suplog = 1 THEN
                schemaSuplog_cursor := dbms_sql.open_cursor;

                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                   "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 10');
                END IF;
                DBMS_SQL.PARSE(schemaSuplog_cursor, 
                               'SELECT column_name 
                                FROM table(LOGMNR$ALWAYS_SUPLOG_COLUMNS ( 
                                           :objOwner_bind , :objName_bind))',
                                DBMS_SQL.V7); 

                DBMS_SQL.BIND_VARIABLE (schemaSuplog_cursor, ':objOwner_bind', objOwner); 
                DBMS_SQL.BIND_VARIABLE (schemaSuplog_cursor, ':objName_bind', objName); 
                DBMS_SQL.DEFINE_COLUMN(schemaSuplog_cursor, 1, 
                                       schemaSuplog_colName, 30); 

                ignore := DBMS_SQL.EXECUTE(schemaSuplog_cursor); 

                log_group_id := 1;
                LOOP 
                    IF DBMS_SQL.FETCH_ROWS(schemaSuplog_cursor) > 0 THEN 
                        DBMS_SQL.COLUMN_VALUE(schemaSuplog_cursor, 1, schemaSuplog_colName);
                        insertToMarker (DDL_HISTORY, '', '', 
                                        itemHeader (MD_COL_ALT_LOG_GROUP_COL, 
                                                    to_char (log_group_id), '', 
                                                    schemaSuplog_colName, 
                                                    ITEM_WHOLE),
                                        ADD_FRAGMENT); 
                        log_group_id := log_group_id + 1;
                    ELSE 
                        -- No more rows to copy: 
                        EXIT; 
                    END IF; 
                END LOOP;

                DBMS_SQL.CLOSE_CURSOR(schemaSuplog_cursor); 
            ELSE
                log_group_id := 1;
                FOR lc IN loggroup_suplog (s_log_group_name, objOwner, objName) LOOP
                    insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_COL_ALT_LOG_GROUP_COL, to_char (log_group_id), '', lc.column_name, ITEM_WHOLE)
                                    , ADD_FRAGMENT); 
                    log_group_id := log_group_id + 1;
                END LOOP;
            END IF;
        END IF;
		
        /* based on unused columns, verify that table is valid */
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 9');
        END IF;
        SELECT COUNT(*) INTO unusedCols FROM sys.col$
        WHERE col# = 0 AND segcol# > 0
        AND obj# = DDLReplication.currentObjectId;
        
        /* check compression table or partitions */
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 8');
        END IF;
        SELECT   (SELECT COUNT(*) FROM sys.tab$ t, sys.seg$ s 
                  WHERE t.obj# = DDLReplication.currentObjectId AND
                  t.file# = s.file# AND
                  t.block# = s.block# AND
                  t.ts# = s.ts# AND
                  decode(bitand(t.property, 32), 32, null, 
                        decode(bitand(s.spare1, 2048), 2048, 
                              'ENABLED', 'DISABLED')) = 'ENABLED' AND rownum=1) 
                + 
                 (SELECT COUNT(*) FROM dba_tab_partitions 
                  WHERE table_owner = objOwner and table_name = objName
                  AND compression = 'ENABLED' AND rownum=1) 
                +
                 (select count(*) from dba_indexes
                  WHERE table_owner = objOwner and table_name = objName
                        and index_type = 'IOT - TOP'
                        and compression = 'ENABLED' AND rownum=1)
        INTO isCompressed
        FROM DUAL;
        
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 7');
        END IF;

        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Compression flag [' || to_char (isCompressed) || '] unused [' ||
                to_char (unusedCols) || ']');
        END IF;
        
        IF unusedCols > 0 OR isCompressed >0 THEN
            IF isCompressed > 0 THEN
                insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_VALID, '', '', 'INVALIDABEND', ITEM_WHOLE)
                            , ADD_FRAGMENT); 
            ELSE
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_VALID, '', '', 'INVALID', ITEM_WHOLE)
                                , ADD_FRAGMENT); 
            END IF;
        ELSE
            insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_VALID, '', '', 'VALID', ITEM_WHOLE) 
                            , ADD_FRAGMENT); 
        END IF;
        
        
        isIOT := 'NO';
        isIOTWithOverflow := 'NO';
        part_id := 1; -- IOT can add alternative ids now
            
        prop := 0;
        IF ddlBaseObjProperty <> -1 THEN 
            prop := DDLReplication.ddlBaseObjProperty;
        END IF;
            
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'IOT,OBJTAB prop= [' || to_char(prop) || ']');
        END IF;            
        IF bitand (prop, IOT) = IOT THEN
            isIOT := 'YES';
            IF bitand (prop, IOT_WITH_OVERFLOW) = IOT_WITH_OVERFLOW THEN
                isIOTWithOverflow := 'YES';
            END IF;
            
            insertToMarker (DDL_HISTORY, '', '', 
                itemHeader (MD_TAB_SUBPARTITION, '', '', 'NO', ITEM_WHOLE)
                , ADD_FRAGMENT); -- to make parsing on extract side easier
                
            IF trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'IOT alt id query, objowner= [' || objOwner || '], name = ['
                || objName || ']');
            END IF;        
            FOR iotId in DDLReplication.iotAltId (objId ,objOwner, objName) LOOP
                if part_id = 1 THEN
                     insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                            , ADD_FRAGMENT);
                END IF;
                 insertToMarker (DDL_HISTORY, '', '', 
                    itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (iotId.object_id), ITEM_WHOLE)
                    , ADD_FRAGMENT);         
                 -- populate alt table for resolution of partition DMLs
                -- we always first delete primary key data to avoid unique violations
                -- object id can be NULL in CREATE statements or for INDEXES
                IF currentObjectId IS NOT NULL AND iotId.object_id IS NOT NULL THEN
    			    BEGIN
                        INSERT INTO "&gg_user"."&ddl_hist_table_alt" (
                            altObjectId,
                            objectId,
                            optime)
                        VALUES (
                            iotId.object_id,
                            currentObjectId,
                            TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                        );
                        EXCEPTION 
                            WHEN DUP_VAL_ON_INDEX THEN 
                            "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (2)');
                            NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                            WHEN NO_DATA_FOUND THEN 
                            "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (2)');
                            NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                            WHEN deadlockDetected THEN
                            "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (2)');
                            NULL; -- do nothing, this means somebody else is doing this exact work!
                    END;
                END IF;    
                part_id := part_id + 1;
            END LOOP;    
            
            IF bitand (prop, IOT_WITH_OVERFLOW) = IOT_WITH_OVERFLOW THEN
                if part_id = 1 THEN
                     insertToMarker (DDL_HISTORY, '', '', 
                            itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                            , ADD_FRAGMENT);
                END IF;
                FOR iotId in DDLReplication.iotOverflowAltId (objOwner, objName) LOOP
                     insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (iotId.object_id), ITEM_WHOLE)
                        , ADD_FRAGMENT);     
                    -- populate alt table for resolution of partition DMLs
                    -- we always first delete primary key data to avoid unique violations
                    -- object id can be NULL in CREATE statements or for INDEXES                        
                    IF currentObjectId IS NOT NULL AND iotId.object_id IS NOT NULL THEN
                        BEGIN                            
                            INSERT INTO "&gg_user"."&ddl_hist_table_alt" (
                                altObjectId,
                                objectId,
                                optime)
                            VALUES (
                                iotId.object_id,
                                currentObjectId,
                                TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                            );
                            EXCEPTION 
                                WHEN DUP_VAL_ON_INDEX THEN 
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (3)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN NO_DATA_FOUND THEN 
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (3)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN deadlockDetected THEN
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (3)');
                                NULL; -- do nothing, this means somebody else is doing this exact work!
                        END;
                    END IF;    
                    part_id := part_id + 1;
                END LOOP;                    
            END IF;
        END IF;
            
        clusterType := 'FALSE';
        IF bitand (prop, CLUSTER_TABLE) = CLUSTER_TABLE THEN
            BEGIN
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
               "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 6');
            END IF;
                SELECT cluster_type 
                INTO clusterType
                FROM dba_clusters ac,
                        dba_tables at 
                WHERE at.owner = objOwner
                    AND at.table_name = objName
                    AND at.owner = ac.owner
                    AND at.cluster_name = ac.cluster_name;                
            EXCEPTION 
                WHEN OTHERS THEN 
                    clusterType := 'FALSE';
            END;
            
            IF clusterType <> 'INDEX' AND clusterType <> 'HASH' THEN
                clusterType := 'FALSE';
            END IF;
            insertToMarker (DDL_HISTORY, '', '', 
                    itemHeader (MD_TAB_CLUSTER, '', '', to_char (clusterType), ITEM_WHOLE)
                    , ADD_FRAGMENT);   
                    
            IF clusterType <> 'FALSE' THEN
                tabColsCounter := 1;
                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                   "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 5');
                END IF;
                FOR tabCols IN (SELECT tab_column_name 
                        FROM dba_clu_columns 
                        WHERE owner = objOwner AND 
                        table_name = objName) LOOP
                    insertToMarker (DDL_HISTORY, '', '', 
                        itemHeader (MD_TAB_CLUSTER_COLNAME, to_char(tabColsCounter), '', to_char (tabCols.tab_column_name), ITEM_WHOLE)
                        , ADD_FRAGMENT);   
                    tabColsCounter := tabColsCounter + 1;
                END LOOP;             
            END IF;                    
        END IF;
        
        insertToMarker (DDL_HISTORY, '', '', 
                itemHeader (MD_TAB_CLUSTER, '', '', to_char (clusterType), ITEM_WHOLE)
                , ADD_FRAGMENT);   
        
        -- determine IOT status (if not, it will show up here too)
        insertToMarker (DDL_HISTORY, '', '', 
            itemHeader (MD_TAB_IOT, '', '', isIOT, ITEM_WHOLE)
            , ADD_FRAGMENT); -- to make parsing on extract side easier
        
        insertToMarker (DDL_HISTORY, '', '', 
            itemHeader (MD_TAB_IOT_OVERFLOW, '', '', isIOTWithOverflow, ITEM_WHOLE)
            , ADD_FRAGMENT); -- to make parsing on extract side easier
        
        
        IF isIOT <> 'YES' THEN 
            
            is_subpart := 0;
            is_part := 0;
            /* number of alternative (if any) objects for subpartitions */
            /* TODO: This is expensive way to find if there are partitions
             * or sub partitions 
             */
            alt_obj_type := 'TABLE SUBPARTITION';
            IF objId <> -1 THEN
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
               "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 4');
            END IF;
               select count(*) into num_objects 
               from sys.tab$ t, sys.tabsubpart$ tsp, sys.tabpart$ tp
              where bitand(t.property, 32)<> 0 and 
                  t.obj# = objId and t.obj# = tp.bo# and tp.obj# = tsp.pobj#
                  and rownum = 1;
            ELSE
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
               "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 3');
            END IF;
            SELECT COUNT(*)
            INTO num_objects
            FROM dba_objects
            WHERE 
                object_name = objName AND
                owner = objOwner AND
                object_type = alt_obj_type;
            
            END IF;
            IF num_objects = 0 THEN
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_SUBPARTITION, '', '', 'NO', ITEM_WHOLE)
                                , ADD_FRAGMENT); 
                /* number of alternative (if any) objects for partitions */
                alt_obj_type := 'TABLE PARTITION';
                IF objId <> -1 THEN
                  IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                     "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 2');
                  END IF;
                  select bitand(property,32) into num_objects
                  from sys.tab$ where obj# = objId;
                ELSE
                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                   "&gg_user".trace_put_line ('DDLTRACE1', 'getTableInfo() query 1');
                END IF;
                SELECT COUNT(*)
                INTO num_objects
                FROM dba_objects
                WHERE 
                    object_name = objName AND
                    owner = objOwner AND
                    object_type = alt_obj_type;
                  END IF;
                IF num_objects = 0 THEN
                    insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_TAB_PARTITION, '', '', 'NO', ITEM_WHOLE)
                                    , ADD_FRAGMENT); 
                ELSE
                    insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                                    , ADD_FRAGMENT); 
                    is_part := 1;
                END IF;
            ELSE
                insertToMarker (DDL_HISTORY, '', '', 
                                itemHeader (MD_TAB_SUBPARTITION, '', '', 'YES', ITEM_WHOLE)
                                , ADD_FRAGMENT); 
                is_subpart := 1;
            END IF; 
            
            IF currentObjectId IS NOT NULL THEN
                BEGIN
                -- object id can be NULL in CREATE statements or for INDEXES
                -- populate alt table for resolution of partition DMLs
                INSERT INTO "&gg_user"."&ddl_hist_table_alt" (
                    altObjectId,
                    objectId,
                    optime)
                VALUES (
                    currentObjectId,
                    currentObjectId,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                );
                EXCEPTION 
                    WHEN DUP_VAL_ON_INDEX THEN 
                        "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (1)');
                        NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                    WHEN NO_DATA_FOUND THEN 
                        "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (1)');
                        NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                    WHEN deadlockDetected THEN
                        "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (1)');
                        NULL; -- do nothing, this means somebody else is doing this exact work!
                END;
            END IF;
            IF num_objects > 0 THEN
                part_id := 1;
                FOR ai IN DDLReplication.alt_objects (objName, objOwner, alt_obj_type) LOOP 
                    insertToMarker (DDL_HISTORY, '', '', 
                                    itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (ai.object_id), ITEM_WHOLE)
                                    , ADD_FRAGMENT); 
                    -- populate alt table for resolution of partition DMLs
                    -- object id can be NULL in CREATE statements or for INDEXES
                    IF ai.object_id IS NOT NULL AND currentObjectId IS NOT NULL THEN
                        BEGIN
                            INSERT INTO "&gg_user"."&ddl_hist_table_alt" (
                                altObjectId,
                                objectId,
                                optime)
                            VALUES (
                                ai.object_id,
                                currentObjectId,
                                TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                            );
                            EXCEPTION 
                                WHEN DUP_VAL_ON_INDEX THEN 
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (4)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN NO_DATA_FOUND THEN 
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (4)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN deadlockDetected THEN
                                "&gg_user".trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (4)');
                                NULL; -- do nothing, this means somebody else is doing this exact work!
                        END;
                    END IF;
                    part_id := part_id + 1; 
                END LOOP; 
            END IF;
        END IF;
        
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'getTableInfo: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END getTableInfo;
    
    
    
    
    /*
    PROCEDURE INSERTTOMARKER
    
    Stores data previously prepared by itemheader() function to either marker or DDL history table.
    This function manages sizing issues (larger than 4K chunks).
    Depending on MARKEROPTYPE param, it can take everything in one (SOLE_FRAGMENT), or in series of
    fragments (BEGIN/ADD/END_FRAGMENT). ADD_FRAGMENT_AND_FLUSH is used for chunks greater than 4K (
    it causes flush to table, i.e. INSERT); otherwise function gathers as much data as possible before
    flushing 4K chunks; this is to save space and increase performance.
    
    param[in] TARGET                         NUMBER(38)              which table to write to? DDL history (DDL_HISTORY), or marker (GENERIC_MARKER)?
    param[in] INTYPE                         VARCHAR2                empty for DDL history, 'DDL' for marker type
    param[in] INSUBTYPE                      VARCHAR2                empty for DDL history, 'DDLINFO' for marker type
    param[in] INSTRING                       VARCHAR2                actual data prepared by itemheader()
    param[in] MARKEROPTYPE                   NUMBER(38)              BEGIN/ADD/END_FRAGMENT (pieces of string), SOLE_FRAGMENT (entire string in one call) mode of usage
    
    remarks Note that this same function is used for both MARKER and DDL history table. In fact,
    extract uses the same internal process for both.
    */
    
    PROCEDURE insertToMarker (
                              target IN INTEGER,
                              inType IN VARCHAR2,
                              inSubType IN VARCHAR2,
                              inString IN VARCHAR2,
                              markerOpType IN INTEGER
                              ) IS
    i INTEGER;
    fragment_raw_length INTEGER;
    string_chunk    VARCHAR2(&frag_size);
    fragment "&gg_user"."&marker_table_name".marker_text%TYPE; 
    runtimeMarkerOpType INTEGER;
    current_fragment_leftover RAW(&frag_size) := '';
    current_fragment_leftover_pos INTEGER := 0;
    end_frag INTEGER := 0;
    BEGIN 
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
           "&gg_user".trace_put_line ('DDLTRACE1', 'Entering insertToMarker()');
        END IF;
        
        runtimeMarkerOpType := markerOpType; 
        
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: inString = [' );
            "&gg_user".trace_put_line ('DDLTRACE1', inString);
            "&gg_user".trace_put_line ('DDLTRACE1','], type = [' 
                                        || to_char(runtimeMarkerOpType) || ']' || ' target = [' || to_char(target) || ']' );
        END IF;
        
        IF runtimeMarkerOpType = SOLE_FRAGMENT OR runtimeMarkerOpType = BEGIN_FRAGMENT THEN
            IF target = GENERIC_MARKER THEN
                SELECT "&gg_user"."&marker_sequence".NEXTVAL INTO currentMarkerSeq FROM dual; 
            END IF;
            -- reset fragment.
            current_fragment := 0; 
            current_fragment_raw := '';
        END IF;
        
        IF trace_level >= 2 THEN
            "&gg_user".trace_put_line ('DDLTRACE2', 'insertToMarker: marker optype = [' || to_char(runtimeMarkerOpType) 
                                        || '], current_fragment = ['
                                        || to_char(current_fragment) || ']');
        END IF;

       -- gathers as much data as possible before flushing 4K chunks.
        current_fragment_raw := utl_raw.concat(current_fragment_raw, utl_raw.cast_to_raw(inString));
        IF utl_raw.length(current_fragment_raw) > &frag_size THEN
            runtimeMarkerOpType := ADD_FRAGMENT_AND_FLUSH;
        END IF;

        IF trace_level >= 2 THEN
            "&gg_user".trace_put_line ('DDLTRACE2', 'insertToMarker: marker optype = [' || to_char(runtimeMarkerOpType)
                                        || '], current_fragment = ['
                                        || to_char(current_fragment) || ']');
        END IF;

        IF (runtimeMarkerOpType = BEGIN_FRAGMENT OR runtimeMarkerOpType = ADD_FRAGMENT) THEN 
            RETURN; 
        END IF;
       
         
        IF trace_level >= 1 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: length current_fragment_raw total = [' || to_char(utl_raw.length(current_fragment_raw)) || ']' );
        END IF;


        -- check if we have fragment from previous call.
        IF utl_raw.length(current_fragment_raw) > 0 THEN
           current_fragment_leftover_pos := 0;

           WHILE (current_fragment_leftover_pos < utl_raw.length(current_fragment_raw) AND end_frag = 0) LOOP
               IF (utl_raw.length(current_fragment_raw) - current_fragment_leftover_pos < &frag_size) THEN
                  string_chunk := utl_raw.cast_to_varchar2(utl_raw.substr(current_fragment_raw, current_fragment_leftover_pos + 1));
                  end_frag := 1;
               ELSE
                   string_chunk := utl_raw.cast_to_varchar2(utl_raw.substr(current_fragment_raw, current_fragment_leftover_pos + 1, &frag_size));
               END IF;
               IF trace_level >= 2 THEN
                    "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: string_chunk = [' ||
                                                string_chunk || '] current_fragment_leftover_pos = [' ||  to_char(current_fragment_leftover_pos)
                                                || ']');
               END IF;

                -- check if multi byte DDL.
                IF length(string_chunk) <> lengthb(string_chunk) THEN
                    IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'MB DDL found: ' ||
                                                    to_char(length(string_chunk)) || ' characters, ' ||
                                                    to_char(lengthb(string_chunk)) || ' bytes.');
                    END IF;
        
                    -- extract only valid characters, so that we don't truncate by middle of character.
                    fragment := substr(string_chunk, 1, length(string_chunk));
        
                    IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'MB DDL fragment: ' || 
                                                    to_char(length(fragment)) || ' characters, ' ||
                                                    fragment);
                    END IF;
        
                    fragment_raw_length := utl_raw.length(utl_raw.cast_to_raw(fragment));
                    current_fragment_leftover_pos := current_fragment_leftover_pos + fragment_raw_length;
                    IF lengthb(string_chunk) > fragment_raw_length THEN
                        current_fragment_leftover := utl_raw.substr(utl_raw.cast_to_raw(string_chunk), 
                                                               fragment_raw_length + 1);
                         IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'left over happen [ bytes length:' 
                                                    ||  to_char(lengthb(string_chunk)) 
                                                    || 'character bytes:'
                                                    ||to_char(fragment_raw_length)
                                                    ||']');
                         END IF;

                    ELSE
                        current_fragment_leftover := '';
                    END IF;
        
                    IF trace_level >= 2 THEN
                        "&gg_user".trace_put_line ('DDLTRACE2', 'fragment_raw_length: ' || 
                                                    to_char(fragment_raw_length) || ' bytes.');
                    END IF;
                ELSE
                    fragment := string_chunk;
                    current_fragment_leftover_pos := current_fragment_leftover_pos +  length(string_chunk);
                    current_fragment_leftover := '';
                END IF;
              
        
                IF fragment IS NOT NULL THEN
                    -- update fragment number.
                    current_fragment := current_fragment + 1;
        
                    -- insert into marker table
                    CASE target
                        WHEN GENERIC_MARKER THEN                            
                            BEGIN
                                IF trace_level >= 1 THEN
                                    "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: inserting into marker');
                                END IF;
                                INSERT INTO "&gg_user"."&marker_table_name" (
                                    seqNo,
                                    fragmentNo,
                                    optime,
                                    TYPE,
                                    SUBTYPE,
                                    marker_text
                                    )
                                    VALUES (
                                    currentMarkerSeq,
                                    current_fragment,
                                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                                    inType,
                                    inSubType, 
                                    fragment
                                ); 
                            END; 
                        WHEN DDL_HISTORY THEN
                            BEGIN 
                                IF trace_level >= 1 THEN
                                    "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: inserting into history, objId ['
                                                                || to_char (DDLReplication.currentObjectId) || ']');
                                END IF; 
                                INSERT INTO "&gg_user"."&ddl_hist_table" (
                                    seqNo,
                                    objectId,
                                    dataObjectId,
                                    ddlType,
                                    objectName,
                                    objectOwner,
                                    objectType,
                                    fragmentNo,
                                    optime, 
                                    startSCN, 
                                    metadata_text,
                                    auditcol
                                )
                                VALUES (
                                    currentDDLSeq,
                                    DDLReplication.currentObjectId,
                                    DDLReplication.currentDataObjectId,
                                    DDLReplication.currentDDLType,
                                    DDLReplication.currentObjectName,
                                    DDLReplication.currentObjectOwner,
                                    DDLReplication.currentObjectType,
                                    current_fragment,
                                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'), 
                                    "&gg_user".DDLReplication.SCNB + "&gg_user".DDLReplication.SCNW * power (2, 32), 
                                    fragment,
                                    DDLReplication.currentRowid -- currently for sequences only
                                ); 
                            END; 
                    END CASE;
                            
                    IF trace_level >= 1 THEN
                        "&gg_user".trace_put_line ('DDLTRACE1', 'insertToMarker: done inserting');
                    END IF;
                END IF;
            END LOOP;
            current_fragment_raw := current_fragment_leftover;
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN 
            errorMessage := 'insertToMarker: ' || ':' || SQLERRM; 
            "&gg_user".trace_put_line ('DDL', errorMessage); 
            RAISE;
    END insertToMarker;
    
END DDLReplication;
/
show errors

/*
DDL Auxillary package
*/
CREATE OR REPLACE PACKAGE "&gg_user".DDLAux AS

  TB_IOT CONSTANT NUMBER := 960;
  TB_CLUSTER CONSTANT NUMBER := 1024;
  TB_NESTED CONSTANT NUMBER := 8192;
  TB_TEMP CONSTANT NUMBER := 12582912;
  TB_EXTERNAL CONSTANT NUMBER := 2147483648; 

  TYPE_INDEX CONSTANT NUMBER := 1;
  TYPE_TABLE CONSTANT NUMBER := 2;
  TYPE_VIEW CONSTANT NUMBER := 4;
  TYPE_SYNONYM CONSTANT NUMBER := 5;
  TYPE_SEQUENCE CONSTANT NUMBER := 6;
  TYPE_PROCEDURE CONSTANT NUMBER := 7;
  TYPE_FUNCTION CONSTANT NUMBER := 8;
  TYPE_PACKAGE CONSTANT NUMBER := 9;
  TYPE_TRIGGER CONSTANT NUMBER := 12;

  CMD_CREATE CONSTANT varchar2(10) := 'CREATE';
  CMD_DROP CONSTANT varchar2(10) := 'DROP';
  CMD_TRUNCATE CONSTANT varchar2(10) := 'TRUNCATE';
  CMD_ALTER CONSTANT varchar2(10) := 'ALTER';


  /* Add a rule for inclusion or exclusion so that DDL trigger will handle
   * the matching object appropriately. Rules are evaluated in the sorted
   * order (asc) of sno. If the sno is not specified then the rule will be
   * added in the tail end (max(sno) + 1). If the user 
   * want to position the rule inbetween two already existing rule 
   * could use decimals in between. 
   * The users can place rules as 11.1, 11.2 etc.
   * The rules added will be placed in the table &ddl_rules
   * Rule addition examples
   * To exclude all objects having name like  GGS%
   *    addRule(obj_name=> 'GGS%');
   * To exclude all temporary table
   *    addRule(base_obj_property => TB_TEMP, obj_type => TYPE_TABLE);
   * To exclude all External table 
   *    addRule(base_obj_property => TB_EXTERNAL, obj_type => TYPE_TABLE);
   * To exclude all INDEXES on External table 
   *    addRule(base_obj_property => TB_EXTERNAL, obj_type => TYPE_INDEX);
   * To exclude all truncate table ddl
   *    addRule(obj_type=>TYPE_TABLE, command => CMD_TRUNCATE);
   *    
   */
  FUNCTION addRule(obj_name IN VARCHAR2 DEFAULT NULL, 
                   base_obj_name IN VARCHAR2 DEFAULT NULL,
                   owner_name IN VARCHAR2 DEFAULT NULL, 
                   base_owner_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_property IN NUMBER DEFAULT NULL, 
                   obj_type IN NUMBER  DEFAULT NULL,
                   command IN VARCHAR2 DEFAULT NULL,
                   inclusion IN boolean DEFAULT NULL , 
                   sno IN NUMBER DEFAULT NULL)
  RETURN NUMBER;

  /* Drop rule by the rule serial number */
  FUNCTION dropRule(dsno IN NUMBER) RETURN BOOLEAN;

  PROCEDURE listRules;

  /* This function returns TRUE if the current ddl object should be skipped
   * FALSE if it should not be skipped. 
   * This function consults the &ddl_rules table to check for inclusion
   * or exclusion. All excluded objects are logged into the table 
   * &ddl_rules_log
   */
  FUNCTION SKIP_OBJECT(obj_id IN NUMBER, base_obj_id IN OUT NUMBER,
                       OBJ_NAME varchar2, obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2, 
                       command varchar2) 
  RETURN BOOLEAN ;

  /* Records an exclusion in &ddl_rules_log table */
  PROCEDURE recordExclusion(sno IN NUMBER, OBJ_NAME varchar2, 
                       obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2, base_obj_property number,
                       command varchar2);

  CURSOR ignoreObj IS
         SELECT sno, obj_name, owner_name, base_obj_name, base_owner_name,
                base_obj_property, obj_type, command,  inclusion
         from "&gg_user"."&ddl_rules" order by sno;
END DDLAux;
/

show errors package "&gg_user".DDLAux;

/*
 DDL Auxillary package Body 
*/
CREATE OR REPLACE PACKAGE BODY "&gg_user".DDLAux AS

  FUNCTION addRule(obj_name IN VARCHAR2 DEFAULT NULL, 
                   base_obj_name IN VARCHAR2 DEFAULT NULL,
                   owner_name IN VARCHAR2 DEFAULT NULL, 
                   base_owner_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_property IN NUMBER DEFAULT NULL, 
                   obj_type IN NUMBER  DEFAULT NULL,
                   command IN VARCHAR2  DEFAULT NULL,
                   inclusion IN boolean DEFAULT NULL , 
                   sno IN NUMBER DEFAULT NULL)
  RETURN NUMBER IS
   new_sno NUMBER;
   cnt NUMBER;
   to_include number;
  BEGIN
    if inclusion then
    to_include := 1;
    else
    to_include := 0;
    end if;
    BEGIN
      /* If SNO is not specified then find the next SNO automatically */
      IF SNO IS NULL THEN
        BEGIN
          SELECT count(*) ,MAX(SNO) into cnt,NEW_SNO 
          FROM "&gg_user"."&ddl_rules";

          /* MAX(SNO) + 1 */
          IF cnt = 0 THEN
           NEW_SNO := 1;
          ELSE
           NEW_SNO := NEW_SNO + 1;
          END IF;
        EXCEPTION WHEN OTHERS THEN
          new_sno := 1;
        END;
      ELSE
        NEW_SNO := SNO;
      END IF;

      INSERT INTO "&gg_user"."&ddl_rules" VALUES
      (NEW_SNO, OBJ_NAME, OWNER_NAME, BASE_OBJ_NAME, BASE_OWNER_NAME,
       base_obj_PROPERTY, OBJ_TYPE, command, to_include);

      COMMIT; 
      RETURN NEW_SNO;
    EXCEPTION WHEN OTHERS THEN
     --dbms_output.put_line (SQLERRM);
     IF "&gg_user".DDLReplication.trace_level >= 1 THEN
       "&gg_user".trace_put_line ('DDLTRACE1','INSERT INTO &ddl_rules ERROR:'||
                                   SQLERRM);
     END IF;
    END;
    RETURN -1;
  END;

  FUNCTION dropRule(dsno IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    BEGIN
      DELETE FROM "&gg_user"."&ddl_rules" WHERE SNO = dsno;
      COMMIT;
      RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
     IF "&gg_user".DDLReplication.trace_level >= 1 THEN
       "&gg_user".trace_put_line ('DDLTRACE1','DELETE FROM &ddl_rules ERROR:'||
                                   SQLERRM);
     END IF;
    END; 
    RETURN FALSE;
  END;

  PROCEDURE listRules IS
  BEGIN
      NULL;
  END;

  PROCEDURE recordExclusion(sno IN NUMBER, OBJ_NAME varchar2, 
                       obj_owner varchar2,
                       obj_type NUMBEr, base_obj_name varchar2,
                       base_owner_name varchar2, base_obj_property number,
                       command varchar2) IS
  BEGIN
    BEGIN
      INSERT INTO "&gg_user"."&ddl_rules_log" VALUES
      (sno, OBJ_NAME, obj_owner, BASE_OBJ_NAME, BASE_OWNER_NAME,
       base_obj_PROPERTY, OBJ_TYPE, command);

    EXCEPTION WHEN OTHERS THEN
     --dbms_output.put_line('recordEx:'||SQLERRM);
     IF "&gg_user".DDLReplication.trace_level >= 1 THEN
       "&gg_user".trace_put_line ('DDLTRACE1','INSERT INTO &ddl_rules_log ERROR:'||
                                   SQLERRM);
     END IF;
   END;
  END;

  FUNCTION SKIP_OBJECT(obj_id IN NUMBER, base_obj_id IN OUT NUMBER,
                       obj_name varchar2, obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2, command varchar2) 
  RETURN BOOLEAN IS
    tab_prop number;
    obj_name_match boolean;
    owner_name_match boolean;
    type_match boolean;
    property_match boolean;  
    base_obj_match boolean;
    base_owner_match boolean;
    command_match boolean;
    exclude boolean;
  BEGIN
    --dbms_output.put_line('SKIPRULE');
    FOR n IN ignoreObj LOOP
      obj_name_match := false;
      owner_name_match := false;
      type_match := false;
      base_obj_match := false;
      base_owner_match := false;
      property_match := false;
      command_match := false;

      --dbms_output.put_line('SKIP_RULE:no:'||n.sno);

      -- TODO : Need to upper ? Using exactly allows user to choose
      -- tables with mixed case names as well. 
      obj_name_match := (obj_name) like (n.obj_name) or 
                        n.obj_name is null;
      owner_name_match := (obj_owner) like (n.owner_name) or
                           n.owner_name is null;
      type_match := (obj_type) like (n.obj_type) or
                    n.obj_type is null;

      base_owner_match := (base_owner_name) like (n.base_owner_name)
                          or n.base_owner_name is NULL;

      base_obj_match := (base_obj_name) like (n.base_obj_name) or
                        n.base_obj_name is null;

      command_match := (command) like (n.command) or n.command is null;

      /* the default is exclusion rule */
      exclude := (n.inclusion is null or n.inclusion = 0);

      IF (obj_name_match and owner_name_match and type_match and
          base_owner_match and base_obj_match and command_match) --5
      THEN
         /* If property was specified then check if it matches */
         IF n.base_obj_property is not null -- 3
         THEN
           BEGIN
             /* For everything other than "create table" we should be
              * able to get the table property
              */
             if command <> CMD_CREATE  or n.obj_type <> TYPE_TABLE -- 2
             THEN
               if base_obj_id is null or base_obj_id = -1 then
                 select o.obj# into base_obj_id from sys.obj$ o, sys.user$ u
                 where o.name = base_obj_name and u.name = base_owner_name
                       and o.owner# = u.user# and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
               end if;

               --dbms_output.put_line('SKIP_RULE:bo_id:'||base_obj_id);
               select t.property into tab_prop from sys.tab$ t
               where t.obj# = base_obj_id;
             ELSE
               /* if its create table then check if rdbms code filled the
                * property 
                */
               if "&gg_user".DDLReplication.ddlBaseObjProperty <> -1
               THEN
                 tab_prop := "&gg_user".DDLReplication.ddlBaseObjProperty;   
               ELSE
                 tab_prop := 0;
               END IF;  
             END IF; --2
               --dbms_output.put_line('SKIP_RULE:matching:'||base_obj_id);
           property_match := bitand(tab_prop, n.base_obj_property) <> 0;
               --dbms_output.put_line('SKIP_RULE:matching:'||tab_prop);
           EXCEPTION WHEN NO_DATA_FOUND THEN
            --dbms_output.put_line('SKIP_RULE:'||SQLERRM);
            property_match := false;
           END;
           IF property_match THEN
             IF exclude THEN
                recordExclusion(n.sno, OBJ_NAME, obj_owner,
                       obj_type, base_obj_name ,
                       base_owner_name , tab_prop ,
                       command);
             END IF;
             return  exclude;
           END IF;
        ELSE
             IF exclude THEN
                recordExclusion(n.sno, OBJ_NAME, obj_owner,
                       obj_type, base_obj_name ,
                       base_owner_name , tab_prop ,
                       command);
             END IF;
          return exclude;
        END IF; --3
      END IF; -- 5
   END LOOP; 
   RETURN FALSE; -- if no rule matched , default is to include
  END;

 
END DDLAux;
/

show errors package body "&gg_user".DDLAux;

CREATE OR REPLACE PACKAGE SYS.DDLCtxInfo AS
    PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER, 
                         baseObjProperty IN NUMBER) ;
END DDLCtxInfo ;
/

CREATE OR REPLACE PACKAGE BODY SYS.DDLCtxInfo AS
   PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER,
                         baseObjProperty IN NUMBER) IS
   BEGIN
       "&gg_user".DDLReplication.setCtxInfo(objNum , baseObjNum ,
                         objUserId , baseObjUserId ,
                         baseObjProperty ) ;
   END;
  
END DDLCtxInfo;
/

/*

BEFORE DDL trigger fires before DDL has taken place
and before the entire implied transaction comitted
old table metadata is available in this trigger

Note however that new metadata information is not available
(this includes for example object id for CREATE TABLE or
table name for CREATE INDEX).

DDL triggers fires on *all* DDL except for DDL on itself.

*/

CREATE OR REPLACE TRIGGER
sys .&ddl_trigger_name
BEFORE ddl ON DATABASE

DECLARE
stmt VARCHAR2(&max_ddl_size);
currSeq NUMBER;
currUserId NUMBER; 
errorMessage VARCHAR2(&message_size); 
objstatus VARCHAR2(&max_status_size);
errorVal VARCHAR2(10);

-- purpose of these is because ora_dict* is oracle implicit function and is not l-value (can't be modified)
-- we want to modify these because object being changed may not be the one we're interested in (for example
-- changing unique index affects table, and DDL on materialized view really affects the 'table' of it...)
-- so we have our own name,owner, type ('real' ones)
real_ora_dict_obj_name VARCHAR2(&java_name_size);
real_ora_dict_obj_owner VARCHAR2(&name_size);
real_ora_dict_obj_type VARCHAR2(&type_size);

otype VARCHAR2(&name_size);
disallowDDL NUMBER;
indexUnique VARCHAR2(&type_size);
moduleNameInfo VARCHAR2(&file_name_size); 
oldModuleNameInfo VARCHAR2(&file_name_size); 
oldActionInfo VARCHAR2(&file_name_size); 


binObject NUMBER;



dbRole VARCHAR2(&type_size);
dbOpenMode VARCHAR2(&type_size);

-- sequence information
seqCache NUMBER;
seqIncrementBy NUMBER;
pieceStmt VARCHAR2(&max_ddl_size);
outMessage VARCHAR2(&message_size); 
toIgnore VARCHAR2(&type_size);
journalId NUMBER;
journalIndexOwner VARCHAR2(&name_size);
journalType VARCHAR2(&type_size);
objectTemporary varchar2(&type_size);
objectGenerated varchar2(&type_size);
objectSecondary varchar2(&type_size);
objectType varchar2(&type_size);
userCancelSimulate EXCEPTION;
userCancelNestedSimulate EXCEPTION;
PRAGMA EXCEPTION_INIT (userCancelSimulate, -1013);
PRAGMA EXCEPTION_INIT (userCancelNestedSimulate, -1017);
isTypeTable varchar2(&type_size);
ntype NUMBER;
BEGIN
    
    -- IMPORTANT: this check must happen BEFORE ANY PROCESSING
    -- perform check for role of this database  
    -- if database is not PRIMARY/LOGICAL STANDBY,  and if it's not READ WRITE
    -- then this trigger cannot (and should not) operate
    -- In case of not wanting trigger on LOGICAL STANDBY (or with READ WRITE),
    -- ddl_disable script can be used on standby to disable the trigger
    BEGIN  
              IF "&gg_user".DDLReplication.dbQueried IS NULL THEN
		SELECT database_role, open_mode 
		INTO dbRole, dbOpenMode
		FROM v$database;
                "&gg_user".DDLReplication.dbQueried := TRUE;
              END IF;
		
		IF NOT (
			(dbRole = 'PRIMARY' OR dbRole = 'LOGICAL STANDBY')
			AND dbOpenMode = 'READ WRITE'
			) 
			THEN
			-- do not write any trace even though it should work as this is standby
                        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

			RETURN; -- do not use trigger if not read/write and primary/logical_standby			
		END IF;		
	EXCEPTION    		
        WHEN OTHERS THEN	-- this should never happen
        "&gg_user".trace_put_line ('DDL', 'Error in obtaining dbrole, open mode, error [' 
                                || SQLERRM || ']');
		raise_application_error (&trigger_error_code,
                                         "&gg_user".DDLReplication.triggerErrorMessage || ':' || SQLERRM);
        
	END;
    -- END OF IMPORTANT CHECK


    -- the following MUST happen after checking for role of the database
    -- but BEFORE anything else. Here we check if DDL is recyclebin. Recyclebin
    -- DDL can happen as 'interrupting' original DDL and shares the same
    -- memory, thus entirely messing up RDBMS trigger processing and potentially
    -- causing db to hang.
    -- set tracing from setup table
                                                
    "&gg_user".DDLReplication.setTracing ();
                                                        
    
    -- retrieve first 4K of DDL statement. 
    -- we only use the DDL for history table that doesn't require whole DDL text.
    IF "&gg_user".DDLReplication.getDDLText (stmt) = 0 THEN
        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);
        RETURN;
    END IF;
                                                                                
    IF "&gg_user".DDLReplication.isRecycle(stmt) = 1 THEN
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDL', 'DDL ignored, it is recycle bin DDL, text [' || stmt || ']');
        END IF;
        IF "&gg_user".DDLReplication.sql_trace = 1 THEN
            dbms_session.set_sql_trace(false);
        END IF;
        -- just ignore recyclebin objects
        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

        RETURN;
    END IF;
    
    disallowDDL := 0; -- DDL is normally allowed 
    toIgnore := 'NO'; -- do not ignore DDL by default
    
    -- used to delete marker entry in cancel error
    "&gg_user".DDLReplication.currentMarkerSeq := NULL;
    
    -- support for exceptions testing
    IF '&_ddl_cause_error' = 'TRUE' THEN
        SELECT VALUE 
        INTO errorVal
        FROM "&gg_user"."&setup_table"
        WHERE property = ',?!%*$#';
    END IF;
    
    -- get DDL history sequence, initialize object Id
    SELECT "&gg_user"."&ddl_sequence".NEXTVAL INTO "&gg_user".DDLReplication.currentDDLSeq FROM dual; 
    "&gg_user".DDLReplication.currentObjectId := NULL;
    
    IF "&gg_user".DDLReplication.trace_level >= 0 THEN
        "&gg_user".trace_put_line ('DDL', '************************* Start of log for DDL sequence [' 
                                || to_char ("&gg_user".DDLReplication.currentDDLSeq) || '], v[ ' || 
                                "&gg_user".DDLReplication.tversion || '] trace level [' || 
                                "&gg_user".DDLReplication.trace_level || '], owner schema of DDL package [&gg_user], objtype [' 
                                || ora_dict_obj_type || '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || ']');
    END IF;

	IF "&gg_user".filterDDL (		
        stmt,
		ora_dict_obj_owner,
		ora_dict_obj_name,
		ora_dict_obj_type,
		ora_sysevent) = 'EXCLUDE' THEN
		IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDL', 'DDL ignored because filterDDL returned EXCLUDE');
        END IF;
                "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

		RETURN;
	END IF;

    -- check if we want this statement at all before going any further
    -- this way we avoid some large DDL that we wouldn't want anyway
    -- per http://www.idevelopment.info/data/Oracle/DBA_tips/Database_Administration/DBA_26.shtml
    IF ora_dict_obj_type <> 'TABLESPACE' 
    AND
        (ora_dict_obj_owner = 'SYS' OR
        ora_dict_obj_owner = 'SYSTEM' OR
        ora_dict_obj_owner = 'DBSNMP' OR
        ora_dict_obj_owner = 'OUTLN' OR
        ora_dict_obj_owner = 'MDSYS' OR
        ora_dict_obj_owner = 'SYSMAN' OR
        ora_dict_obj_owner = 'DMSYS' OR
        (ora_dict_obj_owner = 'PUBLIC' AND ora_dict_obj_type <> 'SYNONYM') OR
        ora_dict_obj_owner = 'ORDSYS' OR
        ora_dict_obj_owner = 'ORDPLUGINS' OR
        ora_dict_obj_owner = 'CTXSYS' OR
        ora_dict_obj_owner = 'DSSYS' OR
        ora_dict_obj_owner = 'PERFSTAT' OR
        ora_dict_obj_owner = 'WKPROXY' OR
        ora_dict_obj_owner = 'WKSYS' OR
        ora_dict_obj_owner = 'WMSYS' OR
        ora_dict_obj_owner = 'EXFSYS' OR
        ora_dict_obj_owner = 'XDB' OR
        ora_dict_obj_owner = 'ANONYMOUS' OR
        ora_dict_obj_owner = 'ODM' OR
        ora_dict_obj_owner = 'ODM_MTR' OR
        ora_dict_obj_owner = 'OLAPSYS' OR
        ora_dict_obj_owner = 'TRACESVR' OR
        ora_dict_obj_owner = 'REPADMIN' OR
        ora_dict_obj_owner = 'AURORA$ORB$UNAUTHENTICATED' OR
        ora_dict_obj_owner = 'AURORA$JIS$UTILITY$' OR
        ora_dict_obj_owner = 'OSE$HTTP$ADMIN')
        THEN
            IF "&gg_user".DDLReplication.trace_level >= 0 THEN
                "&gg_user".trace_put_line ('DDL', 'Object [' || ora_dict_obj_owner || '.' ||
                                    ora_dict_obj_name || '] is ignored because object name is Oracle-reserved system name');
            END IF;
            toIgnore := 'YES';        
    END IF;
    
    IF upper(substr (ora_dict_obj_name, 1, 5)) = 'MLOG$' OR upper(substr (ora_dict_obj_name, 1, 5)) = 'RUPD$'
    THEN
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDL', 'Ignoring MLOG$ Object [' || ora_dict_obj_owner || '.' ||
                            ora_dict_obj_name || ' as it is temporary');
        END IF;
        toIgnore := 'YES';         
    END IF;

    IF upper(substr (ora_dict_obj_name, 1, 6)) = 'OGGQT$' OR upper(substr (ora_dict_obj_name, 1, 3)) = 'AQ$'
    THEN
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDL', 'Ignoring Queue related Object [' || ora_dict_obj_owner || '.' ||
                            ora_dict_obj_name || ' as it is for internal use');
        END IF;
        toIgnore := 'YES';
    END IF;
    
    IF (upper(ora_dict_obj_name) = upper ('&marker_table_name') OR
        upper(ora_dict_obj_name) = upper ('&marker_sequence') OR
        upper(ora_dict_obj_name) = upper ('&ddl_trigger_name') OR
        upper(ora_dict_obj_name) = upper ('&ddl_sequence') OR
        upper(ora_dict_obj_name) = upper ('&ddl_hist_table') OR 
        upper(ora_dict_obj_name) = upper ('&ddl_hist_table_alt') OR
        upper(ora_dict_obj_name) = upper ('&setup_table')) AND
        
        upper(ora_dict_obj_owner) = upper ('&gg_user') AND
        
        (upper(ora_sysevent) = upper ('DROP') OR
         upper(ora_sysevent) = upper ('RENAME'))
        
        THEN 
        disallowDDL := 1;
        raise_application_error (&trigger_error_code,
                                 'Cannot DROP object used in Oracle GoldenGate replication while trigger is enabled. ' ||
                                 'Consult Oracle GoldenGate documentation and/or call Oracle GoldenGate Technical Support if you wish to do so.');
    END IF;
    

    -- check if this is domain index DDL (related to it)
    IF ( ora_dict_obj_type = 'TABLE' OR ora_dict_obj_type = 'INDEX') AND
        (
        (substr(ora_dict_obj_name, 1, 3) = 'DR$' AND 
            (
                substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$I' OR
                substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$K' OR
                substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$N' OR
                substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$R' OR
                substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$X'
            )
        )
        OR
        (
           -- ignore objects that start with SYS_C, much like we ignore DR$, BIN$ etc.
           substr (ora_dict_obj_name, 1, 5) = 'SYS_C'
        )
        )
    THEN
        toIgnore := 'YES';
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Object is secondary for INDEX DOMAIN creation, ignored, objtype [' || ora_dict_obj_type || 
                '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');                    
        END IF;        
    END IF;


    -- check for and ignore Spatial temporary tables used during Spatial index creation.
    -- Table will look something like M2_12AB$$
    IF  length (ora_dict_obj_name) > 5 AND
        substr (ora_dict_obj_name, length (ora_dict_obj_name) - 1, 2) = '$$' AND
        instr  (ora_dict_obj_name, '_') > 0 AND
        substr (ora_dict_obj_name, 1, 1) = 'M'
    THEN
        toIgnore := 'YES';
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDLTRACE1',
                'Ignoring temporary Spatial table used during Spatial index creation [' ||
                ora_dict_obj_type || '] name [' || ora_dict_obj_owner || '.' || 
                ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');                    
        END IF;        
    END IF;


    IF ora_dict_obj_type = 'TABLE' AND
        substr(ora_dict_obj_name, 1, 12) = 'SYS_JOURNAL_' 
    THEN
        BEGIN
        journalId := to_number (substr(ora_dict_obj_name, 13));
        SELECT owner, object_type 
        INTO
            journalIndexOwner, journalType
        FROM sys.dba_objects 
        WHERE object_id = journalId;
        IF journalIndexOwner = ora_dict_obj_owner AND journalType = 'INDEX' THEN
            -- if SYS_JOURNAL_xxxxx has xxxxx to be existing object of type INDEX, this is online rebuild index, which we ignore
            toIgnore := 'YES';
        END IF;
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Object is secondary for INDEX DOMAIN creation, ignored, objtype [' || ora_dict_obj_type || 
                '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');                    
        END IF;        
        EXCEPTION
           WHEN OTHERS THEN
            NULL; -- never mind, this isn't oracle journal table for rebuilding online index
        END;        
    END IF;

    -- Ignore Oracle 9i internal 'create/drop summary' when the user creates or drops of meteriazied view that has a SUM column.
    IF ora_dict_obj_type = 'SUMMARY'
    THEN
        toIgnore := 'YES';
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDLTRACE1', 'Object is Oracle internal create summary for materialized views, ignored, objtype [' || ora_dict_obj_type || 
                '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');
        END IF;
    END IF;
    
    IF "&gg_user".DDLReplication.trace_level >= 0 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [1.0], objtype [' || ora_dict_obj_type || 
            '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || ']');    
    END IF;
    
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [1], original operation = [' ||
                                    stmt || '], DDL seqno = [' || to_char ("&gg_user".DDLReplication.currentDDLSeq) || ']' );
    END IF; 
    
    IF stmt = '' OR stmt IS NULL THEN
		-- oracle sometimes creates a follow-up DDL without statement and session user
		-- this statement is related to previous one and is not a user statement, so is ignored
		"&gg_user".trace_put_line ('DDLTRACE1', 'DDL appears empty, ignoring');                    
        IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
            dbms_session.set_sql_trace(false);
        END IF;
        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

        RETURN;
    END IF;
    
    "&gg_user".DDLReplication.getVersion();
    
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: proceeding with processing');
    END IF; 
    
    -- get user id and object id as of this DDL
    -- we're looking at TABLE and SEQUENCE (or related! such as CREATE UNIQUE INDEX) for object versioning
    -- otherwise there is none
    -- object id is always that of TABLE or SEQUENCE    
    
    
    -- get user id of object owner
    BEGIN 
        IF "&gg_user".DDLReplication.ddlObjUserId = -1 THEN
        SELECT user# INTO currUserId FROM sys.user$ WHERE name = ora_dict_obj_owner; 
        ELSE 
          currUserId := "&gg_user".DDLReplication.ddlObjUserId ;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            currUserId :=  - 1;
        WHEN OTHERS THEN
            currUserId :=  - 1;
    END;
    
    
    "&gg_user".DDLReplication.currentMasterOwner := '';
    "&gg_user".DDLReplication.currentMasterName := '';
    "&gg_user".DDLReplication.currentRowid := '';
    real_ora_dict_obj_name := ora_dict_obj_name;
    real_ora_dict_obj_owner := ora_dict_obj_owner;
    real_ora_dict_obj_type := ora_dict_obj_type;
    
    -- Oracle puts 0 sometimes in these particular predefined variables, at the end, so REPLACE first 
    -- the extract history record query crashes as DDL data seems incomplete
    real_ora_dict_obj_name := REPLACE (real_ora_dict_obj_name, chr(0), ' ');            
    real_ora_dict_obj_name := rtrim (real_ora_dict_obj_name, ' ');            
    real_ora_dict_obj_owner := REPLACE (real_ora_dict_obj_owner, chr(0), ' ');            
    real_ora_dict_obj_owner := rtrim (real_ora_dict_obj_owner, ' ');            
    real_ora_dict_obj_type := REPLACE (real_ora_dict_obj_type, chr(0), ' ');            
    real_ora_dict_obj_type := rtrim (real_ora_dict_obj_type, ' ');        
    
    
    /*
    
    the purpose of following code is to obtain this information:
    
    object id of table or sequence affected
    
    if object is not a table, then we need to get the name and owner
    of table affected (base table), this is currentMasterOwner/currentMasterName
    
    If operation is CREATE, then no metadata is known here (b/c it's before trigger).
    
    */
    
    -- MATERIALIZE VIEW: we're interested in table part of it!
    -- note: this must happen before checking for TABLE!
    IF real_ora_dict_obj_type = 'MATERIALIZED VIEW' OR 
        real_ora_dict_obj_type = 'SNAPSHOT' THEN 
        real_ora_dict_obj_type := 'TABLE';
    END IF;
    
    IF ora_sysevent <> 'CREATE'  or ora_dict_obj_type <> 'TABLE'
    THEN
      "&gg_user".DDLReplication.getDDLObjInfo(ora_dict_obj_type, ora_sysevent,
                    ora_dict_obj_owner, ora_dict_obj_name );
    END IF;
    -- Try to find base object name/owner
    -- If this is CREATE, there is no need to do it, since it doesn't exist yet
    -- In case of CREATE, extract will perform resolution of base object owner
    
    -- first try easier case when it's not CREATE
    IF NOT ora_sysevent = 'CREATE' THEN
        IF real_ora_dict_obj_type = 'INDEX' THEN
            BEGIN
                SELECT i.bo#, u.name, o.name , o.owner#
                INTO "&gg_user".DDLReplication.ddlBaseObjNum,
                     "&gg_user".DDLReplication.currentMasterOwner,
                     "&gg_user".DDLReplication.currentMasterName,
                     "&gg_user".DDLReplication.ddlBaseObjUserId
                FROM sys.ind$ i, sys.obj$ o, sys.user$ u
                WHERE i.obj# =  "&gg_user".DDLReplication.ddlObjNum and
                      o.obj# = i.bo# and u.user# = o.owner#;

                select o.type# into otype FROM sys.obj$ o
                where o.obj# = "&gg_user".DDLReplication.ddlBaseObjNum;

                "&gg_user".DDLReplication.getObjTypeName(otype, otype); 

                real_ora_dict_obj_owner := "&gg_user".DDLReplication.currentMasterOwner; 
                real_ora_dict_obj_name := "&gg_user".DDLReplication.currentMasterName;
                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
					"&gg_user".trace_put_line ('DDLTRACE1', 'Non-CREATE INDEX, master object [' || real_ora_dict_obj_owner ||
						'.' || real_ora_dict_obj_name || ']');
		END IF; 
                "&gg_user".DDLReplication.currentObjectId := 
                     "&gg_user".DDLReplication.ddlBaseObjNum;
                
                IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                    "&gg_user".trace_put_line ('DDLTRACE1', 'Non-CREATE INDEX, parent object id: ' || "&gg_user".DDLReplication.currentObjectId);
                END IF;
                                
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    "&gg_user".DDLReplication.currentMasterOwner := '';
                    "&gg_user".DDLReplication.currentMasterName := '';
                WHEN OTHERS THEN
                    "&gg_user".DDLReplication.currentMasterOwner := '';
                    "&gg_user".DDLReplication.currentMasterName := '';
            END;
        END IF;
        IF real_ora_dict_obj_type = 'TRIGGER' THEN 
            BEGIN
                SELECT tr.baseobject, u.name, o.name 
                INTO "&gg_user".DDLReplication.ddlBaseObjNum,
                     "&gg_user".DDLReplication.currentMasterOwner,
                     "&gg_user".DDLReplication.currentMasterName
                FROM sys.trigger$ tr, sys.obj$ o, sys.user$ u
                WHERE tr.obj# =  "&gg_user".DDLReplication.ddlObjNum and
                      o.obj# = tr.baseobject and u.user# = o.owner#;

                -- do not set real_ora names b/c trigger changes don't affect GG object resolution
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    "&gg_user".DDLReplication.currentMasterOwner := '';
                    "&gg_user".DDLReplication.currentMasterName := '';
                WHEN OTHERS THEN
                    "&gg_user".DDLReplication.currentMasterOwner := '';
                    "&gg_user".DDLReplication.currentMasterName := '';
            END;
        END IF;
    END IF;
    IF real_ora_dict_obj_type = 'SEQUENCE' THEN 
        BEGIN
            -- get sequence CACHE/INCREMENTBY information as well as objectid
            -- which will be used in conjuction with ROWID to resolve sequence
            seqIncrementBy := 0;
            seqCache := 0;
            SELECT o.obj#, s.increment$, s.cache
            INTO "&gg_user".DDLReplication.currentObjectId, seqIncrementBy, seqCache
            FROM sys.obj$ o, sys.seq$ s
            WHERE o.obj# = "&gg_user".DDLReplication.ddlObjNum AND
                  s.obj# = o.obj#;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
            WHEN OTHERS THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
        END;
        -- now find rowid of this sequence
        -- in SYS.SEQ$ table (which is what we get from redo log)
        BEGIN
            SELECT ROWID
            INTO "&gg_user".DDLReplication.currentRowid
            FROM sys.seq$ s
            WHERE s.obj# = "&gg_user".DDLReplication.currentObjectId;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                "&gg_user".DDLReplication.currentRowid := '';
            WHEN OTHERS THEN
                "&gg_user".DDLReplication.currentRowid := '';
        END;
    END IF;
    
    IF real_ora_dict_obj_type = 'TABLE' THEN 
        BEGIN 
            SELECT o.obj# INTO "&gg_user".DDLReplication.currentObjectId 
             FROM sys.obj$ o, sys.tab$ t 
                WHERE ((o.obj# = "&gg_user".DDLReplication.ddlObjNum
                AND o.obj# = t.obj#) AND bitand(t.property, 1) IN (0, 1)); -- account for object table (value 1 for t.property bitand)
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
            WHEN OTHERS THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
        END;
    END IF; 
    
    -- CREATE INDEX is special b/c we don't know it's object id, but we have to figure out table's object id!!!
    IF real_ora_dict_obj_type = 'INDEX' AND ora_sysevent = 'CREATE'  THEN
        -- we need base object id when indexed, it affects tables with no keys (ddlrep_2)
        BEGIN 
            
            IF  "&gg_user".DDLReplication.ddlBaseObjNum <> -1 THEN
              "&gg_user".DDLReplication.currentObjectId :=
                            "&gg_user".DDLReplication.ddlBaseObjNum;
              SELECT o.name, u.name into real_ora_dict_obj_name,
                                         real_ora_dict_obj_owner
              from sys.obj$ o , sys.user$ u where
              o.obj# = "&gg_user".DDLReplication.ddlBaseObjNum and
              u.user# = o.owner# ;
            ELSE
              "&gg_user".DDLReplication.getTableFromIndex (
                                                          stmt, 
                                                          ora_dict_obj_owner,
                                                          ora_dict_obj_name,
                                                          real_ora_dict_obj_owner,
                                                          real_ora_dict_obj_name,
                                                          otype);
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'CREATE INDEX, parent: [' || otype || '] [' ||
                                            real_ora_dict_obj_owner || '.' || real_ora_dict_obj_name || ']');
            END IF;
              SELECT o.object_id 
              INTO "&gg_user".DDLReplication.currentObjectId
              FROM dba_objects o
              WHERE o.object_type = otype
              AND o.object_name = real_ora_dict_obj_name AND 
                  o.owner = real_ora_dict_obj_owner; 
            
              "&gg_user".DDLReplication.ddlBaseObjNum := 
                           "&gg_user".DDLReplication.currentObjectId ;
            END IF;

            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'CREATE INDEX, parent object id: ' || "&gg_user".DDLReplication.currentObjectId);
            END IF;
            
            "&gg_user".DDLReplication.currentMasterName := real_ora_dict_obj_name;
            "&gg_user".DDLReplication.currentMasterOwner := real_ora_dict_obj_owner;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
            WHEN OTHERS THEN
                "&gg_user".DDLReplication.currentObjectId := NULL;
        END; 
    END IF; 
    IF real_ora_dict_obj_type = 'INDEX' AND ora_sysevent = 'DROP' THEN 
        BEGIN 
            SELECT bitand(i.property, 1) 
            INTO indexUnique
            FROM sys.ind$ i 
            WHERE i.obj# = "&gg_user".DDLReplication.ddlObjNum;
            
            IF indexUnique = 1 THEN
             indexUnique := 'UNIQUE';
            ELSE
             indexUnique := 'NONUNIQUE';
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                indexUnique := 'NONUNIQUE';
            WHEN OTHERS THEN
                indexUnique := 'NONUNIQUE';
        END;
    ELSE
        indexUnique := 'NONUNIQUE';
    END IF;
    -- for all synonyms, except for CREATE (where not available)
    -- get table owner/name so it can be used in extract
    IF real_ora_dict_obj_type = 'SYNONYM' AND ora_sysevent <> 'CREATE' THEN 
        BEGIN
            SELECT s.owner, s.name
            INTO 
                "&gg_user".DDLReplication.currentMasterOwner,
                "&gg_user".DDLReplication.currentMasterName
            FROM sys.syn$ s
            WHERE 
                s.obj# = "&gg_user".DDLReplication.ddlObjNum;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Could not find table for public synonym: ' || real_ora_dict_obj_name);
            END IF;
            -- do nothing, PUBLIC/synName is used
        END;
    END IF;
    
    /*
    
    At this point we have object id of table/sequence as well as base object owner/name
    (if object is not table)
    
    */
    
    
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [2]' );
    END IF;
    
    
    -- check if object is valid.
    -- For example, when compiling triggers, procedures, packages, object may not compile
    -- in this case DDL is still considered successful and this DDL trigger will not rollback
    -- however status of object will be INVALID
    BEGIN
        SELECT d.status, d.generated, d.temporary, d.secondary, d.object_type, decode(bitand(t.property,8192),8192,'YES','NO')
        INTO objstatus, objectGenerated, objectTemporary, objectSecondary, objectType, isTypeTable
        FROM dba_objects d, sys.tab$ t
        WHERE d.object_id = "&gg_user".DDLReplication.currentObjectId and t.obj# = "&gg_user".DDLReplication.currentObjectId;
        IF (objstatus <> 'VALID') THEN
            IF "&gg_user".DDLReplication.trace_level >= 0 THEN
                "&gg_user".trace_put_line ('DDL', 'DDL operation yielded invalid status, extract will decide if ignored. DDL operation [' ||
                                        stmt || '], object [' || real_ora_dict_obj_owner || '.' || real_ora_dict_obj_name || '], status [' || 
                                        objstatus || ']'); 
            END IF;
        END IF;
        IF "&gg_user".DDLReplication.trace_level >= 1 THEN
			"&gg_user".trace_put_line ('DDLTRACE1', 'Object atts/type: [gen=' || objectGenerated ||
			', temp=' || objectTemporary || ', sec=' || objectSecondary || ', type=[' || objectType || ']');
	END IF;
        IF (objectGenerated = 'Y' AND objectType <> 'TABLE PARTITION') 
			OR objectTemporary = 'Y' OR objectSecondary = 'Y' OR isTypeTable = 'YES' THEN
            toIgnore := 'YES';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN -- do nothing because for new tables there is no entry
            NULL;
    END;

    -- ignore secondary sequence objects
    BEGIN
        IF ora_dict_obj_type = 'SEQUENCE' THEN
            SELECT d.generated, d.temporary, d.secondary
            INTO objectGenerated, objectTemporary, objectSecondary
            FROM dba_objects d
            WHERE d.object_id = "&gg_user".DDLReplication.currentObjectId;
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Sequence Object atts/type: [gen=' || objectGenerated ||
                ', temp=' || objectTemporary || ', sec=' || objectSecondary || ']');
	    END IF;
            IF objectGenerated = 'Y' OR objectTemporary = 'Y' OR objectSecondary = 'Y' THEN
                toIgnore := 'YES';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN -- do nothing because for new tables there is no entry
            IF instr ("&gg_user".DDLReplication.raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                RAISE;
            END IF;
            NULL;
    END;

    IF "&gg_user".DDLReplication.trace_level >= 0 THEN
        "&gg_user".trace_put_line ('DDL', 
                                'DDL operation [' || stmt || '], sequence [' || "&gg_user".DDLReplication.currentDDLSeq || '], '
                                || 'DDL type [' || ora_sysevent || '] ' || ora_dict_obj_type || ', real object type [' || real_ora_dict_obj_type || 
                                '], validity [' || objstatus || '], object ID [' || "&gg_user".DDLReplication.currentObjectId 
                                || '], object [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '],' 
                                || ' real object [' || real_ora_dict_obj_owner || '.' || real_ora_dict_obj_name || '],' 
                                || ' base object schema [' || "&gg_user".DDLReplication.currentMasterOwner || '],' 
                                || ' base object name [' || "&gg_user".DDLReplication.currentMasterName || '],' 
                                || ' logged as [' || ora_login_user || ']');
    END IF;
    
    
    BEGIN 
        SELECT o.dataobj#
        INTO "&gg_user".DDLReplication.currentDataObjectId
        FROM sys.obj$ o
        WHERE o.obj# = "&gg_user".DDLReplication.currentObjectId;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "&gg_user".DDLReplication.currentDataObjectId := 0;
        WHEN OTHERS THEN
            "&gg_user".DDLReplication.currentDataObjectId := 0;
    END;
    
   
    IF ora_dict_obj_type = 'TABLE' and ora_sysevent <> 'CREATE'
    THEN
      "&gg_user".DDLReplication.ddlBaseObjNum := 
                        "&gg_user".DDLReplication.ddlObjNum; 
    END IF;
    --dbms_output.put_line(ora_dict_obj_type);
    "&gg_user".DDLReplication.getObjType(ora_dict_obj_type, ntype);
    --dbms_output.put_line(ntype);
    IF "&gg_user".DDLAux.SKIP_OBJECT(
                   null,"&gg_user".DDLReplication.ddlBaseObjNum ,
                   ora_dict_obj_name, ora_dict_obj_owner ,
                   ntype,  
                   "&gg_user".DDLReplication.currentMasterName ,
                   "&gg_user".DDLReplication.currentMasterOwner , 
                   ora_sysevent) 

    THEN
       "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

       RETURN;
    END IF;
    
    -- these are stored in columns of DDL history table
    -- they are oracle's original just like for marker table
    -- 'real' ones are used to actually derive metadata *only*
    "&gg_user".DDLReplication.currentObjectName := ora_dict_obj_name; 
    "&gg_user".DDLReplication.currentDDLType := ora_sysevent; 
    "&gg_user".DDLReplication.currentObjectOwner := ora_dict_obj_owner;
    "&gg_user".DDLReplication.currentObjectType := ora_dict_obj_type;
    
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [3]' );
    END IF;
    
    IF real_ora_dict_obj_type = 'INDEX' AND ora_sysevent = 'CREATE' and otype = 'TABLE' THEN 
        "&gg_user".trace_put_line ('DDLTRACE1', 'checking create index for parent type:' || otype || 
  	' owner:' || real_ora_dict_obj_owner || ' name:' || real_ora_dict_obj_name ||
  	' object id:' || to_char("&gg_user".DDLReplication.currentObjectId));
      
      BEGIN
        -- test that base table object exists.
        SELECT t.obj# 
          INTO "&gg_user".DDLReplication.currentObjectId
          FROM sys.tab$ t
          WHERE t.obj# = "&gg_user".DDLReplication.currentObjectId;
	EXCEPTION
          WHEN NO_DATA_FOUND THEN BEGIN
	    toIgnore := 'YES';
  	    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
               "&gg_user".trace_put_line ('DDLTRACE1', 'Base table does not exists');
	    END IF;
	END;
      END;
    END IF;    
    
    /*
    
    insert DDL descriptor string to marker table
    DDL STATEMENT and related info
    construct DDL operation descriptor string
    marker record contains original object name, whereas DDL record contains 'real' (adjusted for INDEX->TABLE)
    
    */
    
    "&gg_user".DDLReplication.saveMarkerDDL (
                                              to_char ("&gg_user".DDLReplication.currentObjectId),
                                              ora_dict_obj_owner,
                                              ora_dict_obj_name,
                                              ora_dict_obj_type,
                                              ora_sysevent,
                                              to_char ("&gg_user".DDLReplication.currentDDLSeq),
                                              '&gg_user' || '.' || '&ddl_hist_table',
                                              ora_login_user,
                                              objstatus, 
                                              indexUnique,
                                              "&gg_user".DDLReplication.currentMasterOwner,
                                              "&gg_user".DDLReplication.currentMasterName, 
                                              stmt,
                                              toIgnore);
    
    
    
    /*
    
    Get Start SCN
    IMPORTANT: start SCN can be obtained *only* after marker record has been
    written - this is Oracle limitation because transaction had no data so far
    (even though this is DDL transaction by itself, however in BEFORE trigger
    there is no start SCN until it's done because transaction hasn't officially
    started yet!!)
    
    */
    
    -- get current module info
    dbms_application_info.read_module(oldModuleNameInfo, oldActionInfo);
    -- 'stamp' current session with unique ddl sequence number
    -- this works even when we have multiple DDLs happenning in several background processes (all with session id of 0)
    moduleNameInfo := 'GGS_DDL_MODULE_' || to_char ("&gg_user".DDLReplication.currentDDLSeq);
    dbms_application_info.set_module(moduleNameInfo, null);
    
    
    -- we let potential error here be handled by extract as it should never happen that we can't find SCN
    SELECT t.start_scnb, t.start_scnw
    INTO "&gg_user".DDLReplication.SCNB, "&gg_user".DDLReplication.SCNW 
    FROM v$transaction t, v$session s 
    WHERE
    t.addr = s.taddr AND t.ses_addr = s.saddr AND s.audsid = USERENV('SESSIONID') 
    AND s.module = moduleNameInfo; 
    
    
    IF "&gg_user".DDLReplication.trace_level >= 0 THEN
        "&gg_user".trace_put_line ('DDL', 
                                'Start SCN found [' || to_char("&gg_user".DDLReplication.SCNB + "&gg_user".DDLReplication.SCNW * power (2, 32)) || ']'); 
    END IF;
    
    -- restore module info
    dbms_application_info.set_module(oldModuleNameInfo, oldActionInfo);
    
    -- do not calculate/record any metadata for objects other than table, index or trigger
    -- because these are the objects we need to resolve base owner/name for
    -- also do not calculate metadata for TRUNCATE TABLE
    -- because customer may have hundreds of those - they don't change table structure!!!
    IF (NOT real_ora_dict_obj_type = 'TABLE' AND
        NOT real_ora_dict_obj_type = 'INDEX' AND 
        NOT real_ora_dict_obj_type = 'TRIGGER' AND
        NOT real_ora_dict_obj_type = 'SEQUENCE') OR
        (real_ora_dict_obj_type = 'TABLE' AND ora_sysevent = 'TRUNCATE')        
        OR "&gg_user".DDLReplication.stay_metadata = 1 -- do not query db for metadata if STAYMETADATA is ON
        THEN
        IF "&gg_user".DDLReplication.trace_level >= 0 THEN
            "&gg_user".trace_put_line ('DDL', '------------------------- End of log for DDL sequence [' || 
                                to_char ("&gg_user".DDLReplication.currentDDLSeq) || '], no DDL history metadata recorded for this DDL operation');
        END IF;
        IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
            dbms_session.set_sql_trace(false);
        END IF;                                    
        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

        RETURN;
    END IF;
    
    
    
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDL', 'Object ID  is [' || to_char ("&gg_user".DDLReplication.currentObjectId) ||
                                    ']');
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [4]' );
    END IF;
    
    
    -- For any CREATE DDL, do the same, because there can't be 
    -- any DML for an object prior to it being created. This also
    -- eliminates the problem of objects that don't exist in the context
    -- of ddl trigger, since this is before ddl trigger. Any CREATE DDL
    -- suffers from that issue. This way that problem is eliminated.
    -- For CREATE INDEX DDLs take history as the key sey may change as
    -- a result of the DDL (bug 14032266).
    IF (ora_sysevent <> 'CREATE' OR 
	(toIgnore = 'NO' AND real_ora_dict_obj_type = 'INDEX' AND otype = 'TABLE')) THEN	
        "&gg_user".DDLReplication.beginHistory ();

        IF real_ora_dict_obj_type = 'SEQUENCE' THEN
            /*
                For sequences, we need sequence object id, name and rowid for the most part in order to map rowid to objectid/name
                As sequences don't have properties as tables, this is where we must stop gathering metadata as well     
            */
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [4-seq], sequence cache [' ||
                                            to_char (seqCache) || '], sequence incrementby [' || to_char (seqIncrementBy) || ']' );
            END IF;

            "&gg_user".DDLReplication.saveSeqInfo (
                      real_ora_dict_obj_owner, real_ora_dict_obj_name,
                      ora_sysevent, to_char(currUserId),
                      seqCache, seqIncrementBy, toIgnore );
        ELSE
            
        /*
        
        BEGIN HISTORY table inserts
        begin inserting metadata to history
        
        */
               
            -- metadata producing calls    
            -- IMPORTANT: here we use real_ora_ values b/c resolution depends on it, also object id is correlated
            IF "&gg_user".DDLReplication.trace_level >= 2 THEN
                "&gg_user".trace_put_line ('DDLTRACE2', 'Goint to call getTableInfo() ' || stmt);
            END IF;
    
           
            "&gg_user".DDLReplication.getTableInfo (
                      "&gg_user".DDLReplication.ddlBaseObjNum,
                      real_ora_dict_obj_name, 
                      real_ora_dict_obj_owner, 
                      real_ora_dict_obj_type, 
                      ora_sysevent, to_char(currUserId), 
                      "&gg_user".DDLReplication.currentMasterOwner,
                      "&gg_user".DDLReplication.currentMasterName, 
                      substr (stmt, 1, &frag_size - 10),
                      toIgnore );
    
            "&gg_user".DDLReplication.getColDefs (
                        "&gg_user".DDLReplication.ddlBaseObjNum, 
                        real_ora_dict_obj_owner, 
                        real_ora_dict_obj_name);
            
            IF "&gg_user".DDLReplication.useAllKeys = 1 THEN
                "&gg_user".DDLReplication.getKeyColsUseAllKeys (
                              "&gg_user".DDLReplication.ddlBaseObjNum,
                               real_ora_dict_obj_owner, 
                               real_ora_dict_obj_name);         
            ELSE
                "&gg_user".DDLReplication.getKeyCols (
                              "&gg_user".DDLReplication.ddlBaseObjNum,
                              real_ora_dict_obj_owner, 
                              real_ora_dict_obj_name);         
            END IF;
            
            IF "&gg_user".DDLReplication.trace_level >= 1 THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [5]' );
            END IF;
            -- end inserting metadata to history
            
        /*
        
        END HISTORY table inserts
        
        */
        END IF;
        /* make sure endHistory record is placed for sequences too */
        "&gg_user".DDLReplication.endHistory ();
    
    END IF; 
    BEGIN
      IF '&_ddl_cause_user_cancel' = 'TRUE' OR '&_ddl_cause_user_nested_cancel' = 'TRUE' THEN
	  "&gg_user".trace_put_line ('DDLTRACE1', 'Trigger: Raising simulated 1013 error');
	  RAISE userCancelSimulate;
      END IF;
      EXCEPTION
          WHEN OTHERS THEN
            IF '&_ddl_cause_user_nested_cancel' = 'TRUE' THEN
	        "&gg_user".trace_put_line ('DDLTRACE1', 'Trigger: Raising simulated nested 1013 error');
                RAISE userCancelNestedSimulate;
            ELSE
                RAISE;
            END IF;
    END;

    -- this is always after last executable statement
    IF "&gg_user".DDLReplication.trace_level >= 1 THEN
        "&gg_user".trace_put_line ('DDLTRACE1', 'Before Trigger: point in execution = [the end]' );
    END IF; 
    
    
    -- EXCEPTIONS        
    -- handle exceptions (if so specified)
    
    IF "&gg_user".DDLReplication.trace_level >= 0 THEN
        "&gg_user".trace_put_line ('DDL', '------------------------- End of log for DDL sequence [' || 
                                to_char ("&gg_user".DDLReplication.currentDDLSeq) || ']');
    END IF;
    
    IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
        dbms_session.set_sql_trace(false);
    END IF;
    "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        "&gg_user".trace_put_line ('DDL', 'Trigger sys.' || '&ddl_trigger_name' || ' :Error processing DDL operation [' || stmt || '], error ' 
                                    || SQLERRM || ', error stack: ' || "&gg_user".ddlora_getErrorStack); 

        -- this code will delete any previous garbage from marker data so if trigger commits, nothing is there
        -- unless we put it down here somewhere (in big trigger exception) or in size handling above                              
        -- this way extract doesn't abend from interrupted garbage
        -- note that this really shouldn't happen (it does when simulated) because oracle actually rollsback transaction
        IF "&gg_user".DDLReplication.currentMarkerSeq IS NOT NULL THEN  -- only if marker seqno set
            BEGIN
                "&gg_user".trace_put_line ('DDL', 'Cleaning up marker sequence [' || "&gg_user".DDLReplication.currentMarkerSeq || ']'); 
                DELETE FROM "&gg_user"."&marker_table_name" WHERE seqNo = "&gg_user".DDLReplication.currentMarkerSeq;
                "&gg_user".trace_put_line ('DDL', 'Cleaned up [' || SQL%ROWCOUNT || '] rows from marker table'); 
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; -- this is a curtesy delete, ignore if any error                            
            END;
        END IF;           
        -- we also delete DDL seqno, so it's not accidentally selected in extract if trigger had problems
		-- and thus incomplete data
	
		BEGIN
			"&gg_user".trace_put_line ('DDL', 'Cleaning up DDL sequence [' || "&gg_user".DDLReplication.currentDDLSeq || ']'); 
			DELETE FROM "&gg_user"."&ddl_hist_table" WHERE seqNo = "&gg_user".DDLReplication.currentDDLSeq;
			"&gg_user".trace_put_line ('DDL', 'Cleaned up [' || SQL%ROWCOUNT || '] rows from DDL table'); 
		EXCEPTION
			WHEN OTHERS THEN
				NULL; -- this is a curtesy delete, ignore if any error							
		END;
		
		IF toIgnore = 'YES' THEN
            -- if we're somehow here, and DDL is ignored anyway, don't error out
            "&gg_user".trace_put_line ('DDL', 'DDL is ignored, error is ignored too.'); 
            IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
                dbms_session.set_sql_trace(false);
            END IF;
            "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

            RETURN;
        END IF;

        IF SQLCODE = -1013 OR "&gg_user".ddlora_errorIsUserCancel THEN    
            -- this is user cancellation error, just  exit, never mind all this
            -- what happens is that Oracle rollsback previous INSERTs but we would have
            -- started new one here. We just want to ignore everything, hence RETURN
            "&gg_user".trace_put_line ('DDL', 'User cancelled operation');
            IF '&_ddl_cause_user_cancel' = 'TRUE' OR '&_ddl_cause_user_nested_cancel' = 'TRUE' THEN
                "&gg_user".trace_put_line ('DDLTRACE1', 'forced user cancel test stack ' ||
                                             DBMS_UTILITY.format_error_stack);
            END IF;             
            IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
                dbms_session.set_sql_trace(false);
            END IF;
            "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

            RETURN;
        END IF;    
        IF disallowDDL = 1 THEN            
            IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
                dbms_session.set_sql_trace(false);
            END IF;
            raise_application_error (&trigger_error_code,
                                     "&gg_user".DDLReplication.triggerErrorMessage || ':' || SQLERRM ||
                                     ', error stack: ' || "&gg_user".ddlora_getErrorStack);
        ELSE
            /*
            
            if there is trouble in trigger
            try to make sure extract knows about it            
            include min necessary information for end-user to examine trace log
            
            */
            
            
            IF SQLCODE = -6508 THEN    
                -- this is improper installation, alert extract to it so user knows                        
                outMessage := 'INSTALLPROBLEM: Oracle could not find properly installed DDL replication package (ORA-6508). Please ' ||
                ' install or upgrade DDL replication package for Oracle (PLSQL code) before proceeding. Please make sure all ' ||
                'processes that use DDL are shutdown during trigger installation. The actual DDL here may or may not succeed.';
                INSERT INTO "&gg_user"."&marker_table_name" (
                    seqNo,
                    fragmentNo,
                    optime,
                    TYPE,
                    SUBTYPE,
                    marker_text
                )
                VALUES (
                    -1,
                    0,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                    'DDL',
                    'DDLINFO', 
                     outMessage -- text of marker
                ); 
            ELSE
                IF "&gg_user".DDLReplication.currentMarkerSeq  IS NULL THEN  -- only if marker seqno not set
                    SELECT "&gg_user"."&marker_sequence".NEXTVAL INTO "&gg_user".DDLReplication.currentMarkerSeq FROM dual; 
                END IF;
                outMessage := 'ERROR: DDL sequence [' || to_char ("&gg_user".DDLReplication.currentDDLSeq) || 
                '], marker sequence [' || to_char ("&gg_user".DDLReplication.currentMarkerSeq) ||
                '], DDL trace log file [' || "&gg_user".DDLReplication.dumpDir || "&gg_user".file_separator || '&trace_file], error code ' ||
                to_char(SQLCODE) || ' error message ' || SQLERRM || ', error stack: ' || "&gg_user".ddlora_getErrorStack;
                INSERT INTO "&gg_user"."&marker_table_name" (
                    seqNo,
                    fragmentNo,
                    optime,
                    TYPE,
                    SUBTYPE,
                    marker_text
                )
                VALUES (
                    "&gg_user".DDLReplication.currentMarkerSeq,
                    0,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                    'DDL',
                    'DDLINFO', 
                         outMessage -- text of marker
                ); 
            END IF;
            IF '&ddl_fire_error_in_trigger' = 'TRUE' THEN
                IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
                    dbms_session.set_sql_trace(false);
                END IF;
                raise_application_error (&trigger_error_code,
                                         "&gg_user".DDLReplication.triggerErrorMessage || ':' || SQLERRM);
            END IF;
        END IF;
        IF "&gg_user".DDLReplication.sql_trace = 1 THEN                        
            dbms_session.set_sql_trace(false);
        END IF;
        "&gg_user".DDLReplication.setCtxInfo(-1,-1,-1,-1,-1);

END;
/
show errors


-- clear out recycle bin for GoldenGate user
SET termout ON
BEGIN
  IF '&paramname' <> 'ddl_ora9.sql' AND '&allow_purge_tablespace' = 'TRUE' THEN
      execute immediate 'PURGE TABLESPACE ' ||
                        :gg_user_default_tablespace ||
                        ' USER &gg_user';
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error (&setup_error_code,
                                 chr(10) || SQLERRM || chr(10));
END;
/
SET termout OFF


-- enable trigger only it's status is valid
-- i.e. if last compilation worked (old could still be there)
DECLARE
tstatus VARCHAR2 (&max_status_size);
BEGIN
    SELECT status INTO tstatus 
    FROM dba_objects 
    WHERE owner = 'SYS' AND object_name = '&ddl_trigger_name';
    IF tstatus = 'VALID' THEN
        EXECUTE IMMEDIATE 'alter trigger sys .&ddl_trigger_name enable';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- Validate new instance of Replication package
-- in case it's been used before (oracle bug #2747350)
DECLARE
BEGIN
    "&gg_user".trace_put_line ('DDL', 'Instantiating new DDL replication package'); 
EXCEPTION
    WHEN OTHERS THEN
        RAISE; 
END;
/

spool OFF
SET verify ON
SET termout ON

prompt
prompt DDL replication setup script complete, running verification script...
@ddl_status &gg_user

prompt 
prompt Script complete.

set feedback on
