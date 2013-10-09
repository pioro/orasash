-- (c) Marcin Przepiorowski 2013
-- v2.4 Initial release
-- view separated from tables - AWR simulation views

set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') = 'SYS';
spool off

@exit.sql

set term on
spool sash_awr_views.log

create or replace view dba_hist_snapshot (SNAP_ID,DBID,INSTANCE_NUMBER,BEGIN_INTERVAL_TIME) as select HIST_SAMPLE_ID,DBID,INSTANCE_NUMBER,HIST_DATE from SASH_HIST_SAMPLE;

create or replace view dba_hist_sysmetric_history as
select snap_id, n.dbid, inst_id INSTANCE_NUMBER, begin_time, begin_time + INTSIZE_CSEC/100/24/3600 end_time, INTSIZE_CSEC INTSIZE, GROUP_ID, n.METRIC_ID, METRIC_NAME, VALUE, METRIC_UNIT from SASH_SYSMETRIC_NAMES n,
sash_sysmetric_history h, sash_target st where n.METRIC_ID = h.METRIC_ID and n.dbid = h.dbid and n.dbid = st.dbid order by begin_time;

create or replace view dba_hist_sqlstat as
select SNAP_ID, s.DBID, INSTANCE_NUMBER, SQL_ID, PLAN_HASH_VALUE, PARSE_CALLS, DISK_READS, DIRECT_WRITES, BUFFER_GETS,
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
from sash_sqlstats s , sash_target st
where s.dbid = st.dbid
order by snap_id, INSTANCE_NUMBER;

create or replace view dba_hist_active_sess_history(
SNAP_ID                  ,
DBID                     ,
INSTANCE_NUMBER          ,
SAMPLE_TIME              ,
SESSION_ID               ,
SESSION_STATE            ,
SESSION_SERIAL#          ,
USER_ID                  ,
SQL_ADDRESS              ,
SQL_ID                   ,
SQL_PLAN_HASH_VALUE      ,
SQL_OPCODE               ,
SESSION_TYPE             ,
EVENT#                   ,
EVENT_ID                 ,
SEQ#                     ,
P1                       ,
P2                       ,
P3                       ,
WAIT_TIME                ,
CURRENT_OBJ#             ,
CURRENT_FILE#            ,
CURRENT_BLOCK#           ,
PROGRAM                  ,
MODULE                   ,
ACTION                   ,
SERVICE_NAME             ,
FIXED_TABLE_SEQUENCE     ,
SAMPLE_ID                ,
EVENT                    ,
WAIT_CLASS               ,
FLAGS                    ,
SQL_CHILD_NUMBER         ,
FORCE_MATCHING_SIGNATURE ,
TOP_LEVEL_SQL_ID         ,
TOP_LEVEL_SQL_OPCODE     ,
SQL_PLAN_LINE_ID         ,
SQL_PLAN_OPERATION       ,
SQL_PLAN_OPTIONS         ,
SQL_EXEC_ID              ,
SQL_EXEC_START           ,
PLSQL_ENTRY_OBJECT_ID    ,
PLSQL_ENTRY_SUBPROGRAM_ID,
PLSQL_OBJECT_ID          ,
PLSQL_SUBPROGRAM_ID      ,
QC_INSTANCE_ID           ,
QC_SESSION_ID            ,
QC_SESSION_SERIAL#       ,
P1TEXT                   ,
P2TEXT                   ,
P3TEXT                   ,
WAIT_CLASS_ID            ,
TIME_WAITED              ,
BLOCKING_SESSION         ,
BLOCKING_SESSION_STATUS  ,
CURRENT_ROW#             ,
BLOCKING_SESSION_SERIAL# ,
CONSUMER_GROUP_ID        ,
XID                      ,
REMOTE_INSTANCE#         ,
IN_CONNECTION_MGMT       ,
IN_PARSE                 ,
IN_HARD_PARSE            ,
IN_SQL_EXECUTION         ,
IN_PLSQL_EXECUTION       ,
IN_PLSQL_RPC             ,
IN_PLSQL_COMPILATION     ,
IN_JAVA_EXECUTION        ,
IN_BIND                  ,
IN_CURSOR_CLOSE          ,
SERVICE_HASH             ,
CLIENT_ID                
)
     as
     select 
                s.snap_id                ,
		s.DBID                   ,
		INST_ID                  ,
		SAMPLE_TIME              ,
		SESSION_ID               ,
		SESSION_STATE            ,
		SESSION_SERIAL#          ,
		USER_ID                  ,
		SQL_ADDRESS              ,
		SQL_ID                   ,
		SQL_PLAN_HASH_VALUE      ,
		SQL_OPCODE               ,
		SESSION_TYPE             ,
		EVENT#                   ,
		EVENT_ID                 ,
		SEQ#                     ,
		P1                       ,
		P2                       ,
		P3                       ,
		WAIT_TIME                ,
		CURRENT_OBJ#             ,
		CURRENT_FILE#            ,
		CURRENT_BLOCK#           ,
		PROGRAM                  ,
		MODULE                   ,
		ACTION                   ,
		SERVICE_NAME             ,
		FIXED_TABLE_SEQUENCE     ,
		SAMPLE_ID                ,
		EVENT                    ,
		WAIT_CLASS               ,
		FLAGS                    ,
		SQL_CHILD_NUMBER         ,
		FORCE_MATCHING_SIGNATURE ,
		TOP_LEVEL_SQL_ID         ,
		TOP_LEVEL_SQL_OPCODE     ,
		SQL_PLAN_LINE_ID         ,
		SQL_PLAN_OPERATION       ,
		SQL_PLAN_OPTIONS         ,
		SQL_EXEC_ID              ,
		SQL_EXEC_START           ,
		PLSQL_ENTRY_OBJECT_ID    ,
		PLSQL_ENTRY_SUBPROGRAM_ID,
		PLSQL_OBJECT_ID          ,
		PLSQL_SUBPROGRAM_ID      ,
		QC_INSTANCE_ID           ,
		QC_SESSION_ID            ,
		QC_SESSION_SERIAL#       ,
		P1TEXT                   ,
		P2TEXT                   ,
		P3TEXT                   ,
		WAIT_CLASS_ID            ,
		TIME_WAITED              ,
		BLOCKING_SESSION         ,
		BLOCKING_SESSION_STATUS  ,
		CURRENT_ROW#             ,
		BLOCKING_SESSION_SERIAL# ,
		CONSUMER_GROUP_ID        ,
		XID                      ,
		REMOTE_INSTANCE#         ,
		IN_CONNECTION_MGMT       ,
		IN_PARSE                 ,
		IN_HARD_PARSE            ,
		IN_SQL_EXECUTION         ,
		IN_PLSQL_EXECUTION       ,
		IN_PLSQL_RPC             ,
		IN_PLSQL_COMPILATION     ,
		IN_JAVA_EXECUTION        ,
		IN_BIND                  ,
		IN_CURSOR_CLOSE          ,
		SERVICE_HASH             ,
		CLIENT_ID                	 
	 from v$active_session_history ash, dba_hist_snapshot s
     where to_char(sample_time,'SS') like '%0'
	 and sample_time between BEGIN_INTERVAL_TIME and BEGIN_INTERVAL_TIME + (select nvl(max(value),15) from sash_configuration where param='STATFREQ')/24/60;



create or replace view DBA_HIST_SYSMETRIC_SUMMARY (
SNAP_ID                   ,
DBID                      ,
INSTANCE_NUMBER           ,
BEGIN_TIME                ,
END_TIME                  ,
INTSIZE                   ,
GROUP_ID                  ,
METRIC_ID                 ,
METRIC_NAME               ,
METRIC_UNIT               ,
NUM_INTERVAL              ,
MINVAL                    ,
MAXVAL                    ,
AVERAGE                   ,
STANDARD_DEVIATION        
) as
select 
SNAP_ID          ,          
DBID             ,
INSTANCE_NUMBER  ,
min(BEGIN_TIME)  ,
max(END_TIME)    ,
max(INTSIZE)     ,
GROUP_ID         ,
METRIC_ID        ,
METRIC_NAME      ,
METRIC_UNIT      ,
count(*)         ,
min(value)       ,
max(value)       ,
avg(value)       ,
STDDEV_SAMP(value) 
from dba_hist_sysmetric_history 
group by SNAP_ID ,          
DBID             ,
INSTANCE_NUMBER  ,
GROUP_ID         ,
METRIC_ID        ,
METRIC_NAME      ,
METRIC_UNIT;


create or replace view dba_hist_event_histogram (
 SNAP_ID         ,
 DBID            ,
 INSTANCE_NUMBER ,
 EVENT_ID        ,
 EVENT_NAME      ,
 WAIT_CLASS_ID   ,
 WAIT_CLASS      ,
 WAIT_TIME_MILLI ,
 WAIT_COUNT      
) as 
select h.SNAP_ID, h.DBID, h.INST_ID ,e.EVENT_ID, NAME, null, WAIT_CLASS, WAIT_TIME_MILLI, WAIT_COUNT
from sash_event_names e, sash_event_histogram_all h, sash_target t
where e.dbid = h.dbid and e.event# = h.event# and t.dbid = h.dbid;

create or replace view dba_hist_sys_time_model (
SNAP_ID        , 
DBID           , 
INSTANCE_NUMBER,
STAT_ID        ,
STAT_NAME      ,
VALUE          
)
as
select snap_id, m.dbid, INST_ID, m.stat_id, STAT_NAME, value from sash_sys_time_model m, sash_sys_time_name n,  sash_target t
where m.STAT_ID = n.STAT_ID and t.dbid = m.dbid;
