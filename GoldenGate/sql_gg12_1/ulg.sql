Rem Script to upgrade Oracle GoldenGate supplemental log groups
Rem 
Rem    MODIFIED   (MM/DD/YY)
Rem    vjanardh    07/30/12  - Backport vjanardh_bug-14333745 from
Rem    smijatov    07/25/12  - bug-14363422: enable script for oracle 9
Rem    vjanardh    19/07/12  - bug-14333745: remove continue statements since not supported on 10.2 db 
Rem    smijatov    07/26/12  - Backport smijatov_bug-14363422 from main
Rem    smijatov    08/18/11  - bug-12659457: Account for any name (double quotes).
Rem                               Do not convert recycle bin tables (log groups).
Rem                               Drop temporary (GGT) log groups.
Rem                               In case of multiple old log groups, combine their columns
Rem                               into single group.
Rem    smijatov    07/18/11  - bug-12659457: Rework TRANDATA in all products
Rem                            to use objid only
Rem

prompt Oracle GoldenGate supplemental log groups upgrade script.
pause Please do not execute any DDL while this script is running. Press ENTER to continue.

spool ulg_spool.txt
set echo off


-- Bug #14363422: enable script for oracle 9. Also remove all dbms_output in the loops
set verify off
set termout off
col queryP new_value queryP
col queryPC new_value queryPC
variable oversion varchar2(100)
variable ocompat varchar2(100)
exec dbms_utility.db_version (:oversion, :ocompat); 
select decode (substr (:oversion, 1, instr (:oversion, '.', 1)), '9.', '', 'log_group_type like ''USER LOG GROUP%'' and generated like ''USER_NAME%''  and') as queryP from dual;
select decode (substr (:oversion, 1, instr (:oversion, '.', 1)), '9.', '', 'and logging_property=''LOG''') as queryPC from dual;
set termout on

set serveroutput on 
declare
objId number;
cols varchar2(4000); -- we will need max 30*30*<bytes per char>, i.e. less than 3600 at worst
stmt varchar2(4000);
tot number;
cnt number;
isRecycle number;
begin
tot:=0;
cnt:=0;


-- A loop to find all supp log groups that satisfy old or new criteria (basically GGS*)
-- ALL logging is excluded from this list
-- We look for GG% because temporary log group be GGT% (and normal GGS%)
-- Bug #14363422: condition the query for oracle 9 vs rest
for tab in (select owner,table_name,log_group_name from dba_log_groups where &queryP always like 'ALWAYS%' and log_group_name like 'GG%') loop

    -- get object id
    -- object tables are also of type 'TABLE'
    select object_id into objId from dba_objects where owner=tab.owner and object_name=tab.table_name and object_type='TABLE';

    -- we ignore recyclebin groups as they pop back up (from the bin itself)
    if substr(tab.log_group_name, 1, 8) ='GGS_BIN$' then
        goto log_group_search;
        --continue;
    end if;


    if substr(tab.log_group_name, 1, 3) ='GGT' then
        -- remove any temporary log groups
        stmt := 'ALTER TABLE '||tab.owner||'.'||tab.table_name||' DROP SUPPLEMENTAL LOG GROUP '||tab.log_group_name;
        begin
            execute immediate (stmt);
        exception
            when others then null; 
        end;

        goto log_group_search;
        --continue;
    end if;


    -- if log group is of new style, don't do anything
    if tab.log_group_name='GGS_'||to_char(objId) then
        goto log_group_search;
        --continue; -- do not add and remove new log groups, because end-step is to remove them
    end if;

    -- anything that is old style will be processed here, excluding GGT groups and
    -- including any duplicates (meaning groups with different GG names but on the same table)

    cnt:=cnt+1;


    -- find all columns in this log group
    -- if there was another old log group before (that starts with GG) but that had different columns, it would be
    -- showing up now as GGS_objId group. We will get all the columns from it before dropping it (which we
    -- have to do because there can be only one GGS_objId group), and then make sure that any extra columns
    -- present there will be in a new group. That's why there is GGS_objid there as well as 'distinct' so there
    -- is no duplicate column names.
    -- Bug #14363422: condition the query for oracle 9 vs rest
    cols := '';
    for c in (select distinct column_name from dba_log_group_columns where owner=tab.owner and table_name=tab.table_name &queryPC and (log_group_name=tab.log_group_name or log_group_name='GGS_'||objId)) loop
        if cols <> '' or cols is not null then
            cols := cols || ',';
        end if;
        cols := cols || c.column_name;
    end loop;


    -- drop the new supp log, in case it's been created, and this is a re-run
    -- also if there were two (or more) old-style GG log groups, the previous one was converted
    -- to GGS_objId. That one will now be dropped. This way, there will be only one log group 
    -- left for table, and any duplicates removed. Note that different log groups on the same table
    -- may have different columns, so they may not be 'duplicates'.
    stmt := 'ALTER TABLE "'||tab.owner||'"."'||tab.table_name||'" DROP SUPPLEMENTAL LOG GROUP GGS_'||objId;
    begin
        execute immediate (stmt);
    exception
        when others then null; 
    end;




    -- create new group
    stmt := 'alter table "'||tab.owner||'"."'||tab.table_name||'" add supplemental log group GGS_'||objId||' ('||cols||') always /* GOLDENGATE_DDL_REPLICATION */';
    begin
        execute immediate (stmt);
        tot:=tot+1;
    exception
        when others then
            -- table can be BIN$, i.e. recyclebin in which case it's no longer
            -- found in dba_recyclebin, it does exist (you can desc it), but it will be reported
            -- as non-existenti. Even if table doesn't exist for any other reason, we'd want
            -- to continue.
            if sqlcode <> -942 then
                -- continue;
                goto log_group_search;
            else
                tot:=tot+1;
            end if;
    end;



    --dropping the old one, note this can never drop the new style one
    stmt:= 'alter table "'||tab.owner||'"."'||tab.table_name||'" drop supplemental log group "'||tab.log_group_name||'"';
    begin
        execute immediate (stmt);
        tot:=tot+1;
    exception
        when others then
        -- table can be BIN$, i.e. recyclebin
        if sqlcode <> -942 then
            null;
        else
            tot:=tot+1;
        end if;
    end;
    <<log_group_search>>
    NULL;
end loop;


-- check if there was an error
-- we were in the loop cnt times, and to be ok, we must have had 2*cnt successes (tot=2*cnt) 
if tot=2*cnt then
    null;
else
    null;
end if;
exception
when others then
dbms_output.put_line ('Error in script: '||SQLERRM);
end;
/
spool off
set verify on

