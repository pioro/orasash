---------------------------------------------------------------------------------------------------
-- File Revision $Rev: 40 $
-- Last change $Date: 2011-08-27 22:19:21 +0100 (Sat, 27 Aug 2011) $
-- SVN URL $HeadURL: https://orasash.svn.sourceforge.net/svnroot/orasash/v2.3/repo_0_user.sql $
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: add password and tablespace prompt, add new privileges to sash user on repository
-- v2.2 Changes: add schema owner as a variable, display more information
 
 set ver off

-- prompt Are you connected as the SYS user? 
-- accept toto prompt "If you are not the SYS user hit Control-C , else Return : "

accept SASH_USER default sash prompt "Enter user name (schema owner) [or enter to accept username sash] ? " 
accept SASH_PASS default sash prompt "Enter user password ? "
accept SASH_TS default users prompt "Enter SASH user default tablespace [or enter to accept USERS tablespace] ? "
prompt SASH default tablespace is: &SASH_TS

prompt "------------------------------------------------------------------------------------"
prompt Existing &SASH_USER user will be deleted.
accept toto prompt "If you are not sure hit Control-C , else Return : "
prompt "------------------------------------------------------------------------------------"

drop user &SASH_USER cascade;

prompt New &SASH_USER user will be created.

WHENEVER SQLERROR EXIT 
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
