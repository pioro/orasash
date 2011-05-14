---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: New procedures for stopping and starting jobs, purge procedure extended
-- v2.2 Changes: todo - add purging of historical data

   
CREATE OR REPLACE PACKAGE sash_repo AS
          PROCEDURE purge;
--		  PROCEDURE configure_db;
		  procedure add_db(v_host varchar2, v_port number, v_sash_pass varchar2, v_db_name varchar2, v_sid varchar2, v_inst_num number, v_version varchar2 default '', v_cpu_count number default 0);
		  PROCEDURE setup_jobs;
		  PROCEDURE stop_collecting_jobs;
		  PROCEDURE start_collecting_jobs;
		  procedure create_repository_jobs;
		  procedure create_collection_jobs;
          procedure stop_and_remove_rep_jobs;
		  PROCEDURE set_retention(rtype varchar2);
		  procedure log_message(vaction varchar2, vmessage varchar2, vresults varchar2);
END sash_repo;
/
show errors


CREATE OR REPLACE PACKAGE BODY sash_repo AS

procedure log_message(vaction varchar2, vmessage varchar2, vresults varchar2) is
  PRAGMA AUTONOMOUS_TRANSACTION; 
  begin
	insert into sash_log (action, message,result) values (vaction, vmessage,vresults);
	commit;
  end;


  procedure purge is
          l_text        varchar2(4000);
          l_day         number;
		  rtype 			varchar2(1);
       begin
	    select substr(value,1,1) into rtype from sash_configuration where param='SASH RETENTION';
        --change partitions every day of the week  1-7 , SUN = 1
        if rtype = 'd' then 
          select to_number(to_char(sysdate,'D')) into l_day from dual;
		-- change partition every day of the month 1 - 31
        elsif rtype = 'w' then
          select to_number(to_char(sysdate,'DD')) into l_day from dual;		  
        elsif rtype = 'h' then
          select to_number(to_char(sysdate,'HH24')) into l_day from dual;
        elsif rtype = 'm' then 
          -- 'm' then
          select mod(to_number(to_char(sysdate,'MI')),30)+1 into l_day from dual;
        end if;
        --l_day:=partn;
        l_text:='truncate table sash'||to_char(l_day);
        execute immediate l_text;
        l_text:='create or replace view sash as select * from sash'||to_char(l_day);
        execute immediate l_text;
       exception
          when others then
			 log_message('PURGE PARTITION', l_text || ' rtype value ' || rtype,'E');
             RAISE_APPLICATION_ERROR(-20010,'SASH purge errored ');
  end purge;


  
  
  procedure set_retention(rtype varchar2) is 
  begin
      update sash_configuration set value = rtype where param='SASH RETENTION';
	  commit;
      exception
          when others then
             log_message('SET_RETENTION', 'update value ' || rtype ,'E');
             RAISE_APPLICATION_ERROR(-20020,'SASH set retention errored ');
  end;
  
procedure create_repository_jobs is
     vjob number;
     v_check number;
     v_interval varchar2(100);
     v_nextdate  date;
     rtype  varchar2(1);
  begin
  
      select count(*) into v_check from user_jobs where what like '%sash_repo%';
      if v_check = 0 then begin              
        insert into sash_log (action, message,result) values ('create_repository_jobs','Adding new repository job', 'I');
        select substr(value,1,1) into rtype from sash_configuration where param='SASH RETENTION';
            --change partitions every day of the week  1-7 , SUN = 1
            if rtype = 'd' then
                v_interval := 'TRUNC(SYSDATE+1)';
                v_nextdate := TRUNC(SYSDATE+1);        
            elsif rtype = 'w' then
                v_interval := 'TRUNC(SYSDATE+1)';
                v_nextdate := TRUNC(SYSDATE+1);        
            elsif rtype = 'h' then
                v_interval := 'trunc(SYSDATE+1/24,''HH'')';
                v_nextdate := trunc(SYSDATE+1/24,'HH');
            elsif rtype = 'm' then
                v_interval := 'TRUNC(SYSDATE+1/24/60,''MM'')';
                v_nextdate := TRUNC(SYSDATE+1/24/60,'MM');        
            end if;  
        dbms_job.submit
        ( job       =>  vjob
         ,what      => 'sash_repo.purge;'
         ,next_date => v_nextdate
         ,interval  => v_interval
         ,no_parse  => TRUE
        );
        commit;
       end;
       else 
         log_message('create_repository_jobs','Repository job exist - remove first', 'I');
         RAISE_APPLICATION_ERROR(-20130,'SASH create_repository_jobs - Repository job exist - remove first');
       end if;
    exception
          when others then
			 log_message('create_repository_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20030,'SASH  create_repository_jobs errored ');
  end;

  procedure stop_and_remove_rep_jobs is
  begin
      for i in  ( select job from user_jobs
                where what like '%sash_repo%'
                ) loop
        dbms_output.put_line( 'dbms_job.broken ' || i.job );
        dbms_job.broken( i.job , true);
        dbms_job.remove( i.job);
        log_message('stop_and_remove_repository_jobs','stopping job ' || i.job, 'I');
     end loop;
     commit;
    exception
          when others then
             log_message('stop_and_remove_repository_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20060,'SASH  stop_and_remove_repository_jobs errored ');
  end;
  
  procedure remove_collection_jobs is
  begin
    for i in  ( select job from user_jobs
                where what like '%sash_pkg%'
                ) loop
        dbms_output.put_line( 'dbms_job.remove ' || i.job );
        dbms_job.remove( i.job );
     end loop;
	 commit;
     exception
          when others then
			 log_message('remove_collection_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20040,'SASH  remove_collection_jobs errored ');
   end;  

  procedure create_collection_jobs is
  vjob number; 
  instnum number;
  vwhat varchar2(4000);
  vinterval varchar2(100);
  v_lastall number;
  
  begin
	begin
		select to_number(value) into v_lastall from sash_configuration where param='STATFREQ';
		dbms_output.put_line('v_lastall ' || v_lastall);
		exception when NO_DATA_FOUND then 
		    v_lastall:=1;
	end;

	for i in (select db_link, inst_num from sash_targets) loop
	vwhat:='begin sash_pkg.collect(1,3600,'''|| i.db_link || ''', '|| i.inst_num || '); end;';
	dbms_output.put_line( 'dbms_job.submit ' || vwhat );
    dbms_job.submit( job       => vjob
                        ,what      => vwhat
                        ,next_date => sysdate
                        ,interval => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
						
	vwhat:='begin sash_pkg.collect_stats(60,60,'''|| i.db_link || ''', '|| i.inst_num || '); end;';
	dbms_output.put_line( 'dbms_job.submit ' || vwhat );
    dbms_job.submit( job       => vjob
                        ,what      => vwhat
                        ,next_date => sysdate
                        ,interval => 'trunc(sysdate+(1/(24)),''HH'')'
                        );						

	vwhat:='begin sash_pkg.get_all('''|| i.db_link || ''',' || i.inst_num || '); end;';
	vinterval:='trunc(sysdate+(' || v_lastall || '/24),''HH'')';
	dbms_output.put_line( 'dbms_job.submit ' || vwhat );						
	dbms_output.put_line( 'dbms_job.submit ' || vinterval );						
    dbms_job.submit(job        => vjob
                        ,what      => vwhat
                        ,next_date => sysdate
                        ,interval  => vinterval
                        );
						
	end loop;
    commit;

    exception
          when others then
             log_message('create_collection_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20050,'SASH  create_collection_jobs errored ');	
  end;     
   
   
  procedure setup_jobs is
  begin
    stop_collecting_jobs;
	remove_collection_jobs;
	create_collection_jobs;
	stop_and_remove_rep_jobs;
	create_repository_jobs;
  end;
  
  procedure stop_collecting_jobs is
  begin
      for i in  ( select job from user_jobs
                where what like '%sash_pkg%'
                ) loop
        dbms_output.put_line( 'dbms_job.broken ' || i.job );
        dbms_job.broken( i.job , true);
		log_message('stop_collecting_jobs','stopping job ' || i.job, 'I');		
     end loop;
	 commit;
	 sys.kill_sash_session;
    exception
          when others then
             log_message('stop_collecting_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20060,'SASH  stop_collecting_jobs errored ');		 
  end;
  
  procedure start_collecting_jobs is
  begin
      for i in  ( select job from user_jobs
                where what like '%sash_pkg%'
                ) loop
        dbms_job.broken( i.job , false);
		log_message('start_collecting_jobs','starting job ' || i.job, 'I');
     end loop;
	 commit;
     exception
          when others then
			log_message('start_collecting_jobs', '' ,'E');
             RAISE_APPLICATION_ERROR(-20070,'SASH  start_collecting_jobs errored ');		 
	 end;

procedure add_db(v_host varchar2, v_port number, v_sash_pass varchar2, v_db_name varchar2, v_sid varchar2, v_inst_num number, v_version varchar2 default '', v_cpu_count number default 0) is
v_dblink varchar2(30);
v_dblink_target varchar2(4000);
no_db_link EXCEPTION;
PRAGMA EXCEPTION_INIT(no_db_link, -2024);
v_dbid number;
v_check number;

begin
	v_dblink_target:='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST =' || v_host || ')(PORT = ' || v_port || ')))(CONNECT_DATA = (SID = ' || v_sid || ')))';
	v_dblink := v_db_name || v_inst_num;
    begin
		execute immediate 'drop database link ' || v_dblink;
		dbms_output.put_line('Link dropped');
	exception when no_db_link then
			log_message('add_db', 'no db link - moving forward ' || v_dblink  ,'W');
	end;
	execute immediate 'create database link ' || v_dblink || ' connect to sash identified by ' || v_sash_pass || ' using ''' || v_dblink_target || '''';
	execute immediate 'select dbid from v$database@' || v_dblink into v_dbid;
	select count(*) into v_check from sash_targets where dbid = v_dbid and inst_num = v_inst_num;
	if v_check = 0 then 
		insert into sash_targets (dbid, host, port, dbname, sid, inst_num, db_link, version, cpu_count) values (v_dbid, v_host, v_port, v_db_name, v_sid, v_inst_num, v_dblink, v_version, v_cpu_count);
	else 
			log_message('add_db', 'Database ' || v_db_name || ' instance ' || v_inst_num || ' already added','W');	
	end if;
end;

end sash_repo;
/
show err 

