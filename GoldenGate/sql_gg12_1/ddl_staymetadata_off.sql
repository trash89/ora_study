-- Copyright (C) 2006, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Turn OFF STAYMETADATA
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
--
-- Revision history
-- 
--  05/06/08 - SRDJAN
--	 Initial version


SET verify OFF 

col gg_user new_value gg_user
col identname new_value identname

prompt
prompt You will be prompted for the name of a schema for the GoldenGate database objects.
prompt NOTE: The schema must be created prior to running this script.
prompt
accept gg_user prompt 'Enter GoldenGate schema name:'
prompt
prompt Working, please wait ...
prompt Spooling to file ddl_staymetadata_off_spool.txt

prompt

SET termout OFF
spool ddl_staymetadata_off_spool.txt

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

@params


SELECT upper('&gg_user') AS gg_user FROM dual;

SET termout ON

-- check if entered user name exists
WHENEVER SQLERROR EXIT
variable user_name VARCHAR2(30)
BEGIN
    SELECT 
        username
    INTO
        :user_name
    FROM all_users
    WHERE username = '&gg_user';
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Cannot find user &gg_user' || chr(10) ||
                                 '*** Please enter existing user name.' || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE



-- check if setup table installed
WHENEVER SQLERROR EXIT
variable numof NUMBER
BEGIN
    SELECT 
        COUNT(*)
    INTO
        :numof
    FROM dba_objects
    WHERE owner = '&gg_user' AND object_name = '&setup_table'  AND object_type = 'TABLE';
    IF :numof <> 1 THEN
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL Replication setup: ' || chr(10) ||
                                 '*** Setup table not found, please run install DDL support first' || chr(10) );
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error (&setup_error_code, 
                                 chr(10) || SQLERRM || chr(10));
END;
/
WHENEVER SQLERROR CONTINUE

update "&gg_user"."&setup_table" set value='OFF' where property='DDL_STAYMETADATA';
commit;

SET termout ON
SET VERIFY ON

spool off
prompt
prompt Script complete, running verification script...
-- show that is' changed
@ddl_status &gg_user




