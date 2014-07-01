set linesize 200
set pagesize 999
SET VER OFF
set feedback off

var output varchar2(2000)

begin
  :output:='';
end;
/


col current_db format a10
select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+)
and s.inst_num = t.inst_num(+) order by dbid, inst_num;

prompt 
accept DBID prompt "Switch to database with DBID "

prompt 
accept INST_NUM prompt "Switch to instance with INST_NUM "

declare 
i number;
begin

 select count(*) into i from sash_targets where  dbid = '&DBID' and inst_num = &INST_NUM ;
 if (i > 0) then
 	update sash_target_static set dbid = '&DBID', inst_num = &INST_NUM;
        :output := 'Database switched.';
	commit;
 else
        :output := 'Database DBID ' ||   '&DBID' || ' and instance nuber ' || &INST_NUM || ' not found as a target';
 end if;

exception when others then
 RAISE_APPLICATION_ERROR(-20050,'Somethings went wrong. Target database didn''t change. Error - ' || SQLERRM);
end;
/

set head off
select :output as result from dual;
set head on

select s.dbname, s.dbid, s.host, s.inst_num, case when t.dbid is null then ' ' else '*' end current_db from sash_targets s, sash_target t where s.dbid = t.dbid(+) 
and s.inst_num = t.inst_num(+) order by dbid, inst_num;
