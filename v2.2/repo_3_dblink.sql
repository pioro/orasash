---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.1 Changes: Database link from repository to target database


accept SASH_PASS default sash prompt "Enter target database SASH password ? "
accept TNSALIAS default sash prompt "Enter target database TNS alias ? "
prompt "Target database tns alias is : " &TNSALIAS

drop database link sashprod;
create database link sashprod connect to sash identified by &SASH_PASS using '&TNSALIAS';

prompt "Check database link - row from dual table is expected"
select * from dual@sashprod;
