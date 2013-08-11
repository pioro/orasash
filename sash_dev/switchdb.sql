set linesize 200
set pagesize 999
SET VER OFF
set feedback off

col current_db format a10
select s.dbname, s.dbid, s.host, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) order by dbid;

prompt 
accept DBID prompt "Switch to database with DBID "

begin
 update sash_target set dbid = '&DBID';
 commit;


exception when others then
 RAISE_APPLICATION_ERROR(-20050,'Somethings went wrong. Target database didn''t change. Error - ' || SQLERRM);
end;
/

select s.dbname, s.dbid, s.host, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) order by dbid;
