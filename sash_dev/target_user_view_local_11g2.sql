-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.0 Part of other file
-- v2.1 - Separated into new file to simplify installation process
--      - New access user and privileges added
-- v2.3 - new fields added - 11g2
--      - checking if SYS user is used to execute 
--      - script clean up
-- v2.4 - new privileges added


set ver off
set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('SYS');
spool off
@exit.sql
set term on

prompt "SASH user will be created and used only by repository connection via db link"
prompt "SASH privileges are limited to create session and select on system objects listed in script" 
accept SASH_PASS default sash prompt "Enter SASH password ? "
accept SASH_TS default users prompt "Enter SASH default tablespace [or enter to accept USERS tablespace] ? "
prompt "SASH default tablespace is: " &SASH_TS
							 

create user sash identified by &SASH_PASS default tablespace &SASH_TS temporary tablespace temp;
-- sash user grants 
grant create session to sash;				 
grant select on v_$database to sash;
grant select on dba_users to sash;
grant select on v_$sql to sash;
grant select on v_$parameter to sash;
grant select on dba_data_files to sash;
grant select on v_$instance to sash;
grant select on dba_objects to sash;
grant select on v_$sql_plan to sash;
grant select on DBA_LIBRARIES to sash;
grant select on v_$event_name to sash;
grant select on v_$sql_plan to sash;
grant select on v_$sqltext to sash;
grant select on v_$latch to sash;
grant select on dba_extents to sash;
grant select on v_$sysstat to sash;
grant select on v_$system_event to sash;
grant select on v_$sysmetric_history to sash;
grant select on v_$iostat_function to sash;
grant select on v_$sqlstats to sash;
grant select on v_$event_histogram to sash;
grant select on v_$sys_time_model to sash;
grant select on v_$osstat to sash;

 

prompt "SASHNOW view will be created in SYS schema. This view will be accesed by repository database via DB link using user sash"
create or replace view sashnow as 
select
    d.dbid,
    sysdate sample_time,
    s.indx          "SESSION_ID",
	decode(s.ksusetim, 0,'WAITING','ON CPU') "SESSION_STATE",
    s.ksuseser      "SESSION_SERIAL#",
    s.ksuseunm      "OSUSER",
	s.ksuseflg      "SESSION_TYPE"  ,
    s.ksuudlui      "USER_ID",
	s.ksuudoct      "COMMAND",	
    s.ksusemnm      "MACHINE",                
    s.ksusemnp      "PORT",	
    s.ksusesql      "SQL_ADDRESS",
    s.ksusesph      "SQL_PLAN_HASH_VALUE",
    decode(s.ksusesch, 65535, to_number(null), s.ksusesch) "SQL_CHILD_NUMBER",
    s.ksusesqi      "SQL_ID" ,    /* real SQL ID starting 10g */ 
    s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
    s.ksusesesta    "SQL_EXEC_START",
    decode(s.ksuseseid, 0, to_number(null), s.ksuseseid)                                                                  "SQL_EXEC_ID",
    decode(s.ksusepeo,0,to_number(null),s.ksusepeo)                                                                       "PLSQL_ENTRY_OBJECT_ID",
    decode(s.ksusepeo,0,to_number(null),s.ksusepes)                                                                       "PLSQL_ENTRY_SUBPROGRAM_ID",
    decode(s.ksusepco,0,to_number(null),decode(bitand(s.ksusstmbv, power(2,11)), power(2,11),s.ksusepco,to_number(null))) "PLSQL_OBJECT_ID",
    decode(s.ksusepcs,0,to_number(null),decode(bitand(s.ksusstmbv, power(2,11)), power(2,11),s.ksusepcs,to_number(null))) "PLSQL_SUBPROGRAM_ID",
    s.ksuseopc      "EVENT#",
    s.ksuseseq      "SEQ#"        /* xksuse.ksuseseq */,
    s.ksusep1       "P1"          /* xksuse.ksusep1  */,
    s.ksusep2       "P2"          /* xksuse.ksusep2  */,
    s.ksusep3       "P3"          /* xksuse.ksusep3  */,
    s.ksusetim      "WAIT_TIME"   /* xksuse.ksusetim */,
    s.ksusewtm      "TIME_WAITED" /* xksuse.ksusewtm */,
    s.ksuseobj      "CURRENT_OBJ#",
    s.ksusefil      "CURRENT_FILE#",
    s.ksuseblk      "CURRENT_BLOCK#",
    s.ksuseslt      "CURRENT_ROW#",
    s.ksusepnm      "PROGRAM",
    s.ksuseapp      "MODULE",
    s.ksuseaph      "MODULE_HASH", 
    s.ksuseact      "ACTION",
    s.ksuseach      "ACTION_HASH",  
    s.ksuseltm      "LOGON_TIME",
    s.ksuseblocker,
    s.ksusesvc      "SERVICE_NAME",
    s.ksusefix      "FIXED_TABLE_SEQUENCE", /* FIXED_TABLE_SEQUENCE */
    s.KSUSEQCSID    "QC"
from
    x$ksuse s , /* v$session */
    v$database d
where
    s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
    s.ksuudlui <> 69 and
    bitand(s.ksspaflg,1)!=0 and
    bitand(s.ksuseflg,1)!=0 and
    (  (
        /* status Active - seems inactive & "on cpu"=> not on CPU */
        s.ksusetim != 0  and  /* on CPU  */
        bitand(s.ksuseidl,11)=1  /* ACTIVE */
    )
            or
    s.ksuseopc not in   /* waiting and the wait event is not idle */
        (  select event# from v$event_name where wait_class='Idle' )
    );
		
grant select on sys.sashnow to sash;

exit;	
