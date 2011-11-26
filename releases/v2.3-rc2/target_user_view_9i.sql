---------------------------------------------------------------------------------------------------
-- File Revision $Rev: 37 $
-- Last change $Date: 2011-05-14 17:45:41 +0100 (Sat, 14 May 2011) $
-- SVN URL $HeadURL: https://orasash.svn.sourceforge.net/svnroot/orasash/v2.3/targ_1_userview_9i.sql $
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.0 Part of other file
-- v2.1 - Separated into new file to simplify installation process
--      - New access user and privileges added
-- v2.3 - new fields added - 11g2
--      - checking if SYS user is used to execute 
--      - script clean up


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
grant select on sys.sashnow to sash;
grant select on v_$database to sash;
grant select on dba_users to sash;
grant select on gv_$sql to sash;
grant select on gv_$parameter to sash;
grant select on dba_data_files to sash;
grant select on v_$instance to sash;
grant select on dba_objects to sash;
grant select on v_$sql_plan to sash;
grant select on dba_libraries to sash;
grant select on gv_$event_name to sash;
grant select on gv_$sql_plan to sash;
grant select on gv_$sqltext to sash;
grant select on v_$latch to sash;
grant select on dba_extents to sash;
grant select on v_$sysstat to sash;






prompt "SASHNOW view will be created in SYS schema. This view will be accesed by repository database via DB link using user sash"
create or replace view sys.sashnow as
   select 
		  d.dbid,
          sysdate sample_time,
          s.indx "session_id",
          decode (w.ksusstim, 0, 'waiting', 'on cpu') "session_state",
          s.ksuseser "session_serial#",
		  s.ksuseflg      "SESSION_TYPE"  ,
          s.ksuudlui "user_id",
		s.ksuudoct      "COMMAND",	
                s.ksusemnm      "MACHINE",                
		  null       "PORT",	
          s.ksusesql "sql_address",
          s.ksusepha "sql_plan_hash_value",
          null "sql_child_number",
          s.ksusesqh "sql_id",
          s.ksuudoct "sql_opcode"                         /* aka sql_opcode */ ,
		  null   "SQL_EXEC_START",
		  null "SQL_EXEC_ID",
		  null "PLSQL_ENTRY_OBJECT_ID",
		  null "PLSQL_ENTRY_SUBPROGRAM_ID",
		  null "PLSQL_OBJECT_ID",
		  null "PLSQL_SUBPROGRAM_ID",
          w.ksussopc "event# ",
          w.ksussseq "seq#"                              /* xksuse.ksuseseq */,
          w.ksussp1 "p1"                                 /* xksuse.ksusep1  */,
          w.ksussp2 "p2"                                 /* xksuse.ksusep2  */,
          w.ksussp3 "p3"                                 /* xksuse.ksusep3  */,
          w.ksusstim "wait_time"                         /* xksuse.ksusetim */,
          w.ksusewtm "time_waited"                       /* xksuse.ksusewtm */,
          s.ksuseobj "current_obj#",
          s.ksusefil "current_file#",
          s.ksuseblk "current_block#",
		  s.ksuseslt      "CURRENT_ROW#",
          s.ksusepnm "program",
		  s.ksuseapp      "MODULE",
          s.ksuseaph "module_hash",                  /* ash collects string */
		  s.ksuseact      "ACTION",
          s.ksuseach "action_hash",                  /* ash collects string */
	      s.ksuseltm      "LOGON_TIME",
		  null "ksuseblocker"
		  s.ksusesvc      "SERVICE_NAME",
          s.ksusefix "fixed_table_sequence",         /* fixed_table_sequence */
          null "QC"
     from x$ksuse s,                                           /* v$session */
          x$ksusecst w,                         /* v$session_wait */
          v$database d
    where     s.indx != (select distinct sid from v$mystat where rownum < 2)
          and bitand (s.ksspaflg, 1) != 0
          and bitand (s.ksuseflg, 1) != 0
          and s.indx = w.indx
          and ( ( /* status active - seems inactive & "on cpu"=> not on cpu */
                 w.ksusstim != 0 and                             /* on cpu  */
                 bitand (s.ksuseidl, 11) = 1   /* active */
                )
               or w.ksussopc not in /* waiting and the wait event is not idle */
                     (select event# from v$event_name where lower (name) in
                                ('queue monitor wait',
                                 'null event',
                                 'pl/sql lock timer',
                                 'px deq: execution msg',
                                 'px deq: table q normal',
                                 'px idle wait',
                                 'sql*net message from client',
                                 'sql*net message from dblink',
                                 'dispatcher timer',
                                 'lock manager wait for remote message',
                                 'pipe get',
                                 'pmon timer',
                                 'queue messages',
                                 'rdbms ipc message',
                                 'slave wait',
                                 'smon timer',
                                 'virtual circuit status',
                                 'wakeup time manager',
                                 'i/o slave wait',
                                 'jobq slave wait',
                                 'queue monitor wait',
                                 'sql*net message from client'
								)
					 )
			 );
