-- (c) Marcin Przepiorowski 2013
-- v2.4 Initial release
-- view separated from tables - moved from repo_schema.sql

set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') = 'SYS';
spool off

@exit.sql

set term on
spool sash_views.log

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
         case when ash.qc is not null then ash.inst_id end QC_INSTANCE_ID,
         ash.qc QC_SESSION_ID,
         cast(null  as number) QC_SESSION_SERIAL#,
 		 ash.p1 p1text,
		 ash.p2 p2text, 
		 ash.p3 p3text,
		 e.wait_class_id wait_class_id,
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
         sash_event_names  e,
	 sash_target st
    where
         e.event# = ash.event# and
         e.dbid = st.dbid and
         ash.inst_id = st.inst_num and
         ash.dbid = st.dbid ;

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
     from sash_targets sts
     where (sash_dbid,inst_num) = ( select dbid,inst_num from sash_target);
	 
create or replace view v$database as select 
        dbid	 dbid,
        host     host_name,
        sid      instance_name,
        dbname   name
     from sash_targets 
     where (sash_dbid, inst_num) = ( select dbid, inst_num from sash_target);	 
	 

create or replace view v$sql_plan as SELECT null address, null hash_value, sql_id, plan_hash_value, null child_number,
	   operation, options, object_node, null object#, object_owner, object_name, null object_alias,
	   object_type, optimizer, id, parent_id, depth, position, null search_columns, cost,
	   cardinality, bytes, other_tag, partition_start, partition_stop, partition_id,
	   other, distribution, cpu_cost, io_cost, temp_space, access_predicates, filter_predicates,
	   null projection, null time, null qblock_name, null remarks
	   FROM sash_sqlplans where dbid = ( select dbid from sash_target);	 

create or replace view v$sql as select sql_id, 100 command_type, to_char(sql_text) sql_text from sash_sqltxt where  dbid = ( select dbid from sash_target);	 

create or replace view v$parameter as select * from sash_params
          where dbid = ( select dbid from sash_target);

create or replace view dba_users as select * from sash_users
          where dbid = ( select dbid from sash_target);

create or replace view dba_data_files as select * from sash_data_files
          where dbid = ( select dbid from sash_target);

create or replace view all_objects as select * from sash_objs
          where dbid = ( select dbid from sash_target);
	  
	  

create or replace view v$sysmetric_history as 
select n.DBID, INST_ID, BEGIN_TIME, BEGIN_TIME + INTSIZE_CSEC/100/24/3600 END_TIME, INTSIZE_CSEC, GROUP_ID, n.METRIC_ID, n.METRIC_NAME, VALUE, n.METRIC_UNIT 
from  sash_sysmetric_history h, sash_sysmetric_names n, sash_target st where h.dbid = n.dbid and n.dbid = st.dbid and h.inst_id = st.inst_num and h.METRIC_ID = n.METRIC_ID and BEGIN_TIME > sysdate - 2/24
order by snap_id;

create or replace view v$iostat_function as
select  io.dbid, INSTANCE_NUMBER, FUNCTION_ID, FUNCTION_NAME, SMALL_READ_MEGABYTES, SMALL_WRITE_MEGABYTES, LARGE_READ_MEGABYTES, LARGE_WRITE_MEGABYTES, SMALL_READ_REQS,        
SMALL_WRITE_REQS, LARGE_READ_REQS, LARGE_WRITE_REQS, NUMBER_OF_WAITS , WAIT_TIME from SASH_IOFUNCSTATS io , sash_target st
where snap_id = (select max(HIST_SAMPLE_ID) from sash_hist_sample h where io.instance_number = h.instance_number and io.dbid = h.dbid)
and io.instance_number = st.inst_num and io.dbid = st.dbid
order by INSTANCE_NUMBER, FUNCTION_ID;

create or replace view  v$sqlstats as 
select s.DBID, INSTANCE_NUMBER, SQL_ID, PLAN_HASH_VALUE, PARSE_CALLS, DISK_READS, DIRECT_WRITES, BUFFER_GETS,
ROWS_PROCESSED, SERIALIZABLE_ABORTS, FETCHES, EXECUTIONS, END_OF_FETCH_COUNT, LOADS, VERSION_COUNT, INVALIDATIONS,
PX_SERVERS_EXECUTIONS, CPU_TIME, ELAPSED_TIME, AVG_HARD_PARSE_TIME, APPLICATION_WAIT_TIME, CONCURRENCY_WAIT_TIME,
CLUSTER_WAIT_TIME, USER_IO_WAIT_TIME, PLSQL_EXEC_TIME, JAVA_EXEC_TIME, SORTS, SHARABLE_MEM, TOTAL_SHARABLE_MEM,
TYPECHECK_MEM, IO_INTERCONNECT_BYTES, IO_DISK_BYTES, PHYSICAL_READ_REQUESTS, PHYSICAL_READ_BYTES, PHYSICAL_WRITE_REQUESTS,
PHYSICAL_WRITE_BYTES, EXACT_MATCHING_SIGNATURE, FORCE_MATCHING_SIGNATURE from sash_sqlstats s, sash_target st where 
snap_id = (select max(HIST_SAMPLE_ID) from sash_hist_sample h where s.instance_number = h.instance_number and s.dbid = h.dbid)
and s.INSTANCE_NUMBER = st.inst_num and s.dbid = st.dbid
order by INSTANCE_NUMBER;

	  
spool off
