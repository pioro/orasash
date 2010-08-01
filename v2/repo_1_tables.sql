
-- (c) Kyle Hailey 2007


Prompt 'Are you connected as the SASH user? '
Accept toto prompt 'If you are not the SASH user hit Control-C , else Return : ' 
--connect sash/&password

        drop table sash1;
        drop table sash2;
        drop table sash3;
        drop table sash4;
        drop table sash5;
        drop table sash6;
        drop table sash7;
        drop table sash_log;
        drop table sash_params;
        drop table sash_sqlids;
        drop table sash_sqltxt;
        drop table sash_sqlstats; 
        drop table sash_sqlplans;
        drop table sash_event_names;
        drop table sash_objs;
        drop table sash_users;
        drop table sash_data_files;
        drop table sash_sesstat;
        drop table sash_sessids;
        drop table sash_latch;
        drop table sash_targets;
        drop table sash_target;

 create table sash1 ( 
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
         ;
         create table sash2 as select * from sash1 where rownum <1;
         create table sash3 as select * from sash1 where rownum <1;
         create table sash4 as select * from sash1 where rownum <1;
         create table sash5 as select * from sash1 where rownum <1;
         create table sash6 as select * from sash1 where rownum <1;
         create table sash7 as select * from sash1 where rownum <1;
         create index sash_1i on sash1(dbid,sample_time) ;
         create index sash_2i on sash2(dbid,sample_time) ;
         create index sash_3i on sash3(dbid,sample_time) ;
         create index sash_4i on sash4(dbid,sample_time) ;
         create index sash_5i on sash5(dbid,sample_time) ;
         create index sash_6i on sash6(dbid,sample_time) ;
         create index sash_7i on sash7(dbid,sample_time) ;
         create or replace view sash as select * from sash1;

         create table sash_log
           (start_time   date default sysdate,
            action       varchar2(100),
            result       char(1),
            message      varchar2(1000));

         create table sash_sqlplans(
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
              other           varchar2(4000),
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
              on sash_sqlplans(dbid, statement_id);
         create table sash_params(
              dbid number, 
              name varchar2(64),
              value varchar2(512));
         create unique index sash_params_i 
              on sash_params( dbid , name );
         create table sash_event_names( 
              dbid number, 
              event# number, 
              wait_class varchar2(64), 
              name varchar2(64));
         create table sash_data_files( 
              dbid number, 
              file_name varchar2(513), 
              file_id number,
              tablespace_name varchar(30) 
              );
         create unique index sash_event_names_i 
              on sash_event_names( dbid , event# );
         create table sash_users
            ( dbid number, 
              username varchar2(30), 
              user_id number);
         create unique index sash_users_i 
              on sash_users(dbid, user_id);
         create table sash_latch
            ( dbid  number,
              latch# number,
              name varchar2(64));
         create table sash_sessids
            ( dbid  number,
              session_id number,
              session_serial# number);
         create table sash_sesstat
            ( dbid  number,
              session_id number,
              session_serial# number);
         create table sash_sqlids
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
         create unique index sash_sqlids_i on sash_sqlids
              (dbid,
               sql_id,
               child_number);
         create table sash_sqltxt
            ( dbid number,
              address raw(8),
              sql_id number,
              child_number number,
              piece number,
              sql_text varchar(64));
         create unique index sash_sqltxt_i on sash_sqltxt
              (dbid,
               sql_id,
               piece);
         create table sash_sqlstats( 
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
              fetches number, 
              rows_processed number); 
         create table sash_objs(
              dbid number,  
              object_id number, 
              owner varchar2(30), 
              object_name varchar2(128), 
              subobject_name varchar2(30), 
              object_type varchar2(18));
         create unique index sash_objs_i on sash_objs
              (dbid, object_id);

         create table sash_target (dbid number);
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

         create or replace view sash_all as 
             select * from sash1
          union all
             select * from sash2
          union all
             select * from sash3
          union all
             select * from sash4
          union all
             select * from sash5
          union all
             select * from sash6
          union all
             select * from sash7
          ;

     drop table waitgroups;
     create table waitgroups (
           NAME         VARCHAR2(64),
           WAIT_CLASS   VARCHAR2(64)
     );
     create index waitgroups_i on waitgroups(name);

     create or replace view v$active_session_history as
       select
         ash.dbid           ,
         ash.sample_time     ,
         ash.session_id      ,
         ash.session_state   ,
         ash.session_serial# ,
         ash.user_id         ,
         ash.sql_address     ,
         ash.sql_id          ,
         ash.sql_plan_hash_value  ,
         ash.sql_opcode      ,
         ash.session_type    ,
         ash.event#          ,
         ash.seq#            ,
         ash.p1              ,
         ash.p2              ,
         ash.p3              ,
         ash.wait_time       ,
         ash.current_obj#    ,
         ash.current_file#   ,
         ash.current_block#  ,
         ash.program         ,
         ash.module          ,
         ash.action          ,
         ash.FIXED_TABLE_SEQUENCE ,
         ash.sample_id       ,
         e.name event         ,
         nvl(e.wait_class,'Other') wait_class
    from
         sash_all ash,
         sash_event_names  e
    where
         e.event# = ash.event# and
         e.dbid = ( select dbid from sash_target) and
         ash.dbid = ( select dbid from sash_target) ;

   create or replace view dba_hist_active_sess_history 
     as 
     select * from v$active_session_history 
     where rownum < 1;

   create or replace view v$sqltext_with_newlines as 
     select 
            DBID         ,
            ADDRESS      ,
            sql_id,    
            PIECE        ,
            SQL_TEXT     
     from  
            sash_sqltxt
     where dbid = ( select dbid from sash_target);

   create or replace view v$instance as select 
        version  version,
        host     host_name,
        sid      instance_name
     from sash_targets 
     where dbid = ( select dbid from sash_target);

   create or replace view v$parameter as select * from sash_params
          where dbid = ( select dbid from sash_target);

   create or replace view dba_users as select * from sash_users
          where dbid = ( select dbid from sash_target);

    create or replace view dba_data_files as select * from sash_data_files
          where dbid = ( select dbid from sash_target);

   create or replace view all_objects as select * from sash_objs
          where dbid = ( select dbid from sash_target);



/*
 if you run this as SYS you'll have to recreate them
  ?/rdbms/admim/catalog.sql
   dba_users 
   all_objects 
  ?/rdbms/admim/catspace.sql
   dba_data_files 
 these should surive attempts to modify
   v$sqltext_with_newlines 
   v$instance 
   v$parameter 
*/






