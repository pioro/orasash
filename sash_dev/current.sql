col current_db format a10
select s.dbname, s.dbid, s.host, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) order by dbid;

