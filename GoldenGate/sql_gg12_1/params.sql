-- Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Customizable parameters for GoldenGate 
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. This is *not* executable script
-- 
-- 2. If you edit this script, do so before executing other scripts that use it (all other scripts)
--
--
-- Revision history
-- 
Rem    MODIFIED   (MM/DD/YY)
Rem    ajadams     06/11/12  - Backport ajadams_bug-13738843 from main
Rem    smijatov    03/12/12  - Bug-13825904: add _skip_lock_check and _skip_create_objects internal params
-- 11/02/2011 - SIJENKI
--    OS-BUG-13032000: add java_name_size for java names
-- 09/16/2010 - AJADAMS
--    OS-BUG-9830035 - AJADAMS: nested user cancel, added _ddl_cause_user_nested_cancel
-- 05/20/2010 - SRDJAN
--    OS-BUG-9421334: remove RECYCLEBIN OFF requirement from Oracle 11 db and extract
--  12/04/09 - SRDJAN
--    OS-6769: added ALLOWRECYCLEBIN to allow recyclebin on for oracle (internal param)
-- 08/13/2008 - SRDJAN
--    OS-7135 - DDL hist table does not create due to ORA-01450
-- 03/10/2008 - SRDJAN
--    FP 17628 - user cancellation is not handled properly (extract abends) - added flag for simulating 1013
--  03/10/08 - SRDJAN
--      FP 17556: near 32K DDL breaks replication (shorter ddl for extract processing reasons)
--  03/05/08 - SRDJAN
--      FP 17556: near 32K DDL breaks replication
--  02/13/08 - SRDJAN
--      No ticket: add index to marker table for much faster DUMP and debugging
--  02/01/08 - SRDJAN
--    FP 4313 : Oracle sequence replication 
--  05/23/07 - SRDJAN
--		DDL replication first release
--




-- ******************************************
-- IMPORTANT:
-- The following are customizable parameters
-- Exercise caution when changing these parameter and/or call Oracle Technical Support
-- ******************************************

-- start of user customizable parameters

define trace_directory = 'GGS_DDL_TRACE' -- Oracle directory name (logical directory)
define trace_file = 'ggs_ddl_trace.log' -- located in user dump directory, for example to view it:

-- NOTE: the following parameters are base table names, change only if necessary
-- all PL/SQL software must be recompiled as if performing new installation
define marker_table_name = 'GGS_MARKER' -- name of marker table
define marker_sequence = 'GGS_MARKER_SEQ' -- name of marker sequence
define marker_index = 'GGS_MARKER_IND1' -- name of marker index
define ddl_trigger_name = 'GGS_DDL_TRIGGER_BEFORE' -- name of DDL trigger

-- NOTE: the following ddl_* parameters, if changed, carry the consequence of having to change
-- GLOBALS file settings among other things. Please consult documentation
-- these parameters define table names used to dump DDL history table information in 
-- relational tables (metadata of tables) (GGSCI DUMP command)
define ddl_sequence = 'GGS_DDL_SEQ' -- name of DDL sequence
define ddl_hist_table = 'GGS_DDL_HIST' -- name of DDL history table
define ddl_rules = 'GGS_DDL_RULES' -- name of DDL ignore table
define ddl_rules_log = 'GGS_DDL_RULES_LOG' -- name of DDL ignore log table
define ddl_dump_tables = 'GGS_DDL_OBJECTS' -- name of DDL dump objects tables
define ddl_dump_columns = 'GGS_DDL_COLUMNS' -- name of DDL dump objects columns
define ddl_dump_log_groups = 'GGS_DDL_LOG_GROUPS' -- name of DDL dump log groups 
define ddl_dump_partitions = 'GGS_DDL_PARTITIONS' -- name of DDL dump partitions
define ddl_dump_primary_keys = 'GGS_DDL_PRIMARY_KEYS' -- name of DDL dump primary keys

-- NOTE:changing the following parameter to TRUE will cause DDL to fail if there are trigger errors, use with caution
define ddl_fire_error_in_trigger = 'FALSE' -- if TRUE, DDL trigger errors are propagated up to the application

define setup_table = 'GGS_SETUP' -- general GoldenGate table

define trigger_error_code = '-20782' -- error code in custom error codes space for raising application error

define gg_role = 'GGS_GGSUSER_ROLE' -- role containing security privs for end-user to use marker etc

define allow_shared_tablespace = 'FALSE' -- allow gg_user to share its default tablespace with other users

define allow_purge_tablespace = 'TRUE' -- allow purging of gg_user's default tablespace when installing DDL support

-- common SQL programming constants, do NOT change unless directed so by GoldenGate support
define frag_size = 4000
define max_varchar2_size = 32767
define max_ddl_size = 31700 -- more than enough considering little overhead [,C1='escaped_sql',], see ddl.h limit
define output_line_size = 900
define file_name_size = 400
define message_size = 32767
define name_size = 100
define java_name_size = 4000
define type_size = 40
define version_size = 100
define time_size = 19
define max_status_size = 100
define charset_size = 100
define valid_size = 30
define charused_size = 50
define xmltype_size = 50
define bool_size = 20
define charsetid_size = 30
define charsetform_size = 50
define audit_size = 80

-- end of user customizable parameters

define _skip_lock_check = '' -- skip lock checking for programs that contain this string in their name
define _skip_create_objects = 'FALSE' -- if TRUE, then DDL objects are not created (except for code). Use with caution.


-- ******************************************
-- Error causing flag for testing purposes
-- DO NOT CHANGE ANYTHING BELOW THIS LINE
define _ddl_cause_error = 'FALSE' -- cause trigger to fail if set to TRUE
define _ddl_cause_user_cancel = 'FALSE' -- cause trigger to fail if set to TRUE (from ora-1013)
define _ddl_cause_user_nested_cancel = 'FALSE' -- cause trigger to fail (from ora-1013 at 2nd level)
