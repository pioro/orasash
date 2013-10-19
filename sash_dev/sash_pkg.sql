-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.0 Package deployed on target database, database link pointed to repository 
-- v2.1 Changes: - Deployed on repository database not on target, 
--               - Data collection via DB link pointed to target, 
--               - Bug fixing in get_sqlids
-- v2.2 Changes: - splited between 10g and above and 9i
--               - gathered instance statistic 
--               - sql information improved
--               - RAC support
--               - multi db support
-- v2.3 Changes  - full RAC and multi DB support
--               - gathering metrics
--               - logging
-- v2.4 Changes  - new collection procedures for AWR


spool sash_pkg.log
prompt Crating SASH_PKG package

create sequence sashseq ;

--
-- BEGIN CREATE TARGET PACKAGE SASH_PKG
--
CREATE OR REPLACE PACKAGE sash_pkg AS
    procedure configure_db(v_dblink varchar2);
    procedure get_all(v_dblink varchar2, v_inst_num number)  ;
    procedure get_stats(v_dblink varchar2) ;
    procedure get_one(v_sql_id varchar2,v_dblink varchar2, v_inst_num number);
    procedure get_objs(l_dbid number, v_dblink varchar2)  ;
    procedure get_latch(v_dblink varchar2) ; 
    procedure get_users(v_dblink varchar2)  ;
    procedure get_params(v_dblink varchar2)  ;
    procedure get_sqltxt(l_dbid number, v_dblink varchar2) ;
    procedure get_sqlstats(l_hist_samp_id number, l_dbid number, v_dblink varchar2, v_inst_num number)  ;
    procedure get_sqlid(l_dbid number, v_sql_id varchar2, v_dblink varchar2) ;
    procedure get_sqlids(l_dbid number, v_inst_num number);
    procedure get_data_files(v_dblink varchar2)  ;
    procedure get_sqlplans(l_hist_samp_id number, l_dbid number,v_dblink varchar2, v_inst_num number) ;
    procedure get_extents(v_dblink varchar2);
    procedure get_event_names(v_dblink varchar2)  ;
    procedure collect_other(v_sleep number, loops number, v_dblink varchar2, vinstance number);
    procedure collect_ash (v_sleep number, loops number,v_dblink varchar2, vinstance number) ;
    function get_dbid (v_dblink varchar2) return number ;
    function get_version (v_dblink varchar2) return varchar2 ;
    procedure set_dbid ( v_dblink varchar2)  ;
--    procedure set_dbid ( v_dbid number)  ;
    procedure collect_metric(v_hist_samp_id number, v_dblink varchar2, vinstance number) ;
    procedure get_metrics(v_dblink varchar2) ;
    procedure collect_iostat(v_hist_samp_id number, v_dblink varchar2, vinstance number) ;
    procedure collect_histogram(v_hist_samp_id number, v_dblink varchar2, vinstance number);
    procedure collect_osstat(v_hist_samp_id number, v_dblink varchar2, vinstance number);
    procedure collect_systime(v_hist_samp_id number, v_dblink varchar2, vinstance number);
END sash_pkg;
/
show errors

CREATE OR REPLACE PACKAGE BODY sash_pkg AS

procedure configure_db(v_dblink varchar2) is 
l_dblink varchar2(40);
begin
    l_dblink := replace(v_dblink,'-','_');
    sash_repo.log_message('configure_db', 'get_event_names' ,'I');
    sash_pkg.get_event_names(l_dblink);
    sash_repo.log_message('configure_db', 'get_users' ,'I');
    sash_pkg.get_users(l_dblink);
    sash_repo.log_message('configure_db', 'get_params' ,'I');
    sash_pkg.get_params(l_dblink);
    sash_repo.log_message('configure_db', 'get_data_files' ,'I');
    sash_pkg.get_data_files(l_dblink);
    sash_repo.log_message('configure_db', 'get_metrics' ,'I');
    sash_pkg.get_metrics(l_dblink);
    commit; 
exception
    when others then
        sash_repo.log_message('configure_db', SUBSTR(SQLERRM, 1 , 1000) ,'E');
        RAISE_APPLICATION_ERROR(-20100,'SASH configure_db error ' || SUBSTR(SQLERRM, 1 , 1000));   
end configure_db;
 

FUNCTION get_dbid(v_dblink varchar2) return number is
    l_dbid number;
    begin
      execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
      return l_dbid;
end get_dbid;

FUNCTION get_version(v_dblink varchar2) return varchar2 is
    l_ver sash_targets.version%type;
    begin
      execute immediate 'select version from sash_targets where lower(db_link) = lower('''||v_dblink||''')' into l_ver;
      return l_ver;
end get_version;

PROCEDURE get_users(v_dblink varchar2) is
    l_dbid number;
    begin
      execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
      execute immediate 'insert into sash_users 
               (dbid, username, user_id)
               select ' || l_dbid || ',username,user_id from dba_users@'||v_dblink;
    exception
        when DUP_VAL_ON_INDEX then
            sash_repo.log_message('GET_USERS', 'Already configured ?','W');
end get_users;

PROCEDURE get_latch(v_dblink varchar2) is
 l_dbid number;
 begin
    execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
    execute immediate 'insert into sash_latch (dbid, latch#, name) select ' || l_dbid || ',latch#, name from sys.v_$latch@'||v_dblink;
    commit;
end get_latch; 
 
procedure get_stats(v_dblink varchar2) is
 l_dbid number;
 begin
    execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
    execute immediate 'insert into sash_stats select ' || l_dbid || ', STATISTIC#, name, 0 from sys.v_$sysstat@'||v_dblink;
    commit;
end get_stats;
 
 
PROCEDURE get_params(v_dblink varchar2) is
   l_dbid number;
   begin
     execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
     execute immediate 'insert into sash_params ( dbid, name, value) select ' || l_dbid || ',name,value from sys.v_$parameter@'||v_dblink;
    exception
        when DUP_VAL_ON_INDEX then
            sash_repo.log_message('GET_PARAMS', 'Already configured ?','W');				  
end get_params;

PROCEDURE get_metrics(v_dblink varchar2) is
   l_dbid number;
   begin
    begin
     l_dbid:=get_dbid(v_dblink);
     execute immediate 'insert into sash_sysmetric_names select distinct ' || l_dbid || ',METRIC_ID,METRIC_NAME,METRIC_UNIT from sys.v_$sysmetric_history@'||v_dblink || 
     ' where metric_name in (
        ''User Transaction Per Sec'',
        ''Physical Reads Per Sec'',
        ''Physical Reads Per Txn'',
        ''Physical Writes Per Sec'',
        ''Redo Generated Per Sec'',
        ''Redo Generated Per Txn'',
        ''Redo Writes Per Sec'',
        ''Logons Per Sec'',
        ''User Calls Per Sec'',
        ''User Commits Per Sec'',
        ''Logical Reads Per Txn'',
        ''Logical Reads Per Sec'',
        ''Total Parse Count Per Txn'',
        ''Network Traffic Volume Per Sec'',
        ''Enqueue Requests Per Txn'',
        ''DB Block Changes Per Txn'',
        ''Current Open Cursors Count'',
        ''SQL Service Response Time'',
        ''Response Time Per Txn'',
        ''Executions Per Sec'',
        ''Average Synchronous Single-Block Read Latency'',
        ''I/O Megabytes per Second'',
        ''I/O Requests per Second'',
        ''Average Active Sessions''
     )';
    exception
        when DUP_VAL_ON_INDEX then
            sash_repo.log_message('GET_METRICS', 'Already configured ?','W');
    end;


    begin
     execute immediate 'insert into sash_sys_time_name select distinct ' || l_dbid || ',STAT_ID, STAT_NAME from sys.v_$sys_time_model@'||v_dblink;
    exception
        WHEN DUP_VAL_ON_INDEX THEN
            sash_repo.log_message('GET_METRICS', 'Already configured ?','W');
    end;

            
    begin
     EXECUTE IMMEDIATE 'insert into sash_osstat_name select distinct ' || L_DBID || ',OSSTAT_ID, STAT_NAME, COMMENTS, CUMULATIVE from sys.v_$osstat@'||V_DBLINK;
    exception
        WHEN DUP_VAL_ON_INDEX THEN
            sash_repo.log_message('GET_METRICS', 'Already configured ?','W');          
    end;

end get_metrics;


PROCEDURE set_dbid(v_dblink varchar2) is
   l_dbid number;
   l_inst number;
   cnt number;
   l_dblink varchar2(40);
   begin
     l_dblink := replace(v_dblink,'-','_'); 
--     execute immediate 'select dbid  from sys.v_$database@'||l_dblink into l_dbid;
--     execute immediate 'select instance_number from sys.v_$instance@'||l_dblink into l_inst;

     execute immediate 'select dbid, inst_num from sash_targets where db_link = :1' into l_dbid, l_inst using v_dblink;
     select count(*) into cnt from 
         sash_target;
     if cnt = 0 then 
         insert into 
            sash_target_static ( dbid, inst_num )
            values (l_dbid, l_inst);
     else
         update sash_target_static set dbid = l_dbid, inst_num = l_inst;     
     end if;
end set_dbid;

--PROCEDURE set_dbid( v_dbid number) is
--   cnt number;
--   begin 
--     select count(*) into cnt from 
--         sash_target;
--     if cnt = 0 then 
--         insert into 
--            sash_target ( dbid )
--            values (v_dbid);
--     else
--         update sash_target set dbid = v_dbid;     
--     end if;
--end set_dbid;



PROCEDURE get_data_files(v_dblink varchar2) is
    l_dbid number;
    sql_stat varchar2(4000);
  TYPE SashcurTyp IS REF CURSOR;
  sash_cur   SashcurTyp;	
    sash_rec sash_data_files%rowtype;		  
  
 begin
     l_dbid:=get_dbid(v_dblink);
     sql_stat:= 'select '|| l_dbid ||', file_name, file_id, tablespace_name from dba_data_files@'||v_dblink;
     open sash_cur FOR sql_stat; 
     loop
         fetch sash_cur into sash_rec;
         exit when sash_cur%notfound;	 
         insert into sash_data_files ( dbid, file_name, file_id, tablespace_name ) values
                 ( l_dbid, 
                  sash_rec.file_name, 
                  sash_rec.file_id, 
                  sash_rec.tablespace_name );
    end loop;
    exception
        when DUP_VAL_ON_INDEX then
            sash_repo.log_message('GET_DATA_FILES', 'Already configured ?','W');		 
end get_data_files;

PROCEDURE get_extents(v_dblink varchar2) is
    l_dbid number;

 begin
    l_dbid:=get_dbid(v_dblink);

    execute immediate 'insert into sash_extents ( dbid, segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno)
             select '|| l_dbid ||', segment_name, partition_name, segment_type, tablespace_name, 	extent_id, file_id, block_id, bytes, blocks, relative_fno from dba_extents@'|| v_dblink;
     exception
            when OTHERS then
                    sash_repo.log_message('GET_EXTENTS error', '','E');
    RAISE_APPLICATION_ERROR(-20115, 'SASH get_extents error ' || SUBSTR(SQLERRM, 1 , 1000));
end get_extents;

PROCEDURE get_event_names(v_dblink varchar2) is
          l_dbid number;
          
       begin
          l_dbid:=get_dbid(v_dblink);
          execute immediate 'insert into sash_event_names ( dbid, event#, name, wait_class ) select distinct '|| l_dbid ||', event#, name, wait_class from sys.v_$event_name@' || v_dblink;
         exception
            when DUP_VAL_ON_INDEX then
                    sash_repo.log_message('GET_EVENT_NAMES', 'Already configured ?','W');
end get_event_names;
       

PROCEDURE get_objs(l_dbid number, v_dblink varchar2) is
type sash_objs_type is table of sash_objs%rowtype;
sash_objsrec  sash_objs_type := sash_objs_type();
type ctype is ref cursor;
C_SASHOBJS ctype;
sql_stat varchar2(4000);


begin
    sql_stat:='select /*+DRIVING_SITE(o) */ :1, 
                           o.object_id,
                           o.owner,
                           o.object_name,
                           o.subobject_name,
                           o.object_type
                    from dba_objects@' || v_dblink || ' o
                    where object_id  in ( 
                            select current_obj# from (
                            select count(*) cnt, CURRENT_OBJ#
                            from sash 
                            where
                               current_obj# > 0
                               and sample_time > (sysdate - 1/24)
                            group by current_obj#
                            order by cnt desc )
                         where rownum < 100)
                      and object_id not in (select object_id from 
                           sash_objs where dbid = :2
                           )';
    open c_sashobjs for sql_stat using l_dbid, l_dbid;
    fetch c_sashobjs bulk collect into sash_objsrec;
    forall i in 1 .. sash_objsrec.count 
             insert into sash_objs values sash_objsrec(i);          
    close c_sashobjs;
exception
    when DUP_VAL_ON_INDEX then null;
    when others then
        sash_repo.log_message('get_objs', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20101, 'SASH get_objs error ' || SUBSTR(SQLERRM, 1 , 1000));    
end get_objs;

PROCEDURE get_sqlplans(l_hist_samp_id number, l_dbid number,  v_dblink varchar2, v_inst_num number) is
type sash_sqlrec_type is table of sash_sqlplans%rowtype;
sash_sqlrec  sash_sqlrec_type := sash_sqlrec_type(); 
type ctype is ref cursor;
c_sqlplans ctype;
sql_stat varchar2(4000);

begin
    sql_stat:='select /*+DRIVING_SITE(sql) */
                          sql.sql_id, 
                          sql.plan_hash_value,
                           ''REMARKS'' remarksdesc ,
                           sql.OPERATION,
                           sql.OPTIONS,
                           sql.OBJECT_NODE,
                           sql.OBJECT_OWNER,
                           sql.OBJECT_NAME,
                           0,
                           sql.OBJECT_TYPE,
                           sql.OPTIMIZER,
                           sql.SEARCH_COLUMNS,
                           sql.ID,
                           sql.PARENT_ID,
                           sql.depth,
                           sql.POSITION,
                           sql.COST,
                           sql.CARDINALITY,
                           sql.BYTES,
                           sql.OTHER_TAG,
                           sql.PARTITION_START,
                           sql.PARTITION_STOP,
                           sql.PARTITION_ID,
                           sql.OTHER,
                           sql.DISTRIBUTION,
                           sql.CPU_COST,
                           sql.IO_COST,
                           sql.TEMP_SPACE,
                           sql.ACCESS_PREDICATES,
                           sql.FILTER_PREDICATES,
                           :1,
			   :2
                    from sys.v_$sql_plan@' || v_dblink || ' sql, sash_hour_sqlid sqlids
                    where sql.sql_id= sqlids.sql_id and sql.plan_hash_value = sqlids.sql_plan_hash_value
                    and not exists (select 1 from sash_sqlplans sqlplans where sqlplans.plan_hash_value = sqlids.sql_plan_hash_value 
                                             and sqlplans.sql_id = sqlids.sql_id and inst_id = :3 )';
    open c_sqlplans for sql_stat using l_dbid, v_inst_num, v_inst_num ;
    fetch c_sqlplans bulk collect into sash_sqlrec;
    forall i in 1 .. sash_sqlrec.count 
             insert into sash_sqlplans values sash_sqlrec(i);          
    close c_sqlplans;	
exception
    when others then
        sash_repo.log_message('get_sqlplans', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20102, 'SASH get_sqlplans error ' || SUBSTR(SQLERRM, 1 , 1000));     
end get_sqlplans;

PROCEDURE get_sqlstats(l_hist_samp_id number, l_dbid number, v_dblink varchar2, v_inst_num number) is
type sash_sqlstats_type is table of sash_sqlstats%rowtype;
sash_sqlstats_rec sash_sqlstats_type;
type ctype is ref cursor;
c ctype;
sql_stat varchar2(4000);
v_lastall number;
l_ver varchar2(8);
l_oldsnap number;

begin
        begin
            select max(snap_id) into l_oldsnap from sash_sqlstats m where m.dbid = l_dbid and m.instance_number = v_inst_num; 
                exception when NO_DATA_FOUND then
                        l_oldsnap:=1;
        end;


        l_ver:=substr(sash_pkg.get_version(v_dblink),0,4); 

        if (l_ver = '10.2') then
        sql_stat:='select /*+driving_site(sql) */  :1, :2, :3,
                   sql_id,  plan_hash_value, parse_calls, disk_reads,
                          direct_writes, buffer_gets, rows_processed, serializable_aborts,
                       fetches, executions, end_of_fetch_count, loads, version_count,
                       invalidations,  px_servers_executions,  cpu_time, elapsed_time,
                       avg_hard_parse_time, application_wait_time, concurrency_wait_time,
                       cluster_wait_time, user_io_wait_time, plsql_exec_time, java_exec_time,
                       sorts, sharable_mem, total_sharable_mem, 0, 0, 0, 0,0,0,0,0,0 ,
                        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                       from sys.v_$sqlstats@' || v_dblink || ' sql
                       where (sql.sql_id, sql.plan_hash_value) in ( select sql_id, SQL_PLAN_HASH_VALUE from sash_hour_sqlid t)';
        elsif (l_ver = '11.1') then
        sql_stat:='select /*+driving_site(sql) */  :1, :2, :3,
                   sql_id,  plan_hash_value, parse_calls, disk_reads,
                          direct_writes, buffer_gets, rows_processed, serializable_aborts,
                       fetches, executions, end_of_fetch_count, loads, version_count,
                       invalidations,  px_servers_executions,  cpu_time, elapsed_time,
                       avg_hard_parse_time, application_wait_time, concurrency_wait_time,
                       cluster_wait_time, user_io_wait_time, plsql_exec_time, java_exec_time,
                       sorts, sharable_mem, total_sharable_mem, typecheck_mem, io_interconnect_bytes,
                       io_disk_bytes, 0,0,0,0, exact_matching_signature, force_matching_signature ,
                        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                       from sys.v_$sqlstats@' || v_dblink || ' sql
                       where (sql.sql_id, sql.plan_hash_value) in ( select sql_id, SQL_PLAN_HASH_VALUE from sash_hour_sqlid t)';
        elsif (l_ver = '11.2') then
    sql_stat:='select /*+driving_site(sql) */  :1, :2, :3,
               sql_id,  plan_hash_value, parse_calls, disk_reads,
               direct_writes, buffer_gets, rows_processed, serializable_aborts,
               fetches, executions, end_of_fetch_count, loads, version_count,
               invalidations,  px_servers_executions,  cpu_time, elapsed_time,
               avg_hard_parse_time, application_wait_time, concurrency_wait_time,
               cluster_wait_time, user_io_wait_time, plsql_exec_time, java_exec_time,
               sorts, sharable_mem, total_sharable_mem, typecheck_mem, io_interconnect_bytes,
               0, physical_read_requests,  physical_read_bytes, physical_write_requests,
               physical_write_bytes, exact_matching_signature, force_matching_signature ,
               0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
               from sys.v_$sqlstats@' || v_dblink || ' sql
                where (sql.sql_id, sql.plan_hash_value) in ( select sql_id, SQL_PLAN_HASH_VALUE from sash_hour_sqlid t)';
        end if;
        --where last_active_time > sysdate - :4/24';
        --open c for sql_stat using l_hist_samp_id, l_dbid, v_inst_num, v_lastall ;
        open c for sql_stat using l_hist_samp_id, l_dbid, v_inst_num;
        fetch c bulk collect into sash_sqlstats_rec;
        forall i in 1..sash_sqlstats_rec.count 
            insert into sash_sqlstats values sash_sqlstats_rec(i);	
            
         update sash_sqlstats s set 
        (fetches_delta, end_of_fetch_count_delta, sorts_delta, executions_delta, px_servers_execs_delta, 
         loads_delta, invalidations_delta, parse_calls_delta, disk_reads_delta, buffer_gets_delta, rows_processed_delta,
         cpu_time_delta, elapsed_time_delta, iowait_delta, clwait_delta, apwait_delta, ccwait_delta, direct_writes_delta,
         plsexec_time_delta, javexec_time_delta, io_interconnect_bytes_delta, io_disk_bytes_delta, physical_read_requests_delta, physical_read_bytes_delta,
         physical_write_requests_delta, physical_write_bytes_delta) = 
        (select 
         s.fetches - old.fetches, s.end_of_fetch_count - old.end_of_fetch_count, s.sorts - old.sorts, s.executions - old.executions, s.px_servers_executions - old.px_servers_executions, 
         s.loads - old.loads, s.invalidations - old.invalidations, s.parse_calls - old.parse_calls, s.disk_reads - old.disk_reads, s.buffer_gets - old.buffer_gets, s.rows_processed - old.rows_processed,
         s.cpu_time - old.cpu_time, s.elapsed_time - old.elapsed_time, s.user_io_wait_time - old.user_io_wait_time, s.cluster_wait_time - old.cluster_wait_time, s.application_wait_time - old.application_wait_time, s.concurrency_wait_time - old.concurrency_wait_time, s.direct_writes - old.direct_writes,
         s.plsql_exec_time - old.plsql_exec_time, s.java_exec_time - old.java_exec_time, s.io_interconnect_bytes - old.io_interconnect_bytes, s.io_disk_bytes - old.io_disk_bytes,
         s.physical_read_requests - old.physical_read_requests, s.physical_read_bytes - old.physical_read_bytes,
         s.physical_write_requests - old.physical_write_requests, s.physical_write_bytes - old.physical_write_bytes
         from sash_sqlstats old where 
         old.snap_id = l_oldsnap and old.sql_id = s.sql_id and old.plan_hash_value = s.plan_hash_value and old.dbid = s.dbid and old.instance_number = s.instance_number)
         where snap_id = l_hist_samp_id;
exception
    when others then
        sash_repo.log_message('get_sqlstats', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20103, 'SASH get_sqlstats error ' || SUBSTR(SQLERRM, 1 , 1000));    		
end get_sqlstats;


PROCEDURE get_sqlid(l_dbid number, v_sql_id varchar2,  v_dblink varchar2 ) is
begin
         insert into sash_hour_sqlid select sql_id, sql_plan_hash_value from sash where l_dbid = dbid and sql_id = v_sql_id;
end get_sqlid;	   

PROCEDURE get_sqlids(l_dbid number, v_inst_num number) is
          v_sqlid  number;
          v_sqllimit number:=0;
          v_lastall number;
          
       begin
         begin
            select to_number(value) into v_sqllimit from sash_configuration where param='SQL LIMIT';
            dbms_output.put_line('v limit ' || v_sqllimit);
            exception when NO_DATA_FOUND then 
              v_sqllimit:=21;
         end;
         
         begin
            select to_number(value) into v_lastall from sash_configuration where param='STATFREQ';
            dbms_output.put_line('v_lastall ' || v_lastall);
            exception when NO_DATA_FOUND then 
              v_lastall:=15;
         end;
	 dbms_output.put_line('v_lastall ' || v_lastall || 'v limit ' || v_sqllimit);
         insert into sash_hour_sqlid select distinct sql_id, sql_plan_hash_value from (
                          select count(*) cnt, sql_id, sql_plan_hash_value
                          from sash 
                          where l_dbid = dbid
                             and sql_id != '0'
                             --and sql_plan_hash_value != '0'
                             and sample_time > sysdate - v_lastall/24/60
                             --and sample_time > sysdate - 1/24 
 			     and inst_id = v_inst_num
                          group by sql_id, sql_plan_hash_value
                          order by cnt desc )
                        where rownum < v_sqllimit;
exception
    when others then
        sash_repo.log_message('get_sqlids', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20104, 'SASH get_sqlids error ' || SUBSTR(SQLERRM, 1 , 1000));    		                        
end get_sqlids;


PROCEDURE get_sqltxt(l_dbid number, v_dblink varchar2)  is
sql_stat varchar2(4000);

begin
    -- we can't use PL/SQL to copy CLOB over DB link - this is a workaround and direct copy from target to repository table
    sql_stat:='insert into sash_sqltxt select /*+DRIVING_SITE(sqlt) */  :1, SQL_ID, to_char(SQL_TEXT), 1
                from sys.v_$sqlstats@'|| v_dblink || ' sqlt 
                where sqlt.sql_id in 
                (select sql_id from sash_hour_sqlid t 
                 where not exists (select 1 from sash_sqltxt psql where t.sql_id = psql.sql_id and psql.dbid = :2))';
    execute immediate sql_stat using l_dbid, l_dbid;
exception
    when others then
        sash_repo.log_message('get_sqltxt', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20105, 'SASH get_sqltxt error ' || SUBSTR(SQLERRM, 1 , 1000));    		                        
end get_sqltxt;
 
 
PROCEDURE collect_ash(v_sleep number, loops number, v_dblink varchar2, vinstance number) is
          sash_rec sash%rowtype;
          TYPE SashcurTyp IS REF CURSOR;
          sash_cur   SashcurTyp;		  
          l_dbid number;
          cur_sashseq   number := 0;
          sql_stat varchar2(4000);
          no_host EXCEPTION;
      PRAGMA EXCEPTION_INIT(no_host, -12543);          

          begin

            l_dbid:=get_dbid(v_dblink);
            sql_stat := 'select a.*, 1 sample_id, null terminal, null inst_id from sys.sashnow@' || v_dblink || ' a';
            for i in 1..loops loop
              select  sashseq.nextval into cur_sashseq from dual;
              open sash_cur FOR sql_stat; 
              loop
                fetch sash_cur into sash_rec;
                exit when sash_cur%notfound;
                  insert into sash
                   (  
                    DBID,
                    SAMPLE_TIME,
                    SESSION_ID,
                    SESSION_STATE,
                    SESSION_SERIAL#,
				    OSUSER,
                    SESSION_TYPE  ,
                    USER_ID,
                    COMMAND,
                    MACHINE,
                    PORT,
                    SQL_ADDRESS,
                    SQL_PLAN_HASH_VALUE,
                    SQL_CHILD_NUMBER,
                    SQL_ID,
                    SQL_OPCODE  /* aka SQL_OPCODE */,
                    SQL_EXEC_START,
                    SQL_EXEC_ID,
                    PLSQL_ENTRY_OBJECT_ID,
                    PLSQL_ENTRY_SUBPROGRAM_ID,
                    PLSQL_OBJECT_ID,
                    PLSQL_SUBPROGRAM_ID,
                    EVENT# ,
                    SEQ#        /* xksuse.ksuseseq */,
                    P1          /* xksuse.ksusep1  */,
                    P2          /* xksuse.ksusep2  */,
                    P3          /* xksuse.ksusep3  */,
                    WAIT_TIME   /* xksuse.ksusetim */,
                    TIME_WAITED   /* xksuse.ksusewtm */,
                    CURRENT_OBJ#,
                    CURRENT_FILE#,
                    CURRENT_BLOCK#,
                    CURRENT_ROW#,                   
                    PROGRAM,
                    MODULE,
                    MODULE_HASH,  /* ASH collects string */
                    ACTION,
                    ACTION_HASH,   /* ASH collects string */
                    LOGON_TIME,
                    ksuseblocker,
                    SERVICE_NAME,
                    FIXED_TABLE_SEQUENCE, /* FIXED_TABLE_SEQUENCE */
                    QC,
                    SAMPLE_ID,
                    inst_id
                    )
                  values 
                       ( 
                        sash_rec.DBID,
                        sash_rec.sample_time,
                        sash_rec.SESSION_ID,
                        sash_rec.SESSION_STATE,
                        sash_rec.SESSION_SERIAL#,
						sash_rec.OSUSER,
                        sash_rec.SESSION_TYPE  ,
                        sash_rec.USER_ID,
                        sash_rec.COMMAND,
                        sash_rec.MACHINE,
                        sash_rec.PORT,
                        sash_rec.SQL_ADDRESS,
                        sash_rec.SQL_PLAN_HASH_VALUE,
                        sash_rec.SQL_CHILD_NUMBER,
                        sash_rec.SQL_ID ,
                        sash_rec.SQL_OPCODE  /* aka SQL_OPCODE */,
                        sash_rec.SQL_EXEC_START,
                        sash_rec.SQL_EXEC_ID,
                        sash_rec.PLSQL_ENTRY_OBJECT_ID,
                        sash_rec.PLSQL_ENTRY_SUBPROGRAM_ID,
                        sash_rec.PLSQL_OBJECT_ID,
                        sash_rec.PLSQL_SUBPROGRAM_ID,
                        sash_rec.EVENT# ,
                        sash_rec.SEQ#        /* xksuse.ksuseseq */,
                        sash_rec.P1          /* xksuse.ksusep1  */,
                        sash_rec.P2          /* xksuse.ksusep2  */,
                        sash_rec.P3          /* xksuse.ksusep3  */,
                        sash_rec.WAIT_TIME   /* xksuse.ksusetim */,
                        sash_rec.TIME_WAITED   /* xksuse.ksusewtm */,
                        sash_rec.CURRENT_OBJ#,
                        sash_rec.CURRENT_FILE#,
                        sash_rec.CURRENT_BLOCK#,
                        sash_rec.CURRENT_ROW#,						
                        sash_rec.PROGRAM,
                        sash_rec.MODULE,
                        sash_rec.MODULE_HASH,  /* ASH collects string */
                        sash_rec.action,
                        sash_rec.ACTION_HASH,   /* ASH collects string */
                        sash_rec.LOGON_TIME,
                        sash_rec.ksuseblocker,			
                        sash_rec.SERVICE_NAME,
                        sash_rec.FIXED_TABLE_SEQUENCE, /* FIXED_TABLE_SEQUENCE */
                        sash_rec.QC,
                        cur_sashseq,
                         vinstance
                        );
              end loop;
              close sash_cur;
              commit;
              dbms_lock.sleep(v_sleep);
            end loop;
exception 
    when no_host then
    sash_repo.log_message('collect_ash', 'can access database ' || v_dblink  || SUBSTR(SQLERRM, 1 , 800),'W');
    when others then
        sash_repo.log_message('collect_ash', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20106, 'SASH collect error ' || SUBSTR(SQLERRM, 1 , 1000));    	            
end collect_ash;
       
procedure collect_io_event(v_dblink varchar2, vinstance number, v_hist_samp_id number) is
type sash_io_system_event_type is table of sash_io_system_event%rowtype;
io_event_rec sash_io_system_event_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;		
l_dbid number;		

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select :1,:2,:3,sysdate,total_waits,total_timeouts,time_waited,average_wait,time_waited_micro,event_id           
                 from sys.v_$system_event@' || v_dblink ||' where event in (''log file sync'',''log file parallel write'',''db file scattered read'',''db file sequential read'',''direct path read''
                ,''direct path read temp'',''direct write'',''direct write temp'')';	
    open sash_cur FOR sql_stat using l_dbid, vinstance, v_hist_samp_id; 
    fetch sash_cur bulk collect into io_event_rec;
    forall i in 1..io_event_rec.count 
        insert into sash_io_system_event values io_event_rec(i);
    --commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_io_event', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20107, 'SASH collect_io_event error ' || SUBSTR(SQLERRM, 1 , 1000));    	    
end collect_io_event;

procedure collect_metric(v_hist_samp_id number, v_dblink varchar2, vinstance number) is
type sash_sysmetric_history_type is table of sash_sysmetric_history%rowtype;
session_rec sash_sysmetric_history_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;		
l_dbid number;
l_time date;		

begin
    l_dbid:=get_dbid(v_dblink);
    select nvl(max(BEGIN_TIME),sysdate-30) into l_time from sash_sysmetric_history where dbid = l_dbid and inst_id = vinstance;
    dbms_output.put_line(l_dbid || ' ' || vinstance || ' ' || l_time);
    sql_stat := 'select  :1, :2, :3, BEGIN_TIME, INTSIZE_CSEC, GROUP_ID, METRIC_ID, VALUE from sys.v_$SYSMETRIC_HISTORY@'|| v_dblink || ' ss where begin_time > :4 and INTSIZE_CSEC > 2000 and metric_id in (select METRIC_ID from sash_sysmetric_names)';	
    dbms_output.put_line(sql_stat || ' ' || l_time);
    open sash_cur FOR sql_stat using l_dbid, vinstance, v_hist_samp_id, l_time;
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count 
        insert into sash_sysmetric_history values session_rec(i);
    --commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_metric', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20108, 'SASH collect_metric error ' || SUBSTR(SQLERRM, 1 , 1000));      
end collect_metric;


procedure collect_histogram(v_hist_samp_id number, v_dblink varchar2, vinstance number) is
type sash_event_histogram_type is table of sash_event_histogram%rowtype;
session_rec sash_event_histogram_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;
l_dbid number;
l_time date;

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select  :1, :2, :3, EVENT#, WAIT_TIME_MILLI, WAIT_COUNT from sys.v_$event_histogram@'|| v_dblink;
    open sash_cur FOR sql_stat using v_hist_samp_id, l_dbid, vinstance;
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count
        insert into sash_event_histogram values session_rec(i);
    --commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_histogram', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20108, 'SASH collect_metric error ' || SUBSTR(SQLERRM, 1 , 1000));
end collect_histogram;


procedure collect_iostat(v_hist_samp_id number, v_dblink varchar2, vinstance number) is
type sash_iofuncstats_type is table of sash_iofuncstats%rowtype;
session_rec sash_iofuncstats_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;		
l_dbid number;	

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select  :1, :2, :3, FUNCTION_ID, FUNCTION_NAME, SMALL_READ_MEGABYTES, SMALL_WRITE_MEGABYTES, LARGE_READ_MEGABYTES, LARGE_WRITE_MEGABYTES, SMALL_READ_REQS,        
                 SMALL_WRITE_REQS, LARGE_READ_REQS, LARGE_WRITE_REQS, NUMBER_OF_WAITS , WAIT_TIME from sys.v_$iostat_function@'|| v_dblink || ' ss';	
    open sash_cur FOR sql_stat using l_dbid, vinstance, v_hist_samp_id;
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count 
        insert into sash_iofuncstats values session_rec(i);
    commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_iostat', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20109, 'SASH collect_iostat error ' || SUBSTR(SQLERRM, 1 , 1000));     
end collect_iostat;

procedure collect_osstat(v_hist_samp_id number, v_dblink varchar2, vinstance number) is 
type sash_osstat_type is table of sash_osstat%rowtype;
session_rec sash_osstat_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;
l_dbid number;

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select :1, :2, :3, OSSTAT_ID, VALUE from sys.v_$osstat@'|| v_dblink;
    open sash_cur FOR sql_stat using v_hist_samp_id, l_dbid, vinstance;
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count
        insert into sash_osstat values session_rec(i);
    commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_osstat', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20109, 'SASH collect_osstat error ' || SUBSTR(SQLERRM, 1 , 1000));
end;

procedure collect_systime(v_hist_samp_id number, v_dblink varchar2, vinstance number) is
type sash_sys_time_model_type is table of sash_sys_time_model%rowtype;
session_rec sash_sys_time_model_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;
l_dbid number;

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select :1, :2, :3, STAT_ID, VALUE from sys.v_$sys_time_model@'|| v_dblink;
    open sash_cur FOR sql_stat using v_hist_samp_id, l_dbid, vinstance;
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count
        insert into sash_sys_time_model values session_rec(i);
    commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_sys_time', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20109, 'SASH collect_sys_time error ' || SUBSTR(SQLERRM, 1 , 1000));
end;

procedure collect_stats(v_dblink varchar2, vinstance number) is
type sash_instance_stats_type is table of sash_instance_stats%rowtype;
session_rec sash_instance_stats_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;		
l_dbid number;		

begin
    l_dbid:=get_dbid(v_dblink);
    sql_stat := 'select /*+DRIVING_SITE(ss) */ ' || l_dbid || ' , ' || vinstance || ' ,sysdate, statistic#, value from sys.v_$sysstat@'|| v_dblink || ' ss where statistic# in (select sash_s.statistic# from sash_stats sash_s where collect = 1)';	
    open sash_cur FOR sql_stat; 
    fetch sash_cur bulk collect into session_rec;
    forall i in 1..session_rec.count 
        insert into sash_instance_stats values session_rec(i);
    commit;
    close sash_cur;
exception
    when others then
        sash_repo.log_message('collect_stats', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20110, 'SASH collect_stats error ' || SUBSTR(SQLERRM, 1 , 1000));        
end collect_stats;

procedure collect_other(v_sleep number, loops number, v_dblink varchar2, vinstance number) is
type sash_instance_stats_type is table of sash_instance_stats%rowtype;
session_rec sash_instance_stats_type;
sql_stat varchar2(4000);
TYPE SashcurTyp IS REF CURSOR;
sash_cur   SashcurTyp;		
l_dbid number;		

begin
    for l in 1..loops loop
        collect_stats(v_dblink, vinstance);
        collect_io_event(v_dblink, vinstance,1);
        commit;
        dbms_lock.sleep(v_sleep);
    end loop;   
end collect_other;

       
     PROCEDURE get_one(v_sql_id varchar2, v_dblink varchar2, v_inst_num number) is
        l_hist_samp_id	number;
        l_dbid number;
       begin
          select hist_id_seq.currval into l_hist_samp_id from dual;
          l_dbid:=get_dbid(v_dblink);
          get_sqlid(l_dbid,v_sql_id, v_dblink);
          get_sqltxt(l_dbid,v_dblink);
          get_sqlstats(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          get_sqlplans(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          insert into sash_hist_sample values (l_hist_samp_id, l_dbid, v_inst_num, sysdate);
          commit;
       end get_one;	

       PROCEDURE get_all(v_dblink varchar2, v_inst_num number) is
        l_hist_samp_id	number;
        l_dbid number;
        l_ver varchar2(8);
       begin
          select hist_id_seq.nextval into l_hist_samp_id from dual;
          l_ver:=substr(sash_pkg.get_version(v_dblink),0,2);
          l_dbid:=get_dbid(v_dblink);
          get_sqlids(l_dbid, v_inst_num);
          get_sqltxt(l_dbid,v_dblink);
          get_sqlstats(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          get_sqlplans(l_hist_samp_id, l_dbid,v_dblink, v_inst_num);
          get_objs(l_dbid, v_dblink);
          collect_metric(l_hist_samp_id, v_dblink , v_inst_num );
          collect_io_event(v_dblink, v_inst_num,l_hist_samp_id);
          collect_histogram(l_hist_samp_id, v_dblink, v_inst_num);
          collect_systime(l_hist_samp_id, v_dblink, v_inst_num);
          collect_osstat(l_hist_samp_id, v_dblink, v_inst_num);
          if (l_ver = '11') then
            collect_iostat(l_hist_samp_id, v_dblink , v_inst_num );
          end if ;
          insert into sash_hist_sample values (l_hist_samp_id, l_dbid, v_inst_num, sysdate);
          commit;
       end get_all;	   
       
END sash_pkg;
/


show errors
spool off

