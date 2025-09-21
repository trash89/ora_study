#!/bin/bash

#. /home/oracle/scripts/setEnv.sh

if [ -z ${ORACLE_HOME} ]; then
   echo "ORACLE_HOME is not defined, check variables !"
   exit 1
fi

if [ -z ${ORACLE_SID} ]; then
   echo "ORACLE_SID is not defined, check variables !"
   exit 1
fi

DAY=$(date +%Y_%m_%d)

-- get the path of DIRECTORY data_pump_dir
cat <<END > /tmp/get_data_pump_dir.sql
connect / as sysdba
set lines 200 pages 0 echo off head off trim off trims off feed off
rem alter session set container=pdb1;
SELECT directory_path FROM dba_directories WHERE directory_name='DATA_PUMP_DIR';
exit
END
vdir_path=$(${ORACLE_HOME}/bin/sqlplus -L -S /nolog @/tmp/get_data_pump_dir.sql | tr -d '\r' | tr -d ' ' | tr -d '\n')
rm -f /tmp/get_data_pump_dir.sql
echo $vdir_path

# First create export dump file with metadata only
cat <<END > $vdir_path/dump_meta_EXP.par
directory       = data_pump_dir
dumpfile        = ${ORACLE_SID}.${DAY}.dmp
logfile         = ${ORACLE_SID}.${DAY}_meta_EXP.log
content         = metadata_only
full            = y
exclude         = statistics
# for 10g,11g
#FLASHBACK_TIME  = "TO_TIMESTAMP(TO_CHAR(systimestamp,'DD-MM-YYYY HH24:MI:SS.FF'), 'DD-MM-YYYY HH24:MI:SS.FF')"
# for 12c,19c
FLASHBACK_TIME  = systimestamp
END
# $ORACLE_HOME/bin/expdp \"/ as sysdba\" parfile=$vdir_path/dump_meta_EXP.par
$ORACLE_HOME/bin/expdp system/manager parfile=$vdir_path/dump_meta_EXP.par

# Now create DDL file FROM the export dump file.
cat <<END > $vdir_path/dump_meta_IMP.par
directory   = data_pump_dir
dumpfile    = ${ORACLE_SID}.${DAY}.dmp
logfile     = ${ORACLE_SID}.${DAY}_meta_IMP.log
SQLFILE     = ${ORACLE_SID}.${DAY}.sql
#schemas    = scott
transform   = storage:n
transform   = segment_attributes:n
END
# $ORACLE_HOME/bin/impdp \"/ as sysdba\" parfile=$vdir_path/dump_meta_IMP.par
$ORACLE_HOME/bin/impdp system/manager parfile=$vdir_path/dump_meta_IMP.par

exit 0
