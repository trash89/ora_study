-- Copyright (c) 2005, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- Program description:
-- Installation script for GoldenGate Replicat Sequence support
-- REFER TO GOLDENGATE DOCUMENTATION PRIOR TO USING THIS SCRIPT
--
-- IMPORTANT, NOTE:
-- 1. If executed from SQL*Plus, must be connected as the SYSDBA user from the
--    same directory where SQL scripts
--    are located. 
-- 
--
-- Example of usage:
--
--      SQL> @sequence
--
--
-- Revision history
--
--  10/24/2011 - SMIJATOV
--     bug 12685825: maxseqdistance is now a percentage of sequence space
--  08/18/2011 - SMIJATOV
--     bug 12847248: if sequence doesn't have two cycles, don't update. Also 
--                   revert session schema on return.
--  07/22/2011 - SMIJATOV
--     bug 12376294: non-existent user causes script to falsely succeed
--  03/04/2011 - SMIJATOV
--     bug 9428942: rework sequences on target side, add cycle sequences, add 
--     FLUSH SEQUENCE to GGSCI
--

define setup_error_code = '-20783' -- error code in custom error codes space for raising application error

-- do not show substitutions in progress
SET verify OFF
SET FEEDBACK OFF


-- check if user has privileges, if not, exit with message
WHENEVER SQLERROR EXIT
variable isdba VARCHAR2(30)
variable sysdba_message VARCHAR2 (2000)
BEGIN
    :sysdba_message := chr(10) || 'Oracle GoldenGate Oracle Sequence setup: ' || chr(10) ||
      '*** Currently logged user does not have SYSDBA privileges, or not logged AS SYSDBA! ' || chr(10) ||
      '*** Please login as SYSDBA.' || chr(10);

    SELECT sys_context('userenv','ISDBA') INTO :isdba FROM DUAL; -- use network method  for isdba determination

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
spool sequence_spool.txt
STORE SET 'sequence_set.txt' REPLACE
SET termout ON

-- do not show substitutions in progress
SET verify OFF 
SET FEEDBACK OFF


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
                 chr(10) || 'GoldenGate Sequence Replication setup: ' || chr(10) ||
                 '*** Cannot find user &gg_user' || chr(10) ||
                 '*** Please enter existing user name.' || chr(10));
        END;
/
WHENEVER SQLERROR CONTINUE

set termout off
GRANT SELECT ON sys.seq$ TO "&gg_user";
GRANT SELECT ON sys.user$ TO "&gg_user";
GRANT SELECT ON sys.obj$ TO "&gg_user";
GRANT SELECT ON dba_sequences TO "&gg_user";


DROP PROCEDURE "&gg_user".replicateSequence;
DROP PROCEDURE "&gg_user".updateSequence;
DROP PROCEDURE "&gg_user".getSeqFlush;
DROP PROCEDURE "&gg_user".seqTrace;
set termout on


/*
PROCEDURE seqTrace
Outputs trace to trace file
Also, if serveroutput is on, displays code to trace (to find problems with trace itself)
param[in] traceStmt SQL statatement (exec...) to perform trace
param[in] traceUser name of schema under which to perform trace
*/
CREATE OR REPLACE PROCEDURE "&gg_user".seqTrace (
   traceStmt IN VARCHAR2,
   traceUser IN VARCHAR2)
AUTHID current_user
IS
BEGIN 
    dbms_output.put_line(traceStmt);
    EXECUTE IMMEDIATE (traceStmt);
END;
/

/*
PROCEDURE getSeqFlush
Creates sequence flushing DDL statement
param[in] seqName name of sequence
param[in] isCycle 1 if sequence is cycling
param[out] flushStmt this is resulting ALTER SEQUENCE statement
param[in] isTrace 1 if tracing is on
param[in] traceUser name of tracing user

Note: the DDL built is idempotent, and it only serves to make
sure next NEXTVAL will move HWM. This is only called if
DBOPTIONS _AUTOMATICSEQUENCEFLUSH. The default is no flush, and
the sequence update script should be used on switchover.
Note: for tracing, Oracle DDL replication must be installed, but not enabled
*/

CREATE OR REPLACE PROCEDURE "&gg_user".getSeqFlush (
   seqName IN VARCHAR2,
   isCycle IN NUMBER,
   flushStmt OUT VARCHAR2,
   isTrace IN NUMBER,
   traceUser IN VARCHAR2)
AUTHID current_user
IS
BEGIN 
    IF isTrace = 1 THEN
       "&gg_user".seqTrace ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''before building flush''); END;', traceUser);
    END IF;
    SELECT 'ALTER SEQUENCE "' || seqName || '" ' ||  decode (isCycle, 1, 'CYCLE', ' NOCYCLE  /* GOLDENGATE_DDL_REPLICATION */') 
    INTO flushStmt
    FROM DUAL;
    IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''flush stmt is ' || flushStmt || '''); END;', traceUser);
    END IF;
END;
/

/*
PROCEDURE replicateSequence
Replicates source sequence update to target. This procedure is called from replicat.
For debugging purposes with Oracle technical support, it can be called standalone.

param[in]   sourceHWM  source high water mark
param[in]   maxDistance  maximum percentage of sequence space (ahead) we will allow  for target
param[in]   seqFlush if 1, we will flush sequence each time this procedure 
            is called, meaning after that, NEXTVAL will move HWM
param[in]   seqOwner owner of sequence
param[in]   seqUpdate source maximum update (cache*incrementby*rac)
param[in]   seqName name of sequence
param[in]   loggedUser name of user logged on
param[in]   racTarget number of rac nodes on target
param[in]   isTrace 1 if this is to be trace
param[in]   traceUser name of trace user. This is a schema in which OGG objects
            are installed

Note: maxDistance is DBOPTIONS _MAXSEQUENCEDISTANCE. If trace is 1, then
DDLOPTIONS _TRACESEQUENCE is used.
_AUTOMATICSEQUENCEFLUSH is off by default, but for RAC is always used to make sure
all instances of RAC are next to HWM.
Tracing is done through EXECUTE IMMEDIATE because having PLSQL OGG tracing facilities
is not a requirement. Without such method, compilation would fail if they are not
present.
Note: for tracing, Oracle DDL replication must be installed, but not enabled
*/
CREATE OR REPLACE PROCEDURE "&gg_user".replicateSequence (
   sourceHWM IN  NUMBER,
   maxDistance  IN NUMBER,
   seqFlush IN  NUMBER,
   seqOwner IN  VARCHAR2,
   seqUpdate IN  NUMBER,
   seqName IN  VARCHAR2,
   loggedUser IN  VARCHAR2,
   racTarget IN  NUMBER,
   isTrace IN  NUMBER,
   traceUser IN  VARCHAR2
) 
AUTHID current_user
IS 
PRAGMA autonomous_transaction;
newSeqVal NUMBER;
HWMTarget NUMBER;
HWMTargetNext NUMBER;
maxVal NUMBER;
minVal NUMBER;
cnt NUMBER;
numberOfSimulatedHWTargetMoves NUMBER;
simulateHWTargetStart NUMBER;
simulateHWTargetEnd NUMBER;
HWMOnSource NUMBER;
isFound NUMBER;
distance NUMBER;
firstPass NUMBER;
isCycle NUMBER;
incBy NUMBER;
flushStmt VARCHAR2(1000);
objId NUMBER;
sCache NUMBER;
mDist NUMBER;
BEGIN
   firstPass := 1;
   
   IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''################ STARTING SEQUENCE REPLICATION FOR '' || '''|| seqOwner || '.' || seqName ||  '''); END;', traceUser);
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''INPUT IS: sourceHWM '' || ''' 
       || to_char(sourceHWM) || ''' || '' maxDistance '' || ''' || to_char(maxDistance) ||  ''' || '' seqFlush '' || ''' || to_char(seqFlush) ||  ''' || '' seqOwner '' || ''' || seqOwner || ''' || '' seqUpdate '' || ''' || to_char(seqUpdate) || ''' || '' seqName '' || ''' || to_char(seqName) || ''' || '' loggedUser '' || ''' || to_char(loggedUser) || ''' || '' racTarget '' || ''' || racTarget || ''' || '' isTrace '' || ''' || to_char(isTrace) || ''' || '' traceUser '' || ''' || traceUser ||'''); END;', traceUser);
   END IF;

 
   -- set current schema to sequence owner. This is to avoid issues when there is a table name same as schema
   -- name in which case sequence name is treated a column to table name and things fail
   EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || seqOwner || '"');


   -- we don't pass object id as parameter because sequences reuse object id (unlike other oracle objects)
   -- because of that we could update wrong oracle sequence if object is dropped and recreated exactly on
   -- target. This is fast as it uses system indexes.
   BEGIN
        SELECT 
	    	s.HIGHWATER, s.MINVALUE, s.MAXVALUE, s.INCREMENT$, s.CYCLE# , o.OBJ#, s.CACHE
        INTO HWMTarget, minVal, maxVal, incBy, isCycle, objId, sCache
	    FROM SYS.SEQ$ s, SYS.OBJ$ o, SYS.USER$ u
		WHERE u.name=seqOwner AND o.owner#=u.user# AND o.name=seqName AND s.obj#=o.obj#;

        -- if NOCACHE, for our purposes we need to use 1
        IF sCache = 0 THEN
            sCache := 1;
        END IF;

        IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''Target Sequence properties, object id '' || '''||  to_char(objId) ||  ''' || '' minvalue '' || ''' || to_char(minVal) || ''' || '' maxvalue '' || ''' || to_char(maxVal) || ''' || '' incBy '' || ''' || to_char(incBy) || ''' || '' isCycle '' || ''' || to_char(isCycle) || ''' || '' HWM '' || ''' || to_char(HWMTarget) || ''' || '' cache '' || ''' || sCache || ''' || '' ********************''); END;', traceUser);
       END IF;

   EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- sequence not found, this will be reflected in error message
            raise_application_error (&setup_error_code,  chr(10) || 'Sequence ' || seqOwner || '.' || seqName || ' not found.' || chr(10)); 
        WHEN OTHERS THEN
            -- there was some other issue, for example shutdown in progress
            raise_application_error (&setup_error_code,  chr(10) || 'Error in getting sequence properties for ' || seqOwner || '.' || seqName || ' :' || SQLERRM || chr(10)); 
   END;


   IF isCycle = 1 and abs(sCache*incBy) > ceil((maxVal - minVal)/2) THEN
       IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''returning as there is not at least two cycles in a sequence''); END;', traceUser);
       END IF;
       EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || loggedUser || '"');
       RETURN;
   END IF;
      

       IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''initial target hw='' || ''' ||  to_char(HWMTarget) || '''); END;', traceUser);
       END IF;


   IF isCycle <> 1 THEN
       -- for non-cycle sequence, check if there is nothing to do (sequence is ahead by enough)
       IF incBy > 0 THEN
           -- case of non-cycle and positive increment by
           IF HWMTarget >= (sourceHWM + seqUpdate) THEN

               IF isTrace = 1 THEN
                   "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''nothing to do, exiting because sourceHWM+seqUpdate='' || ''' ||  to_char(sourceHWM+seqUpdate) || '''); END;', traceUser);
               END IF;

               -- perform flush if _AUTOMATICSEQUENCEFLUSH is used or RAC on target
               IF seqFlush = 1 OR racTarget > 1 THEN
                   "&gg_user".getSeqFlush (seqName, isCycle, flushStmt, isTrace, traceUser);
                    IF isTrace = 1 THEN
                         "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''performing flush''); END;', traceUser);
                    END IF;
                   EXECUTE IMMEDIATE (flushStmt);
               END IF;
               EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || loggedUser || '"');
               RETURN;
           END IF;
       ELSE
           -- case of non-cycle and negative increment by
           IF HWMTarget <= (sourceHWM + seqUpdate) THEN

           IF isTrace = 1 THEN
               "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''nothing to do, exiting because sourceHWM+seqUpdate='' || ''' ||  to_char(sourceHWM+seqUpdate) || '''); END;', traceUser);
           END IF;

               -- perform flush if _AUTOMATICSEQUENCEFLUSH is used or RAC on target
               IF seqFlush = 1  OR racTarget > 1 THEN
                   "&gg_user".getSeqFlush (seqName, isCycle, flushStmt, isTrace, traceUser);
                    IF isTrace = 1 THEN
                         "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''performing flush''); END;', traceUser);
                    END IF;
                   EXECUTE IMMEDIATE (flushStmt);
               END IF;
               EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || loggedUser || '"');
               RETURN;
           END IF;
       END IF;
   ELSE
       -- this is for cycle sequences. Here we go to calculate how many NEXTVALS would we need to do to catch up
       -- with source. 
       IF incBy > 0 THEN
           -- cycle and positive increment by. Check relation between target hwm and source hwm. Depending
           -- on where target hwm is relative to source hwm, we deduce the distance target hwm would need to
           -- cross to reach source hwm.
           IF HWMTarget <= sourceHWM THEN
               distance := ABS(sourceHWM - HWMTarget);
           ELSE
               distance := (maxVal - minVal) - ABS(sourceHWM - HWMTarget);
           END IF;
       ELSE
           IF HWMTarget < sourceHWM THEN
               distance := (maxVal - minVal) - ABS(sourceHWM - HWMTarget);
           ELSE
               distance := ABS(sourceHWM - HWMTarget);
           END IF;
       END IF;

       IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''source HWM='' || ''' || to_char(sourceHWM) || ''' ||'', target HWM='' || '''|| to_char(HWMTarget) || ''' ||'', distance='' || ''' || to_char(distance) || ''' ||'', maxDistance='' || ''' || to_char(maxDistance) || '''); END;', traceUser);
       END IF;

       -- maxDistance is the percentage of sequence space that tells us how much ahead we will
       -- let target be.
       -- convert maxDistance (MAXSEQUENCEDISTANCE, which is a percentage) to  number of NEXTVALS
       mDist := floor((maxDistance*(maxVal - minVal)) /100);

       -- per design doc, the minimum value for mDist is CACHE*INCBY
       IF mDist < abs(sCache*incBy) THEN
            mDist := abs(sCache*incBy);
       END IF;
       IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''maxDistance calculated='' || ''' || to_char(mDist) || '''); END;', traceUser);
       END IF;



       -- this is the algorithm from the design doc. TRUE means don't move the target.
        /*
          return TRUE if source_hwm + cache*increment < maxvalue AND
                      target_hwm >= source_hwm+cache*increment AND
                       target_hwm <= (source_hwm + delta) 
          return TRUE if source_hwm < maxvalue AND
                      source_hwm+cache*increment >= maxvalue AND (
                      target_hwm > maxvalue OR 
                      minvalue+increment <= target_hwm <= minvalue +delta)
        */

       -- the above calculates if target is between sourcehwm and sourcehwm+delta
       -- the 'distance' value is the distance from target to source in NEXTVALS.
       -- mDist is the  maximum distance we will alow target to be ahead of source before moving target
       -- based on the MAXSEQUENCEDISTANCE param.
       -- therefore, if distance is greater than (maxVal-minVal)-mDist, do not do anything.

       IF distance >= (maxVal - minVal) - mDist THEN
        
           IF isTrace = 1 THEN
               "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''nothing to do, exiting because target is ahead by less than maxsequencedistance ''); END;', traceUser);
           END IF;

           -- this is flush_sequence from the design doc, in case we do nothing.
           -- flush if option is given for it
           IF seqFlush = 1 OR racTarget > 1 THEN
               "&gg_user".getSeqFlush (seqName, isCycle, flushStmt, isTrace, traceUser);
                IF isTrace = 1 THEN
                     "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''performing flush''); END;', traceUser);
                END IF;
               EXECUTE IMMEDIATE (flushStmt);
           END IF;
           EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || loggedUser || '"'); 
           RETURN;
       END IF;
   END IF;




   -- isFound will be 1 for cyclic sequences when we reached the source hwm and passed it.
   isFound := 0;
   WHILE 1=1 LOOP 
       
       IF isFound = 1 THEN
          EXIT;
       END IF;

       -- this is performance optimization: first time through here we DO NOT do NEXTVAL simply because we
       -- may not have to. Next time around though we must (the rest of the loop would exit above at isFound=1
       -- if didn't have to)
       IF firstPass = 0 THEN
          EXECUTE IMMEDIATE 'SELECT "' || seqName || '".NEXTVAL FROM DUAL' INTO newSeqVal;
          IF isTrace = 1 THEN
              "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''LAST TARGET NEXTVAL:'' || ''' || to_char(newSeqVal) || '''); END;', traceUser);
          END IF;
       ELSE
          firstPass := 0;
       END IF;

       -- get current HWM on target
       SELECT HIGHWATER INTO HWMTargetNext FROM SYS.SEQ$ WHERE OBJ#=objId;


       IF isCycle <> 1 THEN
           -- check for non-cycle sequence, if we're ahead enough, if so done
           IF incBy > 0 THEN
               -- non-cyle and positive increment
               IF HWMTargetNext >= (sourceHWM + seqUpdate) THEN
                   IF isTrace = 1 THEN
                       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''exiting after target is greater or equal than source+update, target = '' || ''' || to_char(HWMTargetNext) || ''' || '' sourceHWM+seqUpdate='' || ''' || to_char(sourceHWM + seqUpdate) || '''); END;', traceUser);
                   END IF;
                   EXIT;
               END IF;
           ELSE
               -- non-cycle and negative increment
               IF HWMTargetNext <= (sourceHWM + seqUpdate) THEN
                   IF isTrace = 1 THEN
                       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''exiting after target is lesser or equal than source+update, target = '' || ''' || to_char(HWMTargetNext) || ''' || '' sourceHWM+seqUpdate='' || ''' || to_char(sourceHWM + seqUpdate) || '''); END;', traceUser);
                   END IF;
                   EXIT;
               END IF;
           END IF;
       ELSE

      -- the code below implements the main loop from design doc:
      /*
        stop_value := get_target_stop_value();
        do
        {
           current_value := select sequence.nextval();
        } while (current_value <> stop_value)
      */
      -- the algorithm below computes the number of NEXTVALS needed to take to
      -- catch up with source
      -- the algorithm above (from design doc) goes in the loop until the sequence value
      -- catches up the source
      -- so the two algorithms are equivalent
      -- the algorithm here first simulates movement of target NEXTVAL by using an integer counter
      -- (without actually moving sequence). This has the advantage of avoiding pitfalls in
      -- calculating boundary cases. Then NEXTVALs are called.


           -- the following for CYCLE sequence
           HWMOnSource := sourceHWM;
           IF isTrace = 1 THEN
               "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''hwm on source=''||''' || to_char(HWMOnSource) || '''); END;', traceUser);
               "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''hwm on target after one NEXTVAL=''||'''||to_char(HWMTargetNext)||'''); END;', traceUser);
           END IF;


           -- simulateHWTargetStart is 'previous' HW on target. The simulatHWTargetEnd is the 'current' HW.
           -- what we do here is as follows: we move sequence forward, and with each move that doesn't change
           -- HWM we just keep going (because we can't reach source HWM unless we move target HWM). Note that
           -- first time around we don't do NEXTVAL on a chance that we've already reached source HWM. In this
           -- first look these two simulateHW.. are equal. But otherwise, one is previous and the other is current
           -- HWM. Now, before we actually move sequence by means of NEXTVAL, we will simulate movement from previous
           -- to current. We do this in order to make sure we catch if one of those moves will reach source HWM. This is
           -- because our final goal is to make target NEXTVAL EQUAL OR AHEAD OF SOURCE HWM! Why simulation like this?
           -- For one, it's just memory counter so it's fast. For another, checking source HWM is in between gets 
           -- tricky when number intervals wrap around. And finally making a full trace of how we arrieved at source 
           -- HWM becomes much clearer then if we used a number of IFs that break down the cyclical space of sequence
           -- numbers into chunks. The difference is minimal but process is much clearer with this method. And the
           -- least but not the last, we do need to issue a string of NEXTVALS in the same fashion anyway.
           simulateHWTargetStart := HWMTarget;
           simulateHWTargetEnd := HWMTargetNext;

           -- we normalize HW numbers to MINVAL/MAXVAL boundaries. Because we only look at real NEXTVALs
           -- this is what we need to do for proper comparisions. While HWM can go outside MINVAL/MAXVAL
           -- NEXTVAL cannot.
           IF incBy > 0 THEN
               IF HWMOnSource > maxVal THEN
                   HWMOnSource := maxVal;
               END IF;
           ELSE
               IF HWMOnSource < minVal THEN
                   HWMOnSource := minVal;
               END IF;
           END IF;
           IF incBy > 0 THEN
               IF simulateHWTargetEnd > maxVal THEN
                  simulateHWTargetEnd := maxVal;
               END IF;
           ELSE
               IF simulateHWTargetEnd < minVal THEN
                  simulateHWTargetEnd := minVal;
               END IF;
           END IF;
           IF incBy > 0 THEN
               IF simulateHWTargetStart > maxVal THEN
                   simulateHWTargetStart := maxVal;
               END IF;
           ELSE
               IF simulateHWTargetStart < minVal THEN
                   simulateHWTargetStart := minVal;
               END IF;
           END IF;
           numberOfSimulatedHWTargetMoves := 0;



           WHILE 1=1 LOOP
               IF isTrace = 1 THEN
                  "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''Simulation of sequence move: Start=''||'''||to_char(simulateHWTargetStart)||'''||'', hwEnd=''||'''||to_char(simulateHWTargetEnd)||'''|| '', onSource=''||'''||to_char(HWMOnSource)||''' || '', traversed=''||'''||to_char(numberOfSimulatedHWTargetMoves)||'''); END;', traceUser);
               END IF;

               -- if target HWM were to reach source HWM, and if starting point for target HWM is not the
               -- same as the current simulated one, then we must perform actual NEXTVALs to reach that point
               IF simulateHWTargetStart = HWMOnSource AND simulateHWTargetStart <> simulateHWTargetEnd THEN
                   isFound := 1;
                   -- since sequence moves by increment by, and we examine the sequence space in chunks of 1,
                   -- we need to calculate the number of actual sequence moves (it's equal or lesser than
                   -- the number of simulated moves)
                   IF numberOfSimulatedHWTargetMoves MOD ABS (incBy) = 0 THEN
                       numberOfSimulatedHWTargetMoves := numberOfSimulatedHWTargetMoves / ABS(incBy);
                   ELSE
                       numberOfSimulatedHWTargetMoves := numberOfSimulatedHWTargetMoves / ABS(incBy) + 1;
                   END IF;

                   -- perform the moves to match the simulated ones (which reached the source properly)
                   FOR cnt IN 1..numberOfSimulatedHWTargetMoves LOOP
                       EXECUTE IMMEDIATE 'SELECT "' || seqName || '".NEXTVAL FROM DUAL' INTO newSeqVal ;
                       IF isTrace = 1 THEN
                           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''Follow-through on simulation: TARGET NEXTVAL:''||'''||to_char(newSeqVal)||'''); END;', traceUser);
                       END IF;
                   END LOOP;
                   IF isTrace = 1 THEN
                       EXECUTE IMMEDIATE 'SELECT HIGHWATER FROM SYS.SEQ$ WHERE OBJ#=' ||objId INTO HWMTargetNext;
                        "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''New target hwm:''||'''||to_char(HWMTargetNext)||'''); END;', traceUser);
                   END IF;
                   EXIT;
               END IF;

               -- we're here if moved
               IF simulateHWTargetStart = simulateHWTargetEnd THEN
                   HWMTarget := HWMTargetNext;
                   IF isTrace = 1 THEN
                           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''Sync not accomplished yet, status is: simulated hwm on target Start=''||'''||to_char(simulateHWTargetStart)||'''||'', simulated hwm on target End=''||'''||to_char(simulateHWTargetEnd)||'''||'', hwm onSource=''||'''||to_char(HWMOnSource)||'''||'', traversed to reach source in simulation=''||'''||to_char(numberOfSimulatedHWTargetMoves)||'''); END;', traceUser);
                   END IF;
                   EXIT;
               END IF;

               -- depending on increment by, move our sequence simulator exactly one ahead. We go by one
               -- because INCREMENTBY has advisory value only 
               IF incBy > 0 THEN
                   simulateHWTargetStart := simulateHWTargetStart + 1;
               ELSE
                   simulateHWTargetStart := simulateHWTargetStart - 1;
               END IF;

               -- record how mnay simulated moves (by movement of one) we did
               numberOfSimulatedHWTargetMoves := numberOfSimulatedHWTargetMoves + 1;


               -- so after we moved forward (simulated) we may hit MAX or MINVALUE. We need to wrap around
               IF incBy > 0 THEN
                   IF simulateHWTargetStart > maxVal THEN
                       simulateHWTargetStart := minVal;
                   END IF;
               ELSE
                   IF simulateHWTargetStart < minVal THEN
                       simulateHWTargetStart := maxVal;
                   END IF;
               END IF;
           END LOOP;
       END IF;
   END LOOP;

   -- flush if needed
   IF seqFlush = 1 OR racTarget > 1 THEN
       "&gg_user".getSeqFlush (seqName, isCycle, flushStmt, isTrace, traceUser);
       IF isTrace = 1 THEN
            "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''performing flush''); END;', traceUser);
       END IF;
       EXECUTE IMMEDIATE (flushStmt);
   END IF;

   -- return schema to logged on user 
   EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="' || loggedUser || '"');

   IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEREP'', ''################  ENDING FOR '' ||'''|| to_char(objId) ||'''); END;', traceUser);
   END IF;
EXCEPTION 
   WHEN OTHERS THEN 
   raise_application_error (&setup_error_code,  chr(10) || SQLERRM || chr(10));
END;
/


/*
PROCEDURE updateSequence
Updates all sequences in given schema so that HWM is moved forward by a minimal amount
Thus if performed just prior to switchover, all sequences will produce HWM change
which will affect synchronization with target sequences through extract and replicat.

param[in]    schemaName name of schema for which to update sequences
param[in]    seqName name of sequence
param[in]    isTrace 1 if to trace
param[in]    traceUser name of trace user
param[in]    sessUser session user (of caller) 

Note: for tracing, Oracle DDL replication must be installed, but not enabled
Note: if seqName is empty, we will update HWM for all sequences in schemaName.
Note: session schema is properly restored
*/
CREATE OR REPLACE PROCEDURE "&gg_user".updateSequence (
	schemaName IN VARCHAR2, 
	seqName IN VARCHAR2, 
	isTrace IN NUMBER, 
	traceUser IN VARCHAR2,
    sessUser IN VARCHAR2)
AUTHID current_user
IS
	seqVal NUMBER;
    cyc VARCHAR2(100);
    lastN NUMBER;
    userN NUMBER;
    oraSeqName VARCHAR2(100);
BEGIN
	IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''################ BEGIN bumping up HWM, schema='' || ''' ||  schemaName || ''' || '' seq '' || ''' || seqName || '''); END;', traceUser);
	END IF;
    -- replace OGG wildcards with SQLPLUS (do not change the meaning of % and _)
    -- we don't replace % with \% and _ with \_. We could but it's not done anywhere in OGG
    oraSeqName := seqName;
    IF oraSeqName IS NOT NULL THEN
        oraSeqName := REPLACE (oraSeqName, '*', '%');
        oraSeqName := REPLACE (oraSeqName, '?', '_');
    END IF;
    IF oraSeqName = '' OR oraSeqName IS NULL THEN
        oraSeqName := '%';
    END IF;
	IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''new seqname '' || ''' ||  oraSeqName || '''); END;', traceUser);
	END IF;
    -- check if schema exists
    SELECT COUNT(*) INTO userN FROM SYS.USER$ where NAME=schemaName;
    IF userN = 0 THEN
	    IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''schema does not exist ='' || ''' ||  schemaName || '''); END;', traceUser);
    	END IF;
        RETURN;
    END IF;
		
	-- look for all sequences in schema in bring them to be last_number (HWM). This will work because
	-- if nextval reaches it, it will force an update. This update will move to the target system
	-- and bring sequences in "sync"
	FOR seq IN (SELECT sequence_owner, sequence_name, last_number, cycle_flag FROM DBA_SEQUENCES WHERE SEQUENCE_OWNER = schemaName AND SEQUENCE_NAME LIKE oraSeqName) LOOP
        IF seq.cycle_flag = 'Y' THEN
            cyc := 'CYCLE';
        ELSE
            cyc := 'NOCYCLE';
        END IF;
        -- use setting schema to avoid problems with table names equal to that of schema
    	EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="'||schemaName||'"');	
    	IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''set session schema='' || ''' ||  seq.sequence_owner || '''); END;', traceUser);
	    END IF;
		EXECUTE IMMEDIATE 'ALTER SEQUENCE "'|| seq.sequence_name || '" ' || cyc;
	    EXECUTE IMMEDIATE 'SELECT "'|| seq.sequence_name || '".nextval FROM DUAL' INTO seqVal;
	    SELECT last_number INTO lastN FROM DBA_SEQUENCES WHERE SEQUENCE_OWNER=seq.sequence_owner AND
               SEQUENCE_NAME=seq.sequence_name;
			
		IF isTrace = 1 THEN
			"&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''seqName='' || ''' ||  
				seq.sequence_name || ''' || '' old HWM = '' ||' || seq.last_number || ' || '' new HWM = '' ||' || 
				lastN || '); END;', traceUser);
		END IF;
    	EXECUTE IMMEDIATE ('ALTER SESSION SET CURRENT_SCHEMA="'||sessUser||'"');	
    	IF isTrace = 1 THEN
           "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''restore  session schema to '' || ''' || sessUser || '''); END;', traceUser);
	    END IF;
			
	END LOOP;
	
	IF isTrace = 1 THEN
       "&gg_user".seqTrace  ('BEGIN "' || traceUser || '".trace_put_line(''SEQUENCEUPD'', ''################ END schema='' || ''' ||  schemaName || '''); END;', traceUser);
	END IF;
END;
/


prompt
prompt UPDATE_SEQUENCE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'UPDATESEQUENCE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'UPDATESEQUENCE' AND TYPE = 'PROCEDURE';


prompt
prompt GETSEQFLUSH
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'GETSEQFLUSH' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'GETSEQFLUSH' AND TYPE = 'PROCEDURE';

prompt
prompt SEQTRACE
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'SEQTRACE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'SEQTRACE' AND TYPE = 'PROCEDURE';

prompt
prompt REPLICATE_SEQUENCE STATUS:
SELECT substr(to_char(line) || '/' || to_char(position), 1, 10) "Line/pos", text "Error" 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'REPLICATESEQUENCE' AND TYPE = 'PROCEDURE'
UNION
SELECT decode(COUNT(*), 0, 'No errors'), decode(COUNT(*), 0, 'No errors') 
FROM dba_errors WHERE owner = '&gg_user' AND name = 'REPLICATESEQUENCE' AND TYPE = 'PROCEDURE';

SELECT DECODE (COUNT(*), 0, 'SUCCESSFUL installation of Oracle Sequence Replication support',
	'ERRORS in Oracle Sequence  Replication Support') "STATUS OF SEQUENCE SUPPORT"
    FROM dba_errors WHERE owner = '&gg_user' AND (name = 'REPLICATESEQUENCE' OR
		name = 'UPDATESEQUENCE') AND TYPE = 'PROCEDURE';


SET verify ON
SET FEEDBACK ON



