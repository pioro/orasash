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
		  PROCEDURE setup_jobs;
		  PROCEDURE stop_collecting_jobs;
		  PROCEDURE start_collecting_jobs;
		  procedure create_repository_jobs;
          procedure stop_and_remove_rep_jobs;
		  PROCEDURE set_retention(rtype varchar2);
          END sash_repo;
/
show errors


CREATE OR REPLACE PACKAGE BODY sash_repo AS
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
             insert into sash_log (action, message,result) values 
                  ('PURGE PARTITION', l_text || ' rtype value ' || rtype,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20010,'SASH purge errored ');
  end purge;

  procedure set_retention(rtype varchar2) is 
  begin
      update sash_configuration set value = rtype where param='SASH RETENTION';
	  commit;
      exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('SET_RETENTION', 'update value ' || rtype ,'E');
             commit;
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
         insert into sash_log (action, message,result) values ('create_repository_jobs','Repository job exist - remove first', 'I');
         commit;
         RAISE_APPLICATION_ERROR(-20130,'SASH create_repository_jobs - Repository job exist - remove first');
       end if;
    exception
          when others then
             insert into sash_log (action, message,result) values
                  ('create_repository_jobs', '' ,'E');
             commit;
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
        insert into sash_log (action, message,result) values ('stop_and_remove_repository_jobs','stopping job ' || i.job, 'I');
     end loop;
     commit;
    exception
          when others then
             insert into sash_log (action, message,result) values
                  ('stop_and_remove_repository_jobs', '' ,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20060,'SASH  stop_and_remove_repository_jobs errored ');
  end;
  
  procedure remove_collection_jobs is
  begin
    for i in  ( select job from user_jobs
                where what like '%sash%'
                ) loop
        dbms_output.put_line( 'dbms_job.remove ' || i.job );
        dbms_job.remove( i.job );
     end loop;
	 commit;
     exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('remove_collection_jobs', '' ,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20040,'SASH  remove_collection_jobs errored ');
   end;  

  procedure create_collection_jobs is
  vjob number; 
  begin
    dbms_job.submit( job       => vjob
                        ,what      => 'sash_pkg.collect(1,3600);'
                        ,next_date => sysdate
                        ,interval => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
    dbms_job.submit(job        => vjob
                        ,what      => 'sash_pkg.get_all;'
                        ,next_date => sysdate
                        ,interval  => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
    commit;
    exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('create_collection_jobs', '' ,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20050,'SASH  create_collection_jobs errored ');	
   end;     
   
   
  procedure setup_jobs is
  begin
	remove_collection_jobs;
	create_collection_jobs;
	create_repository_jobs;
  end;
  
  procedure stop_collecting_jobs is
  begin
      for i in  ( select job from user_jobs
                where what like '%sash_pkg%'
                ) loop
        dbms_output.put_line( 'dbms_job.broken ' || i.job );
        dbms_job.broken( i.job , true);
		insert into sash_log (action, message,result) values ('stop_collecting_jobs','stopping job ' || i.job, 'I');		
     end loop;
	 commit;
	 sys.kill_sash_session;
    exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('stop_collecting_jobs', '' ,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20060,'SASH  stop_collecting_jobs errored ');		 
  end;
  
  procedure start_collecting_jobs is
  begin
      for i in  ( select job from user_jobs
                where what like '%sash_pkg%'
                ) loop
        --dbms_output.put_line( 'dbms_job.broken ' || i.job );
        dbms_job.broken( i.job , false);
		insert into sash_log (action, message,result) values ('start_collecting_jobs','starting job ' || i.job, 'I');
     end loop;
	 commit;
     exception
          when others then
             insert into sash_log (action, message,result) values 
                  ('start_collecting_jobs', '' ,'E');
             commit;
             RAISE_APPLICATION_ERROR(-20070,'SASH  start_collecting_jobs errored ');		 
	 end;
  
  
end sash_repo;
/
show err 

