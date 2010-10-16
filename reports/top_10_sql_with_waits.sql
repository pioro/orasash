---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Marcin Przepiorowski 2010
-- v2.2 Top 10 SQL query 

set linesize 200
column SQL_ID format 9999999999999 ENTMAP OFF
column CPU  format 999.99
column "User I/O"  format 999.99
column "System I/O"  format 999.99
column Administration format 999.99
column Other  format 999.99
column Configuration  format 999.99
column Application  format 999.99
column Concurrency  format 999.99  
column Network  format 999.99     
column "% Event"  format 999.99

select '<A HREF="#' || sql_id || '">' || sql_id || '</A>' SQL_ID, round("CPU"/&dsamplesize*100,2) as "CPU", 
round("User I/O"/&dsamplesize*100,2) as "User I/O", 
round("System I/O"/&dsamplesize*100,2) as "System I/O", 
round("Administration"/&dsamplesize*100,2) as "Administration", 
round("Other"/&dsamplesize*100,2) as "Other", 
round("Configuration"/&dsamplesize*100,2) as "Configuration" , 
round("Application"/&dsamplesize*100,2) as "Application", 
round("Concurrency"/&dsamplesize*100,2) as "Concurrency", 
round("Network"/&dsamplesize*100,2) as "Network" , 
round("Total"/&dsamplesize*100,2) as "% Event"  from (
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
from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI')--(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'WAITING'
group by sql_id, wait_class
union
select sql_id, 'ON CPU', count(*) wt  from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI') --(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'ON CPU'
group by  sql_id
) where sql_id <> '0'
order by sum(wt) over (partition by sql_id) desc
) 
group by sql_id
)
order by "Total" desc
)
where rownum < 10;