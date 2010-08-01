
-- (c) Kyle Hailey 2007


 -- connect / as sysdba
 --  create tablespace perfstat datafile '&1perfstat.dbf' size 100M;

 drop user sash cascade;
 create user sash identified by sash
     default tablespace perfstat
     temporary tablespace temp;

 alter user sash quota unlimited on perfstat;

 grant connect, resource to sash;

 grant ANALYZE ANY  to sash;
 grant CREATE TABLE         to sash;
 grant ALTER SESSION               to sash;
 grant CREATE SEQUENCE            to sash;
 grant CREATE DATABASE LINK      to sash;
 grant UNLIMITED TABLESPACE     to sash;
 grant CREATE PUBLIC DATABASE LINK to sash;
 grant create view to sash;

