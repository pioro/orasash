OPTS=${1:-2}
#    -1 - drop REPOSITORY tables
#     0 - create REPOSITORY tables, 
#     1 - create TARGET package only
#     2 - DEFAULT : create REPOSITORY and TARGET collection package
#  package is created locally on TARG, tables are created remotely on REPO

# database to be monitored
#
# Target 
#
# local schema to install package, should be SYS
#
  TARG_SCHEMA=sys
  TARG_PW="sys as sysdba"
  TARG_HOST=`hostname`
  TARG_SID=$ORACLE_SID
  TARG_HOME=$ORACLE_HOME

# database to store the performance data
#
# REPOSITORY - need schema/passsword and HOST and SID
#
  REPO_SCHEMA=sash
  REPO_PW=sash
  REPO_SID=cdb
  REPO_HOST=cont01
  REPO_PORT=1521

# number of partitions, based on day of week Sun =1 Sat=7
  nparts=7

#  HOW TO USE:
#  exec dbms_output.enable(1000000)
#  set serveroutput on 
#  -- collect data 10  times at 1 sec intervals
#  exec  sash_pkg.collect(.1,10);
# 
#  -- collect data into sash_all every sec for an hour
#  -- Oracle job runs this every hour
#  variable job number
#  exec dbms_job.submit(:job,'sash.collect(1,3600);',sysdate,'trunc(sysdate+(1/(24)),''HH'')');
#  -- need the commit to actually submit the job
#  commit;
#
#  -- remove job
#  -- exec dbms_job.remove(:job);  
#  
#  -- look at data
#  select sample_time, session_id, session_state from sash_all;
#  -- count samples taken
#  select count(*) from sash_all;
#

  x=1
  CREATE=/tmp/sash_cr_repo.sql
  SASHPKG=/tmp/sash_mngpkg.sql
  DROP=/tmp/sash_drop_repo.sql
  DBL="@SASHREPO"
  DBLINK="/tmp/sash_dblink.sql"

  echo "" > $CREATE
  echo "" > $DROP

# ============== CREATE REPO =======================

# BEGIN CREATE REPOSITORY SCRIPTS
if [  $OPTS -eq 0 -o $OPTS -eq 2 -o $OPTS -eq -1 ]; then

  # get database id for use in script
  DBID=`sqlplus -s "\$TARG_SCHEMA/\$TARG_PW" << EOF
   set heading off
   set feedback off
   select dbid from sys.v\\$database;
  EOF` 

# get rid of the carraige return in the var value if there is one
  DBID=`echo $DBID | awk '{print $1}'`
  echo "DBID $DBID"

  SDATE=`sqlplus -s "\$TARG_SCHEMA/\$TARG_PW" << EOF
  set heading off
  set feedback off
  select to_char(sysdate+1,'DD-MM-YYYY') from dual;
EOF` 


  TNS="(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=$REPO_HOST)(PORT=$REPO_PORT)))(CONNECT_DATA=(SID=$REPO_SID)))"


  # BEGIN CREATE DROP REPOSITORY SCRIPT
  for i in 1; do
  echo "
        drop sequence sash_part_seq;
        drop table sash_all;
        drop table sash_log;
        drop table sash_params_all;
        drop table sash_sqlids_all;
        drop table sash_sqltxt_all;
        drop table sash_sqlstats_all; 
        drop table sash_sqlplans_all;
        drop table sash_event_names_all ;
        drop table sash_objs_all;
        drop table sash_users_all ;
        drop table sash_sesstat_all ;
        drop table sash_sessids_all ;
        drop table sash_latch_all ;
        drop table sash_targets;
        drop table sash_currhost ;
        drop view sash ;
        drop view sash_params ;
        drop view sash_latch ;
        drop view sash_sesstat ;
        drop view sash_sessids ;
        drop view sash_event_names ;
        drop view sash_sqlids;
        drop view sash_sqlplans;
        drop view sash_sqltxt;
        drop view sash_sqlstats;
        drop view sash_objs;
        drop view sash_users;"
  done >> $DROP
  for i in 1; do
  # END CREATE DROP REPOSITORY SCRIPT

  # BEGIN MNG_PACKAGE SCRIPT SASHPKG
  echo " create or replace package sashmng_pkg is
          -- g_offset is how many days in the future to add a new partion
          g_offset  number := 1;
          g_sash_table varchar2(100) := 'SASH_ALL';
          procedure add_subpartition (p_dbid varchar2);
          procedure part_management  (p_table_name varchar2, p_history number);
          procedure range_partition_job(p_sysdate date default sysdate); 
  end sashmng_pkg;
/
show err;

       create or replace package body sashmng_pkg is
       -----------------------------------------------------------------
       -- Create a new subpartition for the most current range partition
       -----------------------------------------------------------------
       procedure add_subpartition (p_dbid varchar2) is
          l_text varchar2(200);
          l_seq_val     number;
          --------------------------------------------------------------
          -- Only create new subpartitions for the current range partition
          --------------------------------------------------------------
          cursor table_parts is
             select partition_name from 
                (select partition_name 
                          from user_tab_partitions 
                          where table_name = g_sash_table
                          order by partition_name desc )
                 where rownum < 3 ;
       begin
          for t in table_parts loop
             select sash_part_seq.nextval into l_seq_val from dual;
             l_text := 'alter table '||g_sash_table||'
             modify partition '||t.partition_name||'
             add subpartition sp_'||p_dbid||'_'||l_seq_val||' 
             values ('||p_dbid||')';
             execute immediate l_text;
          end loop;
       exception
          when others then
             insert into sash_log (action, message,result) 
                          values ('ADD SUBPARTITION', l_text,'E');
             commit;
             raise_application_error(-20010,'Subpartition addition for '||
                          p_dbid||' errored.');
       end;
       ------------------------------------------------------------------
       -- Manage the partitions, drop and add based on p_history.
       -- New partitions are created based on the last partition, including
       -- all subpartitions for the last partition.
       ------------------------------------------------------------------
       procedure part_management(p_table_name varchar2, p_history number) is
          l_text        varchar2(4000);
          l_seq_val     number;
          l_max_part    varchar2(100);
          l_cur_part    varchar2(100);
          cursor table_parts is
             select partition_name from
                (select partition_name, rownum rn from
                   (select  partition_name from user_tab_partitions
                    where table_name = p_table_name order by 1 desc)
                )
             where rn > p_history;
          cursor table_subparts is
             select subpartition_name, partition_name, high_value
             from user_tab_subpartitions
             where table_name = g_sash_table and partition_name =
                (select max(partition_name) 
                          from user_tab_partitions where table_name = g_sash_table)
                order by partition_name desc;
       begin
          -----------------------------------------------------------------
          -- Drop partitions that are past the p_history limit
          -----------------------------------------------------------------
          for part in table_parts loop
             l_text := 'alter table ' ||
                          p_table_name|| 
                          ' drop partition ' || 
                          part.partition_name;
             execute immediate l_text;
          end loop;
          -----------------------------------------------------------------
          -- Add new partition based on last created partition, including
          -- the subpartitions.
          -----------------------------------------------------------------
          select max(partition_name) , 
                          'P_'||to_char(sysdate+g_offset,'YYYY_MM_DD') 
                          into l_max_part, l_cur_part
          from user_tab_partitions where table_name = g_sash_table;
          if (l_max_part < l_cur_part) then
             l_text := 'alter table '||
                          p_table_name||
                          ' add partition P_'||
                          to_char(sysdate + g_offset,'YYYY_MM_DD')||'
              values less than (to_date(''' || 
                          to_char(sysdate + g_offset + 1,'yyyy-mm-dd') || 
                          ''',''yyyy-mm-dd''))';
             l_text := l_text||'(';
             for t in table_subparts loop
                select sash_part_seq.nextval into l_seq_val from dual;
                l_text := l_text||
                          'subpartition SP_'||t.high_value||'_'||
                          l_seq_val||
                          ' values ('||t.high_value||'),';
             end loop;
             l_text := rtrim(l_text, ',');
             l_text := l_text||')';
             execute immediate l_text;
          else
             insert into sash_log (action, message,result) values
             ('ADD PARTITION', 
              'Range partition already exists for '||trunc(sysdate + g_offset),'E');
          end if;
       exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('ADD PARTITION', l_text,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20010,'Range partition errored for '||
                               sysdate + g_offset||'.');
       end;
       --------------------------------------------------------------------
       -- Partition management job, add and dropping of partitions
       --------------------------------------------------------------------
       procedure range_partition_job(p_sysdate date default sysdate) is
         x number;
       begin
          dbms_job.submit
           ( job       => x 
            ,what      => 'sashpkg.part_management('''||g_sash_table||''',7);'
            ,next_date => to_date(to_char(p_sysdate,'dd/mm/yyyy hh24:mi:ss'),'dd/mm/yyyy hh24:mi:ss')
            ,interval  => 'trunc(sysdate)+1'
            ,no_parse  => TRUE
           );
          sys.dbms_output.put_line('Job Number: ' || to_char(x));
       exception
          when others then
             insert into sash_log (action, message,result) 
                    values ('RUN JOB', 'Run job: '||to_char(x), 'E');
             commit;
             RAISE_APPLICATION_ERROR(-20010,'Range partition errored for '||sysdate||'.');
       end;
  end sashmng_pkg;
/
show err 
" > $SASHPKG
  # END MNG_PACKAGE SCRIPT SASHPKG

  # BEGIN CREATE REPOSITORY TABLES SCRIPT
  echo "    create table sash_all ( 
                dbid           number, 
                sample_time     date,
                session_id      number,
                session_state   varchar2(20),
                session_serial# number,
                user_id         number,
                sql_address     varchar2(20),
                sql_plan_hash_value  number,
                sql_child_number  number,
                sql_id          number,
                sql_opcode      number,
                session_type    number,
                event           varchar2(64),
                event#          number,
                seq#            number,
                p1              number,
                p2              number,
                p3              number,
                wait_time       number,
                time_waited     number,
                current_obj#    number,
                current_file#   number,
                current_block#  number,
                program         varchar2(64),
                module          number,
                action          number, 
                FIXED_TABLE_SEQUENCE number,
                sample_id       number,
                machine         varchar2(64), 
                terminal        varchar2(30)
               ) 
             PARTITION BY RANGE (SAMPLE_TIME)
             SUBPARTITION BY LIST (DBID)
             SUBPARTITION TEMPLATE
              (SUBPARTITION S_$DBID VALUES ($DBID)) 
              (PARTITION P_1 VALUES LESS THAN (to_date('$SDATE','DD-MM-YYYY'))
              )
         ;
         create index sash_i on sash_all(sample_time) local;
         create   table sash_curhost (dbid number);
         create sequence sash_part_seq start with 1 increment by 1 nocache;
         create table sash_log
           (start_time   date default sysdate,
            action       varchar2(100),
            result       char(1),
            message      varchar2(1000));

         create table sash_sqlplans_all (
              statement_id    varchar2(30),
              timestamp       date,
              remarks         varchar2(80),
              operation       varchar2(30),
              options         varchar2(255),
              object_node     varchar2(128),
              object_owner    varchar2(30),
              object_name     varchar2(30),
              object_instance numeric,
              object_type     varchar2(30),
              optimizer       varchar2(255),
              search_columns  number,
              id              numeric,
              parent_id       numeric,
              position        numeric,
              cost            numeric,
              cardinality     numeric,
              bytes           numeric,
              other_tag       varchar2(255),
              partition_start varchar2(255),
              partition_stop  varchar2(255),
              partition_id    numeric,
              other           long,
              distribution    varchar2(30),
              cpu_cost        numeric,
              io_cost         numeric,
              temp_space      numeric,
              access_predicates varchar2(4000),
              filter_predicates varchar2(4000),
              hash_value     number,
              child_number     number,
              dbid number);
         create index sash_sqlplans_i  
              on sash_sqlplans_all (dbid, statement_id);
         create table sash_params_all (
              dbid number, 
              name varchar2(64),
              value varchar2(512));
         create unique index sash_params_i 
              on sash_params_all ( dbid , name );
         create table sash_event_names_all ( 
              dbid number, 
              event# number, 
              name varchar2(64));
         create unique index sash_event_names_i 
              on sash_event_names_all ( dbid , event# );
         create table sash_users_all 
            ( dbid number, 
              username varchar2(30), 
              user_id number);
         create unique index sash_users_i on sash_users_all (dbid, user_id);
         create table sash_latch_all   
            ( dbid  number,
              latch# number,
              name varchar2(64));
         create table sash_sessids_all   
            ( dbid  number,
              session_id number,
              session_serial# number);
         create table sash_sesstat_all   
            ( dbid  number,
              session_id number,
              session_serial# number);
         create table sash_sqlids_all   
            ( dbid number,
              address raw(8),
              sql_id  varchar(13),
              child_number number,
              plan_hash_value number,
              command_type number,
              memory  number,
              sql_text varchar(64),
              last_found date,
              first_found date,
              found_count number );
         create unique index sash_sqlids_i on sash_sqlids_all
              (dbid,
               sql_id,
               child_number);
         create table sash_sqltxt_all   
            ( dbid number,
              address raw(8),
              sql_id number,
              child_number number,
              piece number,
              sql_text varchar(64));
         create unique index sash_sqltxt_i on sash_sqltxt_all
              (dbid,
               sql_id,
               piece);
         create table sash_sqlstats_all ( 
              dbid number, 
              sample_time date, 
              address raw(8), 
              hash_value number, 
              child_number number,
              executions number, 
              elapsed_time number, 
              disk_reads number, 
              buffer_gets number, 
              cpu_time number, 
              elasped_time number, 
              fetches number, 
              rows_processed number); 
         create table sash_objs_all (
              dbid number,  
              object_id number, 
              owner varchar2(30), 
              object_name varchar2(128), 
              subobject_name varchar2(30), 
              object_type varchar2(18));
         create unique index sash_objs_i on sash_objs_all 
              (dbid, object_id);
         create table sash_targets (
            dbid number,
            host varchar2(30),
            home varchar2(100),
            sid  varchar2(10),
            version varchar2(20),
            cpu_count number,
            sashseq number
         );
         create unique index sash_targets_i on sash_targets ( host,sid,home);
         drop view sash;
         create view sash as select * from sash_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_params;
         create view sash_params as select * from sash_params_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_event_names;
         create view sash_event_names as select * from sash_event_names_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_latch;
         create view sash_latch as select * from sash_latch_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_objs;
         create view sash_objs as select * from sash_objs_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_users;
         create view sash_users as select * from sash_users_all
             where dbid = ( select dbid from sash_curhost);
      -- sql
         drop view sash_sqlids;
         create view sash_sqlids as select * from sash_sqlids_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_sqltxt;
         create view sash_sqltxt as select * from sash_sqltxt_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_sqlstats;
         create view sash_sqlstats as select * from sash_sqlstats_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_sqlplans;
         create view sash_sqlplans as select * from sash_sqlplans_all
             where dbid = ( select dbid from sash_curhost);
      -- sess
         drop view sash_sessids;
         create view sash_sessids as select * from sash_sessids_all
             where dbid = ( select dbid from sash_curhost);
         drop view sash_sesstat;
         create view sash_sesstat as select * from sash_sesstat_all
             where dbid = ( select dbid from sash_curhost);"
  done >> $CREATE
  # END   CREATE REPOSITORY TABLES SCRIPT

  # BEGIN CREATE DATABASE LINK SCRIPT
  echo 'DROP DATABASE LINK "SASHREPO";' > $DBLINK
  for i in 1 ; do
    echo 'CREATE DATABASE LINK "SASHREPO"'
    echo "CONNECT TO \"$REPO_SCHEMA\""
    echo "IDENTIFIED BY \"$REPO_PW\""
    echo 'USING'
    echo "'$TNS';"
  done >> $DBLINK
  # END   CREATE DATABASE LINK SCRIPT
fi
# END   CREATE REPOSITORY SCRIPTS

# ============ Drop REPO =====================
if [  $OPTS -eq -1 ]; then
  echo "DROPPING ........."
  echo "sqlplus -s $REPO_SCHEMA/$REPO_PW@${TNS} "
  sqlplus -s $REPO_SCHEMA/$REPO_PW@${TNS} << EOF
    @${DROP}
    exit
EOF
fi

# ============ Create REPO =====================
if [  $OPTS -eq 0  -o $OPTS -eq 2 ]; then
  echo "sqlplus -s $REPO_SCHEMA/$REPO_PW@${TNS} "
  sqlplus -s $REPO_SCHEMA/$REPO_PW@${TNS} << EOF
    !echo "CREATING REPO TABLES........."
    @${CREATE}
    !echo "CREATING REPO MNG PKG........."
    @${SASHPKG}
    ! echo 'exec sashmng_pkg.add_subpartition(${DBID});'
    exec sashmng_pkg.add_subpartition(${DBID});
    exit
EOF
fi


# ============ Create Target Sampling Package  =====================
if [ $OPTS -eq 1 -o $OPTS -eq 2 ]; then


sqlplus -s "$TARG_SCHEMA/$TARG_PW" << EOF
  
  @${DBLINK}

  -- don't drop incase it's used by a currently running collection
  -- otherwise start reusing the same values
  --drop sequence sashseq;

  create sequence sashseq ;

/* this view could be change in many ways
   it might be good to get program from v$process
   it might be good to add machine
*/

  drop view sashnow;

  prompt "For 10g only (Errors on 9i or below ok)"
  prompt "elimates costly v\$session_wait join for 10g"
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
                 s.ksusesqh      "SQL_ID" ,
                 decode(s.ksusesch, 65535, to_number(null), s.ksusesch) "SQL_CHILD_NUMBER",
                 s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.ksuseflg      "SESSION_TYPE"  ,
                 ''              "EVENT",
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
               sys.x\$ksuse s , /* v$session */
               v\$database d
       where
               s.indx != ( select distinct sid from v\$mystat  where rownum < 2 ) and
               bitand(s.ksspaflg,1)!=0 and
               bitand(s.ksuseflg,1)!=0 and
            (  (
                  /* status Active - seems inactive & "on cpu"=> not on CPU */
                  s.ksusetim != 0  and  /* on CPU  */
                  bitand(s.ksuseidl,11)=1  /* ACTIVE */
               )
                     or
               s.ksuseopc not in   /* waiting and the wait event is not idle */
                   (  select event# from v\$event_name where wait_class='Idle' )
            );

  prompt "For 9i  (errors on 10g+ or 8 or 7 ok)"
  prompt "joins with v\$session_wait and includes sql_plan_hash_value"
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
                 ''              "EVENT",
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
               sys.x\$ksuse s , /* v$session */
               sys.x\$ksusecst w, /* v$session_wait */
               v\$database d
       where
               s.indx != ( select distinct sid from v\$mystat  where rownum < 2 ) and
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
                             v\$event_name
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
                 ''              "EVENT",
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
               sys.x\$ksuse s , /* v$session */
               sys.x\$ksusecst w, /* v$session_wait */
               v\$database d
       where
               s.indx != ( select distinct sid from v\$mystat  where rownum < 2 ) and
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
                             v\$event_name
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
                 decode(s.WAIT_TIME, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.serial#         "SESSION_SERIAL#",
                 s.user#           "USER_ID",
                 s.sql_address     "SQL_ADDRESS",
                 -1                "SQL_PLAN_HASH_VALUE",
                 -1                "SQL_CHILD_NUMBER",
                 s.sql_hash_value      "SQL_ID" ,
                 s.command         "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.type            "SESSION_TYPE"  ,
                 -1                "EVENT#",
                 w.event           "EVENT",
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
               v\$session s ,
               v\$database d,
               v\$session_wait w
       where
               s.sid != ( select distinct sid from v\$mystat  where rownum < 2 ) and
               w.sid = s.sid and
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
  --  REMOVE OLD JOBS
  --

   begin
     for i in  ( select job from dba_jobs
             where substr(what,1,16)='sash_pkg.collect'
               or
                   substr(what,1,16)='sash_pkg.get_all'
             ) loop
        dbms_output.put_line( 'rdbms_job.remove ' || i.job );
        dbms_job.remove( i.job );
     end loop;
   end;
/

--
-- BEGIN CREATE TARGET PACKAGE SASH_PKG
--
CREATE OR REPLACE PACKAGE sash_pkg AS
--          PROCEDURE print (sleep number, loops number) ;
          PROCEDURE get_all  ;
          PROCEDURE get_objs  ;
          PROCEDURE get_users  ;
	  PROCEDURE get_params  ;
          PROCEDURE get_sqltxt  ;
          PROCEDURE get_sqlstats  ;
          PROCEDURE get_sqlplans  ;
          PROCEDURE get_event_names  ;
          PROCEDURE collect (sleep number, loops number) ;
          PROCEDURE purge (part number) ;
          PROCEDURE purgeall  ;
          FUNCTION get_dbid  return number ;
          PROCEDURE set_dbid  ;
          END sash_pkg;
/
show errors

--
-- BEGIN CREATE TARGET PACKAGE BODY SASH_PKG
--
CREATE OR REPLACE PACKAGE BODY sash_pkg AS

       FUNCTION get_dbid return number is
          l_dbid number;
          begin
            select dbid into l_dbid from sys.v\$database;
            return l_dbid;
            -- return 1;
       end get_dbid;

       PROCEDURE get_users is
          l_dbid number;
          begin
            select dbid into l_dbid from sys.v\$database;
            insert into ${REPO_SCHEMA}.sash_users_all${DBL} 
                     (dbid, username, user_id)
                     select l_dbid,username,user_id from dba_users; 
            commit;
       end get_users;

       PROCEDURE get_params is
          l_dbid number;
          begin
            select dbid into l_dbid from sys.v\$database;
            insert into ${REPO_SCHEMA}.sash_params_all${DBL} 
                  ( dbid, name, value)
                  select l_dbid,name,value from gv\$parameter;
            commit;
       end get_params;

       PROCEDURE set_dbid is
          l_dbid number;
          l_version varchar(17);
          cnt number;
          begin 
            select dbid into l_dbid from sys.v\$database;
            select count(*) into cnt from 
                ${REPO_SCHEMA}.sash_curhost${DBL};
            if cnt = 0 then 
                insert into 
                   ${REPO_SCHEMA}.sash_curhost${DBL} ( dbid )
                   values (l_dbid);
            end if;
            commit;
            select version into l_version from sys.v\$instance;
            insert into ${REPO_SCHEMA}.sash_targets${DBL} 
                  (dbid, host, home, sid, sashseq, version)
                  values (l_dbid,
                          '${TARG_HOST}',
                          '${TARG_HOME}',
                          '${TARG_SID}',
                          0,
                          l_version); 
            commit;
       end set_dbid;

       PROCEDURE purgeall is
          PRAGMA AUTONOMOUS_TRANSACTION;
       begin
         for i in 1..$nparts loop
            purge(i);
         end loop; 
       end purgeall;

       PROCEDURE get_event_names is
          l_dbid number;
       begin
          l_dbid:=get_dbid;
          insert into ${REPO_SCHEMA}.sash_event_names_all${DBL} 
                  ( dbid, event#, name )
                   select l_dbid, event#, name from gv\$event_name;
       end get_event_names;

       PROCEDURE get_objs is
          l_dbid number;
       begin
         l_dbid:=get_dbid;
         -- get object info  for top 20 sql in SASH over the last hour
         insert into  ${REPO_SCHEMA}.sash_objs_all${DBL}
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
                        from ${REPO_SCHEMA}.sash_all${DBL} 
                        where
                               l_dbid = dbid
                           and current_obj# > 0
                           and sample_time > (sysdate - 1/24)
                        group by current_obj#
                        order by cnt desc )
                     where rownum < 21)
                  and object_id not in (select object_id from 
                       ${REPO_SCHEMA}.sash_objs_all${DBL} 
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
         insert into  ${REPO_SCHEMA}.sash_sqlplans_all${DBL} 
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
                      ADDRESS,
                       sysdate,
                       'REMARKS',
                       OPERATION,
                       OPTIONS,
                       OBJECT_NODE,
                       OBJECT_OWNER,
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
                from gv\$sql_plan sql
                where sql.hash_value in ( 
                       select  hash_value
                       from ${REPO_SCHEMA}.sash_sqltxt_all${DBL} 
                       where l_dbid = dbid )
                  and sql.hash_value not in (
                       select hash_value 
                       from ${REPO_SCHEMA}.sash_sqlplans_all${DBL} 
                       where l_dbid = dbid);
         commit;
       end get_sqlplans;

       PROCEDURE get_sqlstats is
          l_dbid number;
       begin
         l_dbid:=get_dbid;
         -- get sql stats  for top 20 sql in SASH over the last hour
         insert into  ${REPO_SCHEMA}.sash_sqlstats_all${DBL} 
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
                from gv\$sql sql
                where sql.hash_value in ( 
                       select  hash_value
                       from ${REPO_SCHEMA}.sash_sqltxt_all${DBL} 
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
                          from ${REPO_SCHEMA}.sash_all${DBL} 
                          where l_dbid = dbid
                             and sql_id != 0
                             and sample_time > (sysdate - 1/24)
                          group by sql_id
                          order by cnt desc )
                        where rownum < 21;

       begin
         l_dbid:=get_dbid;
         for f_sqlid in c_sqlids loop
           update  ${REPO_SCHEMA}.sash_sqlids_all${DBL}
                set 
                       last_found = sysdate ,
                       found_count = nvl(found_count,1) + 1
                where 
                       sql_id = f_sqlid.sql_id
                   and l_dbid = dbid;
           up_rows:=sql%rowcount;
           if up_rows = 0 then
             insert into  ${REPO_SCHEMA}.sash_sqlids_all${DBL} 
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
                  from gv\$sql sqlt
                  where 
                        sqlt.hash_value = f_sqlid.sql_id;
             insert into  ${REPO_SCHEMA}.sash_sqltxt_all${DBL} 
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
                from gv\$sqltext sqlt
                where sqlt.hash_value = f_sqlid.sql_id ;
             end if;
           end loop;
         commit;
       end get_sqltxt;

 
       PROCEDURE purge(part number) is
          PRAGMA AUTONOMOUS_TRANSACTION;
          l_text varchar2(200);
       begin
         l_text:='truncate table ${REPO_SCHEMA}sash_'||
                      to_char(part)||'${DBL} reuse storage';
         dbms_output.put_line(l_text);
         execute immediate l_text;
       end purge;

/*
       PROCEDURE print(sleep number, loops number) is
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
              dbms_lock.sleep(sleep);
              close sash_cur;
            end loop;
       end print;
*/

       PROCEDURE collect(sleep number, loops number) is
          sash_rec ${REPO_SCHEMA}.sash_all${DBL}%rowtype;
          l_dbid number;
          cpart    number := -1;      /* current partition number */
          part     number := 1;       /* new partition number */
          npart    number := $nparts; /* current partition number */
          cur_sashseq   number := 0;
          -- return ${REPO_SCHEMA}.sash${DBL}%rowtype is
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
              -- update  ${REPO_SCHEMA}.sash_targets${DBL} set sashseq = cur_ashseq
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
                  insert into ${REPO_SCHEMA}.sash_all${DBL}
                   (  DBID,
                      SAMPLE_TIME,
                      SESSION_ID,
                      SESSION_STATE,
                      SESSION_SERIAL#,
                      USER_ID,
                      SQL_ADDRESS,
                      SQL_PLAN_HASH_VALUE,
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
              dbms_lock.sleep(sleep);
            end loop;
       end collect;

END sash_pkg;
/

show errors

exec sash_pkg.set_dbid;
exec sash_pkg.get_event_names;
exec sash_pkg.get_users;
exec sash_pkg.get_params;

column job format 99999
column log_user format a8
column priv_user format a8
column schema_user format a8
column last format a8
column b format a1
column fail format 999
column what format a70

-- 
--  START JOBS
--
   variable job number
   begin
         dbms_job.submit( job       => :job
                        ,what      => 'sash_pkg.collect(3,1200);'
                        ,next_date => sysdate
                        ,interval => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
   end;
/
   begin
        dbms_job.submit(:job,
                        'sash_pkg.get_all;',
                        sysdate,
                        'trunc(sysdate+(1/(24)),''HH'')'
                        );
   end;
/
   commit;

--
-- OUTPOUT 
--

select job, log_user,priv_user, schema_user, last_sec,
       this_sec,next_sec, broken b, failures fail, total_time, what
   from dba_jobs
   where substr(what,1,16)='sash_pkg.collect'
           or
         substr(what,1,16)='sash_pkg.get_all'
/


exit
EOF
fi




