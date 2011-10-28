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



drop view sashnow;

create view sys.sashnow as
   select d.dbid,
          sysdate sample_time,
          s.indx "session_id",
          decode (w.ksusstim, 0, 'waiting', 'on cpu') "session_state",
          s.ksuseser "session_serial#",
          s.ksuudlui "user_id",
          s.ksusesql "sql_address",
          s.ksusepha "sql_plan_hash_value",
          -1 "sql_child_number",
          s.ksusesqh "sql_id",
          s.ksuudoct "sql_opcode"                         /* aka sql_opcode */ ,
          s.ksuseflg "session_type",
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
          s.ksusepnm "program",
          s.ksuseaph "module_hash",                  /* ash collects string */
          s.ksuseach "action_hash",                  /* ash collects string */
          s.ksusefix "fixed_table_sequence"         /* fixed_table_sequence */
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

 prompt "sash user will be created and used only by repository connection via db link"
 prompt "sash privileges are limited to create session and select on system objects listed in script" 
 accept sash_pass default sash prompt "enter sash password ? "
 accept sash_ts default users prompt "enter sash default tablespace [or enter to accept users tablespace] ? "
 prompt "sash default tablespace is: " &sash_ts
								 

create user sash identified by &sash_pass default tablespace &sash_ts temporary tablespace temp;

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
