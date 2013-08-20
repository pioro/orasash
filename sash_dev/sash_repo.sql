-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: New procedures for stopping and starting jobs, purge procedure extended
-- v2.2 Changes: todo - add purging of historical data
-- v2.3 Changes: dbms_scheduler used to control repository jobs
--               job watchdog added
--               more logging added
--               support for RAC and multiple databases
-- v2.4 Changes: new names for jobs

spool sash_repo.log
prompt Crating SASH_REPO package

CREATE OR REPLACE PACKAGE sash_repo AS
    procedure purge_tables;
    procedure add_db(v_host varchar2, v_port number, v_sash_pass varchar2, v_db_name varchar2, v_sid varchar2, v_inst_num number, v_version varchar2 default '', v_cpu_count number default 0);
    procedure setup_jobs;
    procedure stop_collecting_jobs;
    procedure start_collecting_jobs;
    procedure create_repository_jobs;
    procedure create_collection_jobs;
    procedure stop_and_remove_rep_jobs;
    procedure watchdog;
    procedure set_retention(rtype varchar2);
    procedure log_message(vaction varchar2, vmessage varchar2, vresults varchar2);
    procedure add_instance_job (v_dbname varchar2, v_inst_num number, v_db_link varchar2);
    procedure remove_instance_job (v_dbname varchar2, v_inst_num number);
END sash_repo;
/
show errors


CREATE OR REPLACE PACKAGE BODY sash_repo AS

-- procedure log_message
-- logging all messaages to sash_log table as an autonomus transaction
-- action  - varchar(100)
-- message - varchar(1000)
-- result  - char(1) - E - error / W - warining / I - info

procedure log_message(vaction varchar2, vmessage varchar2, vresults varchar2) is
PRAGMA AUTONOMOUS_TRANSACTION; 
begin
    dbms_output.put_line(vmessage || ' ' || vresults);
    insert into sash_log (log_id, action, message,result) values (log_id_seq.nextval, vaction, vmessage,vresults);
    commit;
end;


-- procedure purge 
-- Purging SASH tables with Active Session History data and switching a view SASH to proper table
-- 4 data retentions are available
-- d - change table every day with 7 day retention     - sash1 to sash7
-- w - change table every day with one month retention - sash1 to sash31
-- h - change table every hour with 24 h retention     - sash1 to sash24
-- m - change table every minute with 30 min retention - sash1 to sash24 - not implemented now in jobs 
-- purge job is calling this function and it has to have proper schedule

procedure purge_tables is
    l_text  varchar2(4000);
    l_day   number;
    rtype   varchar2(1);
    l_minusdays number;
begin
    select substr(value,1,1) into rtype from sash_configuration where param='SASH RETENTION';
    if rtype = 'd' then 
        select to_number(to_char(sysdate,'D')) into l_day from dual;
        l_minusdays := 8;
    elsif rtype = 'w' then
        select to_number(to_char(sysdate,'DD')) into l_day from dual;		  
        l_minusdays := 32;
    elsif rtype = 'h' then
        select to_number(to_char(sysdate,'HH24')) into l_day from dual;
        l_minusdays := 1;
    elsif rtype = 'm' then 
        select mod(to_number(to_char(sysdate,'MI')),30)+1 into l_day from dual;
        l_minusdays := 1;
    end if;
    l_text:='truncate table sash'||to_char(l_day);
    execute immediate l_text;
    l_text:='create or replace view sash as select * from sash'||to_char(l_day);
    execute immediate l_text;

-- sash_event_histogram
    l_text:='truncate table sash_event_histogram'||to_char(l_day);
    execute immediate l_text;
    l_text:='create or replace view sash_event_histogram as select * from sash_event_histogram'||to_char(l_day);
    execute immediate l_text;

-- sash_sqlstats
    l_text:='truncate table sash_sqlstats'||to_char(l_day);
    execute immediate l_text;
    l_text:='create or replace view sash_sqlstats as select * from sash_sqlstats'||to_char(l_day);
    execute immediate l_text;


-- delete rows from not ASH tables

--    delete from SASH_SQLSTATS where snap_id in (select HIST_SAMPLE_ID from SASH_HIST_SAMPLE where HIST_DATE < sysdate - l_minusdays);
    delete from SASH_IO_SYSTEM_EVENT where snap_id in (select HIST_SAMPLE_ID from SASH_HIST_SAMPLE where HIST_DATE < sysdate - l_minusdays);
    delete from SASH_SYSMETRIC_HISTORY where snap_id in (select HIST_SAMPLE_ID from SASH_HIST_SAMPLE where HIST_DATE < sysdate - l_minusdays);
    commit;

exception
    when others then
        log_message('PURGE PARTITION', 'l_text value ' || l_text || ' rtype value ' || rtype || 'SQLERR' || SUBSTR(SQLERRM, 1 , 900),'E');
        RAISE_APPLICATION_ERROR(-20010,'SASH purge error ' || SUBSTR(SQLERRM, 1 , 1000));
end purge_tables;

-- procedure set_retention 
-- setting a sash retention
-- 4 data retentions are available
-- d - change table every day with 7 day retention     - sash1 to sash7
-- w - change table every day with one month retention - sash1 to sash31
-- h - change table every hour with 24 h retention     - sash1 to sash24
-- m - change table every minute with 30 min retention - sash1 to sash24 - not implemented now in jobs 

-- to do - retention check !!!


procedure set_retention(rtype varchar2) is 
begin
    update sash_configuration set value = rtype where param='SASH RETENTION';
    commit;
exception
    when others then
        log_message('SET_RETENTION', 'update value ' || rtype || SUBSTR(SQLERRM, 1 , 900) ,'E');
        RAISE_APPLICATION_ERROR(-20020,'SASH set retention error ' || SUBSTR(SQLERRM, 1 , 1000));
end;


-- procedure create_repository_jobs
-- Repository job calling a purge procedure has to be scheduled in relation to defined retention type

procedure create_repository_jobs is
    vjob number;
    v_check number;
    v_interval varchar2(100);
    v_nextdate  date;
    rtype  varchar2(1);
begin
    begin
        select substr(value,1,1) into rtype from sash_configuration where param='SASH RETENTION';        
    exception when NO_DATA_FOUND then 
        rtype:='w';
    end;    
    select count(*) into v_check from user_scheduler_jobs where job_name = 'SASH_REPO_PURGE';
    if v_check = 0 then
      begin
        log_message('create_repository_jobs', 'adding new repository job', 'I');
        if rtype      = 'd' then
          v_interval := 'freq = daily; interval = 1';
          v_nextdate := trunc(sysdate) + 1;
        elsif rtype   = 'w' then
          v_interval := 'freq = daily; interval = 1';
          v_nextdate := trunc(sysdate) + 1;
        elsif rtype   = 'h' then
          v_interval := 'freq = hourly; interval = 1';
          v_nextdate := to_date(to_char(sysdate+1/24,'dd-mm-yyyy hh24'),'dd-mm-yyyy hh24');
        end if;
        dbms_scheduler.create_job(job_name => 'sash_repo_purge',
                                  job_type => 'plsql_block',
                                  job_action => 'sash_repo.purge_tables;',
                                  start_date => v_nextdate,
                                  repeat_interval => v_interval,
                                  enabled=>true);
        dbms_scheduler.create_job(job_name => 'sash_repo_watchdog', job_type => 'plsql_block', job_action => 'sash_repo.watchdog;', start_date => sysdate, 
                                  repeat_interval => 'freq = minutely; interval = 5',enabled=>true);
      end;
    else
      log_message('create_repository_jobs','repository job exist - remove first', 'I');
      RAISE_APPLICATION_ERROR(-20030,'sash create_repository_jobs - repository job exist - remove first');
    end if;
exception when others then
  log_message('create_repository_jobs', SUBSTR(SQLERRM, 1 , 1000) ,'E');
  RAISE_APPLICATION_ERROR(-20030,'sash  create_repository_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));            
end;

-- procedure create_collection_jobs
-- Creating a collection jobs schedule
-- ASH jobs are started every hour and are running for 1 hour sampling data every 1 sec
-- instance statistics jobs are started every hour and are running for 1 hour sampling data every 1 min
-- SQL stats / plans jobs are started depends on value of STATFREQ parameter in minutes

procedure create_collection_jobs is
vwhat varchar2(4000);
v_getall number;
v_startmin number;

begin
    begin
        select to_number(value) into v_getall from sash_configuration where param='STATFREQ';
        dbms_output.put_line('v_getall ' || v_getall);
        exception when NO_DATA_FOUND then 
            v_getall:=15;
    end;

    v_startmin := v_getall * 60;
    for i in (select db_link, inst_num, dbname from sash_targets) loop
        
        add_instance_job( i.dbname, i.inst_num, i.db_link); 
        /*                  
        vwhat:='begin sash_pkg.collect_ash(1,3600,'''|| i.db_link || ''', '|| i.inst_num || '); end;';
        dbms_scheduler.create_job(job_name => 'sash_pkg_collect_' || i.dbname || i.inst_num,
                                job_type => 'PLSQL_BLOCK',
                                job_action => vwhat,
                                start_date => sysdate,
                                repeat_interval => 'FREQ = HOURLY; INTERVAL = 1',
                                enabled=>true);
        log_message('create_collection_jobs','adding scheduler job sash_pkg_collect_' || i.dbname || i.inst_num,'I');
        vwhat:='begin sash_pkg.collect_other(60,60,'''|| i.db_link || ''', '|| i.inst_num || '); end;';
        dbms_scheduler.create_job(job_name => 'sash_pkg_collect_other_' || i.inst_num,
                                job_type => 'PLSQL_BLOCK',
                                job_action => vwhat,
                                start_date => sysdate,
                                repeat_interval => 'FREQ = HOURLY; INTERVAL = 1',
                                enabled => true);
        vwhat:='begin sash_pkg.get_all('''|| i.db_link || ''',' || i.inst_num || '); end;';
        dbms_scheduler.create_job(job_name => 'sash_pkg_get_all_' || i.dbname || i.inst_num,
                              job_type=>'PLSQL_BLOCK',
                              job_action=> vwhat,
                              start_date=>to_date(trunc((to_char(sysdate,'SSSSS')+v_startmin)/v_startmin)*v_startmin,'SSSSS'),
                              repeat_interval=>'FREQ = MINUTELY; INTERVAL = ' || v_getall,
                              enabled=>true);
        log_message('create_collection_jobs','adding scheduler job sash_pkg_get_all_' || i.dbname || i.inst_num,'I');
        */
                        
    end loop;
    commit;

    exception when others then
            log_message('create_collection_jobs', SUBSTR(SQLERRM, 1 , 1000) ,'E');
            RAISE_APPLICATION_ERROR(-20031,'SASH  create_collection_jobs errored ' || SUBSTR(SQLERRM, 1 , 1000));	
end;     


-- procedure stop_and_remove_rep_jobs
-- Remove repository job

procedure stop_and_remove_rep_jobs is
begin
    for i in (select job_name from user_scheduler_jobs where job_name like '%SASH_REPO%') loop
      dbms_scheduler.drop_job(i.job_name, true);
      log_message('stop_and_remove_rep_jobs', 'removed scheduler job ' || i.job_name, 'I');
    end loop;
    exception
        when others then
            log_message('stop_and_remove_rep_jobs', SUBSTR(SQLERRM, 1 , 1000) ,'E');
            RAISE_APPLICATION_ERROR(-20032,'SASH  stop_and_remove_rep_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));
end;


-- procedure remove_collection_jobs
-- Remove collection jobs

procedure remove_collection_jobs is
begin
    for i in (select job_name from user_scheduler_jobs where job_name like '%SASH_PKG%') loop
      dbms_scheduler.drop_job(i.job_name, true);
      log_message('remove_collection_jobs', 'removing scheduler job ' || i.job_name, 'I');
    end loop;
    exception
        when others then
            log_message('remove_collection_jobs', SUBSTR(SQLERRM, 1 , 1000) ,'E');
            RAISE_APPLICATION_ERROR(-20033,'SASH  remove_collection_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));
end;  

-- procedure setup_jobs
-- Remove any existing SASH jobs and create a new one
-- Has to be run during configuration phase or anytime after configuration change - i.e. new database has been added to repository

procedure setup_jobs is
begin
    stop_collecting_jobs;
    remove_collection_jobs;
    create_collection_jobs;
    stop_and_remove_rep_jobs;
    create_repository_jobs;
end;

-- procedure stop_collecting_jobs
-- Stop any running collection jobs

procedure stop_collecting_jobs is
begin
    for i in (select job_name, state from user_scheduler_jobs where job_name like '%SASH_PKG%') loop
        if (i.state = 'RUNNING') then
            dbms_scheduler.stop_job(i.job_name, true);
        end if;
        dbms_scheduler.disable(i.job_name);
        dbms_output.put_line('stoping scheduler job ' || i.job_name);
        log_message('stop_collecting_jobs', 'stopping scheduler job ' || i.job_name, 'I');
    end loop;
    sys.kill_sash_session;
    exception
        when others then
            log_message('stop_collecting_jobs', SUBSTR(SQLERRM, 1 , 1000) ,'E');
            RAISE_APPLICATION_ERROR(-20034,'SASH  stop_collecting_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));		 
end;

-- procedure start_snap_collecting_jobs
-- Start snapshot jobs - running every STATFREQ

procedure start_snap_collecting_jobs is
begin
    for i in (select job_name from user_scheduler_jobs where job_name like '%SASH_PKG_GET%' and state<>'RUNNING') loop
      dbms_scheduler.enable(i.job_name);
      dbms_scheduler.run_job(i.job_name, false);
      dbms_output.put_line('starting scheduler job ' || i.job_name);
      log_message('start_snap_collecting_jobs', 'starting scheduler job ' || i.job_name, 'I');
    end loop;
exception
    when others then
        log_message('start_snap_collecting_jobs', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20035,'SASH  start_collecting_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));
end;

-- procedure start_rt_collecting_jobs
-- Start real time jobs - collecting ASH data

procedure start_rt_collecting_jobs is
begin
    for i in (select job_name from user_scheduler_jobs where job_name like '%SASH_PKG_COLL%' and state<>'RUNNING') loop
      dbms_scheduler.enable(i.job_name);
      dbms_scheduler.run_job(i.job_name, false);
      dbms_output.put_line('starting scheduler job ' || i.job_name);
      log_message('start_rt_collecting_jobs', 'starting scheduler job ' || i.job_name, 'I');
    end loop;
exception
    when others then
        log_message('start_rt_collecting_jobs', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20036,'SASH  start_collecting_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));		 
end;

-- procedure start_collecting_jobs
-- Starting both real time and snapshot jobs 

procedure start_collecting_jobs is
begin
    start_rt_collecting_jobs;
    start_snap_collecting_jobs;
exception
    when others then
        log_message('start_collecting_jobs', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20037,'SASH  start_collecting_jobs error ' || SUBSTR(SQLERRM, 1 , 1000));
end;

-- procedure watchdog
-- Checking status of real time (ASH) jobs and trying to restart SCHEDULED but not running jobs
-- It doesn't run DISABLED jobs

procedure watchdog is
i number;
begin
  select count(*) into i from user_scheduler_jobs where JOB_NAME like 'SASH_PKG_COLLECT%' and state = 'SCHEDULED';
  if ( i != 0 ) then
      log_message('watchdog','Trying to restart real time collection jobs','I');
      start_rt_collecting_jobs;
  end if;
exception
    when others then
        log_message('watchdog', SUBSTR(SQLERRM, 1 , 1000),'E');
        RAISE_APPLICATION_ERROR(-20040,'SASH watchdog error ' || SUBSTR(SQLERRM, 1 , 1000));
end;

-- procedure add_db
-- Adding new instance and/or database to repository (sash_targets) and creating a database link to new database 
-- using following naming convencion for database link name - v_db_name || v_inst_num
-- v_host - target host name
-- v_port - target listener port
-- v_sash_pass - target SASH user password
-- v_db_name - target database name
-- v_sid - target SID
-- v_inst_num - target instance number
-- v_version - target database version (todo - add default check)
-- v_cpu_count - target number of CPU (todo - propagete this value from sash_params)

procedure add_db(v_host varchar2, v_port number, v_sash_pass varchar2, v_db_name varchar2, v_sid varchar2, v_inst_num number, v_version varchar2 default '', v_cpu_count number default 0) is
v_dblink varchar2(30);
v_dblink_target varchar2(4000);
no_db_link EXCEPTION;
PRAGMA EXCEPTION_INIT(no_db_link, -2024);
v_dbid number;
v_check number;
s_version sash_targets.version%TYPE;

begin
    v_dblink_target:='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST =' || v_host || ')(PORT = ' || v_port || ')))(CONNECT_DATA = (SID = ' || v_sid || ')))';
    --v_dblink := v_db_name || v_inst_num || replace(substr(v_host,1,8),'.','_');
    v_dblink := substr(v_db_name || '_' || replace(replace(v_host,'.','_'),'-','_'),1,30);
    begin
        execute immediate 'drop database link ' || v_dblink;
        dbms_output.put_line('Link dropped');
    exception when no_db_link then
            log_message('add_db', 'no db link - moving forward ' || v_dblink  ,'W');
    end;
    execute immediate 'create database link ' || v_dblink || ' connect to sash identified by ' || v_sash_pass || ' using ''' || v_dblink_target || '''';
    execute immediate 'select dbid from sys.v_$database@' || v_dblink into v_dbid;
	execute immediate 'select version from v$instance@' || v_dblink into s_version;
    select count(*) into v_check from sash_targets where dbid = v_dbid and inst_num = v_inst_num;
    if v_check = 0 then 
        insert into sash_targets (dbid, host, port, dbname, sid, inst_num, db_link, version, cpu_count) values (v_dbid, v_host, v_port, v_db_name, v_sid, v_inst_num, v_dblink, coalesce(v_version, s_version), v_cpu_count);
    else 
        log_message('add_db', 'Database ' || v_db_name || ' instance ' || v_inst_num || ' already added','W');	
    end if;
end;

procedure remove_instance_job (v_dbname varchar2, v_inst_num number)  is
 v_dbid number;
begin
 select dbid into v_dbid from sash_targets where dbname = v_dbname and inst_num = v_inst_num; 
 dbms_scheduler.drop_job(job_name => 'sash_pkg_collect_' || v_inst_num || '_' || v_dbid);
 log_message('remove_instance_job','removing scheduler job sash_pkg_collect_' || v_inst_num || '_' || v_dbid ,'I');
 dbms_scheduler.drop_job(job_name => 'sash_pkg_get_all_' || v_inst_num || '_' || v_dbid);
 log_message('remove_instance_job','removing scheduler job sash_pkg_get_all__' || v_inst_num || '_' || v_dbid,'I');
exception when NO_DATA_FOUND then
 log_message('remove_instance_job','removing scheduler job sash_pkg_get_all__' || v_inst_num || '_' || v_dbid || ' failed','E');
 RAISE_APPLICATION_ERROR(-20033,'SASH remove_instance_job errored ' || SUBSTR(SQLERRM, 1 , 1000));	
end;

-- this is needed to avoid cross reference

FUNCTION get_dbid(v_dblink varchar2) return number is
    l_dbid number;
    begin
      execute immediate 'select dbid  from sys.v_$database@'||v_dblink into l_dbid;
      return l_dbid;
end get_dbid;


procedure add_instance_job (v_dbname varchar2, v_inst_num number, v_db_link varchar2)  is
vwhat varchar2(4000);
v_getall number;
v_startmin number;
v_dbid number;

begin
    begin
        select to_number(value) into v_getall from sash_configuration where param='STATFREQ';
        dbms_output.put_line('v_getall ' || v_getall);
        exception when NO_DATA_FOUND then 
            v_getall:=15;
    end;
        dbms_output.put_line(v_db_link || ' ' );
        -- problem if target is down - add exception
	v_dbid := get_dbid(v_db_link);
        v_startmin := v_getall * 60;
        vwhat:='begin sash_pkg.collect_ash(1,3600,'''|| v_db_link || ''', '|| v_inst_num || '); end;';
        dbms_scheduler.create_job(job_name => 'sash_pkg_collect_' || v_inst_num || '_' || v_dbid,
                                job_type => 'PLSQL_BLOCK',
                                job_action => vwhat,
                                start_date => sysdate,
                                repeat_interval => 'FREQ = HOURLY; INTERVAL = 1',
                                enabled=>true);
        log_message('add_instance_job','adding scheduler job sash_pkg_collect_' || v_inst_num || '_' || v_dbid,'I');
        
        vwhat:='begin sash_pkg.get_all('''|| v_db_link || ''',' || v_inst_num || '); end;';
        dbms_scheduler.create_job(job_name => 'sash_pkg_get_all_' || v_inst_num || '_' || v_dbid,
                              job_type=>'PLSQL_BLOCK',
                              job_action=> vwhat,
                              start_date=>to_date(trunc((to_char(sysdate,'SSSSS')+v_startmin)/v_startmin)*v_startmin,'SSSSS'),
                              repeat_interval=>'FREQ = MINUTELY; INTERVAL = ' || v_getall,
                              enabled=>true);
        log_message('add_instance_job','adding scheduler job sash_pkg_get_all_' || v_inst_num || '_' || v_dbid,'I');
    exception when others then
            log_message('add_instance_job', SUBSTR(SQLERRM, 1 , 1000) ,'E');
            RAISE_APPLICATION_ERROR(-20031,'SASH add_instance_job errored ' || SUBSTR(SQLERRM, 1 , 1000));	
end;



end sash_repo;
/
show err 
spool off
