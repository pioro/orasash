
-- (c) Kyle Hailey 2007




exec sash_pkg.set_dbid;
exec sash_pkg.get_event_names;
exec sash_pkg.get_users;
exec sash_pkg.get_params;

update  sash_event_names@SASHREPO sen 
   set sen.wait_class = ( select wg.wait_class from
       waitgroups@SASHREPO wg where wg.name=sen.name);

column job format 99999
column log_user format a8
column priv_user format a8
column schema_user format a8
column last format a8
column b format a1
column fail format 999
column what format a70


  -- 
  --  REMOVE OLD JOBS
  --

   begin
     for i in  ( select job from dba_jobs
             where substr(what,1,16)='sash_pkg.collect'
               or
                   substr(what,1,16)='sash_pkg.get_all'
             ) loop
        dbms_output.put_line( 'rdbms_job.remove ' || i.job );
        dbms_job.remove( i.job );
     end loop;
   end;
/

-- 
--  START JOBS
--
   variable job number
   begin
         dbms_job.submit( job       => :job
                        ,what      => 'sash_pkg.collect(1,3600);'
                        --,what      => 'sash_pkg.collect(3,1200);'
                        ,next_date => sysdate
                        ,interval => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
   end;
/
   begin
        dbms_job.submit(job        => :job
                        ,what      => 'sash_pkg.get_all;'
                        ,next_date => sysdate
                        ,interval  => 'trunc(sysdate+(1/(24)),''HH'')'
                        );
   end;
/
   commit;

--
-- OUTPOUT 
--

select job, log_user,priv_user, schema_user, last_sec,
       this_sec,next_sec, broken b, failures fail, total_time, what
   from dba_jobs
   where substr(what,1,16)='sash_pkg.collect'
           or
         substr(what,1,16)='sash_pkg.get_all'
/

