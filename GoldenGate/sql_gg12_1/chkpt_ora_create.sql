-- Copyright (c) 2005, 2012, Oracle and/or its affiliates. 
-- All rights reserved. 
-- 
-- chkpt_ora_create.sql
--
-- Oracle Checkpoint Creation 
--
-- Description:
-- Create the GGS_CHECKPOINT table.
--
-- Note: execute this script from the command line as "sqlplus userid/password @chkpt_ora_create.sql".
--

DROP TABLE ggs_checkpoint;
CREATE TABLE ggs_checkpoint
(
    group_name       VARCHAR2(8) NOT NULL,
    group_key        NUMBER(19) NOT NULL,
    seqno            NUMBER(10),
    rba              NUMBER(19) NOT NULL,
    audit_ts         VARCHAR2(29),
    create_ts        DATE NOT NULL,
    last_update_ts   DATE NOT NULL,
    current_dir      VARCHAR2(255) NOT NULL,
    log_csn          VARCHAR2(129),
    log_xid          VARCHAR2(129),
    log_cmplt_csn    VARCHAR2(129),
    log_cmplt_xids   VARCHAR2(2000),
    version          NUMBER(3),
    PRIMARY KEY (group_name, group_key)
        USING INDEX
);

DROP TABLE ggs_checkpoint_lox;
CREATE TABLE ggs_checkpoint_lox
(
    group_name VARCHAR2(8) NOT NULL,
    group_key NUMBER(19) NOT NULL,
    log_cmplt_csn VARCHAR2(129) NOT NULL,
    log_cmplt_xids_seq NUMBER(5) NOT NULL,
    log_cmplt_xids VARCHAR2(2000) NOT NULL,
    PRIMARY KEY(group_name, group_key, log_cmplt_csn, log_cmplt_xids_seq)
        USING INDEX
);
