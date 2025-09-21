-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_pk_befores_inserts.sql
--
-- Oracle Tutorial
--
-- Description:
-- Insert the PK_BF_TIMESRC and PK_BF_TIMETRG tables.

Truncate table PK_BF_TIMESRC;
Truncate table PK_BF_TIMETRG;

Insert into PK_BF_TIMESRC values (1000, 'Some test data 1000', 'Some more test data',
                                  12345, 5656.00, 'X', 
                                  to_date ('2000:01:01 10:00:01' , 'YYYY:MM:DD HH:MI:SS')) ;

Insert into PK_BF_TIMESRC values (2000, 'Some being test data', 'Some more test data',
                                  23456, 6565.99, 'Y',  
                                  to_date ('2000:01:01 10:00:01' , 'YYYY:MM:DD HH:MI:SS'));

Insert into PK_BF_TIMESRC values (3000, 'Some being test data', 'Some more test data',
                                  34567, 5566.11, 'X', 
                                  to_date ('2000:01:01 10:00:01' , 'YYYY:MM:DD HH:MI:SS'));

Insert into PK_BF_TIMESRC values (4000, 'Some being test data', 'Some more test data',
                                  45678, 6655.00, 'Y',
                                  to_date ('2000:01:01 10:00:01' , 'YYYY:MM:DD HH:MI:SS'));
commit;
