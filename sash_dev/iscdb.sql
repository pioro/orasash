set linesize 200 
set pagesize 999
SET HEAD OFF
SET VER OFF
set feedback off
set echo off
set term off
set serveroutput on
spool includecdb.sql
declare
  a varchar2(10);
begin
  $IF DBMS_DB_VERSION.VER_LE_11 $THEN
     null;
  $ELSE
     select cdb into a from v$database;
     if a = 'YES' then
        dbms_output.put_line('@cdb.sql');
     end if;  
  $END
end;
/
spool off
set term on
set define on
@includecdb.sql 
