-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_insert.sql
--
-- Oracle Tutorial
--
-- Description:
-- Insert initial data into the TCUSTMER and TCUSTORD tables.
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_ora_insert.sql"
--

INSERT INTO tcustmer
VALUES
(
    'WILL',
    'BG SOFTWARE CO.',
    'SEATTLE',
    'WA'
);

INSERT INTO tcustmer
VALUES
(
    'JANE',
    'ROCKY FLYER INC.',
    'DENVER',
    'CO'
);

INSERT INTO tcustord
VALUES
(
    'WILL',
    TO_DATE ('1994-09-30 15:33:00','YYYY-MM-DD HH24:MI:SS'),
    'CAR',
    144,
    17520,
    3,
    100
);

INSERT INTO tcustord
VALUES
(
    'JANE',
    TO_DATE ('1995-11-11 13:52:00','YYYY-MM-DD HH24:MI:SS'),
    'PLANE',
    256,
    133300,
    1,
    100
);

COMMIT;
