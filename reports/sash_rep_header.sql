set linesize 200
set termout off
column f_st new_value dstarttime
select to_char(sysdate-1/24,'DD/MM/YYYY HH24:MI') f_st from dual;
column f_st1 new_value dstoptime
select to_char(sysdate,'DD/MM/YYYY HH24:MI') f_st1 from dual;
set termout on
set ver off
set feedback off

accept starttime date default "&DSTARTTIME" for 'DD/MM/YYYY HH24:MI' prompt 'start date DD/MM/YYYY HH24:MI (default sysdate-1/24): '
accept stoptime date default "&DSTOPTIME" for 'DD/MM/YYYY HH24:MI' prompt 'stop date DD/MM/YYYY HH24:MI (default sysdate): '

set term off
column v_samplesize new_value dsamplesize
column v_elapsed_time new_value delapsed_time
select count(*) v_samplesize from v$active_session_history
where sample_time >= to_date('&starttime','DD/MM/YYYY HH24:MI:SS')
and sample_time <= to_date('&stoptime','DD/MM/YYYY HH24:MI:SS');
select (to_date('&stoptime','DD/MM/YYYY HH24:MI') - to_date('&starttime','DD/MM/YYYY HH24:MI'))*24*60*60 v_elapsed_time from dual;
set term on

set echo off
set serveroutput on size 1000000
set long 1000000

SET MARKUP HTML ON 


set termout off
SET MARKUP HTML OFF
column v_dbname new_value ddbname ENTMAP OFF
--select '<H1>SASH report for ' || sid || ' </H1>' v_dbname from sash_targets where dbid = (select dbid from sash_target);
select '<H1>SASH report for ' || name || ' </H1>' v_dbname from v$database;
set termout on

spool c:\test.html
prompt <HTML><HEAD><TITLE>SASH</TITLE> -
<style type='text/css'> -
body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} -
p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} -
table,td {font:10pt Arial,Helvetica,sans-serif; color:Black; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} -
th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} -
h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} -
h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} -
a {font:9pt Arial,Helvetica,sans-serif; color:#663300; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} -
tr.odd_row { background: #cccc99; } -
td.sqlid { background: white; } -
</style> -
<script language='JavaScript'> 
prompt window.onload = start; -
function start(){ -
var table = document.getElementById('tabbed'); -
var allTRs = table.getElementsByTagName('tr'); -
for (i=1; i <= allTRs.length ; i++) { -
if (i % 2 == 0) -
allTRs[i].className = "odd_row"; } } -
</script> -
<title>Sash report</title> -
</head><body> 


SET MARKUP HTML ON

@header "&ddbname"
@anch top

--select sid name, dbid, version release, host from sash_targets where dbid = (select dbid from sash_target);
select name, dbid from v$database;
prompt 
@header "<H2>Top Events</H2>"
@header "<UL>"
@header "<LI><A HREF='#userevents'>User Top Events</A></LI>"
@header "<LI><A HREF='#backevents'>Background Top Events</A></LI>"
@header "</UL>"
@header "<A HREF='#top'>Back to Top</A>"
@header "<H2>Top User Events</H2>"
@anch userevents
define SESS_TYPE='FOREGROUND'
@top_events_body.sql
prompt 
@header "<H2>Top Background Events</H2>"
@anch backevents
define SESS_TYPE='BACKGROUND'
@top_events_body.sql
@header "<H2>Top 10 SQLs</H2>"
@top_10_sql_with_waits.sql
@header "<H2>Top 10 SQLs text</H2>"
@top_10_sql_txt.sql
@header "<H2>Top 10 SQL events</H2>"
@top_10_sql_with_waits_split.sql

SET MARKUP HTML ON
spool off
SET MARKUP HTML OFF