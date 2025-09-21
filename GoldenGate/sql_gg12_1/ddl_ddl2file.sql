-- Copyright (C) 2005, 2010, Oracle and/or its affiliates. All rights reserved.
--
-- Program description:
-- Save DDL from marker table to a file
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as SYSDBA from the same directory where SQL scripts
--    are located.
-- 
-- 2. Command line arguments (when executing from SQL*Plus)
--      &1 is GoldenGate Schema that must exist prior to executing this script
--          Notes: This parameter is mandatory. 
--          This parameter must match schema used to install marker table and DDL Replication.
--      &2 is the sequence number in marker table
--          Notes: This parameter is mandatory. 
--      &3 is name of the file to save DDL to
--          Notes: This parameter is mandatory. 
--
--    For example:
--    SQL> @ddl_ddl2file GGS_USER 12331 myDDL.sql
--
--
-- Revision history
-- 
--  2/10/08 - SRDJAN
--    OS-5079: large DDL for Oracle

SET verify OFF 
set feedback off

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error
col gg_user new_value gg_user
col gg_seq new_value gg_seq
col gg_file new_value gg_file

-- User showtime
prompt
accept gg_user prompt 'Enter GoldenGate schema name:'
prompt
accept gg_seq prompt 'Enter marker sequence number:'
prompt
accept gg_file prompt 'Enter DDL text file name:'
prompt


SELECT VALUE || '/' || '&gg_file' "LOCATION OF DDL TEXT FILE"
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;

prompt Saving DDL file, please wait...

SET termout OFF
SELECT upper('&gg_user') AS gg_user FROM dual;
SELECT '&gg_seq' AS gg_seq FROM dual;
SELECT '&gg_file' AS gg_file FROM dual;

@params


SET termout ON
WHENEVER SQLERROR EXIT
DECLARE
	output_file utl_file.file_type; -- file to output to
	ddlOn NUMBER;  -- are we processing ddl text
	t VARCHAR2(4000);  -- current chunk of ddl text
begin

	-- first remove old file
	BEGIN
		utl_file.fremove ('&trace_directory', '&gg_file'); 
		EXCEPTION 
			WHEN OTHERS THEN 
				IF SQLCODE =  - 29283 THEN -- avoid 'file not found' 
					NULL;
				ELSE
					RAISE;
				END IF;       
	END;
	
	-- open file for writing
	output_file := utl_file.fopen ('&trace_directory', '&gg_file', 'A', max_linesize => 4000);
	
	ddlOn := 0;	
	-- get all data for DDL with given sequence number
	FOR ddlT IN (SELECT 
				marker_text txt 
				FROM &gg_user ."&marker_table_name" 
				WHERE seqno=&gg_seq) 
	LOOP
		t := ddlT.txt;
		
		-- find out very first DDL piece of text
		IF INSTR(ddlT.txt, ',C1=',1)<>0 THEN
			ddlOn := 1;  -- now we're processing DDL
			t := REPLACE(t,',C1=''','');  -- remove tag formatting
		ELSE
		
			-- if we're processing DDL but find another tag, exit, because there is no more DDL text
			IF ddlOn = 1 and INSTR(ddlT.txt, '=''',1)<>0 THEN
				EXIT;
			END IF;
		END IF;
		-- if we're processing DDL and find the last-record-tag, remove that tag
		IF ddlOn=1 THEN
			IF INSTR(ddlT.txt, ''',',1) <> 0 THEN
				t := REPLACE(t,''',','');
			END IF;
		END IF;
		

		-- remove formatting escape chars
		t := REPLACE (t,'\=','=');
		t := REPLACE (t,'\''','''');
		t := REPLACE (t,'\,',',');
		t := REPLACE (t,'\(','(');
		t := REPLACE (t,'\)',')');
		t := REPLACE (t,'\=','=');
		t := REPLACE (t,'\\','\');
	
		-- if formatting escape char is the last one (overflowing to next one), remove it
		-- this way the very next char is unescaped
		IF SUBSTRB(t, LENGTHB(t), 1) = '\' THEN
			t:= SUBSTRB (t, 1, LENGTHB(t)-1);
		end if;
	
		-- put the line out and flush
		utl_file.put (output_file, t);
		utl_file.fflush (output_file);

	END LOOP;
	utl_file.FCLOSE (output_file);

EXCEPTION 
    WHEN OTHERS THEN 
		-- any error is fatal, print out error and exit
        raise_application_error (&setup_error_code, 
                                 chr(10) || 'GoldenGate DDL text utility error: ' || chr(10) ||
                                 '*** Could not save DDL text, error ' || SQLERRM || chr(10) || "&gg_user".ddlora_getErrorStack);
end;
/
SET termout ON
undefine 1
undefine 2
undefine 3

WHENEVER SQLERROR CONTINUE



SET termout ON
SET verify ON
set feedback on
prompt Done
prompt
