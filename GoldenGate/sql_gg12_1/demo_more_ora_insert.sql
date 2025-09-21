-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_more_ora_insert.sql
--
-- Oracle Tutorial
--
-- Description:
-- Insert initial data into the MORE_RECS_TBL table.
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_more_ora_insert.sql"
--

INSERT INTO MORE_RECS_TBL VALUES 
(1001,
 '4#1|3|8:8:1001|14:100:XSYS, PUNE, MH|23:29:2008-01-01 00:00:00.000|2|4|8:8:1001|7:20:ABC XYZ|23:29:1983-01-01 12:11:54.888|8:100:PUNE, MH|3|2|8:8:1001|5:10:C/C++|4|3|8:8:1001|2:10:GG|23:29:2007-09-18 00:00:00.000'
 ,sysdate, 'A test to show the more_recs_ind use'
);


INSERT INTO MORE_RECS_TBL VALUES 
(1002,
 '4#1|3|8:8:1002|15:100:Y-SYS, PUNE, MH|23:29:2008-02-01 00:00:00.000|2|4|8:8:1002|7:20:DEF UVW|23:29:1982-06-01 12:11:54.888|16:100:DECCAN, PUNE, MH|3|2|8:8:1002|10:10:JAVA, .NET|4|3|8:8:1002|2:10:YY|23:29:2007-09-18 00:00:00.000'
 ,sysdate, 'A test to show the more_recs_ind use'
);


COMMIT;
