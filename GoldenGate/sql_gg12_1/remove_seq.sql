Rem
Rem $Header: oggcore/OpenSys/redist/SQLScripts/remove_seq.sql /main/1 2011/04/07 20:55:14 smijatov Exp $
Rem
Rem remove_seq.sql
Rem
Rem Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 
Rem
Rem    NAME
Rem      remove_seq.sql - Remove Oracle sequence replication support
Rem
Rem    DESCRIPTION
Rem      Oracle sequence replication support is installed via sequence.sql
Rem      This script will remove that support
Rem
Rem    NOTES
Rem      Do not use this if Oracle sequence replication support is needed
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smijatov    03/17/11 - Script to remove Oracle sequence replication
Rem                           support
Rem    smijatov    03/17/11 - Created
Rem

define setup_error_code = '-20783' -- error code in custom error codes space 
                                   -- for raising application error

-- do not show substitutions in progress
SET verify OFF
SET FEEDBACK OFF


-- check if user has privileges, if not, exit with message
WHENEVER SQLERROR EXIT
variable isdba VARCHAR2(30)
variable sysdba_message VARCHAR2 (2000)
BEGIN
    :sysdba_message := chr(10) || 'GoldenGate Oracle Sequence removal: ' 
    || chr(10) || '*** Currently logged user does not have SYSDBA privileges,' 
    || 'or not logged AS SYSDBA! ' || chr(10) || '*** Please login as SYSDBA.' 
    || chr(10);

    SELECT sys_context('userenv','ISDBA') INTO :isdba FROM DUAL; -- use network 
                                             -- method  for isdba determination

    IF :isdba <> 'TRUE' THEN
        raise_application_error (&setup_error_code, :sysdba_message);
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
       raise_application_error (&setup_error_code, :sysdba_message);
END;
/
WHENEVER SQLERROR CONTINUE


col gg_user new_value gg_user

prompt Please enter the name of a schema for the GoldenGate database objects:
SET termout OFF
define mypar=&1
SELECT upper('&mypar') AS gg_user FROM dual;


SET termout ON
prompt Setting schema name to &gg_user
SET termout OFF
spool sequence_remove_spool.txt
STORE SET 'sequence_remove_set.txt' REPLACE
SET termout ON

-- do not show substitutions in progress
SET verify OFF 
SET FEEDBACK OFF

DROP PROCEDURE "&gg_user".seqTrace;

DROP PROCEDURE "&gg_user".getSeqFlush;

DROP PROCEDURE "&gg_user".replicateSequence;

DROP PROCEDURE "&gg_user".updateSequence;


SET verify ON
SET FEEDBACK ON




