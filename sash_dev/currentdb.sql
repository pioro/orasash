col current_db format a10

prompt
prompt List of configured databases

select s.dbname, s.dbid, s.sash_dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.sash_dbid = t.dbid(+)
and s.inst_num = t.inst_num(+) order by dbid, inst_num;

prompt 
