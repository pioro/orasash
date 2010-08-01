
-- (c) Kyle Hailey 2007



  accept REPO_HOST default kylehpd prompt "Repository Host name or IP "
  prompt "Repository host is : " &REPO_HOST
  accept REPO_SID default ora9 prompt "Reposistory SID "
  prompt "Repository sid is : " &REPO_SID

  drop database link SASHREPO;
  create database link  "SASHREPO"
    CONNECT TO "SASH"
    IDENTIFIED BY "SASH"
    USING 
  '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=&REPO_HOST)(PORT=1521)))(CONNECT_DATA=(SID=&REPO_SID)))'
/

  Prompt "Testing connection ... should return X"
  select * from dual@sashrepo;
  Accept toto prompt "If this connection failed, then control C out"


  create sequence sashseq ;

  drop view sashnow;

  prompt "For 10g only (Errors on 9i or below ok)"
  prompt "elimates costly v$session_wait join for 10g"
  create view sashnow as 
              Select
                 d.dbid,
                 sysdate sample_time,
                 s.indx          "SESSION_ID",
                 decode(s.ksusetim, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.ksuseser      "SESSION_SERIAL#",
                 s.ksuudlui      "USER_ID",
                 s.ksusesql      "SQL_ADDRESS",
                 s.ksusesph      "SQL_PLAN_HASH_VALUE",
                 decode(s.ksusesch, 65535, to_number(null), s.ksusesch) "SQL_CHILD_NUMBER",
                 s.ksusesqh      "SQL_ID" ,
                 s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.ksuseflg      "SESSION_TYPE"  ,
                 s.ksuseopc      "EVENT# ",
                 s.ksuseseq      "SEQ#"        /* xksuse.ksuseseq */,
                 s.ksusep1       "P1"          /* xksuse.ksusep1  */,
                 s.ksusep2       "P2"          /* xksuse.ksusep2  */,
                 s.ksusep3       "P3"          /* xksuse.ksusep3  */,
                 s.ksusetim      "WAIT_TIME"   /* xksuse.ksusetim */,
                 s.ksusewtm      "TIME_WAITED"   /* xksuse.ksusewtm */,
                 s.ksuseobj      "CURRENT_OBJ#",
                 s.ksusefil      "CURRENT_FILE#",
                 s.ksuseblk      "CURRENT_BLOCK#",
                 s.ksusepnm      "PROGRAM",
                 s.ksuseaph      "MODULE_HASH",  /* ASH collects string */
                 s.ksuseach      "ACTION_HASH",   /* ASH collects string */
                 s.ksusefix      "FIXED_TABLE_SEQUENCE" /* FIXED_TABLE_SEQUENCE */
       from
               x$ksuse s , /* v$session */
               v$database d
       where
               s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
               bitand(s.ksspaflg,1)!=0 and
               bitand(s.ksuseflg,1)!=0 and
            (  (
                  /* status Active - seems inactive & "on cpu"=> not on CPU */
                  s.ksusetim != 0  and  /* on CPU  */
                  bitand(s.ksuseidl,11)=1  /* ACTIVE */
               )
                     or
               s.ksuseopc not in   /* waiting and the wait event is not idle */
                   (  select event# from v$event_name where wait_class='Idle' )
            );

  prompt "For 9i  (errors on 10g+ or 8 or 7 ok)"
  prompt "joins with v$session_wait and includes sql_plan_hash_value"
  create view sashnow as 
              Select
                 d.dbid,
                 sysdate sample_time,
                 s.indx          "SESSION_ID",
                 decode(w.ksusstim, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.ksuseser      "SESSION_SERIAL#",
                 s.ksuudlui      "USER_ID",
                 s.ksusesql      "SQL_ADDRESS",
                 s.ksusepha      "SQL_PLAN_HASH_VALUE",
                 -1              "SQL_CHILD_NUMBER",
                 s.ksusesqh      "SQL_ID" ,
                 s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.ksuseflg      "SESSION_TYPE"  ,
                 w.ksussopc      "EVENT# ",
                 w.ksussseq      "SEQ#"        /* xksuse.ksuseseq */,
                 w.ksussp1       "P1"          /* xksuse.ksusep1  */,
                 w.ksussp2       "P2"          /* xksuse.ksusep2  */,
                 w.ksussp3       "P3"          /* xksuse.ksusep3  */,
                 w.ksusstim      "WAIT_TIME"   /* xksuse.ksusetim */,
                 w.ksusewtm      "TIME_WAITED"   /* xksuse.ksusewtm */,
                 s.ksuseobj      "CURRENT_OBJ#",
                 s.ksusefil      "CURRENT_FILE#",
                 s.ksuseblk      "CURRENT_BLOCK#",
                 s.ksusepnm      "PROGRAM",
                 s.ksuseaph      "MODULE_HASH",  /* ASH collects string */
                 s.ksuseach      "ACTION_HASH",   /* ASH collects string */
                 s.ksusefix      "FIXED_TABLE_SEQUENCE" /* FIXED_TABLE_SEQUENCE */
       from
               x$ksuse s , /* v$session */
               x$ksusecst w, /* v$session_wait */
               v$database d
       where
               s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
               bitand(s.ksspaflg,1)!=0 and
               bitand(s.ksuseflg,1)!=0 and
               s.indx = w.indx and
            (  (
                  /* status Active - seems inactive & "on cpu"=> not on CPU */
                  w.ksusstim != 0  and  /* on CPU  */
                  bitand(s.ksuseidl,11)=1  /* ACTIVE */
               )
                     or
               w.ksussopc not in   /* waiting and the wait event is not idle */
                   ( select
                             event#
                    from
                             v$event_name
                     where
                            lower(name) in (
                                 'queue monitor wait',
                                 'null event',
                                 'pl/sql lock timer',
                                 'px deq: execution msg',
                                 'px deq: table q normal',
                                 'px idle wait',
                                 'sql*net message from client',
                                 'sql*net message from dblink',
                                 'dispatcher timer',
                                 'lock manager wait for remote message',
                                 'pipe get',
                                 'pmon timer',
                                 'queue messages',
                                 'rdbms ipc message',
                                 'slave wait',
                                 'smon timer',
                                 'virtual circuit status',
                                 'wakeup time manager',
                                 'i/o slave wait',
                                 'jobq slave wait',
                                 'queue monitor wait',
                                 'SQL*Net message from client'
                            )
                       )
              );

  prompt "For 7 and 8  (errors on 9i or 10g+  ok)"
  create view sashnow as 
              Select
                 d.dbid,
                 sysdate sample_time,
                 s.indx          "SESSION_ID",
                 decode(w.ksusstim, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.ksuseser      "SESSION_SERIAL#",
                 s.ksuudlui      "USER_ID",
                 s.ksusesql      "SQL_ADDRESS",
                 -1              "SQL_PLAN_HASH_VALUE",
                 -1              "SQL_CHILD_NUMBER",
                 s.ksusesqh      "SQL_ID" ,
                 s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.ksuseflg      "SESSION_TYPE"  ,
                 w.ksussopc      "EVENT#",
                 w.ksussseq      "SEQ#"        /* xksuse.ksuseseq */,
                 w.ksussp1       "P1"          /* xksuse.ksusep1  */,
                 w.ksussp2       "P2"          /* xksuse.ksusep2  */,
                 w.ksussp3       "P3"          /* xksuse.ksusep3  */,
                 w.ksusstim      "WAIT_TIME"   /* xksuse.ksusetim */,
                 w.ksusewtm      "TIME_WAITED"   /* xksuse.ksusewtm */,
                 s.ksuseobj      "CURRENT_OBJ#",
                 s.ksusefil      "CURRENT_FILE#",
                 s.ksuseblk      "CURRENT_BLOCK#",
                 s.ksusepnm      "PROGRAM",
                 s.ksuseaph      "MODULE_HASH",  /* ASH collects string */
                 s.ksuseach      "ACTION_HASH",   /* ASH collects string */
                 s.ksusefix      "FIXED_TABLE_SEQUENCE" /* FIXED_TABLE_SEQUENCE */
       from
               x$ksuse s , /* v$session */
               x$ksusecst w, /* v$session_wait */
               v$database d
       where
               s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
               bitand(s.ksspaflg,1)!=0 and
               bitand(s.ksuseflg,1)!=0 and
               s.indx = w.indx and
            (  (
                  /* status Active - seems inactive & "on cpu"=> not on CPU */
                  w.ksusstim != 0  and  /* on CPU  */
                  bitand(s.ksuseidl,11)=1  /* ACTIVE */
               )
                     or
               w.ksussopc not in   /* waiting and the wait event is not idle */
                   ( select
                             event#
                    from
                             v$event_name
                     where
                            lower(name) in (
                                 'queue monitor wait',
                                 'null event',
                                 'pl/sql lock timer',
                                 'px deq: execution msg',
                                 'px deq: table q normal',
                                 'px idle wait',
                                 'sql*net message from client',
                                 'sql*net message from dblink',
                                 'dispatcher timer',
                                 'lock manager wait for remote message',
                                 'pipe get',
                                 'pmon timer',
                                 'queue messages',
                                 'rdbms ipc message',
                                 'slave wait',
                                 'smon timer',
                                 'virtual circuit status',
                                 'wakeup time manager',
                                 'i/o slave wait',
                                 'jobq slave wait',
                                 'queue monitor wait',
                                 'SQL*Net message from client'
                            )
                       )
              );

  prompt "For conneting as system for all versions"
  create view sashnow as 
         Select
                 d.dbid,
                 sysdate sample_time,
                 s.sid               "SESSION_ID"    ,
                 decode(w.WAIT_TIME, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.serial#         "SESSION_SERIAL#",
                 s.user#           "USER_ID",
                 s.sql_address     "SQL_ADDRESS",
                 -1                "SQL_PLAN_HASH_VALUE",
                 -1                "SQL_CHILD_NUMBER",
                 s.sql_hash_value      "SQL_ID" ,
                 s.command         "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.type            "SESSION_TYPE"  ,
                 n.event#          "EVENT#",
                 w.seq#            "SEQ#"        /* xksuse.ksuseseq */,
                 w.p1              "P1"          /* xksuse.ksusep1  */,
                 w.p2              "P2"          /* xksuse.ksusep2  */,
                 w.p3              "P3"          /* xksuse.ksusep3  */,
                 w.wait_time       "WAIT_TIME"   /* xksuse.ksusetim */,
                 w.seconds_in_wait     "TIME_WAITED"   /* xksuse.ksusewtm */,
                 s.ROW_WAIT_OBJ#   "CURRENT_OBJ#",
                 s.ROW_WAIT_FILE#  "CURRENT_FILE#",
                 s.ROW_WAIT_BLOCK# "CURRENT_BLOCK#",
                 s.program         "PROGRAM",
                 s.module_hash     "MODULE_HASH",  /* ASH collects string */
                 s.action_hash     "ACTION_HASH",   /* ASH collects string */
                 s.FIXED_TABLE_SEQUENCE        "FIXED_TABLE_SEQUENCE"
       from
               v$session s ,
               v$database d,
               v$session_wait w,
               v$event_name n
       where
               s.sid != ( select distinct sid from v$mystat  where rownum < 2 ) and
               w.sid = s.sid and
               n.name = w.event and
            (  (
                  /* status Active - seems inactive & "on cpu"=> not on CPU */
                  w.wait_time != 0  and  /* on CPU  */
                  s.status='ACTIVE'  /* ACTIVE */
               )
                     or
               lower(w.event)  not in   /* waiting and the wait event is not idle */
                            (
                                 'queue monitor wait',
                                 'null event',
                                 'pl/sql lock timer',
                                 'px deq: execution msg',
                                 'px deq: table q normal',
                                 'px idle wait',
                                 'sql*net message from client',
                                 'sql*net message from dblink',
                                 'dispatcher timer',
                                 'lock manager wait for remote message',
                                 'pipe get',
                                 'pmon timer',
                                 'queue messages',
                                 'rdbms ipc message',
                                 'slave wait',
                                 'smon timer',
                                 'virtual circuit status',
                                 'wakeup time manager',
                                 'i/o slave wait',
                                 'jobq slave wait',
                                 'queue monitor wait',
                                 'SQL*Net message from client'
                            )
            );


--
-- BEGIN CREATE TARGET PACKAGE SASH_PKG
--
CREATE OR REPLACE PACKAGE sash_pkg AS
--          PROCEDURE print (v_sleep number, loops number) ;
          PROCEDURE get_all  ;
          PROCEDURE get_objs  ;
          PROCEDURE get_users  ;
	  PROCEDURE get_params  ;
          PROCEDURE get_sqltxt  ;
          PROCEDURE get_sqlstats  ;
          PROCEDURE get_data_files  ;
          PROCEDURE get_sqlplans  ;
          PROCEDURE get_event_names  ;
          PROCEDURE collect (v_sleep number, loops number) ;
          FUNCTION get_dbid  return number ;
          PROCEDURE set_dbid  ;
          END sash_pkg;
/
show errors

--
-- BEGIN CREATE TARGET PACKAGE BODY SASH_PKG
--
-- ZZZZ
CREATE OR REPLACE PACKAGE BODY sash_pkg AS

       FUNCTION get_dbid return number is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database;
            return l_dbid;
            -- return 1;
       end get_dbid;

       PROCEDURE get_users is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database;
            insert into SASH.sash_users@SASHREPO 
                     (dbid, username, user_id)
                     select l_dbid,username,user_id from dba_users; 
            commit;
       end get_users;

       PROCEDURE get_params is
          l_dbid number;
          begin
            select dbid into l_dbid from v$database;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
            insert into SASH.sash_params@SASHREPO 
                  ( dbid, name, value)
                  select l_dbid,name,value from gv$parameter;
            commit;
       end get_params;

       PROCEDURE set_dbid is
          l_dbid number;
          l_version varchar(17);
          l_oracle_home varchar2(150);
          l_instance_name varchar2(30);
          l_host varchar2(30);
          cnt number;
          begin 
            select dbid into l_dbid from v$database;
            select count(*) into cnt from 
                SASH.sash_target@SASHREPO;
            if cnt = 0 then 
                insert into 
                   SASH.sash_target@SASHREPO ( dbid )
                   values (l_dbid);
            end if;
            commit;
            select 
                      version,
                      host_name,
                      instance_name 
               into 
                      l_version,
                      l_host,
                      l_instance_name 
               from v$instance;
            select substr(file_spec,0,instr(file_spec,'bin')-2) into l_oracle_home
            from DBA_LIBRARIES  where library_name = 'DBMS_SUMADV_LIB';
            insert into SASH.sash_targets@SASHREPO 
                  (       dbid, 
                          host, 
                          home, 
                          sid, 
                          sashseq, 
                          version)
                  values (l_dbid,
                          l_host,
                          l_oracle_home,
                          l_instance_name,
                          0,
                          l_version); 
/*
                  values (l_dbid,
                          '${TARG_HOST}',
                          '${TARG_HOME}',
                          '${TARG_SID}',
                          0,
                          l_version); 
*/
            commit;
       end set_dbid;

       PROCEDURE get_data_files is
          l_dbid number;
          --v_file_name varchar2(513);
          --v_file_id number;
          --v_tablespace_name varchar2(30);
          cursor files_cur is
             select file_name, file_id, tablespace_name from dba_data_files;
       begin
          l_dbid:=get_dbid;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
         /*
          insert into SASH.sash_data_files@SASHREPO 
                  ( dbid, file_name, file_id, tablespace_name )
                   select l_dbid, file_name, file_id, tablespace_name 
                   from dba_data_files;
         */
         for file_rec in files_cur loop 
          insert into SASH.sash_data_files@SASHREPO 
                  ( dbid, file_name, file_id, tablespace_name ) values
                   ( l_dbid, 
                    file_rec.file_name, 
                    file_rec.file_id, 
                    file_rec.tablespace_name );
         end loop;
       end get_data_files;

       PROCEDURE get_event_names is
          l_dbid number;
       begin
          l_dbid:=get_dbid;
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
          insert into SASH.sash_event_names@SASHREPO 
                  ( dbid, event#, name )
                   select l_dbid, event#, name from gv$event_name;
       end get_event_names;

       PROCEDURE get_objs is
          l_dbid number;
       begin
         l_dbid:=get_dbid;
         -- get object info  for top 20 sql in SASH over the last hour
         insert into  SASH.sash_objs@SASHREPO
                (      dbid, 
                       object_id, 
                       owner, 
                       object_name, 
                       subobject_name, 
                       object_type)
                select l_dbid, 
                       o.object_id,
                       o.owner,
                       o.object_name,
                       o.subobject_name,
                       o.object_type
                from dba_objects o
                where object_id  in ( 
                        select current_obj# from (
                        select count(*) cnt, CURRENT_OBJ#
                        from SASH.sash@SASHREPO 
                        where
                               l_dbid = dbid
                           and current_obj# > 0
                           and sample_time > (sysdate - 1/24)
                        group by current_obj#
                        order by cnt desc )
                     where rownum < 21)
                  and object_id not in (select object_id from 
                       SASH.sash_objs@SASHREPO 
                       where l_dbid = dbid) ;
         commit;
       end get_objs;

       PROCEDURE get_all is
       begin
          get_sqltxt;
          commit;
          get_sqlstats;
          commit;
          get_objs;
          commit;
          get_sqlplans;
          commit;
       end get_all;

       PROCEDURE get_sqlplans is
          l_dbid number;
       begin
         l_dbid:=get_dbid;
         -- get sql stats  for top 20 sql in SASH over the last hour
         insert into  SASH.sash_sqlplans@SASHREPO 
              (     statement_id    ,
                    timestamp       ,
                    remarks         ,
                    operation       ,
                    options         ,
                    object_node     ,
                    object_owner    ,
                    object_name     ,
                    object_instance ,
                    object_type     ,
                    optimizer       ,
                    search_columns  ,
                    id              ,
                    parent_id       ,
                    position        ,
                    cost            ,
                    cardinality     ,
                    bytes           ,
                    other_tag       ,
                    partition_start ,
                    partition_stop  ,
                    partition_id    ,
                    other           ,
                    distribution    ,
                    cpu_cost        ,
                    io_cost         ,
                    temp_space      ,
                    access_predicates ,
                    filter_predicates ,
                    dbid )
                select 
                      hash_value,
                       sysdate,
                       'REMARKS',
                       OPERATION,
                       OPTIONS,
                       OBJECT_NODE,
                       --OBJECT_OWNER, getting ora-22804 with this column !
                       'unknown',
                       OBJECT_NAME,
                       0,
                       'OBJECT_TYPE',
                       OPTIMIZER,
                       SEARCH_COLUMNS,
                       ID,
                       PARENT_ID,
                       POSITION,
                       COST,
                       CARDINALITY,
                       BYTES,
                       OTHER_TAG,
                       PARTITION_START,
                       PARTITION_STOP,
                       PARTITION_ID,
                       OTHER,
                       DISTRIBUTION,
                       CPU_COST,
                       IO_COST,
                       TEMP_SPACE,
                       ACCESS_PREDICATES,
                       FILTER_PREDICATES,
                       l_dbid
                from gv$sql_plan sql
                where sql.hash_value in ( 
                       select  hash_value
                       from SASH.sash_sqltxt@SASHREPO 
                       where l_dbid = dbid )
                  and sql.hash_value not in (
                       select hash_value 
                       from SASH.sash_sqlplans@SASHREPO 
                       where l_dbid = dbid);
         commit;
       end get_sqlplans;

       PROCEDURE get_sqlstats is
          l_dbid number;
       begin
         l_dbid:=get_dbid;
         -- get sql stats  for top 20 sql in SASH over the last hour
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
         insert into  SASH.sash_sqlstats@SASHREPO 
              (       dbid ,
                      sample_time ,
                      address ,
                      hash_value ,
                      executions ,
                      elapsed_time ,
                      rows_processed  )
                select l_dbid,
                       sysdate,
                       sql.address,
                       sql.hash_value,
                       sql.executions,
                       sql.elapsed_time,
                       sql.rows_processed 
                from gv$sql sql
                where sql.hash_value in ( 
                       select  hash_value
                       from SASH.sash_sqltxt@SASHREPO 
                       where l_dbid = dbid );
         commit;
       end get_sqlstats;

       PROCEDURE get_sqltxt is
          l_dbid number;
          v_sqlid  number;
          up_rows  number:=0;
          cursor c_sqlids is
                        select sql_id from (
                          select count(*) cnt, sql_id
                          from SASH.sash@SASHREPO 
                          where l_dbid = dbid
                             and sql_id != 0
                             and sample_time > (sysdate - 1/24)
                          group by sql_id
                          order by cnt desc )
                        where rownum < 21;

       begin
         l_dbid:=get_dbid;
         for f_sqlid in c_sqlids loop
           update  SASH.sash_sqlids@SASHREPO
                set 
                       last_found = sysdate ,
                       found_count = nvl(found_count,1) + 1
                where 
                       sql_id = f_sqlid.sql_id
                   and l_dbid = dbid;
           up_rows:=sql%rowcount;
           if up_rows = 0 then
            -- using gv$ because of problem with the error
            -- ORA-02070: database SASHREPO does not 
            -- support operator USERENV in this context
             insert into  SASH.sash_sqlids@SASHREPO 
                   ( dbid ,
                     address ,
                     sql_id ,
                     command_type ,
                     child_number ,
                     plan_hash_value ,
                     memory ,
                     last_found,
                     first_found,
                     found_count 
                   )
                  select 
                       l_dbid ,
                       sqlt.address,
                       sqlt.hash_value,
                       sqlt.command_type,
                       sqlt.child_number ,
                       sqlt.plan_hash_value ,
                       sqlt.SHARABLE_MEM + sqlt.PERSISTENT_MEM + sqlt.RUNTIME_MEM ,
                       sysdate,
                       sysdate,
                       1 
                  from gv$sql sqlt
                  where 
                        sqlt.hash_value = f_sqlid.sql_id;
             insert into  SASH.sash_sqltxt@SASHREPO 
                  ( dbid ,
                    address ,
                    sql_id ,
                    piece ,
                    sql_text )
                select l_dbid, 
                       sqlt.address,
                       sqlt.hash_value,
                       sqlt.piece,
                       sqlt.sql_text
                from gv$sqltext sqlt
                where sqlt.hash_value = f_sqlid.sql_id ;
             end if;
           end loop;
         commit;
       end get_sqltxt;

 
/*
       PROCEDURE print(v_sleep number, loops number) is
          sash_rec sash%rowtype;
          cursor sash_cur
             return sash%ROWTYPE is  
               select a.*, sashseq.nextval sample_id from sashnow a;
          begin
            for i in 1..loops loop
              open sash_cur; loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                dbms_output.put_line(sash_rec.sample_time||' '||
                                     to_char(sash_rec.session_id)||' '||
                                     sash_rec.session_state);
              end loop;
              dbms_lock.sleep(v_sleep);
              close sash_cur;
            end loop;
       end print;
*/

       PROCEDURE collect(v_sleep number, loops number) is
          --sash_rec SASH.sash@SASHREPO%rowtype;
          sash_rec sash@SASHREPO%rowtype;
          l_dbid number;
          cpart    number := -1;      /* current partition number */
          part     number := 1;       /* new partition number */
          cur_sashseq   number := 0;
          -- return SASH.sash@SASHREPO%rowtype is
          cursor sash_cur is
               select a.*, 
                      cur_sashseq sample_id ,
                      null machine,
                      null terminal
                      from sashnow a;
          begin
            l_dbid:=get_dbid;
            for i in 1..loops loop
              --this looks questionable -looks expensive 
              select  sashseq.nextval into cur_sashseq from dual;
              -- update  SASH.sash_targets@SASHREPO set sashseq = cur_ashseq
              -- where dbid = l_dbid;
              dbms_output.put_line('loop # '||to_char(i));
              --change partitions every day of the week  1-7 , SUN = 1
              select to_number(to_char(sysdate,'D')) into part from dual;
              --if part != cpart then
              --   -- don't purge the first time around incase data exists from previous run
              --   if cpart != -1 then
              --      purge(part);
              --   end if;
              --   cpart:=part;
              --end if; 
              open sash_cur; loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                -- ie if sample_id not great than 1 then its not real data, don't insert
                if sash_rec.sample_id > 1 then
                  --dbms_output.put_line('insert into part '||to_char(part));
                  -- dbms_output.put_line('insert '||
                  --      to_char(sash_rec.DBID)||','||
                  --      to_char( sash_rec.SESSION_ID)||','||
                  --      to_char(sash_rec.SQL_ID)||','||
                  --      to_char(sash_rec.EVENT#) );
                  insert into SASH.sash@SASHREPO
                   (  DBID,
                      SAMPLE_TIME,
                      SESSION_ID,
                      SESSION_STATE,
                      SESSION_SERIAL#,
                      USER_ID,
                      SQL_ADDRESS,
                      SQL_PLAN_HASH_VALUE,
                      SQL_CHILD_NUMBER,
                      SQL_ID,
                      SQL_OPCODE,
                      SESSION_TYPE,
                      EVENT#,
                      SEQ#,
                      P1,
                      P2,
                      P3,
                      WAIT_TIME,
                      TIME_WAITED,
                      CURRENT_OBJ#,
                      CURRENT_FILE#,
                      CURRENT_BLOCK#,
                      PROGRAM,
                      MODULE,
                      ACTION,
                      FIXED_TABLE_SEQUENCE,
                      SAMPLE_ID )
                  values 
                       ( sash_rec.DBID,
                         sash_rec.SAMPLE_TIME,
                         sash_rec.SESSION_ID,
                         sash_rec.SESSION_STATE,
                         sash_rec.SESSION_SERIAL#,
                         sash_rec.USER_ID,
                         sash_rec.SQL_ADDRESS,
                         sash_rec.SQL_PLAN_HASH_VALUE,
                         sash_rec.SQL_CHILD_NUMBER,
                         sash_rec.SQL_ID,
                         sash_rec.SQL_OPCODE,
                         sash_rec.SESSION_TYPE,
                         sash_rec.EVENT#,
                         sash_rec.SEQ#,
                         sash_rec.P1,
                         sash_rec.P2,
                         sash_rec.P3,
                         sash_rec.WAIT_TIME,
                         sash_rec.TIME_WAITED,
                         sash_rec.CURRENT_OBJ#,
                         sash_rec.CURRENT_FILE#,
                         sash_rec.CURRENT_BLOCK#,
                         sash_rec.PROGRAM,
                         sash_rec.MODULE,
                         sash_rec.ACTION,
                         sash_rec.FIXED_TABLE_SEQUENCE,
                         sash_rec.SAMPLE_ID );
                end if;
              end loop;
              close sash_cur;
              commit;
              dbms_lock.sleep(v_sleep);
            end loop;
       end collect;

END sash_pkg;
/


show errors
