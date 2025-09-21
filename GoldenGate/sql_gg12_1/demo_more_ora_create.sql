-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_more_ora_create.sql
--
-- Oracle Tutorial
--
-- Description:
-- Create the MORE_RECS_TBL table.
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_more_ora_create.sql".
--

-- FOR SOURCE --

DROP TABLE MORE_RECS_TBL;

CREATE TABLE MORE_RECS_TBL
(
    EMP_NO	 	INT 		NOT NULL,
    LARGE_DATA    	VARCHAR(3000),
    RECORD_DATE		DATE,
    DESCRIPTION		VARCHAR(100),
    PRIMARY KEY (EMP_NO)
);



-- FOR TARGET --

DROP TABLE EMPOFFICEDTL;

CREATE TABLE EMPOFFICEDTL
(
    EMP_NO    		INT    NOT NULL,
    OFF_ADDRESS 	VARCHAR(100),
    OFF_JOIN_DATE 	DATE,
    PRIMARY KEY (EMP_NO)
);

DROP TABLE EMPPERSONALDTL;

CREATE TABLE EMPPERSONALDTL
(
    EMP_NO	INT    NOT NULL,
    NAME	VARCHAR(20),
    DOB		DATE,
    ADDRESS	VARCHAR(100),
    PRIMARY KEY (EMP_NO)
);

DROP TABLE EMPSKILLSDTL;

CREATE TABLE EMPSKILLSDTL
(
    EMP_NO    			INT    NOT NULL,
    MAJOR_SKILL_NAME		VARCHAR(10),
    PRIMARY KEY (EMP_NO)
);

DROP TABLE EMPPROJECTDTL;

CREATE TABLE EMPPROJECTDTL
(
    EMP_NO    		INT    NOT NULL,
    PROJ_NAME		VARCHAR(10),
    PROJ_JOIN_DATE 	DATE,
    PRIMARY KEY (EMP_NO)
);


