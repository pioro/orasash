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
-- v2.4 Changes: new tables for event histogram, osstat and sys_time_model
--               repository is created using helpers procedures to create "poor man" partitions and indexes
--               views moved to repo_views.sql


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
create sequence fakedbid;

Prompt Create tables

-- create first table to keep active sessions data

create table sash1 ( 
                dbid                number, 
                sample_time         date,
                session_id          number,
                session_state       varchar2(20),
                session_serial#     number,
		    OSUSER              VARCHAR2(128),
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
                module              varchar2(64),
                MODULE_HASH         number,
                action              varchar2(64), 
                ACTION_HASH         number,
                LOGON_TIME          date,
                KSUSEBLOCKER        number,
                SERVICE_NAME        varchar2(64),
                FIXED_TABLE_SEQUENCE    number,
                QC                  number,
                BLOCKING_INSTANCE  number,
                BLOCKING_SESSION   number,
                FINAL_BLOCKING_INSTANCE number,
                FINAL_BLOCKING_SESSION number,
                sample_id           number,
                terminal            varchar2(30),
		inst_id		        number
);

-- create rest of active sessions tables to simulate poor man partitioning
-- this is improved now thanks to helpers procedures

exec create_partitions('sash',31);
exec create_indexes('sash',31,'sash_i1','sample_time,dbid');
create or replace view sash as select * from sash1;

-- rest of tables

create table sash_log
   (log_id       number,
    start_time   date default sysdate,
    action       varchar2(100),
    result       char(1),
    message      varchar2(1000));
	
create or replace public synonym sash_log for sash_log;

create global temporary table sash_hour_sqlid (sql_id varchar2(13), SQL_PLAN_HASH_VALUE number) on commit delete rows;			
	
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
      dbid number,
      inst_id number
);
	  
create index SASH_SQLPLANS_ID1 on SASH_SQLPLANS (sql_id, plan_hash_value, dbid);			  
 
create table sash_params(
      dbid number, 
      name varchar2(64),
      value varchar2(512));

create unique index sash_params_i on sash_params( dbid , name );

create table sash_event_names( 
      dbid number, 
      event# number, 
      event_id  number,
      wait_class varchar2(64), 
      name varchar2(64),
      wait_class_id number
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

-- adding poor man partitning to sql stats

create table sash_sqlstats1 (
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

exec create_partitions('sash_sqlstats',31);
exec create_indexes('sash_sqlstats',31,'sash_sqlstats_i1','snap_id');
exec create_indexes('sash_sqlstats',31,'sash_sqlstats_i2','sql_id, plan_hash_value');
create or replace view sash_sqlstats as select * from sash_sqlstats1;

create table sash_objs(
      dbid number,  
      object_id number, 
      owner varchar2(30), 
      object_name varchar2(128), 
      subobject_name varchar2(30), 
      object_type varchar2(18));
	  
create unique index sash_objs_i on sash_objs
      (dbid, object_id);

create table sash_target_static (
  dbid number,
  inst_num number,
  table_order number
);


create global temporary table sash_target_dynamic (
  dbid number,
  inst_num number,
  table_order number
);


create or replace view sash_target as 
select * from (select * from 
(select * from sash_target_static union all 
 select * from sash_target_dynamic ) order by TABLE_ORDER) where rownum < 2;
 
create table sash_targets (
    dbid number,
    host varchar2(30),
    port number,
    dbname varchar2(30),
    sid varchar2(8),
    inst_num number,
    db_link varchar(4000),
    version varchar2(20),
    cpu_count number,
    sash_dbid number
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


create table sash_event_histogram1(
SNAP_ID          NUMBER,
DBID             NUMBER,
INST_ID          NUMBER,
EVENT#           NUMBER,
WAIT_TIME_MILLI  NUMBER,
WAIT_COUNT       NUMBER
);


exec create_partitions('sash_event_histogram',31);
exec create_indexes('sash_event_histogram',31,'sash_event_histogram_i1','dbid, EVENT#');
exec create_indexes('sash_event_histogram',31,'sash_event_histogram_i2','snap_id,dbid, EVENT#');
create or replace view sash_event_histogram as select * from sash_event_histogram1;

create table sash_sys_time_name (
DBID            NUMBER,
STAT_ID		NUMBER,
STAT_NAME	VARCHAR2(64)
);

create table sash_osstat_name (
DBID            NUMBER,
OSSTAT_ID       NUMBER,
STAT_NAME	VARCHAR2(64),
COMMENTS	VARCHAR2(64),
CUMULATIVE      VARCHAR2(3)
);

create table sash_sys_time_model (
SNAP_ID          NUMBER,
DBID             NUMBER,
INST_ID          NUMBER,
STAT_ID		 NUMBER,
VALUE		 NUMBER
);

create index sash_sys_time_model_i1 on sash_sys_time_model(SNAP_ID, DBID, STAT_ID);

create table sash_osstat (
SNAP_ID          NUMBER,
DBID             NUMBER,
INST_ID          NUMBER,
OSSTAT_ID        NUMBER,
VALUE            NUMBER
);

create index sash_osstat_i1 on sash_osstat(SNAP_ID, DBID, OSSTAT_ID);
 
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
