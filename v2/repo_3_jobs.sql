
-- (c) Kyle Hailey 2007

column job format 99999
column log_user format a8
column priv_user format a8
column schema_user format a8
column last format a8
column b format a1
column fail format 999
column what format a70

set serveroutput on
exec dbms_output.enable(1000000);

   begin
     for i in  ( select job from user_jobs
                where what like '%sash%'
                ) loop
        dbms_output.put_line( 'rdbms_job.remove ' || i.job );
        dbms_job.remove( i.job );
     end loop;
   end;
/

--------------------------------------------------------------------
-- Partition management job
--------------------------------------------------------------------

var job number;

begin
  sys.dbms_job.submit
    ( job       => :job
     ,what      => 'sash_repo.purge(''h'');'
     ,next_date => trunc(SYSDATE+1/24,'HH')
     ,interval  => 'trunc(SYSDATE+1/24,''HH'')'
     ,no_parse  => TRUE
    );
end;
/
-- purge every ...
-- minute
     --,next_date => trunc(sysdate, 'HH24' )+(to_number(to_char(sysdate, 'MI' ))+1)/(24*60)
     --,interval => 'trunc(sysdate,''HH24'')+(to_number(to_char(sysdate,''MI''))+1)/(24*60)' 
-- hour
     --,next_date => trunc(SYSDATE+1/24,'HH')
     --,interval  => 'trunc(SYSDATE+1/24,''HH'')'
-- day
     --,next_date => trunc(sysdate)
     --,interval  => 'trunc(sysdate)+1'
-- need the commit to actually submit the job
   commit;


select job, log_user,priv_user, schema_user, last_sec,
       this_sec,next_sec, broken b, failures fail, total_time, what
from user_jobs
where what like '%sash%'
/

