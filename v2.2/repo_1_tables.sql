---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: Increase number of tables to poor man paritioning, add configuration tables
-- v2.2 Changes: Schema clean up - hash values, statament id changed to sql_id,
--               sql_id changed to 10g and above format - varachar2(13)
--               new table, sequence and columns for better history clean up - T: sash_hist_sample, S: hist_id_seq C:hist_sample_id
--               new table - sash_extents to keep extentes from target database

Prompt Are you connected as the SASH schema owner? All objects will be dropped and recreated
Accept toto prompt 'If you are not the SASH user hit Control-C , else Return : ' 

Prompt Dropping old objects

drop table sash1;
drop table sash2;
drop table sash3;
drop table sash4;
drop table sash5;
drop table sash6;
drop table sash7;
drop table sash8;		
drop table sash9;		
drop table sash10;
drop table sash11;
drop table sash12;
drop table sash13;
drop table sash14;
drop table sash15;
drop table sash16;
drop table sash17;
drop table sash18;
drop table sash19;
drop table sash20;
drop table sash21;
drop table sash22;
drop table sash23;
drop table sash24;
drop table sash25;
drop table sash26;
drop table sash27;
drop table sash28;
drop table sash29;
drop table sash30;
drop table sash31;
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
drop table sash_stats;
drop table sash_sessids;
drop table sash_latch;
drop table sash_targets;
drop table sash_target;
drop table sash_extents;
drop table sash_configuration;
drop table sash_hist_sample;
drop table waitgroups;
drop sequence hist_id_seq;
 
Prompt Create sequence

create sequence hist_id_seq;				

Prompt Create tables

-- create first table to keep active sessions data

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
);

-- create rest of active sessions tables to simulate poor man partitioning

create table sash2 as select * from sash1 where rownum <1;
create table sash3 as select * from sash1 where rownum <1;
create table sash4 as select * from sash1 where rownum <1;
create table sash5 as select * from sash1 where rownum <1;
create table sash6 as select * from sash1 where rownum <1;
create table sash7 as select * from sash1 where rownum <1;
create table sash8 as select * from sash1 where rownum <1;		 
create table sash9 as select * from sash1 where rownum <1;
create table sash10 as select * from sash1 where rownum <1;
create table sash11 as select * from sash1 where rownum <1;
create table sash12 as select * from sash1 where rownum <1;
create table sash13 as select * from sash1 where rownum <1;
create table sash14 as select * from sash1 where rownum <1;
create table sash15 as select * from sash1 where rownum <1;
create table sash16 as select * from sash1 where rownum <1;
create table sash17 as select * from sash1 where rownum <1;
create table sash18 as select * from sash1 where rownum <1;
create table sash19 as select * from sash1 where rownum <1;
create table sash20 as select * from sash1 where rownum <1;
create table sash21 as select * from sash1 where rownum <1;
create table sash22 as select * from sash1 where rownum <1;
create table sash23 as select * from sash1 where rownum <1;
create table sash24 as select * from sash1 where rownum <1;
create table sash25 as select * from sash1 where rownum <1;
create table sash26 as select * from sash1 where rownum <1;
create table sash27 as select * from sash1 where rownum <1;
create table sash28 as select * from sash1 where rownum <1;
create table sash29 as select * from sash1 where rownum <1;
create table sash30 as select * from sash1 where rownum <1;
create table sash31 as select * from sash1 where rownum <1;

-- create indexes 		 
create index sash_1i on sash1(dbid,sample_time) ;
create index sash_2i on sash2(dbid,sample_time) ;
create index sash_3i on sash3(dbid,sample_time) ;
create index sash_4i on sash4(dbid,sample_time) ;
create index sash_5i on sash5(dbid,sample_time) ;
create index sash_6i on sash6(dbid,sample_time) ;
create index sash_7i on sash7(dbid,sample_time) ;
create index sash_8i on sash8(dbid,sample_time) ;
create index sash_9i on sash9(dbid,sample_time) ;
create index sash_10i on sash10(dbid,sample_time) ;
create index sash_11i on sash11(dbid,sample_time) ;
create index sash_12i on sash12(dbid,sample_time) ;
create index sash_13i on sash13(dbid,sample_time) ;
create index sash_14i on sash14(dbid,sample_time) ;
create index sash_15i on sash15(dbid,sample_time) ;
create index sash_16i on sash16(dbid,sample_time) ;
create index sash_17i on sash17(dbid,sample_time) ;
create index sash_18i on sash18(dbid,sample_time) ;
create index sash_19i on sash19(dbid,sample_time) ;
create index sash_20i on sash20(dbid,sample_time) ;
create index sash_21i on sash21(dbid,sample_time) ;
create index sash_22i on sash22(dbid,sample_time) ;
create index sash_23i on sash23(dbid,sample_time) ;
create index sash_24i on sash24(dbid,sample_time) ;
create index sash_25i on sash25(dbid,sample_time) ;
create index sash_26i on sash26(dbid,sample_time) ;
create index sash_27i on sash27(dbid,sample_time) ;
create index sash_28i on sash28(dbid,sample_time) ;
create index sash_29i on sash29(dbid,sample_time) ;
create index sash_30i on sash30(dbid,sample_time) ;
create index sash_31i on sash31(dbid,sample_time) ;

         create or replace view sash as select * from sash1;

         create table sash_log
           (start_time   date default sysdate,
            action       varchar2(100),
            result       char(1),
            message      varchar2(1000));
			
		 create or replace public synonym sash_log for sash_log;
			
		 create table sash_stats
			(
			  dbid        number,
			  statistic#  number,
			  name        varchar2(4000)
			);

		 create table sash_hist_sample(
			hist_sample_id  number,
			dbid			number,
			hist_date		date
		 );
			
         create table sash_sqlplans(
			  hist_sample_id  number,
              sql_id    	  varchar2(13),
			  plan_hash_value number,
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
              on sash_sqlplans(dbid, sql_id);
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
            (   statid           number,
				sdate            date,
				dbid             number,
				session_id       number,
				session_serial#  number,
				statistic#       number,
				value            number);
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
              hist_sample_id number, 
              address raw(8), 
              sql_id varchar2(13), 
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
		 
		 create table sash_extents (
            dbid number,
			segment_name varchar2 (100),
			partition_name varchar2 (30),
			segment_type varchar2 (20),
			tablespace_name	varchar2 (30),
			extent_id	number,	
			file_id		number,
			block_id	number,
			bytes		number,	
			blocks		number,
			relative_fno number
         );
		 
		 create index sash_extents_blc_idx on sash_extents (file_id, block_id, block_id+blocks);
		 
         create unique index sash_targets_i on sash_targets ( host,sid,home);

		create or replace force view sash_all
		as
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
		   select *from sash7
		   union all
		   select * from sash8
		   union all
		   select * from sash9
		   union all
		   select * from sash10
		   union all
		   select * from sash11
		   union all
		   select * from sash12
		   union all
		   select * from sash13
		   union all
		   select * from sash14
		   union all
		   select * from sash15
		   union all
		   select * from sash16
		   union all
		   select * from sash17
		   union all
		   select * from sash18
		   union all
		   select * from sash19
		   union all
		   select * from sash20
		   union all
		   select * from sash21
		   union all
		   select * from sash22
		   union all
		   select * from sash23
		   union all
		   select * from sash24
		   union all
		   select * from sash25
		   union all
		   select * from sash26
		   union all
		   select * from sash27
		   union all
		   select * from sash28
		   union all
		   select * from sash29
		   union all
		   select * from sash30
		   union all
		   select * from sash31;




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
         decode(bitand(ash.session_type,19),17,'BACKGROUND',1,'FOREGROUND',2,'RECURSIVE','?') session_type, --9i
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
	  
   create table sash_configuration (
      param       	varchar2(30),
      value		    varchar2(100)
   );
   
   create unique index sash_configuration_unq on sash_configuration(param);
   
   insert into sash_configuration values ('SASH RETENTION','w');
   commit;
   
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


