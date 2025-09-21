-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_create.sql
--
-- Oracle Tutorial
--
-- Description:
-- Create the TCUSTMER and TCUSTORD tables.
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_ora_create.sql".
--

DROP TABLE tcustmer;
CREATE TABLE tcustmer
(
    cust_code        VARCHAR2(4),
    name             VARCHAR2(30),
    city             VARCHAR2(20),
    state            CHAR(2),
    PRIMARY KEY (cust_code)
        USING INDEX
);

DROP TABLE tcustord;
CREATE TABLE tcustord
(
    cust_code        VARCHAR2(4),
    order_date       DATE,
    product_code     VARCHAR2(8),
    order_id         NUMBER,
    product_price    NUMBER(8,2),
    product_amount   NUMBER(6),
    transaction_id   NUMBER,
    PRIMARY KEY (cust_code, order_date, product_code, order_id)
        USING INDEX
);
