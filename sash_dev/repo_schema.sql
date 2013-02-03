---------------------------------------------------------------------------------------------------
-- File Revision $Rev: 43 $
-- Last change $Date: 2011-10-27 17:07:43 +0100 (Thu, 27 Oct 2011) $
-- SVN URL $HeadURL: https://orasash.svn.sourceforge.net/svnroot/orasash/v2.3/repo_1_tables.sql $
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: Increase number of tables to poor man paritioning, add configuration tables
-- v2.2 Changes: Schema clean up - hash values, statament id changed to sql_id,
--               sql_id changed to 10g and above format - varachar2(13)
--               new table, sequence and columns for better history clean up - T: sash_hist_sample, S: hist_id_seq C:hist_sample_id
--               new table - sash_extents to keep extentes from target database
-- v2.3 Changes: new fields in SASH table
--               new installation script
--               changes in v$active_session_istory view
--               new tables to keep metrics history
--               new version of sash_sqlstats
--v2.3 Changes:  new field in SASH table OSUSER -- AlbertoFro
--		 new table SASH_OBJ_PLUS -- AlbertoFro
--               new field in SASH_EVENT_NAMES table event_id -- AlbertoFro
--		 new table SASH_TOP10 -- AlbertoFro
--		 new column OWNER in SASH_OBJ_PLUS -- AlbertoFro
--		 new table SASH_RMAN_STAT -- AlbertoFro


set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('&SASH_USER');
spool off

@exit.sql

-- drop objects

spool drop.sql
select 'drop ' || object_type || ' ' || object_name || ';' from user_objects where object_type in ('TABLE','SEQUENCE','PACKAGE','DATABASE LINK');
spool off
@drop.sql

set term on
spool sash_tables.log
 
Prompt Create sequence

create sequence hist_id_seq;				
create sequence log_id_seq;				

Prompt Create tables

-- create first table to keep active sessions data

create table sash1 ( 
                dbid                number, 
                sample_time         date,
                session_id          number,
                session_state       varchar2(20),
                session_serial#     number,
                OSUSER              VARCHAR2(30),
                session_type        number,                
                user_id             number,
                command             number,
                machine             varchar2(64), 
                port                number,
                sql_address         varchar2(20),
                sql_plan_hash_value number,
                sql_child_number    number,
                sql_id              varchar2(13),
                sql_opcode          number,
                SQL_EXEC_START      date,
				SQL_EXEC_ID         number,
                PLSQL_ENTRY_OBJECT_ID       number,
				PLSQL_ENTRY_SUBPROGRAM_ID   number,
				PLSQL_OBJECT_ID     number,
				PLSQL_SUBPROGRAM_ID number,                
                event#              number,
                seq#                number,
                p1                  number,
                p2                  number,
                p3                  number,
                wait_time           number,
                time_waited         number,
                current_obj#        number,
                current_file#       number,
                current_block#      number,
				current_row#      	number,
                program             varchar2(64),
                module              varchar2(48),
                MODULE_HASH         number,
                action              varchar2(64), 
                ACTION_HASH         number,
                LOGON_TIME          date,
                KSUSEBLOCKER        number,
                SERVICE_NAME        varchar2(64),
                FIXED_TABLE_SEQUENCE    number,
                QC                  number,
                sample_id           number,
                terminal            varchar2(30),
				inst_id		        number
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
create index sash_1i on sash1(sample_time,dbid) ;
create index sash_2i on sash2(sample_time,dbid) ;
create index sash_3i on sash3(sample_time,dbid) ;
create index sash_4i on sash4(sample_time,dbid) ;
create index sash_5i on sash5(sample_time,dbid) ;
create index sash_6i on sash6(sample_time,dbid) ;
create index sash_7i on sash7(sample_time,dbid) ;
create index sash_8i on sash8(sample_time,dbid) ;
create index sash_9i on sash9(sample_time,dbid) ;
create index sash_10i on sash10(sample_time,dbid) ;
create index sash_11i on sash11(sample_time,dbid) ;
create index sash_12i on sash12(sample_time,dbid) ;
create index sash_13i on sash13(sample_time,dbid) ;
create index sash_14i on sash14(sample_time,dbid) ;
create index sash_15i on sash15(sample_time,dbid) ;
create index sash_16i on sash16(sample_time,dbid) ;
create index sash_17i on sash17(sample_time,dbid) ;
create index sash_18i on sash18(sample_time,dbid) ;
create index sash_19i on sash19(sample_time,dbid) ;
create index sash_20i on sash20(sample_time,dbid) ;
create index sash_21i on sash21(sample_time,dbid) ;
create index sash_22i on sash22(sample_time,dbid) ;
create index sash_23i on sash23(sample_time,dbid) ;
create index sash_24i on sash24(sample_time,dbid) ;
create index sash_25i on sash25(sample_time,dbid) ;
create index sash_26i on sash26(sample_time,dbid) ;
create index sash_27i on sash27(sample_time,dbid) ;
create index sash_28i on sash28(sample_time,dbid) ;
create index sash_29i on sash29(sample_time,dbid) ;
create index sash_30i on sash30(sample_time,dbid) ;
create index sash_31i on sash31(sample_time,dbid) ;

create or replace view sash as select * from sash1;
create or replace view sash_all as select * from sash1;


create table sash_obj_plus (
DBID	number,
owner varchar2(30),
table_name	varchar2(30),
index_name	varchar2(30),
type_index	varchar2(9),
lblocks	number,
DKEYS	NUMBER,
cf	number,
status	varchar2(8),
NROWS	NUMBER,
blocks	number,
avgrow_l	number,
LANALYZED_T	DATE,
lanalyzed_i	date,
clustering	number,
partitioned	varchar2(3)
);

create unique index SASH_OBJ_PLUS_I on sash_obj_plus (owner,DBID, TABLE_NAME,INDEX_NAME) ;


create table sash_top10 ( 
		dbid			 number,
                date_snap           date,
                sql_id              varchar2(13),
                cpu                number, 
                user_i_o                number, 
                system_i_o                number, 
                administration          number,
                other          number,
                configuration          number,
                application         number,
                concurrency         number,
                network               number,
                total               number            
);

create unique index SASH_GET_TOP10_I on sash_top10 (SQL_ID,DATE_SNAP) ;


create table SASH_RMAN_STAT (
DBID	number,
INPUT_TYPE	VARCHAR2(13),
OUTPUT_DEVICE_TYPE	VARCHAR2(17),
STATUS	VARCHAR2(23),
OUTPUT_BYTES_DISPLAY	VARCHAR2(4000),
OUTPUT_BYTES_PER_SEC_DISPLAY	VARCHAR2(4000),
TIME_TAKEN_DISPLAY	VARCHAR2(4000),
START_TIME	DATE,
END_TIME	DATE,
SESSION_RECID	NUMBER
);

create index SASH_RMAN_STAT_I on SASH_RMAN_STAT (DBID, INPUT_TYPE);

create table sash_log
   (log_id       number,
    start_time   date default sysdate,
    action       varchar2(100),
    result       char(1),
    message      varchar2(1000));
	
create or replace public synonym sash_log for sash_log;

create global temporary table sash_hour_sqlid (sql_id varchar2(13), SQL_PLAN_HASH_VALUE number) on commit preserve rows;			
	
create table sash_stats
	(
	  dbid        number,
	  statistic#  number,
	  name        varchar2(4000),
	  collect     number
	);

create table sash_instance_stats (
	dbid number,
	inst_id number,
	sample_time date,
	STATISTIC#  NUMBER,
	VALUE NUMBER
);	

create index sash_instance_stats_id1 on sash_instance_stats(sample_time, STATISTIC#, dbid);		
	
 create table sash_hist_sample(
	hist_sample_id  number,
	dbid			number,
	instance_number		number,
	hist_date		date
 );

create index sash_hist_sample_i1 on sash_hist_sample (dbid, instance_number, hist_sample_id);
	
 create table sash_sqlplans(
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
	  depth		      numeric,
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
      dbid number);
	  
create index SASH_SQLPLANS_ID1 on SASH_SQLPLANS (sql_id, plan_hash_value, dbid);			  
 
create table sash_params(
      dbid number, 
      name varchar2(64),
      value varchar2(512));

create unique index sash_params_i on sash_params( dbid , name );

create table sash_event_names( 
      dbid number, 
      event# number, 
      wait_class varchar2(64), 
      name varchar2(64),
      event_id number
	  );

create unique index sash_event_names_i on sash_event_names( event# , dbid );
	  
create table sash_data_files( 
      dbid number, 
      file_name varchar2(513), 
      file_id number,
      tablespace_name varchar(30) 
      );

create table sash_users
    ( dbid number, 
      username varchar2(30), 
      user_id number);

create unique index sash_users_i on sash_users(dbid, user_id);

create table sash_latch
    ( dbid  number,
      latch# number,
      name varchar2(64));

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
	  inst_id number,
      child_number number,
      plan_hash_value number,
      command_type number,
      memory  number,
      sql_text varchar(64),
      last_found date,
      first_found date,
      found_count number );
	  
create unique index sash_sqlids_i on sash_sqlids (
       sql_id,
	   plan_hash_value,
       child_number,
	   dbid,
	   inst_id
);
	   
create table sash_sqltxt (
 DBID         NUMBER,
 SQL_ID       VARCHAR2(13),
 SQL_TEXT     CLOB,
 COMMAND_TYPE NUMBER
);

create index sash_sqltxt_1 on sash_sqltxt(SQL_ID, DBID);

create table sash_sqlstats (
 SNAP_ID                       NUMBER,
 DBID                          NUMBER,
 INSTANCE_NUMBER               NUMBER,
 SQL_ID                        VARCHAR2(13),
 PLAN_HASH_VALUE               NUMBER,
 PARSE_CALLS                   NUMBER,
 DISK_READS                    NUMBER,
 DIRECT_WRITES                 NUMBER,
 BUFFER_GETS                   NUMBER,
 ROWS_PROCESSED                NUMBER,
 SERIALIZABLE_ABORTS           NUMBER,
 FETCHES                       NUMBER,
 EXECUTIONS                    NUMBER,
 END_OF_FETCH_COUNT            NUMBER,
 LOADS                         NUMBER,
 VERSION_COUNT                 NUMBER,
 INVALIDATIONS                 NUMBER,
 PX_SERVERS_EXECUTIONS         NUMBER,
 CPU_TIME                      NUMBER,
 ELAPSED_TIME                  NUMBER,
 AVG_HARD_PARSE_TIME           NUMBER,
 APPLICATION_WAIT_TIME         NUMBER,
 CONCURRENCY_WAIT_TIME         NUMBER,
 CLUSTER_WAIT_TIME             NUMBER,
 USER_IO_WAIT_TIME             NUMBER,
 PLSQL_EXEC_TIME               NUMBER,
 JAVA_EXEC_TIME                NUMBER,
 SORTS                         NUMBER,
 SHARABLE_MEM                  NUMBER,
 TOTAL_SHARABLE_MEM            NUMBER,
 TYPECHECK_MEM                 NUMBER,
 IO_INTERCONNECT_BYTES         NUMBER,
 IO_DISK_BYTES                 NUMBER,
 physical_read_requests        NUMBER,  
 physical_read_bytes           NUMBER, 
 physical_write_requests       NUMBER,
 physical_write_bytes          NUMBER,
 EXACT_MATCHING_SIGNATURE      NUMBER,
 FORCE_MATCHING_SIGNATURE      NUMBER,
 FETCHES_DELTA                 NUMBER,
 END_OF_FETCH_COUNT_DELTA      NUMBER,
 SORTS_DELTA                   NUMBER,
 EXECUTIONS_DELTA              NUMBER,
 PX_SERVERS_EXECS_DELTA        NUMBER,
 LOADS_DELTA                   NUMBER,
 INVALIDATIONS_DELTA           NUMBER,
 PARSE_CALLS_DELTA             NUMBER,
 DISK_READS_DELTA              NUMBER,
 BUFFER_GETS_DELTA             NUMBER,
 ROWS_PROCESSED_DELTA          NUMBER,
 CPU_TIME_DELTA                NUMBER,
 ELAPSED_TIME_DELTA            NUMBER,
 IOWAIT_DELTA                  NUMBER,
 CLWAIT_DELTA                  NUMBER,
 APWAIT_DELTA                  NUMBER,
 CCWAIT_DELTA                  NUMBER,
 DIRECT_WRITES_DELTA           NUMBER,
 PLSEXEC_TIME_DELTA            NUMBER,
 JAVEXEC_TIME_DELTA            NUMBER,
 IO_INTERCONNECT_BYTES_DELTA   NUMBER,
 IO_DISK_BYTES_DELTA           NUMBER,
 physical_read_requests_delta  NUMBER,  
 physical_read_bytes_delta     NUMBER, 
 physical_write_requests_delta NUMBER,
 physical_write_bytes_delta    NUMBER 
);

create index sash_sqlstats_i1 on sash_sqlstats (snap_id);

create index sash_sqlstats_i2 on sash_sqlstats (sql_id, plan_hash_value);
 
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
	port number,
	dbname varchar2(30),
	sid varchar2(8),
	inst_num number,
    db_link varchar(4000),
	version varchar2(20),
    cpu_count number						
 );

create unique index sash_targets_i on sash_targets ( host,sid );
 
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

create table waitgroups (
           NAME         VARCHAR2(64),
           WAIT_CLASS   VARCHAR2(64)
);

create index waitgroups_i on waitgroups(name);

create table sash_configuration (
      param       	varchar2(30),
      value		    varchar2(100)
);
   
create unique index sash_configuration_unq on sash_configuration(param);
   
insert into sash_configuration values ('SASH RETENTION','w');
commit;

create table SASH_IO_SYSTEM_EVENT (
 DBID                    NUMBER,
 INST_ID                 NUMBER,
 SNAP_ID                 NUMBER,
 SAMPLE_TIME             DATE,
 TOTAL_WAITS             NUMBER,
 TOTAL_TIMEOUTS          NUMBER,
 TIME_WAITED             NUMBER,
 AVERAGE_WAIT            NUMBER,
 TIME_WAITED_MICRO       NUMBER,
 EVENT_ID                NUMBER
);

create table SASH_SYSMETRIC_HISTORY (
 DBID           NUMBER,
 INST_ID        NUMBER,
 SNAP_ID        NUMBER,
 BEGIN_TIME     DATE,
 INTSIZE_CSEC   NUMBER,
 GROUP_ID       NUMBER,
 METRIC_ID      NUMBER,
 VALUE          NUMBER
);

create index SASH_SYSM_HISTORY_I1 on SASH_SYSMETRIC_HISTORY (DBID, INST_ID, BEGIN_TIME);

create table SASH_SYSMETRIC_NAMES (
 DBID           NUMBER,
 METRIC_ID      NUMBER,
 METRIC_NAME    VARCHAR2(64),
 METRIC_UNIT    VARCHAR2(64)
);

create unique index SASH_SYSMETRIC_NAMES_I1 on SASH_SYSMETRIC_NAMES(DBID, METRIC_ID);

create table SASH_IOFUNCSTATS (
 DBID                    NUMBER,
 INSTANCE_NUMBER         NUMBER,
 SNAP_ID                 NUMBER, 
 FUNCTION_ID             NUMBER,
 FUNCTION_NAME           VARCHAR2(30),
 SMALL_READ_MEGABYTES    NUMBER,
 SMALL_WRITE_MEGABYTES   NUMBER,
 LARGE_READ_MEGABYTES    NUMBER,
 LARGE_WRITE_MEGABYTES   NUMBER,
 SMALL_READ_REQS         NUMBER,
 SMALL_WRITE_REQS        NUMBER,
 LARGE_READ_REQS         NUMBER,
 LARGE_WRITE_REQS        NUMBER,
 NUMBER_OF_WAITS         NUMBER,
 WAIT_TIME               NUMBER
);

 
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

create or replace view v$active_session_history as
       select
         ash.dbid            ,
		 ash.inst_id		 ,
         ash.sample_time     ,
         ash.session_id      ,
         ash.session_state   ,
         ash.session_serial# ,
         ash.user_id         ,
         ash.sql_address     ,
         ash.sql_id          ,
         ash.sql_plan_hash_value  ,
         ash.sql_opcode      ,
         decode(bitand(ash.session_type,19),17,'BACKGROUND',1,'FOREGROUND',2,'RECURSIVE','?') session_type, 
         decode(session_state,'WAITING',ash.event#,null) event#,
		 decode(session_state,'WAITING',ash.event#,null) event_id,
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
         ash.SERVICE_NAME    ,
         ash.FIXED_TABLE_SEQUENCE ,
         ash.sample_id       ,
         decode(session_state,'WAITING',e.name,null) event,
         nvl(e.wait_class,'Other') wait_class,
		 null FLAGS,
		 SQL_CHILD_NUMBER,
		 null FORCE_MATCHING_SIGNATURE,
		 null TOP_LEVEL_SQL_ID,
		 null TOP_LEVEL_SQL_OPCODE,
		 null SQL_PLAN_LINE_ID,
		 null SQL_PLAN_OPERATION,
		 null SQL_PLAN_OPTIONS,
		 SQL_EXEC_ID,
         SQL_EXEC_START, 
		 PLSQL_ENTRY_OBJECT_ID,
		 PLSQL_ENTRY_SUBPROGRAM_ID,
		 PLSQL_OBJECT_ID,
		 PLSQL_SUBPROGRAM_ID,
         null QC_INSTANCE_ID,
         null QC_SESSION_ID,
         null QC_SESSION_SERIAL#,
 		 ash.p1 p1text,
		 ash.p2 p2text, 
		 ash.p3 p3text,
		 null wait_class_id,
		 TIME_WAITED TIME_WAITED,
		 decode(ksuseblocker, 4294967295,to_number(null),4294967294,to_number(null), 4294967293,to_number(null), 4294967292,to_number(null),4294967291,  to_number(null),bitand(ksuseblocker, 65535)) BLOCKING_SESSION,
		 decode(ksuseblocker,4294967295,'UNKNOWN',  4294967294, 'UNKNOWN',4294967293,'UNKNOWN',4294967292,'NO HOLDER',  4294967291,'NOT IN WAIT','VALID') BLOCKING_SESSION_STATUS,
         CURRENT_ROW# CURRENT_ROW#,
         null BLOCKING_SESSION_SERIAL#,
         null CONSUMER_GROUP_ID,
         null XID,
         null REMOTE_INSTANCE#,
         null IN_CONNECTION_MGMT,
         null IN_PARSE,
         null IN_HARD_PARSE,
         null IN_SQL_EXECUTION,
         null IN_PLSQL_EXECUTION,
         null IN_PLSQL_RPC,
         null IN_PLSQL_COMPILATION,
         null IN_JAVA_EXECUTION,
         null IN_BIND,
         null IN_CURSOR_CLOSE,
         null SERVICE_HASH,
         null CLIENT_ID
    from
         sash_all ash,
         sash_event_names  e
    where
         e.event# = ash.event# and
         e.dbid = ( select dbid from sash_target) and
         ash.dbid = e.dbid ;

create or replace view dba_hist_active_sess_history 
     as 
     select * from v$active_session_history 
     where rownum < 1;

create or replace view v$sqltext_with_newlines as 
     select 
            DBID  ,
            sql_id,    
            SQL_TEXT     
     from  
            sash_sqltxt
     where dbid = ( select dbid from sash_target);

create or replace view v$instance as select 
        version  version,
		inst_num instance_number,
        host     host_name,
        sid      instance_name
     from sash_targets 
     where dbid = ( select dbid from sash_target);
	 
create or replace view v$database as select 
        dbid	 dbid,
        host     host_name,
        sid      instance_name,
        dbname   name
     from sash_targets 
     where dbid = ( select dbid from sash_target);	 
	 

create or replace view v$sql_plan as SELECT null address, null hash_value, sql_id, plan_hash_value, null child_number,
	   operation, options, object_node, null object#, object_owner, object_name, null object_alias,
	   object_type, optimizer, id, parent_id, depth, position, null search_columns, cost,
	   cardinality, bytes, other_tag, partition_start, partition_stop, partition_id,
	   other, distribution, cpu_cost, io_cost, temp_space, access_predicates, filter_predicates,
	   null projection, null time, null qblock_name, null remarks
	   FROM sash_sqlplans;	 

create or replace view v$sql as select sql_id, 100 command_type, to_char(sql_text) sql_text from sash_sqltxt where  dbid = ( select dbid from sash_target);	 

create or replace view v$parameter as select * from sash_params
          where dbid = ( select dbid from sash_target);

create or replace view dba_users as select * from sash_users
          where dbid = ( select dbid from sash_target);

create or replace view dba_data_files as select * from sash_data_files
          where dbid = ( select dbid from sash_target);

create or replace view all_objects as select * from sash_objs
          where dbid = ( select dbid from sash_target);
	  
CREATE OR REPLACE FORCE VIEW SASH_PLAN_TABLE (STATEMENT_ID, PLAN_ID, TIMESTAMP, REMARKS, OPERATION, OPTIONS, OBJECT_NODE, 
OBJECT_OWNER, OBJECT_NAME, OBJECT_ALIAS, OBJECT_INSTANCE, OBJECT_TYPE, OPTIMIZER,
 SEARCH_COLUMNS, ID, PARENT_ID, DEPTH, POSITION, COST, CARDINALITY, BYTES, OTHER_TAG, PARTITION_START, PARTITION_STOP, 
 PARTITION_ID, OTHER, OTHER_XML, DISTRIBUTION, CPU_COST, IO_COST, TEMP_SPACE, 
 ACCESS_PREDICATES, FILTER_PREDICATES, PROJECTION, TIME, QBLOCK_NAME) AS
  select
 SQL_ID             ,
 PLAN_HASH_VALUE    ,
 sysdate,
 null ,
 OPERATION,
 OPTIONS   ,
 OBJECT_NODE,
 OBJECT_OWNER,
 OBJECT_NAME  ,
 'ALIAS',
 OBJECT_INSTANCE    ,
 OBJECT_TYPE        ,
 OPTIMIZER          ,
 SEARCH_COLUMNS     ,
 ID                 ,
 PARENT_ID          ,
 depth,
 POSITION           ,
 COST               ,
 CARDINALITY        ,
 BYTES              ,
 OTHER_TAG          ,
 PARTITION_START    ,
 PARTITION_STOP     ,
 PARTITION_ID       ,
 OTHER              ,
 null           ,
 DISTRIBUTION       ,
 CPU_COST           ,
 IO_COST            ,
 TEMP_SPACE         ,
 ACCESS_PREDICATES  ,
 FILTER_PREDICATES  ,
 null,
1,
 null
 from sash_sqlplans;

	  
create or replace view dba_hist_sysmetric_history as
select snap_id, n.dbid, inst_id INSTANCE_NUMBER, begin_time, begin_time + INTSIZE_CSEC/100/24/3600 end_time, INTSIZE_CSEC INTSIZE, GROUP_ID, n.METRIC_ID, METRIC_NAME, VALUE, METRIC_UNIT from SASH_SYSMETRIC_NAMES n,
sash_sysmetric_history h where n.METRIC_ID = h.METRIC_ID and n.dbid = h.dbid and n.dbid = ( select dbid from sash_target) order by begin_time;


create or replace view v$sysmetric_history as 
select n.DBID, INST_ID, BEGIN_TIME, BEGIN_TIME + INTSIZE_CSEC/100/24/3600 END_TIME, INTSIZE_CSEC, GROUP_ID, n.METRIC_ID, n.METRIC_NAME, VALUE, n.METRIC_UNIT 
from  sash_sysmetric_history h, sash_sysmetric_names n where h.dbid = n.dbid and n.dbid = ( select dbid from sash_target) and h.METRIC_ID = n.METRIC_ID and BEGIN_TIME > sysdate - 2/24
order by snap_id;

create or replace view v$iostat_function as
select  dbid, INSTANCE_NUMBER, FUNCTION_ID, FUNCTION_NAME, SMALL_READ_MEGABYTES, SMALL_WRITE_MEGABYTES, LARGE_READ_MEGABYTES, LARGE_WRITE_MEGABYTES, SMALL_READ_REQS,        
SMALL_WRITE_REQS, LARGE_READ_REQS, LARGE_WRITE_REQS, NUMBER_OF_WAITS , WAIT_TIME from SASH_IOFUNCSTATS io 
where snap_id = (select max(HIST_SAMPLE_ID) from sash_hist_sample h where io.instance_number = h.instance_number and io.dbid = h.dbid)
order by INSTANCE_NUMBER, FUNCTION_ID;

create or replace view dba_hist_sqlstat as 
select SNAP_ID, DBID, INSTANCE_NUMBER, SQL_ID, PLAN_HASH_VALUE, PARSE_CALLS, DISK_READS, DIRECT_WRITES, BUFFER_GETS,
ROWS_PROCESSED, SERIALIZABLE_ABORTS, FETCHES, EXECUTIONS, END_OF_FETCH_COUNT, LOADS, VERSION_COUNT, INVALIDATIONS,
PX_SERVERS_EXECUTIONS, CPU_TIME, ELAPSED_TIME, AVG_HARD_PARSE_TIME, APPLICATION_WAIT_TIME, CONCURRENCY_WAIT_TIME,
CLUSTER_WAIT_TIME, USER_IO_WAIT_TIME, PLSQL_EXEC_TIME, JAVA_EXEC_TIME, SORTS, SHARABLE_MEM, TOTAL_SHARABLE_MEM,
TYPECHECK_MEM, IO_INTERCONNECT_BYTES, IO_DISK_BYTES, PHYSICAL_READ_REQUESTS, PHYSICAL_READ_BYTES, PHYSICAL_WRITE_REQUESTS,
PHYSICAL_WRITE_BYTES, EXACT_MATCHING_SIGNATURE, FORCE_MATCHING_SIGNATURE, FETCHES_DELTA,  END_OF_FETCH_COUNT_DELTA, 
SORTS_DELTA, EXECUTIONS_DELTA, PX_SERVERS_EXECS_DELTA, LOADS_DELTA, INVALIDATIONS_DELTA, PARSE_CALLS_DELTA,
DISK_READS_DELTA, BUFFER_GETS_DELTA, ROWS_PROCESSED_DELTA, CPU_TIME_DELTA, ELAPSED_TIME_DELTA, IOWAIT_DELTA,                     
CLWAIT_DELTA, APWAIT_DELTA, CCWAIT_DELTA, DIRECT_WRITES_DELTA, PLSEXEC_TIME_DELTA, JAVEXEC_TIME_DELTA,
IO_INTERCONNECT_BYTES_DELTA, IO_DISK_BYTES_DELTA, PHYSICAL_READ_REQUESTS_DELTA, PHYSICAL_READ_BYTES_DELTA,
PHYSICAL_WRITE_REQUESTS_DELTA, PHYSICAL_WRITE_BYTES_DELTA       
from sash_sqlstats s 
order by snap_id, INSTANCE_NUMBER;

create or replace view  v$sqlstats as 
select DBID, INSTANCE_NUMBER, SQL_ID, PLAN_HASH_VALUE, PARSE_CALLS, DISK_READS, DIRECT_WRITES, BUFFER_GETS,
ROWS_PROCESSED, SERIALIZABLE_ABORTS, FETCHES, EXECUTIONS, END_OF_FETCH_COUNT, LOADS, VERSION_COUNT, INVALIDATIONS,
PX_SERVERS_EXECUTIONS, CPU_TIME, ELAPSED_TIME, AVG_HARD_PARSE_TIME, APPLICATION_WAIT_TIME, CONCURRENCY_WAIT_TIME,
CLUSTER_WAIT_TIME, USER_IO_WAIT_TIME, PLSQL_EXEC_TIME, JAVA_EXEC_TIME, SORTS, SHARABLE_MEM, TOTAL_SHARABLE_MEM,
TYPECHECK_MEM, IO_INTERCONNECT_BYTES, IO_DISK_BYTES, PHYSICAL_READ_REQUESTS, PHYSICAL_READ_BYTES, PHYSICAL_WRITE_REQUESTS,
PHYSICAL_WRITE_BYTES, EXACT_MATCHING_SIGNATURE, FORCE_MATCHING_SIGNATURE from sash_sqlstats s where 
snap_id = (select max(HIST_SAMPLE_ID) from sash_hist_sample h where s.instance_number = h.instance_number and s.dbid = h.dbid)
order by INSTANCE_NUMBER;

	  
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

spool off
