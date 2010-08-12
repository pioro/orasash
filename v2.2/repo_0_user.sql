
-- (c) Kyle Hailey 2007
-- Changes: add password and tablespace prompt, add new privileges to sash user on repository -- Marcin Przepiorowski 2010


 -- connect / as sysdba
 --  create tablespace perfstat datafile '&1perfstat.dbf' size 100M;

 accept SASH_PASS default sash prompt "Enter SASH password ? "
 accept SASH_TS default users prompt "Enter SASH default tablespace [or enter to accept USERS tablespace] ? "
 prompt "SASH default tablespace is: " &SASH_TS

 
 drop user sash cascade;
 create user sash identified by &SASH_PASS
     default tablespace &SASH_TS
     temporary tablespace temp;

 alter user sash quota unlimited on &SASH_TS;

 grant connect, resource to sash;

 grant ANALYZE ANY  to sash;
 grant CREATE TABLE         to sash;
 grant ALTER SESSION               to sash;
 grant CREATE SEQUENCE            to sash;
 grant CREATE DATABASE LINK      to sash;
 grant UNLIMITED TABLESPACE     to sash;
 grant CREATE PUBLIC DATABASE LINK to sash;
 grant create view to sash;
 grant execute on dbms_lock to sash;
