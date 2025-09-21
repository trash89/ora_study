-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_pk_befores_create.sql
--
-- Oracle Tutorial
--
-- Description:
-- Create the PK_BF_TIMESRC and PK_BF_TIMETRG tables.

DROP TABLE PK_BF_TIMESRC;
CREATE TABLE PK_BF_TIMESRC
(KEY_NUM                                   NUMBER not null
,FIRST_VAR_DATA_COL                        VARCHAR2(20)
,SECOND_VAR_DATA_COL                       VARCHAR2(20)
,FIRST_NUM_DATA_COL                        NUMBER
,SECOND_NUM_DATA_COL                       NUMBER (8,2)
,CAT_CODE                                  char (1)
,LAST_UPDATE_DATETIME                      date
,CONSTRAINT PK_PK_BF_TIMESRC
PRIMARY KEY (key_num, CAT_CODE, FIRST_NUM_DATA_COL) 
USING INDEX)
;

DROP TABLE PK_BF_TIMETRG;
CREATE TABLE PK_BF_TIMETRG
(KEY_NUM                                   NUMBER not null
,FIRST_VAR_DATA_COL                        VARCHAR2(20)
,SECOND_VAR_DATA_COL                       VARCHAR2(20)
,FIRST_NUM_DATA_COL                        NUMBER
,SECOND_NUM_DATA_COL                       NUMBER (8,2)
,CAT_CODE                                  char (1)
,LAST_UPDATE_DATETIME                      date
,CONSTRAINT PK_BF_PKTIMETRG
PRIMARY KEY (key_num, CAT_CODE, FIRST_NUM_DATA_COL)
USING INDEX)
;


