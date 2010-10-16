SET MARKUP HTML OFF
declare 
cursor c is with sql_list as (
select sql_id from (
select sql_id, "Total" from (
select sql_id, max(r) "Total"  from (
select sql_id, 
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
where rownum < 10
)
select sq.sql_id, substr(event,1,60) event, wt, "Total" from (
select sql_id, event, wt, "Total" from (
select sql_id, event, max(wt) wt, max(r) "Total"  from (
select sql_id, event, wt,
sum(wt) over (partition by sql_id) r
from (
select sql_id, event, count(*) wt 
from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI')--(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'WAITING'
group by sql_id, event
union
select sql_id, 'ON CPU', count(*) wt  from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI') --(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI') --(sysdate - 1/24/60)
and session_state = 'ON CPU'
group by  sql_id
) where sql_id <> '0'
order by sum(wt) over (partition by sql_id) desc
) 
group by sql_id, event
) 
) sq, sql_list sq2
where sq.sql_id = sq2.sql_id
order by "Total" desc, sql_id, wt desc;
v_sqlid varchar2(30);

begin
v_sqlid:=0;
dbms_output.put_line('<TABLE id="tabbed" border="1" width="90%" align="center"><TR><th scope="col">SQL_ID</th><th scope="col">Event</th><th scope="col">% Event</th>');
for rec in c loop
    --dbms_output.put_line('SQL ID v ' || v_sqlid || ' ' || rec.sql_id );
	if (v_sqlid <> rec.sql_id) then
		dbms_output.put_line('</TR><TR><TD class="sqlid"><A NAME="' || rec.sql_id || '"></A>');	
		dbms_output.put_line('SQL ID ' || rec.sql_id );
		dbms_output.put_line('</TD>');			
		v_sqlid := rec.sql_id;
	else 
		dbms_output.put_line('<TR><TD class="sqlid"></TD>');			
	end if;
	dbms_output.put_line('<TD>' || rec.event || '</TD><TD>' || trunc(rec.wt/&DSAMPLESIZE*100,2) || '</TD></TR>');
end loop;
dbms_output.put_line('</TABLE>');
end;
/