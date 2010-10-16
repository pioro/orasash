set linesize 200
column tevent format a30
column "Event class"  format a30
column "Avg Active Session"  format 99.99
column "Event %"  format 999.99

set termout off
column f_st new_value dstarttime
select to_char(sysdate-1/24,'DD/MM/YYYY HH24:MI') f_st from dual;
column f_st1 new_value dstoptime
select to_char(sysdate,'DD/MM/YYYY HH24:MI') f_st1 from dual;
column v_samplesize new_value dsamplesize
column v_elapsed_time new_value delapsed_time
select count(*) v_samplesize from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI:SS')
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI:SS');
select (to_date('&stoptime','DD/MM/YYYY HH24:MI') - to_date('&starttime','DD/MM/YYYY HH24:MI'))*24*60*60 v_elapsed_time from dual;
set termout on
set ver off

accept starttime date default "&DSTARTTIME" for 'DD/MM/YYYY HH24:MI' prompt 'start date DD/MM/YYYY HH24:MI (default sysdate-1/24): '
accept stoptime date default "&DSTOPTIME" for 'DD/MM/YYYY HH24:MI' prompt 'stop date DD/MM/YYYY HH24:MI (default sysdate): '

prompt 
prompt Start time is :  &starttime
prompt Stop  time is :  &stoptime

define SESS_TYPE='FOREGROUND'
@top_user_events_body.sql