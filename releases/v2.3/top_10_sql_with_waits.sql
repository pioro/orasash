set linesize 200
column SQL_ID format 9999999999999
column CPU  format 99999
column "User I/O"  format 99999
column "System I/O"  format 99999
column Administration format 99999
column Other  format 99999
column Configuration  format 99999
column Application  format 99999
column Concurrency  format 99999  
column Network  format 99999     
column Total  format 99999

set termout off
column f_st new_value dstarttime
select to_char(sysdate-1/24,'DD/MM/YYYY HH24:MI') f_st from dual;
column f_st1 new_value dstoptime
select to_char(sysdate,'DD/MM/YYYY HH24:MI') f_st1 from dual;

set termout on
set ver off

accept starttime date default "&DSTARTTIME" for 'DD/MM/YYYY HH24:MI' prompt 'start date DD/MM/YYYY HH24:MI (default sysdate-1/24): '
accept stoptime date default "&DSTOPTIME" for 'DD/MM/YYYY HH24:MI' prompt 'stop date DD/MM/YYYY HH24:MI (default sysdate): '

prompt 
prompt Start time is :  &starttime
prompt Stop  time is :  &stoptime

select * from (
select * from (
select sql_id, max(oncpu) "CPU" , max(userio) "User I/O", max(systemio) "System I/O", max(adm) "Administration", max(other) "Other" , max(conf) "Configuration" , max(app) "Application", max(conc) "Concurrency", max(net) "Network" , max(r) "Total"  from (
select sql_id, 
decode(wait_class, 'ON CPU', wt, NULL) oncpu,
decode(wait_class, 'User I/O', wt, NULL) userio,
decode(wait_class, 'System I/O', wt, NULL) systemio,
decode(wait_class, 'Administrative', wt, NULL) adm,
decode(wait_class, 'Other', wt, NULL) other,
decode(wait_class, 'Configuration', wt, NULL) conf,
decode(wait_class, 'Application', wt, NULL) app,
decode(wait_class, 'Concurrency', wt, NULL) conc,
decode(wait_class, 'Network', wt, NULL) net,
sum(wt) over (partition by sql_id) r
from (
select sql_id, wait_class, count(*) wt 
from sash.v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI')--(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'WAITING'
group by sql_id, wait_class
union
select sql_id, 'ON CPU', count(*) wt  from sash.v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI') --(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'ON CPU'
group by  sql_id
) where sql_id is not null  
order by sum(wt) over (partition by sql_id) desc
) 
group by sql_id
)
order by "Total" desc
)
where rownum < 10;
