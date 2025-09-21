-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_pk_befores_updates.sql
--
-- Oracle Tutorial
--
-- Description:
--  update the PK_BF_TIMESRC and PK_BF_TIMETRG tables.

update PK_BF_TIMESRC set 
 KEY_NUM = 5001,
 FIRST_VAR_DATA_COL = 'First var data col', 
 SECOND_VAR_DATA_COL = 'Second var data col',
 FIRST_NUM_DATA_COL = 6969,
 SECOND_NUM_DATA_COL = 54321.23,
 CAT_CODE  = 'M',          
 LAST_UPDATE_DATETIME  =  to_date ('2005:12:01 14:23:59' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 1000;

update PK_BF_TIMESRC set 
 SECOND_VAR_DATA_COL = 'Second var data col',
 SECOND_NUM_DATA_COL = 6589.22,
 LAST_UPDATE_DATETIME  =  to_date ('2005:12:01 14:23:59' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 2000;

update PK_BF_TIMETRG set 
 SECOND_VAR_DATA_COL = 'Setting target conf',
 LAST_UPDATE_DATETIME  =  to_date ('2005:12:01 14:23:59' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 3000;

commit;

update PK_BF_TIMESRC set 
 SECOND_VAR_DATA_COL = 'Source conflict rec',
 SECOND_NUM_DATA_COL = 9999.99,
 LAST_UPDATE_DATETIME  =  to_date ('2006:04:14 20:15:19' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 3000;

update PK_BF_TIMESRC set 
 KEY_NUM = 9999,
 FIRST_VAR_DATA_COL = 'First var data col', 
 SECOND_VAR_DATA_COL = 'Second var data col',
 FIRST_NUM_DATA_COL = 666,
 SECOND_NUM_DATA_COL = 7878.27,
 CAT_CODE  = 'L',
 LAST_UPDATE_DATETIME  = to_date ('2006:04:14 20:15:19' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 4000;

commit;

update PK_BF_TIMESRC set 
 SECOND_VAR_DATA_COL = 'Source not conflict',
 SECOND_NUM_DATA_COL = 9999.99,
 LAST_UPDATE_DATETIME  = to_date ('2007:06:11 21:45:16' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 3000;

update PK_BF_TIMETRG set 
 SECOND_VAR_DATA_COL = 'Setting target conf',
 LAST_UPDATE_DATETIME  = to_date ('2007:06:11 21:45:16' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 5001;

commit;

update PK_BF_TIMESRC set 
 KEY_NUM = 1000,
 FIRST_VAR_DATA_COL = 'Conflict', 
 SECOND_VAR_DATA_COL = 'Ignored',
 FIRST_NUM_DATA_COL = 1111,
 SECOND_NUM_DATA_COL = 12341.23,
 CAT_CODE  = 'C',          
 LAST_UPDATE_DATETIME  = to_date ('2008:12:21 19:45:56' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 5001;

commit;

update PK_BF_TIMESRC set 
 KEY_NUM = 6969,
 FIRST_VAR_DATA_COL = 'Conflict', 
 SECOND_VAR_DATA_COL = 'resolved',
 FIRST_NUM_DATA_COL = 1111,
 SECOND_NUM_DATA_COL = 12341.23,
 CAT_CODE  = 'R',          
 LAST_UPDATE_DATETIME  = to_date ('2008:12:21 19:45:56' , 'YYYY:MM:DD HH24:MI:SS')
 where key_num = 1000;

commit;
