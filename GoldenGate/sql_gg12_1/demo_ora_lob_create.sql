-- Copyright (C) 2002, 2010, Oracle and/or its affiliates. All rights reserved.
-- 
-- demo_ora_lob_create.sql
--
-- Oracle Tutorial
--
-- Description:
-- Create the TSRSLOB and TTRGVAR tables.After creation of source and target table run stored 
-- procedure from sqlplus prompt as 
-- exec testing_lobs;
--
-- Note: execute this script from the command line as "sqlplus userid/password @demo_ora_lob_create.sql".
--


DROP TABLE TSRSLOB;
CREATE TABLE TSRSLOB
(  LOB_RECORD_KEY         NUMBER
,  LOB1_CLOB                     CLOB  NULL
,  LOB2_BLOB	               BLOB  NULL
,  CONSTRAINT PK_TSRSLOB
   PRIMARY KEY
   (LOB_RECORD_KEY) USING INDEX
);

DROP TABLE TTRGVAR;
CREATE TABLE TTRGVAR
(  LOB_RECORD_KEY            NUMBER
,  LOB1_VCHAR0                    VARCHAR2 (1000) NULL
,  LOB1_VCHAR1                    VARCHAR2 (500) NULL
,  LOB1_VCHAR2                    VARCHAR2 (2500) NULL
,  LOB1_VCHAR3                    VARCHAR2 (200) NULL
,  LOB1_VCHAR4                    VARCHAR2 (2000) NULL
,  LOB1_VCHAR5                    VARCHAR2 (2000) NULL
,  LOB1_VCHAR6                    VARCHAR2 (100) NULL
,  LOB1_VCHAR7                    VARCHAR2 (250) NULL
,  LOB1_VCHAR8                    VARCHAR2 (300) NULL
,  LOB1_VCHAR9                    VARCHAR2 (1000) NULL
,  LOB2_VCHAR0                    VARCHAR2 (2000) NULL
,  LOB2_VCHAR1                    VARCHAR2 (1500) NULL
,  LOB2_VCHAR2                    VARCHAR2 (800) NULL
,  LOB2_VCHAR3                    VARCHAR2 (1000) NULL
,  LOB2_VCHAR4                    VARCHAR2 (400) NULL
,  LOB2_VCHAR5                    VARCHAR2 (2000) NULL
,  LOB2_VCHAR6                    VARCHAR2 (1000) NULL
,  LOB2_VCHAR7                    VARCHAR2 (150) NULL
,  LOB2_VCHAR8                    VARCHAR2 (2000) NULL
,  LOB2_VCHAR9                    VARCHAR2 (50) NULL
,  CONSTRAINT PK_TTRGVAR
   PRIMARY KEY
   (LOB_RECORD_KEY) USING INDEX
);

Create or Replace procedure testing_lobs
IS 

 err_num NUMBER;
 position INTEGER;
 lang_warn INTEGER;
 begin_key INTEGER;
 current_key INTEGER;

 buf_size BINARY_INTEGER;

 var_a_buf varchar2 (9850);
 var_b_buf varchar2 (10900);
 blob_mem BLOB;

 begin
    lang_warn  := 0;
    position := 1;
    buf_size := 10900;

    var_a_buf  := var_a_buf || rpad('a',1000,'a');
    var_a_buf  := var_a_buf || rpad('b',500,'b');
    var_a_buf  := var_a_buf || rpad('c',2500,'c');
    var_a_buf  := var_a_buf || rpad('d',200,'d');
    var_a_buf  := var_a_buf || rpad('e',2000,'e');
    var_a_buf  := var_a_buf || rpad('f',2000,'f');
    var_a_buf  := var_a_buf || rpad('g',100,'g');
    var_a_buf  := var_a_buf || rpad('h',250,'h');
    var_a_buf  := var_a_buf || rpad('i',300,'i');
    var_a_buf  := var_a_buf || rpad('j',1000,'j');

    var_b_buf  := var_b_buf || rpad('h',2000,'h');   
    var_b_buf  := var_b_buf || rpad('i',1500,'i');   
    var_b_buf  := var_b_buf || rpad('j',800,'j');   
    var_b_buf  := var_b_buf || rpad('k',1000,'k');   
    var_b_buf  := var_b_buf || rpad('l',400,'l');   
    var_b_buf  := var_b_buf || rpad('m',2000,'m');   
    var_b_buf  := var_b_buf || rpad('n',1000,'n');   
    var_b_buf  := var_b_buf || rpad('o',150,'o');   
    var_b_buf  := var_b_buf || rpad('p',2000,'p');   
    var_b_buf  := var_b_buf || rpad('q',50,'q');   

    SELECT count (*)
        INTO  begin_key
     FROM   tsrslob;
   
     if begin_key != 0 then
       SELECT max (LOB_RECORD_KEY)
           INTO  begin_key
        FROM   tsrslob;
     end if;
  
     current_key := begin_key + 100;

     INSERT INTO tsrslob VALUES
     (current_key,
      var_a_buf ,
      NULL
     );
 
     COMMIT;
 
     SELECT LOB2_BLOB
         INTO  blob_mem
      FROM   tsrslob 
      WHERE LOB_RECORD_KEY = current_key
      FOR UPDATE;

     DBMS_LOB.createtemporary(blob_mem, TRUE);
   
     DBMS_LOB.convertToBlob (blob_mem, var_b_buf, buf_size, position , position, 1, lang_warn, lang_warn);

     UPDATE tsrslob set LOB2_BLOB = blob_mem
                   WHERE LOB_RECORD_KEY = current_key;

    commit;
end;
 /
quit;



