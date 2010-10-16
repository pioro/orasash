create table sash_instance_stats (
dbid number,
sample_time date,
STATISTIC#  NUMBER,
VALUE NUMBER
);


declare
type sash_instance_stats_type is table of sash_instance_stats%rowtype;
session_rec sash_instance_stats_type;
session_rec1 sash_instance_stats_type;
session_rec_delta sash_instance_stats_type := sash_instance_stats_type();
begin
if session_rec_delta.count < 3 then 
	session_rec_delta.extend(3);
end if;
for l in 1..30 loop
select 1, sysdate, statistic#, value bulk collect into session_rec from v$sysstat@sashprod where statistic# in (4,5,6);
dbms_lock.sleep(15);
select 1, sysdate, statistic#, value bulk collect into session_rec1 from v$sysstat@sashprod where statistic# in (4,5,6);
for i in 1..session_rec.count loop
	session_rec_delta(i).value := session_rec1(i).value - session_rec(i).value;
	session_rec_delta(i).sample_time := session_rec1(i).sample_time;
	session_rec_delta(i).statistic# := session_rec1(i).statistic#;
	session_rec_delta(i).dbid := 1;
end loop;
forall i in 1..session_rec_delta.count 
	insert into sash_instance_stats values session_rec_delta(i);
--dbms_output.put_line('Commits ' || session_rec1(2).value ||' ' || session_rec(2).value || ' rate ' || to_number((session_rec1(2).value - session_rec(2).value))/15 );
--dbms_output.put_line('Calls ' || session_rec1(3).value ||' ' || session_rec(3).value || ' rate ' || to_number((session_rec1(3).value - session_rec(3).value))/15 );
commit;
end loop;
end;
/
