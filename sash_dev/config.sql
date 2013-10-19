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

undef ENTER_SASH_TNS
col sash_tns noprint new_value SASH_TNS
accept ENTER_SASH_TNS prompt "Enter TNS alias to connect to database - required for 12c plugable DB [leave it empty to use SID]?"
select case when nvl('&&ENTER_SASH_TNS','x') = 'x' then '' else '@' || nvl('&&ENTER_SASH_TNS','') end  sash_tns from dual;

connect &SASH_USER/&SASH_PASS&SASH_TNS
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

@repo_helpers.sql
@repo_schema.sql
@repo_triggers.sql
@repo_views.sql
@sash_repo.sql
@sash_pkg.sql
@sash_xplan.sql
@sash_awr_views.sql
set term on

prompt "------------------------------------------------------------------------------------"
prompt  Instalation completed. Starting SASH configuration process                         
prompt  Press Control-C if you do not want to configure target database at that time.
prompt "------------------------------------------------------------------------------------"

@adddb.sql

exit 
