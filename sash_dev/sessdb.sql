set linesize 200
set pagesize 999
SET VER OFF
set feedback off

col current_db format a10
select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+)
and s.inst_num = t.inst_num(+) order by dbid, inst_num;

prompt 
accept DBID prompt "Switch to database with DBID "

prompt 
accept INST_NUM prompt "Switch to instance with INST_NUM "

begin
 delete from sash_target_dynamic;
 insert into sash_target_dynamic(dbid, inst_num) values ('&DBID', '&INST_NUM');

exception when others then
 RAISE_APPLICATION_ERROR(-20050,'Somethings went wrong. Target database didn''t change. Error - ' || SQLERRM);
end;
/

select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) 
and s.inst_num = t.inst_num(+) order by dbid, inst_num;
