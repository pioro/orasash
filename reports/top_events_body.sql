select tevent Event, decode(tevent, 'ON CPU', 'CPU', wc) "Event class", round(ev/&dsamplesize*100,2) "Event %", aas "Avg Active Session"
from (
select decode(session_state, 'WAITING',event,'ON CPU') tevent, min(wait_class) wc, round(count(*)/(&delapsed_time),2) aas, count(*) ev
from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI:SS')--(sysdate - 41/24/60)
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI:SS') --(sysdate - 1/24/60)
--and session_state = 'WAITING'
and session_type='&SESS_TYPE'
group by decode(session_state, 'WAITING',event,'ON CPU')
order by aas desc
) where rownum < 11;
