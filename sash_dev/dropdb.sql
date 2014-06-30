set linesize 200
set pagesize 999
SET VER OFF
set feedback off
set head on


var output varchar2(2000)
var dblink varchar2(2000)

begin
  :output:='';
end;
/

col current_db format a10
select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+)
and s.inst_num = t.inst_num(+) order by dbid, inst_num;

prompt 
accept DBID prompt "Enter DBID of target database to drop "

prompt 
accept INST_NUM default 1 prompt "Enter INST_NUM of target database to drop [default 1] "


begin
 select db_link into :dblink from sash_targets where dbid = '&DBID' and inst_num = &INST_NUM;
 delete from sash_targets where dbid = '&DBID' and inst_num = &INST_NUM;
 if (sql%rowcount > 0) then
        execute immediate 'drop database link ' || :dblink;
	:output := 'Database dropped. Data will be delete from retention period.';
 else 
        :output := 'Database DBID ' ||   '&DBID' || ' and instance nuber ' || &INST_NUM || ' not found as a target';
 end if;
 commit;

exception when others then
 RAISE_APPLICATION_ERROR(-20051,'Somethings went wrong. Target database didn''t drop. Error - ' || SQLERRM);
end;
/

set head off
select :output as result from dual;
set head on

exec sash_repo.setup_jobs

select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) 
and s.inst_num = t.inst_num(+) order by dbid, inst_num;
