DROP TABLE "GGS_OWNER"."GGS_DDL_RULES";

CREATE TABLE "GGS_OWNER"."GGS_DDL_RULES"
               ( SNO NUMBER PRIMARY KEY, 
               OBJ_NAME VARCHAR2(200),OWNER_NAME VARCHAR2(200),
               BASE_OBJ_NAME VARCHAR2(200), BASE_OWNER_NAME VARCHAR2(200),
               BASE_OBJ_PROPERTY NUMBER, OBJ_TYPE NUMBER,
               COMMAND VARCHAR2(50),
               INCLUSION NUMBER);

DROP TABLE "GGS_OWNER"."GGS_DDL_RULES_LOG";

CREATE TABLE "GGS_OWNER"."GGS_DDL_RULES_LOG"
               ( SNO NUMBER , 
               OBJ_NAME VARCHAR2(200),OWNER_NAME VARCHAR2(200),
               BASE_OBJ_NAME VARCHAR2(200), BASE_OWNER_NAME VARCHAR2(200),
               BASE_OBJ_PROPERTY NUMBER, OBJ_TYPE NUMBER,
               COMMAND VARCHAR2(50));

DROP TABLE "GGS_OWNER"."GGS_TEMP_COLS";

CREATE GLOBAL TEMPORARY TABLE "GGS_OWNER"."GGS_TEMP_COLS" (
            seqNo            NUMBER NOT NULL, 
            colName        VARCHAR2(100), 
            nullable          NUMBER, 
            virtual          NUMBER, 
            udt            NUMBER, 
            isSys          NUMBER, 
            primary key (seqNo, colName) 
            ) on commit preserve rows;

DROP TABLE "GGS_OWNER"."GGS_TEMP_UK";

CREATE GLOBAL TEMPORARY TABLE "GGS_OWNER"."GGS_TEMP_UK" (
            seqNo            NUMBER NOT NULL, 
            keyName        VARCHAR2(100), 
            colName        VARCHAR2(100), 
            nullable       NUMBER, 
            virtual           NUMBER, 
            udt            NUMBER, 
            isSys            NUMBER, 
            primary key (seqNo, keyName, colName) 
            ) on commit preserve rows;

TRUNCATE TABLE "GGS_OWNER"."GGS_STICK";

DROP TABLE "GGS_OWNER"."GGS_STICK";

CREATE GLOBAL TEMPORARY TABLE "GGS_OWNER"."GGS_STICK" (
            property            VARCHAR2(100) NOT NULL, 
            value			 VARCHAR2(100), 
            primary key (property)
            ) on commit preserve rows;

DROP TABLE "GGS_OWNER"."GGS_SETUP";

CREATE TABLE "GGS_OWNER"."GGS_SETUP" (
            property        VARCHAR2(100), 
            value          VARCHAR2 (4000), 
            constraint GGS_SETUP_ukey unique (property) 
);

insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            'DDL_TRACE_LEVEL',
            0);

insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            'DDL_SQL_TRACING',
            0);

insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            '_USEALLKEYS',
            0);

insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            'ALLOWNONVALIDATEDKEYS',
            0);
insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            '_LIMIT32K',
            0);
insert into "GGS_OWNER"."GGS_SETUP" (
             property,
             value)
            values ( 
            'DDL_STAYMETADATA',
            'OFF');
commit;

exec "GGS_OWNER".create_trace;
exec "GGS_OWNER".trace_put_line ('DDL', 'Initial setup starting');

DROP SEQUENCE "GGS_OWNER"."GGS_DDL_SEQ";
CREATE SEQUENCE "GGS_OWNER"."GGS_DDL_SEQ" 
            INCREMENT BY 1 
            CACHE 500 
            MINVALUE 1 
            MAXVALUE 9999999999999999999999999999 CYCLE;

DROP TABLE "GGS_OWNER"."GGS_DDL_HIST_ALT";
CREATE TABLE "GGS_OWNER"."GGS_DDL_HIST_ALT" (
            altObjectId		NUMBER, 
            objectId	NUMBER, 
            optime			CHAR(19) NOT NULL);

CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_ALT_u1" ON  
            "GGS_OWNER"."GGS_DDL_HIST_ALT" (
            objectId, altObjectId);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_ALT_u2" ON  
            "GGS_OWNER"."GGS_DDL_HIST_ALT" (
            optime);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_ALT_u3" ON  
            "GGS_OWNER"."GGS_DDL_HIST_ALT" (
            altObjectId, objectId);

DROP TABLE "GGS_OWNER"."GGS_DDL_HIST";
CREATE TABLE "GGS_OWNER"."GGS_DDL_HIST" (
            seqNo            NUMBER NOT NULL, 
            objectId        NUMBER, 
            dataObjectId    NUMBER, 
            ddlType        VARCHAR2(40), 
            objectName        VARCHAR2(100), 
            objectOwner    VARCHAR2(100), 
            objectType     VARCHAR2(40), 
            fragmentNo        NUMBER NOT NULL, 
            optime            CHAR(19) NOT NULL, 
            startSCN        NUMBER, 
            metadata_text        VARCHAR2 (4000) NOT NULL, 
            auditcol            VARCHAR2 (80) 
            );

CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i1" on "GGS_OWNER"."GGS_DDL_HIST" (seqno, fragmentNo);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i2"  on "GGS_OWNER"."GGS_DDL_HIST" (objectid, startSCN, fragmentNo);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i3"  on "GGS_OWNER"."GGS_DDL_HIST" (startSCN, fragmentNo);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i4"  on "GGS_OWNER"."GGS_DDL_HIST" (objectName, objectOwner, objectType, startSCN, fragmentNo);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i5"  on "GGS_OWNER"."GGS_DDL_HIST" (optime);
CREATE INDEX "GGS_OWNER"."GGS_DDL_HIST_i6"  on "GGS_OWNER"."GGS_DDL_HIST" (startSCN, auditcol, fragmentNo);
CREATE INDEX "GGS_OWNER".GGS_DDL_HIST_index1 ON "GGS_OWNER"."GGS_DDL_HIST" (
            objectId);

DROP TABLE "GGS_OWNER"."GGS_DDL_COLUMNS";
CREATE TABLE "GGS_OWNER"."GGS_DDL_COLUMNS" (
            seqNo            NUMBER NOT NULL, 
            name    varchar2(100),
            pos    number,
            type    varchar2(40),
            length    number,
            isnull    varchar2(30),
            prec    number,
            scale    number,
            charsetid    varchar2(30),
            charsetform    varchar2(50),
            segpos    number,
            altname    varchar2(100),
            alttype    varchar2(40),
            altprec    number,
            altcharused    varchar2(50),
            altxmltype    varchar2(50)
            );

DROP TABLE "GGS_OWNER"."GGS_DDL_LOG_GROUPS";
CREATE TABLE "GGS_OWNER"."GGS_DDL_LOG_GROUPS" (
            seqNo            NUMBER NOT NULL, 
            column_name    varchar2(100) 
            );

DROP TABLE "GGS_OWNER"."GGS_DDL_PARTITIONS";
CREATE TABLE "GGS_OWNER"."GGS_DDL_PARTITIONS" (
            seqNo            NUMBER NOT NULL, 
            partition_id    number 
            );

DROP TABLE "GGS_OWNER"."GGS_DDL_PRIMARY_KEYS";
CREATE TABLE "GGS_OWNER"."GGS_DDL_PRIMARY_KEYS" (
            seqNo            NUMBER NOT NULL, 
            column_name    varchar2(100) 
            );

DROP TABLE "GGS_OWNER"."GGS_DDL_OBJECTS";
CREATE TABLE "GGS_OWNER"."GGS_DDL_OBJECTS" (
            seqNo            NUMBER NOT NULL, 
            optime            CHAR(19) NOT NULL, 
            marker_table    varchar2 (100),
            marker_seq        number,
            start_scn        number,
            optype            varchar2(40),
            objtype        varchar2(40),
            db_blocksize    number,
            objowner        varchar2(100),
            objname        varchar2(100),
            objectid        number, 
            master_owner    varchar2(100),
            master_name    varchar2(100),
            data_objectid    number, 
            valid            varchar2(30),
            cluster_cols    number,
            log_group_exists    varchar2(20),
            subpartition        varchar2(20),
            partition    varchar2(20),
            primary_key    varchar2(100),
            total_cols    number,
            cols_count    number,
            ddl_statement   CLOB
            );
