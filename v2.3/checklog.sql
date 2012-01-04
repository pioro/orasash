set linesize 200
col message format a100
col result format a1
col action format a48
col start_time format a25
select result, to_char(start_time,'YYYY-MM-DD HH24:MI:SS') start_time, action, message from sash_log order by log_id;
