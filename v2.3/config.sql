
SET HEAD OFF
SET VER OFF

accept DBNAME prompt "Enter database name " 

accept INST_NUM default 1 prompt "Enter number of instances [default 1]"

SET TERMOUT OFF

spool instance.sql
select 'accept HOST' || rownum || ' prompt "Enter hostname for instance number ' || rownum || ' "' from all_objects where rownum <= &INST_NUM;
spool off

SET TERMOUT ON

@instance.sql

accept PORT default 1521 prompt "Enter listener port number [default 1521] "
accept SASHPASS prompt "Enter SASH password on target database "

set term off
spool setup.sql
select 'exec sash_repo.add_db(''&' || 'HOST' || rownum || ''', ' || &PORT || ', ''&SASHPASS'', ''&DBNAME'', ''&DBNAME' || rownum || ''',' || rownum || ', ''11.2.0.2'', 8);' from all_objects where rownum <= &INST_NUM;
select 'exec sash_pkg.configure_db(''&DBNAME' || 1 || ''');' from dual;
select 'exec sash_pkg.set_dbid(''&DBNAME' || 1 || ''');' from dual;
select 'exec sash_repo.setup_jobs' from dual;
select 'exec sash_repo.start_collecting_jobs' from dual;
select 'exec sash_repo.purge' from dual;
spool off
set term on

@setup.sql

