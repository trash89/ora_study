-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_misc.sql
--
-- Oracle Tutorial
--
-- Description:
-- Perform a variety of database operations on the TCUSTMER and TCUSTORD tables.
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_ora_misc.sql"
--

INSERT INTO tcustmer
VALUES
(
    'DAVE',
    'DAVE''S PLANES INC.',
    'TALLAHASSEE',
    'FL'
);

INSERT INTO tcustmer
VALUES
(
    'BILL',
    'BILL''S USED CARS',
    'DENVER',
    'CO'
);

INSERT INTO tcustmer
VALUES
(
    'ANN',
    'ANN''S BOATS',
    'SEATTLE',
    'WA'
);

COMMIT;

INSERT INTO tcustord
VALUES
(
    'BILL',
    TO_DATE ('1995-12-31 15:00:00','YYYY-MM-DD HH24:MI:SS'),
    'CAR',
    765,
    15000,
    3,
    100
);

INSERT INTO tcustord
VALUES
(
    'BILL',
    TO_DATE ('1996-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'),
    'TRUCK',
    333,
    26000,
    15,
    100
);

INSERT INTO tcustord
VALUES
(
    'DAVE',
    TO_DATE ('1993-11-03 07:51:35','YYYY-MM-DD HH24:MI:SS'),
    'PLANE',
    600,
    135000,
    2,
    200
);

COMMIT;

UPDATE tcustord
SET product_price  = 14000.00
WHERE cust_code    = 'BILL' AND
      order_date   = TO_DATE ('1995-12-31 15:00:00','YYYY-MM-DD HH24:MI:SS') AND
      product_code = 'CAR' AND
      order_id     = 765;

UPDATE tcustord
SET product_price  = 25000.00
WHERE cust_code    = 'BILL' AND
      order_date   = TO_DATE ('1996-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') AND
      product_code = 'TRUCK' AND
      order_id     = 333;

UPDATE tcustord
SET product_price  = 16520.00
WHERE cust_code    = 'WILL' AND
      order_date   = TO_DATE ('1994-09-30 15:33:00','YYYY-MM-DD HH24:MI:SS') AND
      product_code = 'CAR' AND
      order_id     = 144;

UPDATE tcustmer
SET city  = 'NEW YORK',
    state = 'NY'
WHERE cust_code = 'ANN';

COMMIT;

DELETE FROM tcustord
WHERE cust_code    = 'DAVE' AND
      order_date   = TO_DATE ('1993-11-03 07:51:35','YYYY-MM-DD HH24:MI:SS') AND
      product_code = 'PLANE' AND
      order_id     = 600;

DELETE from tcustord
WHERE cust_code    = 'JANE' AND
      order_date   = TO_DATE ('1995-11-11 13:52:00','YYYY-MM-DD HH24:MI:SS') AND
      product_code = 'PLANE' AND
      order_id     = 256;

COMMIT;

DELETE FROM tcustord;

ROLLBACK;
