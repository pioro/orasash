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
set serveroutput on


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
DECLARE
    l_ver VARCHAR2(10);
BEGIN
    SELECT
        substr(version, 1, 4)
    INTO l_ver
    FROM
        sys.v_$instance;

    CASE
        WHEN substr(l_ver, 1, 2) = '10' THEN
   -- Oracle version 10g
            EXECUTE IMMEDIATE q'[
            CREATE OR REPLACE VIEW sashnow AS
                SELECT
                    d.dbid,
                    sysdate                                            sample_time,
                    s.indx                                             "SESSION_ID",
                    decode(s.ksusetim, 0, 'WAITING', 'ON CPU')         "SESSION_STATE",
                    s.ksuseser                                         "SESSION_SERIAL#",
                    s.ksuseunm                                         "OSUSER",
                    s.ksuseflg                                         "SESSION_TYPE",
                    s.ksuudlui                                         "USER_ID",
                    s.ksuudoct                                         "COMMAND",
                    s.ksusemnm                                         "MACHINE",
                    NULL                                               "PORT",
                    s.ksusesql                                         "SQL_ADDRESS",
                    s.ksusesph                                         "SQL_PLAN_HASH_VALUE",
                    decode(s.ksusesch,
                        65535,
                        TO_NUMBER(NULL),
                        s.ksusesch)                                 "SQL_CHILD_NUMBER",
                    s.ksusesqi                                         "SQL_ID",
                    s.ksuudoct                                         "SQL_OPCODE",
                    NULL                                               "SQL_EXEC_START",
                    NULL                                               "SQL_EXEC_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepeo)                                 "PLSQL_ENTRY_OBJECT_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepes)                                 "PLSQL_ENTRY_SUBPROGRAM_ID",
                    decode(s.ksusepco,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepco)                                 "PLSQL_OBJECT_ID",
                    NULL                                               "PLSQL_SUBPROGRAM_ID",
                    s.ksuseopc                                         "EVENT#",
                    s.ksuseseq                                         "SEQ#",
                    s.ksusep1                                          "P1",
                    s.ksusep2                                          "P2",
                    s.ksusep3                                          "P3",
                    s.ksusetim                                         "WAIT_TIME",
                    s.ksusewtm                                         "TIME_WAITED",
                    s.ksuseobj                                         "CURRENT_OBJ#",
                    s.ksusefil                                         "CURRENT_FILE#",
                    s.ksuseblk                                         "CURRENT_BLOCK#",
                    s.ksuseslt                                         "CURRENT_ROW#",
                    s.ksusepnm                                         "PROGRAM",
                    s.ksuseapp                                         "MODULE",
                    s.ksuseaph                                         "MODULE_HASH",
                    s.ksuseact                                         "ACTION",
                    s.ksuseach                                         "ACTION_HASH",
                    s.ksuseltm                                         "LOGON_TIME",
                    s.ksuseblocker,
                    s.ksusesvc                                         "SERVICE_NAME",
                    s.ksusefix                                         "FIXED_TABLE_SEQUENCE",
                    s.ksuseqcsid                                       "QC",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 2147418112) / 65536)    "BLOCKING_INSTANCE",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 65535))                 "BLOCKING_SESSION",
                    NULL                                               "FINAL_BLOCKING_INSTANCE",
                    NULL                                               "FINAL_BLOCKING_SESSION"
                FROM
                    x$ksuse    s,
                    v$database d
                WHERE
                        s.indx != (
                            SELECT DISTINCT
                                sid
                            FROM
                                v$mystat
                            WHERE
                                ROWNUM < 2
                        )
                    AND bitand(s.ksspaflg, 1) != 0
                    AND bitand(s.ksuseflg, 1) != 0
                    AND ( ( s.ksusetim != 0
                            AND bitand(s.ksuseidl, 11) = 1 )
                        AND s.ksuseopc NOT IN (
                        SELECT
                            event#
                        FROM
                            v$event_name
                        WHERE
                            wait_class = 'Idle'
                    ) )
            ]';
        WHEN l_ver = '11.1' THEN
   -- Oracle version 11.1
            EXECUTE IMMEDIATE q'[
            CREATE OR REPLACE VIEW sashnow AS
                SELECT
                    d.dbid,
                    sysdate                                    sample_time,
                    s.indx                                     "SESSION_ID",
                    decode(s.ksusetim, 0, 'WAITING', 'ON CPU') "SESSION_STATE",
                    s.ksuseser                                 "SESSION_SERIAL#",
                    s.ksuseunm                                 "OSUSER",
                    s.ksuseflg                                 "SESSION_TYPE",
                    s.ksuudlui                                 "USER_ID",
                    s.ksuudoct                                 "COMMAND",
                    s.ksusemnm                                 "MACHINE",
                    NULL                                       "PORT",
                    s.ksusesql                                 "SQL_ADDRESS",
                    s.ksusesph                                 "SQL_PLAN_HASH_VALUE",
                    decode(s.ksusesch,
                           65535,
                           TO_NUMBER(NULL),
                           s.ksusesch)                         "SQL_CHILD_NUMBER",
                    s.ksusesqi                                 "SQL_ID",
                    s.ksuudoct                                 "SQL_OPCODE",
                    s.ksusesesta                               "SQL_EXEC_START",
                    decode(s.ksuseseid,
                           0,
                           TO_NUMBER(NULL),
                           s.ksuseseid)                        "SQL_EXEC_ID",
                    decode(s.ksusepeo,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepeo)                         "PLSQL_ENTRY_OBJECT_ID",
                    decode(s.ksusepeo,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepes)                         "PLSQL_ENTRY_SUBPROGRAM_ID",
                    decode(s.ksusepco,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepco)                         "PLSQL_OBJECT_ID",
                    decode(s.ksusepcs,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepcs)                         "PLSQL_SUBPROGRAM_ID",
                    s.ksuseopc                                 "EVENT#",
                    s.ksuseseq                                 "SEQ#",
                    s.ksusep1                                  "P1",
                    s.ksusep2                                  "P2",
                    s.ksusep3                                  "P3",
                    s.ksusetim                                 "WAIT_TIME",
                    s.ksusewtm                                 "TIME_WAITED",
                    s.ksuseobj                                 "CURRENT_OBJ#",
                    s.ksusefil                                 "CURRENT_FILE#",
                    s.ksuseblk                                 "CURRENT_BLOCK#",
                    s.ksuseslt                                 "CURRENT_ROW#",
                    s.ksusepnm                                 "PROGRAM",
                    s.ksuseapp                                 "MODULE",
                    s.ksuseaph                                 "MODULE_HASH",
                    s.ksuseact                                 "ACTION",
                    s.ksuseach                                 "ACTION_HASH",
                    s.ksuseltm                                 "LOGON_TIME",
                    s.ksuseblocker,
                    s.ksusesvc                                 "SERVICE_NAME",
                    s.ksusefix                                 "FIXED_TABLE_SEQUENCE",
                    s.ksuseqcsid                               "QC",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 2147418112) / 65536)  "BLOCKING_INSTANCE",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 65535))               "BLOCKING_SESSION",
                    NULL                                             "FINAL_BLOCKING_INSTANCE",
                    NULL                                             "FINAL_BLOCKING_SESSION"                    
                FROM
                    x$ksuse    s,
                    v$database d
                WHERE
                        s.indx != (
                            SELECT DISTINCT
                                sid
                            FROM
                                v$mystat
                            WHERE
                                ROWNUM < 2
                        )
                    AND bitand(s.ksspaflg, 1) != 0
                    AND bitand(s.ksuseflg, 1) != 0
                    AND ( ( s.ksusetim != 0
                            AND bitand(s.ksuseidl, 11) = 1 )
                        AND s.ksuseopc NOT IN (
                        SELECT
                            event#
                        FROM
                            v$event_name
                        WHERE
                            wait_class = 'Idle'
                    ) )
            ]';
        WHEN l_ver = '11.2' THEN
   -- Oracle version 11.2
            EXECUTE IMMEDIATE q'[
            CREATE OR REPLACE VIEW sashnow AS
                SELECT
                    d.dbid,
                    sysdate                                             sample_time,
                    s.indx                                              "SESSION_ID",
                    decode(s.ksusetim, 0, 'WAITING', 'ON CPU')          "SESSION_STATE",
                    s.ksuseser                                          "SESSION_SERIAL#",
                    s.ksuseunm                                          "OSUSER",
                    s.ksuseflg                                          "SESSION_TYPE",
                    s.ksuudlui                                          "USER_ID",
                    s.ksuudoct                                          "COMMAND",
                    s.ksusemnm                                          "MACHINE",
                    s.ksusemnp                                          "PORT",
                    s.ksusesql                                          "SQL_ADDRESS",
                    s.ksusesph                                          "SQL_PLAN_HASH_VALUE",
                    decode(s.ksusesch,
                        65535,
                        TO_NUMBER(NULL),
                        s.ksusesch)                                  "SQL_CHILD_NUMBER",
                    s.ksusesqi                                          "SQL_ID",
                    s.ksuudoct                                          "SQL_OPCODE",
                    s.ksusesesta                                        "SQL_EXEC_START",
                    decode(s.ksuseseid,
                        0,
                        TO_NUMBER(NULL),
                        s.ksuseseid)                                 "SQL_EXEC_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepeo)                                  "PLSQL_ENTRY_OBJECT_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepes)                                  "PLSQL_ENTRY_SUBPROGRAM_ID",
                    decode(s.ksusepco,
                        0,
                        TO_NUMBER(NULL),
                        decode(bitand(s.ksusstmbv,
                                        power(2, 11)),
                                power(2, 11),
                                s.ksusepco,
                                TO_NUMBER(NULL)))                     "PLSQL_OBJECT_ID",
                    decode(s.ksusepcs,
                        0,
                        TO_NUMBER(NULL),
                        decode(bitand(s.ksusstmbv,
                                        power(2, 11)),
                                power(2, 11),
                                s.ksusepcs,
                                TO_NUMBER(NULL)))                     "PLSQL_SUBPROGRAM_ID",
                    s.ksuseopc                                          "EVENT#",
                    s.ksuseseq                                          "SEQ#",
                    s.ksusep1                                           "P1",
                    s.ksusep2                                           "P2",
                    s.ksusep3                                           "P3",
                    s.ksusetim                                          "WAIT_TIME",
                    s.ksusewtm                                          "TIME_WAITED",
                    s.ksuseobj                                          "CURRENT_OBJ#",
                    s.ksusefil                                          "CURRENT_FILE#",
                    s.ksuseblk                                          "CURRENT_BLOCK#",
                    s.ksuseslt                                          "CURRENT_ROW#",
                    s.ksusepnm                                          "PROGRAM",
                    s.ksuseapp                                          "MODULE",
                    s.ksuseaph                                          "MODULE_HASH",
                    s.ksuseact                                          "ACTION",
                    s.ksuseach                                          "ACTION_HASH",
                    s.ksuseltm                                          "LOGON_TIME",
                    s.ksuseblocker,
                    s.ksusesvc                                          "SERVICE_NAME",
                    s.ksusefix                                          "FIXED_TABLE_SEQUENCE",
                    s.ksuseqcsid                                        "QC",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 2147418112) / 65536)  "BLOCKING_INSTANCE",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 65535))               "BLOCKING_SESSION",
                    decode(s.ksusefblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksusefblocker, 2147418112) / 65536) "FINAL_BLOCKING_INSTANCE",
                    decode(s.ksusefblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksusefblocker, 65535))              "FINAL_BLOCKING_SESSION"
                FROM
                    x$ksuse    s,
                    v$database d
                WHERE
                        s.indx != (
                            SELECT DISTINCT
                                sid
                            FROM
                                v$mystat
                            WHERE
                                ROWNUM < 2
                        )
                    AND bitand(s.ksspaflg, 1) != 0
                    AND bitand(s.ksuseflg, 1) != 0
                    AND ( ( s.ksusetim != 0
                            AND bitand(s.ksuseidl, 11) = 1 )
                        AND s.ksuseopc NOT IN (
                        SELECT
                            event#
                        FROM
                            v$event_name
                        WHERE
                            wait_class = 'Idle'
                    ) )
            ]';
        WHEN substr(l_ver, 1, 2) = '12' THEN
    -- Oracle version 12c
            EXECUTE IMMEDIATE q'[
            CREATE OR REPLACE VIEW sashnow AS
                SELECT
                    d.con_dbid                                          dbid,
                    sysdate                                             sample_time,
                    s.indx                                              "SESSION_ID",
                    decode(s.ksusetim, 0, 'WAITING', 'ON CPU')          "SESSION_STATE",
                    s.ksuseser                                          "SESSION_SERIAL#",
                    s.ksuseunm                                          "OSUSER",
                    s.ksuseflg                                          "SESSION_TYPE",
                    s.ksuudlui                                          "USER_ID",
                    s.ksuudoct                                          "COMMAND",
                    s.ksusemnm                                          "MACHINE",
                    s.ksusemnp                                          "PORT",
                    s.ksusesql                                          "SQL_ADDRESS",
                    s.ksusesph                                          "SQL_PLAN_HASH_VALUE",
                    decode(s.ksusesch,
                        65535,
                        TO_NUMBER(NULL),
                        s.ksusesch)                                  "SQL_CHILD_NUMBER",
                    s.ksusesqi                                          "SQL_ID",
                    s.ksuudoct                                          "SQL_OPCODE",
                    s.ksusesesta                                        "SQL_EXEC_START",
                    decode(s.ksuseseid,
                        0,
                        TO_NUMBER(NULL),
                        s.ksuseseid)                                 "SQL_EXEC_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepeo)                                  "PLSQL_ENTRY_OBJECT_ID",
                    decode(s.ksusepeo,
                        0,
                        TO_NUMBER(NULL),
                        s.ksusepes)                                  "PLSQL_ENTRY_SUBPROGRAM_ID",
                    decode(s.ksusepco,
                        0,
                        TO_NUMBER(NULL),
                        decode(bitand(s.ksusstmbv,
                                        power(2, 11)),
                                power(2, 11),
                                s.ksusepco,
                                TO_NUMBER(NULL)))                     "PLSQL_OBJECT_ID",
                    decode(s.ksusepcs,
                        0,
                        TO_NUMBER(NULL),
                        decode(bitand(s.ksusstmbv,
                                        power(2, 11)),
                                power(2, 11),
                                s.ksusepcs,
                                TO_NUMBER(NULL)))                     "PLSQL_SUBPROGRAM_ID",
                    s.ksuseopc                                          "EVENT#",
                    s.ksuseseq                                          "SEQ#",
                    s.ksusep1                                           "P1",
                    s.ksusep2                                           "P2",
                    s.ksusep3                                           "P3",
                    s.ksusetim                                          "WAIT_TIME",
                    s.ksusewtm                                          "TIME_WAITED",
                    s.ksuseobj                                          "CURRENT_OBJ#",
                    s.ksusefil                                          "CURRENT_FILE#",
                    s.ksuseblk                                          "CURRENT_BLOCK#",
                    s.ksuseslt                                          "CURRENT_ROW#",
                    s.ksusepnm                                          "PROGRAM",
                    s.ksuseapp                                          "MODULE",
                    s.ksuseaph                                          "MODULE_HASH",
                    s.ksuseact                                          "ACTION",
                    s.ksuseach                                          "ACTION_HASH",
                    s.ksuseltm                                          "LOGON_TIME",
                    s.ksuseblocker,
                    s.ksusesvc                                          "SERVICE_NAME",
                    s.ksusefix                                          "FIXED_TABLE_SEQUENCE",
                    s.ksuseqcsid                                        "QC",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 2147418112) / 65536)  "BLOCKING_INSTANCE",
                    decode(s.ksuseblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksuseblocker, 65535))               "BLOCKING_SESSION",
                    decode(s.ksusefblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksusefblocker, 2147418112) / 65536) "FINAL_BLOCKING_INSTANCE",
                    decode(s.ksusefblocker,
                        4294967295,
                        TO_NUMBER(NULL),
                        4294967294,
                        TO_NUMBER(NULL),
                        4294967293,
                        TO_NUMBER(NULL),
                        4294967292,
                        TO_NUMBER(NULL),
                        4294967291,
                        TO_NUMBER(NULL),
                        bitand(s.ksusefblocker, 65535))              "FINAL_BLOCKING_SESSION"
                FROM
                    x$ksuse    s,
                    v$database d
                WHERE
                        s.indx != (
                            SELECT DISTINCT
                                sid
                            FROM
                                v$mystat
                            WHERE
                                ROWNUM < 2
                        )
                    AND bitand(s.ksspaflg, 1) != 0
                    AND bitand(s.ksuseflg, 1) != 0
                    AND ( ( s.ksusetim != 0
                            AND bitand(s.ksuseidl, 11) = 1 )
                        AND s.ksuseopc NOT IN (
                        SELECT
                            event#
                        FROM
                            v$event_name
                        WHERE
                            wait_class = 'Idle'
                    ) )
            ]';
        WHEN substr(l_ver, 1, 2) = '19' THEN
    -- Oracle version 19c
            EXECUTE IMMEDIATE q'[
            CREATE OR REPLACE VIEW sashnow AS
                SELECT
                    d.con_dbid                                           dbid,
                    sysdate                                              sample_time,
                    s.indx                                               "SESSION_ID",
                    decode(s.ksusetim, 0, 'WAITING', 'ON CPU')           "SESSION_STATE",
                    s.ksuseser                                           "SESSION_SERIAL#",
                    s.ksuseunm                                           "OSUSER",
                    s.ksuseflg                                           "SESSION_TYPE",
                    s.ksuudlui                                           "USER_ID",
                    s.ksuudoct                                           "COMMAND",
                    s.ksusemnm                                           "MACHINE",
                    s.ksusemnp                                           "PORT",
                    s.ksusesql                                           "SQL_ADDRESS",
                    s.ksusesph                                           "SQL_PLAN_HASH_VALUE",
                    decode(s.ksusesch,
                           65535,
                           TO_NUMBER(NULL),
                           s.ksusesch)                                   "SQL_CHILD_NUMBER",
                    s.ksusesqi                                           "SQL_ID",
                    s.ksuudoct                                           "SQL_OPCODE",
                    s.ksusesesta                                         "SQL_EXEC_START",
                    decode(s.ksuseseid,
                           0,
                           TO_NUMBER(NULL),
                           s.ksuseseid)                                  "SQL_EXEC_ID",
                    decode(s.ksusepeo,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepeo)                                   "PLSQL_ENTRY_OBJECT_ID",
                    decode(s.ksusepeo,
                           0,
                           TO_NUMBER(NULL),
                           s.ksusepes)                                   "PLSQL_ENTRY_SUBPROGRAM_ID",
                    decode(s.ksusepco,
                           0,
                           TO_NUMBER(NULL),
                           decode(bitand(s.ksusstmbv,
                                         power(2, 11)),
                                  power(2, 11),
                                  s.ksusepco,
                                  TO_NUMBER(NULL)))                      "PLSQL_OBJECT_ID",
                    decode(s.ksusepcs,
                           0,
                           TO_NUMBER(NULL),
                           decode(bitand(s.ksusstmbv,
                                         power(2, 11)),
                                  power(2, 11),
                                  s.ksusepcs,
                                  TO_NUMBER(NULL)))                      "PLSQL_SUBPROGRAM_ID",
                    s.ksuseopc                                           "EVENT#",
                    s.ksuseseq                                           "SEQ#",
                    s.ksusep1                                            "P1",
                    s.ksusep2                                            "P2",
                    s.ksusep3                                            "P3",
                    s.ksusetim                                           "WAIT_TIME",
                    s.ksusewtm                                           "TIME_WAITED",
                    s.ksuseobj                                           "CURRENT_OBJ#",
                    s.ksusefil                                           "CURRENT_FILE#",
                    s.ksuseblk                                           "CURRENT_BLOCK#",
                    s.ksuseslt                                           "CURRENT_ROW#",
                    s.ksusepnm                                           "PROGRAM",
                    s.ksuseapp                                           "MODULE",
                    s.ksuseaph                                           "MODULE_HASH",
                    s.ksuseact                                           "ACTION",
                    s.ksuseach                                           "ACTION_HASH",
                    s.ksuseltm                                           "LOGON_TIME",
                    s.ksuseblocker,
                    s.ksusesvc                                           "SERVICE_NAME",
                    s.ksusefix                                           "FIXED_TABLE_SEQUENCE",
                    s.ksuseqcsid                                         "QC",
                    decode(s.ksuseblocker,
                           4294967295,
                           TO_NUMBER(NULL),
                           4294967294,
                           TO_NUMBER(NULL),
                           4294967293,
                           TO_NUMBER(NULL),
                           4294967292,
                           TO_NUMBER(NULL),
                           4294967291,
                           TO_NUMBER(NULL),
                           bitand(s.ksuseblocker, 2147221504) / 262144)  "BLOCKING_INSTANCE",
                    decode(s.ksuseblocker,
                           4294967295,
                           TO_NUMBER(NULL),
                           4294967294,
                           TO_NUMBER(NULL),
                           4294967293,
                           TO_NUMBER(NULL),
                           4294967292,
                           TO_NUMBER(NULL),
                           4294967291,
                           TO_NUMBER(NULL),
                           bitand(s.ksuseblocker, 262143))               "BLOCKING_SESSION",
                    decode(s.ksusefblocker,
                           4294967295,
                           TO_NUMBER(NULL),
                           4294967294,
                           TO_NUMBER(NULL),
                           4294967293,
                           TO_NUMBER(NULL),
                           4294967292,
                           TO_NUMBER(NULL),
                           4294967291,
                           TO_NUMBER(NULL),
                           bitand(s.ksusefblocker, 2147221504) / 262144) "FINAL_BLOCKING_INSTANCE",
                    decode(s.ksusefblocker,
                           4294967295,
                           TO_NUMBER(NULL),
                           4294967294,
                           TO_NUMBER(NULL),
                           4294967293,
                           TO_NUMBER(NULL),
                           4294967292,
                           TO_NUMBER(NULL),
                           4294967291,
                           TO_NUMBER(NULL),
                           bitand(s.ksusefblocker, 262143))              "FINAL_BLOCKING_SESSION"
                FROM
                    x$ksuse    s,
                    v$database d
                WHERE
                        s.indx != (
                            SELECT DISTINCT
                                sid
                            FROM
                                v$mystat
                            WHERE
                                ROWNUM < 2
                        )
                    AND bitand(s.ksspaflg, 1) != 0
                    AND bitand(s.ksuseflg, 1) != 0
                    AND bitand(s.ksuseidl, 9) = 1
                    AND s.ksuseopc NOT IN (
                        SELECT
                            event#
                        FROM
                            v$event_name
                        WHERE
                            wait_class = 'Idle'
                    )
            ]';
        ELSE
            dbms_output.put_line('Not a tested and valid Oracle version for orasash');
    END CASE;
END;
/

grant select on sys.sashnow to sash;
exit;