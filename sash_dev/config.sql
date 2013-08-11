set linesize 200
set pagesize 999
SET HEAD OFF
SET VER OFF
set feedback off

spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('SYS');
spool off
@exit.sql

prompt "------------------------------------------------------------------------------------"
prompt  Creating repository owner and job kill function using SYS user                     
prompt "------------------------------------------------------------------------------------"

spool sys_objects.log
@repo_user.sql
@repo_sys_procedure.sql
spool off

WHENEVER SQLERROR CONTINUE NONE 

connect &SASH_USER/&SASH_PASS
set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('&SASH_USER');
spool off
@exit.sql

set term on
prompt "------------------------------------------------------------------------------------"
prompt  Installing SASH objects into &SASH_USER schema                                     
prompt "------------------------------------------------------------------------------------"
set term off

@repo_schema.sql
@sash_repo.sql
@sash_pkg.sql
@sash_xplan.sql
set term on

prompt "------------------------------------------------------------------------------------"
prompt  Instalation completed. Starting SASH configuration process                         
prompt  Press Control-C if you do not want to configure target database at that time.
prompt "------------------------------------------------------------------------------------"

@adddb.sql

exit 
