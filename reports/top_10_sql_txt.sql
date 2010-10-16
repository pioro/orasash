---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Marcin Przepiorowski 2010
-- v2.2 Top 10 SQL query 

SET MARKUP HTML OFF
declare 
temp varchar2(100);
ret clob;
v_sqlid varchar2(30);
cursor c_sql_text(c_sql_id varchar2) is select sql_text from v$sqltext where sql_id = c_sql_id order by piece;
cursor c is select sql_id from (
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
where rownum < 10;

begin
v_sqlid:=0;
dbms_output.put_line('<TABLE border="1" width="90%" align="center"><TR><th scope="col">SQL_ID</th><th scope="col">SQL text</th>');
for rec in c loop
    --dbms_output.put_line('SQL ID v ' || v_sqlid || ' ' || rec.sql_id );
	--if (v_sqlid <> rec.sql_id) then
		dbms_output.put_line('</TR><TR><TD class="sqlid"><A NAME="' || rec.sql_id || '"></A>');	
		dbms_output.put_line(rec.sql_id );
		dbms_output.put_line('</TD>');			
		v_sqlid := rec.sql_id;
--	else 
--		dbms_output.put_line('<TR><TD class="sqlid"></TD>');			
--	end if;
	ret:='';
	dbms_output.put_line('<TD>');				
	for rec in c_sql_text(v_sqlid) loop
		temp := rec.sql_text;
		dbms_output.put_line(temp);
	end loop;
	dbms_output.put_line('</TD>');					
end loop;
dbms_output.put_line('</TABLE>');
end;
/