---------------------------------------------------------------------------------------------------
-- File Revision $Rev$
-- Last change $Date$
-- SVN URL $HeadURL$
---------------------------------------------------------------------------------------------------

-- (c) Kyle Hailey 2007
-- (c) Marcin Przepiorowski 2010
-- v2.0 Part of other file
-- v2.1 - Separated into new file to simplify installation process
--      - New access user and privileges added

  drop view sashnow;

  -- prompt "elimates costly v$session_wait join for 10g"
  create view sashnow as 
              Select
                 d.dbid,
                 sysdate sample_time,
                 s.indx          "SESSION_ID",
                 decode(s.ksusetim, 0,'WAITING','ON CPU') "SESSION_STATE",
                 s.ksuseser      "SESSION_SERIAL#",
                 s.ksuudlui      "USER_ID",
                 s.ksusesql      "SQL_ADDRESS",
                 s.ksusesph      "SQL_PLAN_HASH_VALUE",
                 decode(s.ksusesch, 65535, to_number(null), s.ksusesch) "SQL_CHILD_NUMBER",
                 s.ksusesqh      "SQL_ID" ,
                 s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
                 s.ksuseflg      "SESSION_TYPE"  ,
                 s.ksuseopc      "EVENT# ",
                 s.ksuseseq      "SEQ#"        /* xksuse.ksuseseq */,
                 s.ksusep1       "P1"          /* xksuse.ksusep1  */,
                 s.ksusep2       "P2"          /* xksuse.ksusep2  */,
                 s.ksusep3       "P3"          /* xksuse.ksusep3  */,
                 s.ksusetim      "WAIT_TIME"   /* xksuse.ksusetim */,
                 s.ksusewtm      "TIME_WAITED"   /* xksuse.ksusewtm */,
                 s.ksuseobj      "CURRENT_OBJ#",
                 s.ksusefil      "CURRENT_FILE#",
                 s.ksuseblk      "CURRENT_BLOCK#",
                 s.ksusepnm      "PROGRAM",
                 s.ksuseaph      "MODULE_HASH",  /* ASH collects string */
                 s.ksuseach      "ACTION_HASH",   /* ASH collects string */
                 s.ksusefix      "FIXED_TABLE_SEQUENCE" /* FIXED_TABLE_SEQUENCE */
       from
               x$ksuse s , /* v$session */
               v$database d
       where
               s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
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
grant select on DBA_LIBRARIES to sash;
grant select on gv_$event_name to sash;
grant select on gv_$sql_plan to sash;
grant select on gv_$sqltext to sash;
grant select on v_$latch to sash;
grant select on dba_extents to sash;