#!/bin/bash

INSTALLED_DIR="/opt/oracle/oradata/sash"
INSTALLED_FILE="$INSTALLED_DIR/.orasash"

# check if environment variable is set
if [ -z "${SASH_PWD}" ]; then
  echo "SASH_PWD environment variable not set. Exiting..."
  exit 1
fi

# check if folder and the file exists
if [ ! -d $INSTALLED_DIR ]; then
    echo "Directory $INSTALLED_DIR does not exist. Creating it now."
    mkdir -p $INSTALLED_DIR
fi

if [ -f $INSTALLED_FILE ]; then
  echo "Oracle SASH is already installed."
  sqlplus / as sysdba << EOF
    alter session set container = sash;
    alter user sash identified by $SASH_PWD;
    exit;
EOF
  exit 0
fi

echo "installing sash"

cat << EOF >> /opt/oracle/oradata/dbconfig/FREE/tnsnames.ora
SASH =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = SASH)
    )
  )
EOF

sqlplus / as sysdba << EOF

prompt "------------------------------------------------------------------------------------"
prompt  Switching to nonarchive log
prompt "------------------------------------------------------------------------------------"
shutdown immediate 
startup mount
alter database noarchivelog;
alter database open;

create pluggable database sash admin user PDBADMIN identified by oracle FILE_NAME_CONVERT = ('pdbseed','sash');

alter pluggable database sash open;

alter pluggable database sash save state;

-- alter pluggable database FREEPDB1 close immediate;

-- drop pluggable database FREEPDB1 including datafiles;

alter session set container = sash;

prompt "------------------------------------------------------------------------------------"
prompt  Creating repository owner and job kill function using SYS user                     
prompt "------------------------------------------------------------------------------------"

define SASH_USER = "SASH";
define SASH_PASS = $SASH_PWD;
define SASH_TS = "USERS";

spool $INSTALLED_DIR/sys_objects.log
drop user &SASH_USER cascade;

prompt New &SASH_USER user will be created.

WHENEVER SQLERROR EXIT 

create tablespace &SASH_TS datafile '/opt/oracle/oradata/FREE/sash/&SASH_TS..dbf' size 100M autoextend on 
next 100M maxsize unlimited;

create user &SASH_USER identified by &SASH_PASS default tablespace &SASH_TS;

alter user &SASH_USER quota unlimited on &SASH_TS;

grant connect, resource to &SASH_USER;

grant ANALYZE ANY  to &SASH_USER;
grant CREATE TABLE         to &SASH_USER;
grant ALTER SESSION               to &SASH_USER;
grant CREATE SEQUENCE            to &SASH_USER;
grant CREATE DATABASE LINK      to &SASH_USER;
grant UNLIMITED TABLESPACE     to &SASH_USER;
grant CREATE PUBLIC DATABASE LINK to &SASH_USER;
grant create view to &SASH_USER;
grant create public synonym to &SASH_USER;
grant execute on dbms_lock to &SASH_USER;
grant Create job to  &SASH_USER;
grant manage scheduler to  &SASH_USER;
@/opt/oracle/sash/repo_sys_procedure.sql


connect &SASH_USER/&SASH_PASS@SASH
WHENEVER SQLERROR EXIT 1

set term on
prompt "------------------------------------------------------------------------------------"
prompt  Installing SASH objects into &SASH_USER schema                                     
prompt "------------------------------------------------------------------------------------"
set term off

@/opt/oracle/sash/repo_helpers.sql
@/opt/oracle/sash/repo_schema.sql
@/opt/oracle/sash/repo_triggers.sql
@/opt/oracle/sash/repo_views.sql
@/opt/oracle/sash/sash_repo.sql
@/opt/oracle/sash/sash_pkg.sql
@/opt/oracle/sash/sash_xplan.sql
@/opt/oracle/sash/sash_awr_views.sql
set term on

prompt "------------------------------------------------------------------------------------"
prompt  Instalation completed.                          
prompt "------------------------------------------------------------------------------------"


spool off

EOF

# check retrun code of sqlplus
if [ $? -ne 0 ]; then
  echo "Error while installing SASH. Please check the logs."
  exit 1
fi

touch $INSTALLED_FILE